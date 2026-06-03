//================================================================================
// Module: ucie_TX_Data_to_Clock_eye_sweep
// Description: TX-side eye sweep test module for UCIe link training
//              Performs data-to-clock eye diagram measurement by generating test
//              patterns and collecting results from the remote RX side
//================================================================================

module ucie_TX_Data_to_Clock_eye_sweep # (
    parameter DECODING_WIDTH = 9,   // Width of command decoding input
    parameter DATA_WIDTH = 64,       // Width of data input/output
    parameter INFO_WIDTH = 16,      // Width of info/control output
    parameter MAXIMUM_ITERATIONS = 4,      // Maximum number of test retry iterations

    parameter logic [63:0] data_DATA_FIELD = {
        4'b0000,       // [63:60] Reserved
        1'b0,          // [59]    Comparison Mode (Per Lane)
        16'd1,         // [58:43] Iteration Count
        16'd0,         // [42:27] Idle Count
        16'd4000,      // [26:11] Burst Count
        1'b0,          // [10]    Pattern Mode (Continuous)
        4'h0,          // [9:6]   Clock Phase (Clock PI Center)
        3'h0,          // [5:3]   Valid Pattern (Functional)
        3'h0           // [2:0]   Data Pattern (LFSR)
    },

    parameter logic [63:0] valid_DATA_FIELD = {
        4'b0000,       // [63:60] Reserved
        1'b0,          // [59]    Comparison Mode (Per Lane)
        16'd1,         // [58:43] Iteration Count
        16'd0,         // [42:27] Idle Count
        16'd128,       // [26:11] Burst Count
        1'b0,          // [10]    Pattern Mode (Continuous)
        4'h0,          // [9:6]   Clock Phase (Clock PI Center)
        3'h0,          // [5:3]   Valid Pattern (Functional)
        3'h0           // [2:0]   Data Pattern (LFSR)
    },

    parameter ERROR_THRESHOLD = 1   // Error threshold for test pass/fail
) (
    // Clock and reset
    input i_clk,
    input i_reset,
    
    // Interface inputs - from remote side
    input [DECODING_WIDTH-1:0] i_xx_decoding,  // Decoded command from remote
    input [DATA_WIDTH-1:0] i_xx_data,          // Data from remote
    input [INFO_WIDTH-1:0] i_xx_info,          // Data from remote
    input [7:0] i_xx_sweep_result,             // Eye sweep results from remote
    
    // Sideband control inputs
    input i_sb_xx_req,     // Sideband request from remote
    input i_sb_xx_rsp,     // Sideband response from remote
    input i_sb_xx_done,    // Sideband done from remote
    input i_xx_done,       // Operation complete
    
    // Control inputs
    input done_ack,        // Acknowledgement of done signal
    input init,            // Initialize mode flag
    input no_retry,        // Disable retry on test failure
    input comparison_type,        // 0:data, 1:valid
    
    // Interface outputs - to remote side
    output logic [DECODING_WIDTH-1:0] o_xx_encoding,  // Encoded command to send
    output logic [DATA_WIDTH-1:0] o_xx_data,          // Data to send
    output logic [INFO_WIDTH-1:0] o_xx_info,          // Info/control to send
    
    // Sideband control outputs
    output logic o_xx_sb_req,   // Sideband request to remote
    output logic o_xx_sb_rsp,   // Sideband response to remote
    
    // Status outputs
    output logic train_error,   // Training error occurred
    output logic failed_test,   // Current test failed
    output logic [DATA_WIDTH-1:0] per_lane_result,   // Current test failed
    output logic done           // Eye sweep test complete
);

//================================================================================
// State Machine Definitions
//================================================================================

// State encoding for eye sweep sequence
localparam REQ_HANDSHAKE = 3'b000;            // Initial request handshake
localparam LFSR_HANDSHAKE = 3'b001;           // LFSR (pseudo-random) setup handshake
localparam DATA_GENERATE = 3'b010;            // Data pattern generation state
localparam RESULT_HANDSHAKE = 3'b011;         // Result collection handshake
localparam SWEEP_RESULT_HANDSHAKE = 3'b100;   // Sweep parameter result handshake
localparam END_HANDSHAKE = 3'b101;            // Final completion handshake

// State registers
logic [2:0] CS;  // Current state
logic [2:0] NS;  // Next state

logic [2:0] count;
logic [2:0] count_reg;

logic [DATA_WIDTH-1:0] per_lane_result_old;
logic failed_test_old;

//================================================================================
// State Machine Sequential Logic
//================================================================================

// State register update
always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        CS <= REQ_HANDSHAKE;  // Reset to initial state
        count <= 0;
    end else begin
        CS <= NS;             // Advance to next state
        count <= count_reg;   // Update count register
    end
end

always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        failed_test_old     <= 1'b0;
    end else begin
        per_lane_result_old <= per_lane_result;  // Capture previous per-lane result for reporting
        failed_test_old     <= failed_test;      // Capture previous test result for reporting
    end
end


//================================================================================
// Main State Machine Combinational Logic
//================================================================================
always @(*) begin
        o_xx_sb_req = 0;
        o_xx_sb_rsp = 0;
        done = 0;
        train_error = 0;
        o_xx_sb_rsp = 0;
        o_xx_info = 0;
        o_xx_data = 0;
        per_lane_result = per_lane_result_old;
        count_reg = count;
        failed_test = failed_test_old;
        NS = CS;
        o_xx_encoding = 0;
        // Two different sequences based on init flag
        if (init) begin
            //====================================================================
            // INITIALIZATION MODE - TX initiates the test
            //====================================================================
            case (CS)
                // State 0: Send initial test request
                REQ_HANDSHAKE: begin
                    o_xx_encoding = 'h180;  // Request encoding
                    done = 0;
                    count_reg = 0;  // Reset retry count
                    train_error = 0;
                    o_xx_sb_rsp = 0;

                    // Request handshake with acknowledge
                    if (done_ack) o_xx_sb_req = 0;
                    else o_xx_sb_req = 1;

                    o_xx_info = ERROR_THRESHOLD;  // Send error threshold parameter

                    if (comparison_type) begin
                        o_xx_data = valid_DATA_FIELD;  // Send error threshold parameter
                    end else begin
                        o_xx_data = data_DATA_FIELD;  // Send data pattern parameters
                    end

                    // Wait for matching response
                    if (i_sb_xx_rsp && i_xx_decoding == 'h180) begin
                        o_xx_encoding = 'h181;  // LFSR setup encoding
                        NS = LFSR_HANDSHAKE;
                        o_xx_sb_req = 0;
                        o_xx_sb_rsp = 0;
                    end 
                    else NS = REQ_HANDSHAKE;
                end 

                // State 1: Setup LFSR (Linear Feedback Shift Register) for pattern generation
                LFSR_HANDSHAKE: begin
                    o_xx_encoding = 'h181;  // LFSR setup encoding
                    done = 0;

                    if (done_ack) o_xx_sb_req = 0;
                    else o_xx_sb_req = 1;

                    // Wait for LFSR setup confirmation
                    if (i_sb_xx_rsp && i_xx_decoding == 'h181) begin
                        o_xx_encoding = 'h182;  // Data generation encoding
                        count_reg = count + 1;  // Increment count for retries
                        NS = DATA_GENERATE;
                        o_xx_sb_req = 0;
                        o_xx_sb_rsp = 0;
                    end 
                    else NS = LFSR_HANDSHAKE;
                end 

                // State 2: Generate test data patterns
                DATA_GENERATE: begin
                    o_xx_encoding = 'h182;  // Data generation encoding
                    done = 0;

                    // Wait for data generation to complete
                    if (i_xx_done) begin
                        o_xx_encoding = 'h183;  // Result collection encoding
                        NS = RESULT_HANDSHAKE;
                        o_xx_sb_req = 0;
                        o_xx_sb_rsp = 0;
                    end
                    else NS = DATA_GENERATE;
                end 

                // State 3: Collect test results from RX
                RESULT_HANDSHAKE: begin
                    o_xx_encoding = 'h183;  // Result collection encoding
                    done = 0;

                    if (done_ack) o_xx_sb_req = 0;
                    else o_xx_sb_req = 1;

                    // Check result and decide on retry
                    if (i_sb_xx_rsp && i_xx_decoding == 'h183) begin
                        failed_test = !(&i_xx_data);  // Test fails if any bit is 0
                        per_lane_result = i_xx_data;  // Capture per-lane results for reporting
                        // Retry if failed and retries allowed, otherwise complete
                        if (failed_test && !no_retry) begin
                            if (count == MAXIMUM_ITERATIONS) begin
                                train_error = 1;  // Mark training error if max retries reached
                            end else begin
                                o_xx_encoding = 'h181;  // LFSR setup encoding
                                NS = LFSR_HANDSHAKE;
                                o_xx_sb_req = 0;
                                o_xx_sb_rsp = 0;
                                train_error = 0;  // Clear training error for retry
                            end 
                        end else begin
                            o_xx_encoding = 'h184;  // End encoding
                            NS = END_HANDSHAKE;
                            o_xx_sb_req = 0;
                            o_xx_sb_rsp = 0;
                        end
                    end else NS = RESULT_HANDSHAKE;

                end 

                // State 4: Final handshake to complete test
                END_HANDSHAKE: begin
                    o_xx_encoding = 'h184;  // End encoding

                    if (done_ack) o_xx_sb_req = 0;
                    else o_xx_sb_req = 1;

                    // Signal completion when acknowledged
                    if (i_sb_xx_rsp && i_xx_decoding == 'h184) done = 1;
                    else done = 0;
                end 
            endcase
        end else begin
            //====================================================================
            // NON-INITIALIZATION MODE - TX responds to RX-initiated test
            //====================================================================
            case (CS)
                // State 0: Respond to initial test request
                REQ_HANDSHAKE: begin
                    o_xx_encoding = 'h188;  // Response encoding
                    done = 0;
                    count_reg = 0;  // Reset retry count
                    train_error = 0;

                    // Response handshake
                    if (i_sb_xx_done) o_xx_sb_rsp = 0;
                    else o_xx_sb_rsp = 1;

                    // Wait for done signal
                    if (i_sb_xx_done) begin
                        o_xx_info = i_xx_info;  // Send error threshold parameter
                        o_xx_encoding = 'h189;  // LFSR setup encoding
                        NS = LFSR_HANDSHAKE;
                        o_xx_sb_req = 0;
                        o_xx_sb_rsp = 0;
                    end
                    else NS = REQ_HANDSHAKE;
                end 

                // State 1: Setup LFSR for pattern generation
                LFSR_HANDSHAKE: begin
                    o_xx_encoding = 'h189;  // LFSR setup encoding
                    done = 0;

                    if (done_ack) o_xx_sb_req = 0;
                    else o_xx_sb_req = 1;

                    if (i_sb_xx_rsp && i_xx_decoding == 'h181) begin
                        o_xx_encoding = 'h18A;  // Data generation encoding
                        count_reg = count + 1;  // Increment count for retries
                        NS = DATA_GENERATE;
                        o_xx_sb_req = 0;
                        o_xx_sb_rsp = 0;
                    end 
                    else NS = LFSR_HANDSHAKE;
                end 

                // State 2: Generate test data patterns
                DATA_GENERATE: begin
                    o_xx_encoding = 'h18A;  // Data generation encoding
                    done = 0;

                    if (i_xx_done) begin
                        o_xx_encoding = 'h18B;  // Result collection encoding
                        o_xx_sb_req = 0;
                        o_xx_sb_rsp = 0;
                        NS = RESULT_HANDSHAKE;
                    end
                    else NS = DATA_GENERATE;
                end

                // State 3: Collect test results
                RESULT_HANDSHAKE: begin
                    o_xx_encoding = 'h18B;  // Result collection encoding
                    done = 0;

                    if (done_ack) o_xx_sb_req = 0;
                    else o_xx_sb_req = 1;
                    

                    // Check result and decide on retry
                    if (i_sb_xx_rsp && i_xx_decoding == 'h18B) begin
                        failed_test = !(&i_xx_data);  // Test fails if any bit is 0
                        per_lane_result = i_xx_data;  // Capture per-lane results for reporting
                        // Retry if failed and retries allowed, otherwise get sweep result
                        if (failed_test && !no_retry) begin
                            if (count == MAXIMUM_ITERATIONS) begin
                                train_error = 1;  // Mark training error if max retries reached
                            end else begin
                                o_xx_encoding = 'h189;  // LFSR setup encoding
                                NS = LFSR_HANDSHAKE;
                                o_xx_sb_req = 0;
                                o_xx_sb_rsp = 0;
                                train_error = 0;  // Clear training error for retry
                            end
                        end else begin
                            o_xx_encoding = 'h18C;  // Sweep result encoding
                            o_xx_sb_req = 0;
                            o_xx_sb_rsp = 0;
                            NS = SWEEP_RESULT_HANDSHAKE;
                        end
                    end else NS = RESULT_HANDSHAKE;
                end 

                // State 4: Send sweep parameter results
                SWEEP_RESULT_HANDSHAKE: begin
                    o_xx_encoding = 'h18C;  // Sweep result encoding
                    done = 0;
                    o_xx_data = i_xx_sweep_result;  // Send sweep measurement data

                    if (done_ack) o_xx_sb_req = 0;
                    else o_xx_sb_req = 1;

                    // Wait for acknowledgement
                    if (i_sb_xx_req && i_xx_decoding == 'h18D) begin
                        o_xx_encoding = 'h18D;  // End encoding
                        NS = END_HANDSHAKE;
                        o_xx_sb_req = 0;
                        o_xx_sb_rsp = 0;
                    end
                    else NS = SWEEP_RESULT_HANDSHAKE;
                end 

                // State 5: Final handshake to complete test
                END_HANDSHAKE: begin
                    o_xx_encoding = 'h18D;  // End encoding
                    o_xx_data = 0;          // Clear data

                    // Response handshake
                    if (i_sb_xx_done) o_xx_sb_rsp = 0;
                    else o_xx_sb_rsp = 1;

                    // Signal completion when done received
                    if (i_sb_xx_done) done = 1;
                    else done = 0;
                end 
            endcase
        end
    end

`ifdef ASSERT_ON

    property reset_state_property;
        @(posedge i_clk)
        i_reset |=> (CS == REQ_HANDSHAKE);
    endproperty

    property reset_count_property;
        @(posedge i_clk)
        i_reset |=> (count == 0);
    endproperty

    property valid_state_init_property;
        @(posedge i_clk) disable iff (i_reset)
        init |-> (CS == REQ_HANDSHAKE) || (CS == LFSR_HANDSHAKE) || (CS == DATA_GENERATE) || (CS == RESULT_HANDSHAKE) || (CS == END_HANDSHAKE);
    endproperty

    property state_transition_property;
        @(posedge i_clk) disable iff (i_reset)
        (CS != NS) && (!i_reset) |=> (CS == $past(NS));
    endproperty

    property init_req_to_lfsr_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == REQ_HANDSHAKE && i_sb_xx_rsp && i_xx_decoding == 'h180) |=> (CS == LFSR_HANDSHAKE);
    endproperty

    property init_lfsr_to_data_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == LFSR_HANDSHAKE && i_sb_xx_rsp && i_xx_decoding == 'h181) |=> (CS == DATA_GENERATE);
    endproperty

    property init_data_to_result_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == DATA_GENERATE && i_xx_done) |=> (CS == RESULT_HANDSHAKE);
    endproperty

    property init_result_to_end_pass_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == RESULT_HANDSHAKE && i_sb_xx_rsp && i_xx_decoding == 'h183 && &i_xx_data) |=> (CS == END_HANDSHAKE);
    endproperty

    property init_result_to_lfsr_retry_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == RESULT_HANDSHAKE && i_sb_xx_rsp && i_xx_decoding == 'h183 && !(&i_xx_data) && !no_retry && count != MAXIMUM_ITERATIONS-1) |=> (CS == LFSR_HANDSHAKE);
    endproperty

    property init_done_at_end_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == END_HANDSHAKE && i_sb_xx_rsp && i_xx_decoding == 'h184) |-> done;
    endproperty

    property done_low_not_end_init_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS != END_HANDSHAKE) |-> !done;
    endproperty

    property count_reset_at_req_init_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == REQ_HANDSHAKE) |-> (count_reg == 0);
    endproperty

    property count_increment_init_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == LFSR_HANDSHAKE && i_sb_xx_rsp && i_xx_decoding == 'h181) |=> (count == $past(count) + 1);
    endproperty

    property train_error_max_retry_init_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == RESULT_HANDSHAKE && i_sb_xx_rsp && i_xx_decoding == 'h183 && !(&i_xx_data) && !no_retry && count == MAXIMUM_ITERATIONS-1) |-> train_error;
    endproperty

    property train_error_low_at_req_init_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == REQ_HANDSHAKE) |-> !train_error;
    endproperty

    property failed_test_init_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == RESULT_HANDSHAKE && i_sb_xx_rsp && i_xx_decoding == 'h183 && !(&i_xx_data)) |-> failed_test;
    endproperty

    property pass_test_init_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == RESULT_HANDSHAKE && i_sb_xx_rsp && i_xx_decoding == 'h183 && &i_xx_data) |-> !failed_test;
    endproperty

    property init_req_sb_req_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == REQ_HANDSHAKE && NS == REQ_HANDSHAKE && !done_ack) |-> o_xx_sb_req;
    endproperty

    property init_req_sb_req_deassert_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == REQ_HANDSHAKE && done_ack) |-> !o_xx_sb_req;
    endproperty

    property init_info_threshold_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == REQ_HANDSHAKE) |-> (o_xx_info == ERROR_THRESHOLD);
    endproperty

    property init_encoding_req_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == REQ_HANDSHAKE && !(i_sb_xx_rsp && i_xx_decoding == 'h180)) && !i_reset |-> (o_xx_encoding == 'h180);
    endproperty

    property init_encoding_lfsr_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == LFSR_HANDSHAKE && !(i_sb_xx_rsp && i_xx_decoding == 'h181)) |-> (o_xx_encoding == 'h181);
    endproperty

    property init_encoding_data_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == DATA_GENERATE && !i_xx_done) |-> (o_xx_encoding == 'h182);
    endproperty

    property init_encoding_result_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == RESULT_HANDSHAKE && !(i_sb_xx_rsp && i_xx_decoding == 'h183)) |-> (o_xx_encoding == 'h183);
    endproperty

    property init_encoding_end_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == END_HANDSHAKE) |-> (o_xx_encoding == 'h184);
    endproperty

    property req_stays_without_rsp_init_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == REQ_HANDSHAKE && !(i_sb_xx_rsp && i_xx_decoding == 'h180)) |=> (CS == REQ_HANDSHAKE);
    endproperty

    property lfsr_stays_without_rsp_init_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == LFSR_HANDSHAKE && !(i_sb_xx_rsp && i_xx_decoding == 'h181)) |=> (CS == LFSR_HANDSHAKE);
    endproperty

    property data_stays_without_done_init_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == DATA_GENERATE && !i_xx_done) |=> (CS == DATA_GENERATE);
    endproperty

    property result_stays_without_rsp_init_property;
        @(posedge i_clk) disable iff (i_reset)
        (init && CS == RESULT_HANDSHAKE && !(i_sb_xx_rsp && i_xx_decoding == 'h183)) |=> (CS == RESULT_HANDSHAKE);
    endproperty

    property count_max_value_property;
        @(posedge i_clk) disable iff (i_reset)
        (count <= MAXIMUM_ITERATIONS-1);
    endproperty

    property mutual_exclusive_req_rsp_init_req_property;
        @(posedge i_clk) disable iff (i_reset)
         !(o_xx_sb_req && o_xx_sb_rsp);
    endproperty

    reset_state_assertion: assert property (reset_state_property)
        else $error("Assertion failed: CS should be REQ_HANDSHAKE after reset");
    cover property (reset_state_property);

    reset_count_assertion: assert property (reset_count_property)
        else $error("Assertion failed: count should be 0 after reset");
    cover property (reset_count_property);

    valid_state_init_assertion: assert property (valid_state_init_property)
        else $error("Assertion failed: CS contains an invalid state value in init mode");
    cover property (valid_state_init_property);

    state_transition_assertion: assert property (state_transition_property)
        else $error("Assertion failed: state should transition to NS on state change");
    cover property (state_transition_property);

    init_req_to_lfsr_assertion: assert property (init_req_to_lfsr_property)
        else $error("Assertion failed: init mode should transition from REQ_HANDSHAKE to LFSR_HANDSHAKE");
    cover property (init_req_to_lfsr_property);

    init_lfsr_to_data_assertion: assert property (init_lfsr_to_data_property)
        else $error("Assertion failed: init mode should transition from LFSR_HANDSHAKE to DATA_GENERATE");
    cover property (init_lfsr_to_data_property);

    init_data_to_result_assertion: assert property (init_data_to_result_property)
        else $error("Assertion failed: init mode should transition from DATA_GENERATE to RESULT_HANDSHAKE");
    cover property (init_data_to_result_property);

    init_result_to_end_pass_assertion: assert property (init_result_to_end_pass_property)
        else $error("Assertion failed: init mode should transition from RESULT_HANDSHAKE to END_HANDSHAKE on pass");
    cover property (init_result_to_end_pass_property);

    init_result_to_lfsr_retry_assertion: assert property (init_result_to_lfsr_retry_property)
        else $error("Assertion failed: init mode should transition from RESULT_HANDSHAKE to LFSR_HANDSHAKE on retry");
    cover property (init_result_to_lfsr_retry_property);

    init_done_at_end_assertion: assert property (init_done_at_end_property)
        else $error("Assertion failed: done should be asserted at END_HANDSHAKE in init mode");
    cover property (init_done_at_end_property);

    done_low_not_end_init_assertion: assert property (done_low_not_end_init_property)
        else $error("Assertion failed: done should be low when not in END_HANDSHAKE in init mode");
    cover property (done_low_not_end_init_property);

    count_reset_at_req_init_assertion: assert property (count_reset_at_req_init_property)
        else $error("Assertion failed: count_reg should be 0 at REQ_HANDSHAKE in init mode");
    cover property (count_reset_at_req_init_property);

    count_increment_init_assertion: assert property (count_increment_init_property)
        else $error("Assertion failed: count should increment after LFSR_HANDSHAKE in init mode");
    cover property (count_increment_init_property);

    train_error_max_retry_init_assertion: assert property (train_error_max_retry_init_property)
        else $error("Assertion failed: train_error should be set when max retries reached in init mode");
    cover property (train_error_max_retry_init_property);

    train_error_low_at_req_init_assertion: assert property (train_error_low_at_req_init_property)
        else $error("Assertion failed: train_error should be low at REQ_HANDSHAKE in init mode");
    cover property (train_error_low_at_req_init_property);

    failed_test_init_assertion: assert property (failed_test_init_property)
        else $error("Assertion failed: failed_test should be set when data is not all ones in init mode");
    cover property (failed_test_init_property);

    pass_test_init_assertion: assert property (pass_test_init_property)
        else $error("Assertion failed: failed_test should be low when data is all ones in init mode");
    cover property (pass_test_init_property);

    init_req_sb_req_assertion: assert property (init_req_sb_req_property)
        else $error("Assertion failed: o_xx_sb_req should be asserted at REQ_HANDSHAKE when done_ack is low in init mode");
    cover property (init_req_sb_req_property);

    init_req_sb_req_deassert_assertion: assert property (init_req_sb_req_deassert_property)
        else $error("Assertion failed: o_xx_sb_req should be deasserted at REQ_HANDSHAKE when done_ack is high in init mode");
    cover property (init_req_sb_req_deassert_property);

    init_info_threshold_assertion: assert property (init_info_threshold_property)
        else $error("Assertion failed: o_xx_info should be ERROR_THRESHOLD at REQ_HANDSHAKE in init mode");
    cover property (init_info_threshold_property);

    init_encoding_req_assertion: assert property (init_encoding_req_property)
        else $error("Assertion failed: o_xx_encoding should be 'h180 at REQ_HANDSHAKE in init mode");
    cover property (init_encoding_req_property);

    init_encoding_lfsr_assertion: assert property (init_encoding_lfsr_property)
        else $error("Assertion failed: o_xx_encoding should be 'h181 at LFSR_HANDSHAKE in init mode");
    cover property (init_encoding_lfsr_property);

    init_encoding_data_assertion: assert property (init_encoding_data_property)
        else $error("Assertion failed: o_xx_encoding should be 'h182 at DATA_GENERATE in init mode");
    cover property (init_encoding_data_property);

    init_encoding_result_assertion: assert property (init_encoding_result_property)
        else $error("Assertion failed: o_xx_encoding should be 'h183 at RESULT_HANDSHAKE in init mode");
    cover property (init_encoding_result_property);

    init_encoding_end_assertion: assert property (init_encoding_end_property)
        else $error("Assertion failed: o_xx_encoding should be 'h184 at END_HANDSHAKE in init mode");
    cover property (init_encoding_end_property);

    req_stays_without_rsp_init_assertion: assert property (req_stays_without_rsp_init_property)
        else $error("Assertion failed: REQ_HANDSHAKE should stay without matching response in init mode");
    cover property (req_stays_without_rsp_init_property);

    lfsr_stays_without_rsp_init_assertion: assert property (lfsr_stays_without_rsp_init_property)
        else $error("Assertion failed: LFSR_HANDSHAKE should stay without matching response in init mode");
    cover property (lfsr_stays_without_rsp_init_property);

    data_stays_without_done_init_assertion: assert property (data_stays_without_done_init_property)
        else $error("Assertion failed: DATA_GENERATE should stay without i_xx_done in init mode");
    cover property (data_stays_without_done_init_property);

    result_stays_without_rsp_init_assertion: assert property (result_stays_without_rsp_init_property)
        else $error("Assertion failed: RESULT_HANDSHAKE should stay without matching response in init mode");
    cover property (result_stays_without_rsp_init_property);

    count_max_value_assertion: assert property (count_max_value_property)
        else $error("Assertion failed: count should not exceed MAXIMUM_ITERATIONS-1");
    cover property (count_max_value_property);

    mutual_exclusive_req_rsp_init_req_assertion: assert property (mutual_exclusive_req_rsp_init_req_property)
        else $error("Assertion failed: o_xx_sb_req and o_xx_sb_rsp should both be low on transition in init REQ_HANDSHAKE");
    cover property (mutual_exclusive_req_rsp_init_req_property);

`endif
    
endmodule