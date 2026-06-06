//================================================================================
// Module: ucie_RX_Data_to_Clock_eye_sweep
// Description: RX-side eye sweep test module for UCIe link training
//              Performs data-to-clock eye diagram measurement by detecting test
//              patterns from TX and reporting results back
//================================================================================

module ucie_RX_Data_to_Clock_eye_sweep #(
    parameter DECODING_WIDTH  = 9,   // Width of command decoding input
    parameter DATA_WIDTH      = 64,  // Width of data input/output
    parameter INFO_WIDTH      = 16,  // Width of info/control output
    parameter ERROR_THRESHOLD = 1,   // Error threshold for test pass/fail

    parameter logic [63:0] data_DATA_FIELD = {
      4'b0000,  // [63:60] Reserved
      1'b0,  // [59]    Comparison Mode (Per Lane)
      16'd1,  // [58:43] Iteration Count
      16'd0,  // [42:27] Idle Count
      16'd4000,  // [26:11] Burst Count
      1'b0,  // [10]    Pattern Mode (Continuous)
      4'h0,  // [9:6]   Clock Phase (Clock PI Center)
      3'h0,  // [5:3]   Valid Pattern (Functional)
      3'h0  // [2:0]   Data Pattern (LFSR)
    },

    parameter logic [63:0] valid_DATA_FIELD = {
      4'b0000,  // [63:60] Reserved
      1'b0,  // [59]    Comparison Mode (Per Lane)
      16'd1,  // [58:43] Iteration Count
      16'd0,  // [42:27] Idle Count
      16'd128,  // [26:11] Burst Count
      1'b0,  // [10]    Pattern Mode (Continuous)
      4'h0,  // [9:6]   Clock Phase (Clock PI Center)
      3'h0,  // [5:3]   Valid Pattern (Functional)
      3'h0  // [2:0]   Data Pattern (LFSR)
    },

    parameter MAXIMUM_ITERATIONS = 4  // Maximum retry attempts before train_error
) (
    // Clock and reset
    input i_clk,
    input i_reset,

    // Interface inputs - from remote TX
    input [DECODING_WIDTH-1:0] i_xx_decoding,  // Decoded command from TX
    input [    DATA_WIDTH-1:0] i_xx_data,      // Data from TX
    input [    INFO_WIDTH-1:0] i_xx_info,      // Data from TX

    // Sideband control inputs
    input i_sb_xx_req,   // Sideband request from TX
    input i_sb_xx_rsp,   // Sideband response from TX
    input i_sb_xx_done,  // Sideband done from TX
    input i_xx_done,     // Operation complete

    // Control inputs
    input                    done_ack,         // Acknowledgement of done signal
    input                    init,             // Initialize mode flag
    input                    no_retry,         // Disable retry on test failure
    input                    comparison_type,  // 0:data, 1:valid
    input [DATA_WIDTH-1 : 0] data_result,      // Test data_result from pattern detector
    input                    valid_result,     // Test data_result from pattern detector

    // Interface outputs - to remote TX
    output logic [DECODING_WIDTH-1:0] o_xx_encoding,     // Encoded command to send
    output logic [    DATA_WIDTH-1:0] o_xx_data,         // Data to send
    output logic [    INFO_WIDTH-1:0] o_xx_info,         // Info/control to send
    output logic [               7:0] o_xx_sweep_result, // Eye sweep results to send

    // Sideband control outputs
    output logic o_xx_sb_req,  // Sideband request to TX
    output logic o_xx_sb_rsp,  // Sideband response to TX

    // Status outputs
    output logic train_error,  // Training error occurred
    output logic failed_test,  // Current test failed
    output logic done          // Eye sweep test complete
);

  //================================================================================
  // State Machine Definitions
  //================================================================================

  // State encoding for eye sweep sequence
  localparam REQ_HANDSHAKE = 3'b000;  // Initial request handshake
  localparam LFSR_HANDSHAKE = 3'b001;  // LFSR (pseudo-random) setup handshake
  localparam DATA_DETECTION = 3'b010;  // Data pattern detection state
  localparam RESULT_HANDSHAKE = 3'b011;  // Result reporting handshake
  localparam SWEEP_RESULT_HANDSHAKE = 3'b100;  // Sweep parameter data_result handshake
  localparam END_HANDSHAKE = 3'b101;  // Final completion handshake

  // State registers
  logic [2:0] CS;  // Current state
  logic [2:0] NS;  // Next state

  logic [1:0] count;
  logic [1:0] count_reg;

  //================================================================================
  // Combinational Logic
  //================================================================================

  // Test fails if any bit in data_result is 0 (all bits should be 1 for pass)
  assign failed_test = !(&data_result);

  //================================================================================
  // State Machine Sequential Logic
  //================================================================================

  // State register update
  always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
      CS <= REQ_HANDSHAKE;  // Reset to initial state
      count <= 0;
    end else begin
      CS    <= NS;  // Advance to next state
      count <= count_reg;
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
    o_xx_sweep_result = 0;
    count_reg = count;
    NS = CS;
    o_xx_encoding = 0;
    if (init) begin
      //====================================================================
      // INITIALIZATION MODE - RX initiates the test
      //====================================================================
      case (CS)
        // State 0: Send initial test request
        REQ_HANDSHAKE: begin
          o_xx_encoding = 'h188;  // Request encoding
          done = 0;
          count_reg = 0;  // Reset retry count
          train_error = 0;

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
          if (i_sb_xx_req && i_xx_decoding == 'h181) begin
            NS = LFSR_HANDSHAKE;
            o_xx_encoding = 'h189;  // LFSR setup encoding
            o_xx_sb_req = 0;
            o_xx_sb_rsp = 0;
          end else NS = REQ_HANDSHAKE;
        end

        // State 1: Setup LFSR (Linear Feedback Shift Register) for pattern detection
        LFSR_HANDSHAKE: begin
          o_xx_encoding = 'h189;  // LFSR setup encoding
          done = 0;
          o_xx_info = 0;

          // Response handshake
          if (done_ack) o_xx_sb_rsp = 0;
          else o_xx_sb_rsp = 1;

          // Wait for LFSR setup done signal
          if (i_sb_xx_done) begin
            o_xx_encoding = 'h18A;  // Data detection encoding
            o_xx_sb_req = 0;
            o_xx_sb_rsp = 0;
            count_reg = count + 1;  // Increment count for retries
            NS = DATA_DETECTION;
          end else NS = LFSR_HANDSHAKE;
        end

        // State 2: Detect incoming test data patterns
        DATA_DETECTION: begin
          o_xx_encoding = 'h18A;  // Data detection encoding
          done = 0;

          // Wait for data detection to complete
          if (i_sb_xx_req && i_xx_decoding == 'h18B) begin
            o_xx_encoding = 'h18B;  // Result reporting encoding
            NS = RESULT_HANDSHAKE;
            o_xx_sb_req = 0;
            o_xx_sb_rsp = 0;
          end else NS = DATA_DETECTION;
        end

        // State 3: Report test results back to TX
        RESULT_HANDSHAKE: begin
          o_xx_encoding = 'h18B;  // Result reporting encoding
          done = 0;
          o_xx_data = data_result;  // Send detection data_result
          o_xx_info = {'b0, valid_result, !failed_test, 4'b0000};  // Send detection data_result

          // Response handshake
          if (done_ack) o_xx_sb_rsp = 0;
          else o_xx_sb_rsp = 1;

          // Check if we need to retry or send sweep results
          if (i_sb_xx_req && i_xx_decoding == 'h189) begin
            o_xx_encoding = 'h189;  // LFSR setup encoding
            NS = LFSR_HANDSHAKE;
            o_xx_sb_req = 0;
            o_xx_sb_rsp = 0;
            train_error = 0;  // Clear training error for retry
          end else if (i_sb_xx_req && i_xx_decoding == 'h18C) begin
            o_xx_encoding = 'h18C;  // Sweep data_result encoding
            NS = SWEEP_RESULT_HANDSHAKE;
            o_xx_sb_req = 0;
            o_xx_sb_rsp = 0;
          end else NS = RESULT_HANDSHAKE;
        end

        // State 4: Receive sweep parameter results from TX
        SWEEP_RESULT_HANDSHAKE: begin
          o_xx_encoding = 'h18D;  // Sweep data_result encoding
          done = 0;
          o_xx_sweep_result = i_xx_data[7:0];  // Extract sweep measurement data
          NS = END_HANDSHAKE;
          o_xx_sb_req = 0;
          o_xx_sb_rsp = 0;
        end

        // State 5: Final handshake to complete test
        END_HANDSHAKE: begin
          o_xx_encoding = 'h18D;  // End encoding

          if (done_ack) o_xx_sb_req = 0;
          else o_xx_sb_req = 1;

          // Signal completion when acknowledged
          if (i_sb_xx_rsp && i_xx_decoding == 'h18D) done = 1;
          else done = 0;
        end
      endcase
    end else begin
      //====================================================================
      // NON-INITIALIZATION MODE - RX responds to TX-initiated test
      //====================================================================
      case (CS)
        // State 0: Respond to initial test request
        REQ_HANDSHAKE: begin
          o_xx_encoding = 'h180;  // Response encoding
          done = 0;
          count_reg = 0;  // Reset retry count
          train_error = 0;

          // Response handshake
          if (done_ack) o_xx_sb_rsp = 0;
          else o_xx_sb_rsp = 1;

          // Wait for done signal
          if (i_sb_xx_req && i_xx_decoding == 'h181) begin
            o_xx_info = i_xx_info;  // Send error threshold parameter
            NS = LFSR_HANDSHAKE;
            o_xx_encoding = 'h181;  // LFSR setup encoding
            o_xx_sb_req = 0;
            o_xx_sb_rsp = 0;
          end else NS = REQ_HANDSHAKE;
        end

        // State 1: Setup LFSR for pattern detection
        LFSR_HANDSHAKE: begin
          o_xx_encoding = 'h181;  // LFSR setup encoding
          done = 0;

          // Response handshake
          if (done_ack) o_xx_sb_rsp = 0;
          else o_xx_sb_rsp = 1;

          // Wait for done signal
          if (i_sb_xx_done) begin
            count_reg = count + 1;  // Increment count for retries
            NS = DATA_DETECTION;
            o_xx_sb_req = 0;
            o_xx_sb_rsp = 0;
            o_xx_encoding = 'h182;  // LFSR setup encoding
          end else NS = LFSR_HANDSHAKE;
        end

        // State 2: Detect incoming test data patterns
        DATA_DETECTION: begin
          o_xx_encoding = 'h182;  // Data detection encoding
          done = 0;

          // Wait for data detection to complete
          if (i_sb_xx_req && i_xx_decoding == 'h183) begin
            NS = RESULT_HANDSHAKE;
            o_xx_sb_req = 0;
            o_xx_sb_rsp = 0;
            o_xx_encoding = 'h183;  // LFSR setup encoding
          end else NS = DATA_DETECTION;
        end

        // State 3: Report test results back to TX
        RESULT_HANDSHAKE: begin
          o_xx_encoding = 'h183;  // Result reporting encoding
          done = 0;
          o_xx_data = data_result;  // Send detection data_result
          o_xx_info = {'b0, valid_result, !failed_test, 4'b0000};  // Send detection data_result

          // Response handshake
          if (done_ack) o_xx_sb_rsp = 0;
          else o_xx_sb_rsp = 1;

          if (i_sb_xx_req && i_xx_decoding == 'h181) begin
            o_xx_encoding = 'h181;  // LFSR setup encoding
            NS = LFSR_HANDSHAKE;
            o_xx_sb_req = 0;
            o_xx_sb_rsp = 0;
            train_error = 0;  // Clear training error for retry
          end else if (i_sb_xx_req && i_xx_decoding == 'h184) begin
            o_xx_encoding = 'h184;  // Sweep data_result encoding
            NS = END_HANDSHAKE;
            o_xx_sb_req = 0;
            o_xx_sb_rsp = 0;
          end else NS = RESULT_HANDSHAKE;
        end

        // State 4: Final handshake to complete test
        END_HANDSHAKE: begin
          o_xx_encoding = 'h184;  // End encoding

          // Response handshake
          if (done_ack) o_xx_sb_rsp = 0;
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
    @(posedge i_clk) i_reset |=> (CS == REQ_HANDSHAKE);
  endproperty

  property reset_count_property;
    @(posedge i_clk) i_reset |=> (count == 0);
  endproperty

  property valid_state_init_property;
    @(posedge i_clk) disable iff (i_reset)
        init |-> (CS == REQ_HANDSHAKE) || (CS == LFSR_HANDSHAKE) || (CS == DATA_DETECTION) || (CS == RESULT_HANDSHAKE) || (CS == SWEEP_RESULT_HANDSHAKE) || (CS == END_HANDSHAKE);
  endproperty

  property state_transition_property;
    @(posedge i_clk) disable iff (i_reset) (CS != NS) |=> (CS == $past(
        NS
    ));
  endproperty

  property pass_test_combinational_property;
    @(posedge i_clk) disable iff (i_reset) (&data_result) |-> !failed_test;
  endproperty

  property init_req_to_lfsr_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == REQ_HANDSHAKE && i_sb_xx_req && i_xx_decoding == 'h189) |=> (CS == LFSR_HANDSHAKE);
  endproperty

  property init_lfsr_to_data_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == LFSR_HANDSHAKE && i_sb_xx_done) |=> (CS == DATA_DETECTION);
  endproperty

  property init_data_to_result_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == DATA_DETECTION && i_sb_xx_req && i_xx_decoding == 'h18B) |=> (CS == RESULT_HANDSHAKE);
  endproperty

  property init_result_to_lfsr_retry_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == RESULT_HANDSHAKE && i_sb_xx_req && i_xx_decoding == 'h189) |=> (CS == LFSR_HANDSHAKE);
  endproperty

  property init_result_to_sweep_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == RESULT_HANDSHAKE && i_sb_xx_req && i_xx_decoding == 'h18C) |=> (CS == SWEEP_RESULT_HANDSHAKE);
  endproperty

  property init_sweep_to_end_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == SWEEP_RESULT_HANDSHAKE) |=> (CS == END_HANDSHAKE);
  endproperty

  property init_done_at_end_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == END_HANDSHAKE && i_sb_xx_rsp && i_xx_decoding == 'h18D) |-> done;
  endproperty

  property init_done_low_not_end_property;
    @(posedge i_clk) disable iff (i_reset) (init && CS != END_HANDSHAKE) |-> !done;
  endproperty

  property init_count_reset_at_req_property;
    @(posedge i_clk) disable iff (i_reset) (init && CS == REQ_HANDSHAKE) |-> (count_reg == 0);
  endproperty

  property init_count_increment_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == LFSR_HANDSHAKE && i_sb_xx_done) |=> (count == $past(
        count
    ) + 1);
  endproperty

  property init_train_error_low_at_req_property;
    @(posedge i_clk) disable iff (i_reset) (init && CS == REQ_HANDSHAKE) |-> !train_error;
  endproperty

  property init_train_error_clear_on_retry_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == RESULT_HANDSHAKE && i_sb_xx_req && i_xx_decoding == 'h189) |-> !train_error;
  endproperty

  property init_encoding_req_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == REQ_HANDSHAKE && !(i_sb_xx_req && i_xx_decoding == 'h189)) |-> (o_xx_encoding == 'h188);
  endproperty

  property init_encoding_lfsr_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == LFSR_HANDSHAKE && !i_sb_xx_done) |-> (o_xx_encoding == 'h189);
  endproperty

  property init_encoding_result_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == RESULT_HANDSHAKE && !(i_sb_xx_req && i_xx_decoding == 'h189) && !(i_sb_xx_req && i_xx_decoding == 'h18C)) |-> (o_xx_encoding == 'h18B);
  endproperty

  property init_encoding_sweep_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == SWEEP_RESULT_HANDSHAKE) |-> (o_xx_encoding == 'h18D);
  endproperty

  property init_encoding_end_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == END_HANDSHAKE) |-> (o_xx_encoding == 'h18D);
  endproperty

  property init_req_sb_req_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && NS == REQ_HANDSHAKE && !done_ack) |-> o_xx_sb_req;
  endproperty

  property init_req_sb_req_deassert_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == REQ_HANDSHAKE && done_ack) |-> !o_xx_sb_req;
  endproperty

  property init_lfsr_sb_rsp_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == LFSR_HANDSHAKE && !done_ack && !i_sb_xx_done) |-> o_xx_sb_rsp;
  endproperty

  property init_lfsr_sb_rsp_deassert_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == LFSR_HANDSHAKE && done_ack) |-> !o_xx_sb_rsp;
  endproperty

  property init_result_sb_rsp_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == RESULT_HANDSHAKE && !done_ack && !(i_sb_xx_req && i_xx_decoding == 'h189) && !(i_sb_xx_req && i_xx_decoding == 'h18C)) |-> o_xx_sb_rsp;
  endproperty

  property init_result_sb_rsp_deassert_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == RESULT_HANDSHAKE && done_ack) |-> !o_xx_sb_rsp;
  endproperty

  property init_end_sb_req_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == END_HANDSHAKE && !done_ack) |-> o_xx_sb_req;
  endproperty

  property init_end_sb_req_deassert_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == END_HANDSHAKE && done_ack) |-> !o_xx_sb_req;
  endproperty

  property init_info_threshold_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == REQ_HANDSHAKE) |-> (o_xx_info == ERROR_THRESHOLD);
  endproperty

  property init_result_data_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == RESULT_HANDSHAKE) |-> (o_xx_data == data_result);
  endproperty

  property init_sweep_result_data_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == SWEEP_RESULT_HANDSHAKE) |-> (o_xx_sweep_result == i_xx_data[7:0]);
  endproperty

  property init_sweep_clear_sideband_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == SWEEP_RESULT_HANDSHAKE) |-> (!o_xx_sb_req && !o_xx_sb_rsp);
  endproperty

  property init_req_transition_clear_sideband_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == REQ_HANDSHAKE && i_sb_xx_req && i_xx_decoding == 'h189) |-> (!o_xx_sb_req && !o_xx_sb_rsp);
  endproperty

  property init_lfsr_transition_clear_sideband_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == LFSR_HANDSHAKE && i_sb_xx_done) |-> (!o_xx_sb_req && !o_xx_sb_rsp);
  endproperty

  property init_data_transition_clear_sideband_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == DATA_DETECTION && i_sb_xx_req && i_xx_decoding == 'h18B) |-> (!o_xx_sb_req && !o_xx_sb_rsp);
  endproperty

  property init_result_retry_clear_sideband_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == RESULT_HANDSHAKE && i_sb_xx_req && i_xx_decoding == 'h189) |-> (!o_xx_sb_req && !o_xx_sb_rsp);
  endproperty

  property init_result_sweep_clear_sideband_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == RESULT_HANDSHAKE && i_sb_xx_req && i_xx_decoding == 'h18C) |-> (!o_xx_sb_req && !o_xx_sb_rsp);
  endproperty

  property req_stays_without_match_init_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == REQ_HANDSHAKE && !(i_sb_xx_req && i_xx_decoding == 'h189)) |=> (CS == REQ_HANDSHAKE);
  endproperty

  property lfsr_stays_without_done_init_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == LFSR_HANDSHAKE && !i_sb_xx_done) |=> (CS == LFSR_HANDSHAKE);
  endproperty

  property result_stays_without_match_init_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == RESULT_HANDSHAKE && !(i_sb_xx_req && i_xx_decoding == 'h189) && !(i_sb_xx_req && i_xx_decoding == 'h18C)) |=> (CS == RESULT_HANDSHAKE);
  endproperty

  property count_max_value_property;
    @(posedge i_clk) disable iff (i_reset) (count <= MAXIMUM_ITERATIONS - 1);
  endproperty

  property init_done_low_at_sweep_property;
    @(posedge i_clk) disable iff (i_reset) (init && CS == SWEEP_RESULT_HANDSHAKE) |-> !done;
  endproperty

  property init_done_low_at_result_property;
    @(posedge i_clk) disable iff (i_reset) (init && CS == RESULT_HANDSHAKE) |-> !done;
  endproperty

  property init_done_low_at_data_property;
    @(posedge i_clk) disable iff (i_reset) (init && CS == DATA_DETECTION) |-> !done;
  endproperty

  property init_done_low_at_lfsr_property;
    @(posedge i_clk) disable iff (i_reset) (init && CS == LFSR_HANDSHAKE) |-> !done;
  endproperty

  property init_done_low_at_req_property;
    @(posedge i_clk) disable iff (i_reset) (init && CS == REQ_HANDSHAKE) |-> !done;
  endproperty

  property init_end_done_low_without_rsp_property;
    @(posedge i_clk) disable iff (i_reset)
        (init && CS == END_HANDSHAKE && !(i_sb_xx_rsp && i_xx_decoding == 'h18D)) |-> !done;
  endproperty

  reset_state_assertion :
  assert property (reset_state_property)
  else $error("Assertion failed: CS should be REQ_HANDSHAKE after reset");
  cover property (reset_state_property);

  reset_count_assertion :
  assert property (reset_count_property)
  else $error("Assertion failed: count should be 0 after reset");
  cover property (reset_count_property);

  valid_state_init_assertion :
  assert property (valid_state_init_property)
  else $error("Assertion failed: CS contains an invalid state value in init mode");
  cover property (valid_state_init_property);

  state_transition_assertion :
  assert property (state_transition_property)
  else $error("Assertion failed: state should transition to NS on state change");
  cover property (state_transition_property);

  pass_test_combinational_assertion :
  assert property (pass_test_combinational_property)
  else $error("Assertion failed: failed_test should be low when data_result is all ones");
  cover property (pass_test_combinational_property);

  init_req_to_lfsr_assertion :
  assert property (init_req_to_lfsr_property)
  else $error("Assertion failed: init mode should transition from REQ_HANDSHAKE to LFSR_HANDSHAKE");
  cover property (init_req_to_lfsr_property);

  init_lfsr_to_data_assertion :
  assert property (init_lfsr_to_data_property)
  else
    $error("Assertion failed: init mode should transition from LFSR_HANDSHAKE to DATA_DETECTION");
  cover property (init_lfsr_to_data_property);

  init_data_to_result_assertion :
  assert property (init_data_to_result_property)
  else
    $error("Assertion failed: init mode should transition from DATA_DETECTION to RESULT_HANDSHAKE");
  cover property (init_data_to_result_property);

  init_result_to_lfsr_retry_assertion :
  assert property (init_result_to_lfsr_retry_property)
  else
    $error(
        "Assertion failed: init mode should transition from RESULT_HANDSHAKE to LFSR_HANDSHAKE on retry"
    );
  cover property (init_result_to_lfsr_retry_property);

  init_result_to_sweep_assertion :
  assert property (init_result_to_sweep_property)
  else
    $error(
        "Assertion failed: init mode should transition from RESULT_HANDSHAKE to SWEEP_RESULT_HANDSHAKE"
    );
  cover property (init_result_to_sweep_property);

  init_sweep_to_end_assertion :
  assert property (init_sweep_to_end_property)
  else
    $error(
        "Assertion failed: init mode should transition from SWEEP_RESULT_HANDSHAKE to END_HANDSHAKE"
    );
  cover property (init_sweep_to_end_property);

  init_done_at_end_assertion :
  assert property (init_done_at_end_property)
  else $error("Assertion failed: done should be asserted at END_HANDSHAKE in init mode");
  cover property (init_done_at_end_property);

  init_done_low_not_end_assertion :
  assert property (init_done_low_not_end_property)
  else $error("Assertion failed: done should be low when not in END_HANDSHAKE in init mode");
  cover property (init_done_low_not_end_property);

  init_count_reset_at_req_assertion :
  assert property (init_count_reset_at_req_property)
  else $error("Assertion failed: count_reg should be 0 at REQ_HANDSHAKE in init mode");
  cover property (init_count_reset_at_req_property);

  init_count_increment_assertion :
  assert property (init_count_increment_property)
  else $error("Assertion failed: count should increment after LFSR_HANDSHAKE in init mode");
  cover property (init_count_increment_property);

  init_train_error_low_at_req_assertion :
  assert property (init_train_error_low_at_req_property)
  else $error("Assertion failed: train_error should be low at REQ_HANDSHAKE in init mode");
  cover property (init_train_error_low_at_req_property);

  init_train_error_clear_on_retry_assertion :
  assert property (init_train_error_clear_on_retry_property)
  else $error("Assertion failed: train_error should be cleared on retry in init mode");
  cover property (init_train_error_clear_on_retry_property);

  init_encoding_req_assertion :
  assert property (init_encoding_req_property)
  else $error("Assertion failed: o_xx_encoding should be 'h188 at REQ_HANDSHAKE in init mode");
  cover property (init_encoding_req_property);

  init_encoding_lfsr_assertion :
  assert property (init_encoding_lfsr_property)
  else $error("Assertion failed: o_xx_encoding should be 'h189 at LFSR_HANDSHAKE in init mode");
  cover property (init_encoding_lfsr_property);

  init_encoding_result_assertion :
  assert property (init_encoding_result_property)
  else $error("Assertion failed: o_xx_encoding should be 'h18B at RESULT_HANDSHAKE in init mode");
  cover property (init_encoding_result_property);

  init_encoding_sweep_assertion :
  assert property (init_encoding_sweep_property)
  else
    $error(
        "Assertion failed: o_xx_encoding should be 'h18D at SWEEP_RESULT_HANDSHAKE in init mode"
    );
  cover property (init_encoding_sweep_property);

  init_encoding_end_assertion :
  assert property (init_encoding_end_property)
  else $error("Assertion failed: o_xx_encoding should be 'h18D at END_HANDSHAKE in init mode");
  cover property (init_encoding_end_property);

  init_req_sb_req_assertion :
  assert property (init_req_sb_req_property)
  else
    $error(
        "Assertion failed: o_xx_sb_req should be asserted at REQ_HANDSHAKE when done_ack is low in init mode"
    );
  cover property (init_req_sb_req_property);

  init_req_sb_req_deassert_assertion :
  assert property (init_req_sb_req_deassert_property)
  else
    $error(
        "Assertion failed: o_xx_sb_req should be deasserted at REQ_HANDSHAKE when done_ack is high in init mode"
    );
  cover property (init_req_sb_req_deassert_property);

  init_lfsr_sb_rsp_assertion :
  assert property (init_lfsr_sb_rsp_property)
  else
    $error(
        "Assertion failed: o_xx_sb_rsp should be asserted at LFSR_HANDSHAKE when done_ack is low in init mode"
    );
  cover property (init_lfsr_sb_rsp_property);

  init_lfsr_sb_rsp_deassert_assertion :
  assert property (init_lfsr_sb_rsp_deassert_property)
  else
    $error(
        "Assertion failed: o_xx_sb_rsp should be deasserted at LFSR_HANDSHAKE when done_ack is high in init mode"
    );
  cover property (init_lfsr_sb_rsp_deassert_property);

  init_result_sb_rsp_assertion :
  assert property (init_result_sb_rsp_property)
  else
    $error(
        "Assertion failed: o_xx_sb_rsp should be asserted at RESULT_HANDSHAKE when done_ack is low in init mode"
    );
  cover property (init_result_sb_rsp_property);

  init_result_sb_rsp_deassert_assertion :
  assert property (init_result_sb_rsp_deassert_property)
  else
    $error(
        "Assertion failed: o_xx_sb_rsp should be deasserted at RESULT_HANDSHAKE when done_ack is high in init mode"
    );
  cover property (init_result_sb_rsp_deassert_property);

  init_end_sb_req_assertion :
  assert property (init_end_sb_req_property)
  else
    $error(
        "Assertion failed: o_xx_sb_req should be asserted at END_HANDSHAKE when done_ack is low in init mode"
    );
  cover property (init_end_sb_req_property);

  init_end_sb_req_deassert_assertion :
  assert property (init_end_sb_req_deassert_property)
  else
    $error(
        "Assertion failed: o_xx_sb_req should be deasserted at END_HANDSHAKE when done_ack is high in init mode"
    );
  cover property (init_end_sb_req_deassert_property);

  init_info_threshold_assertion :
  assert property (init_info_threshold_property)
  else
    $error("Assertion failed: o_xx_info should be ERROR_THRESHOLD at REQ_HANDSHAKE in init mode");
  cover property (init_info_threshold_property);

  init_result_data_assertion :
  assert property (init_result_data_property)
  else $error("Assertion failed: o_xx_data should be data_result at RESULT_HANDSHAKE in init mode");
  cover property (init_result_data_property);

  init_sweep_result_data_assertion :
  assert property (init_sweep_result_data_property)
  else
    $error(
        "Assertion failed: o_xx_sweep_result should be i_xx_data[7:0] at SWEEP_RESULT_HANDSHAKE in init mode"
    );
  cover property (init_sweep_result_data_property);

  init_sweep_clear_sideband_assertion :
  assert property (init_sweep_clear_sideband_property)
  else
    $error(
        "Assertion failed: o_xx_sb_req and o_xx_sb_rsp should be low at SWEEP_RESULT_HANDSHAKE in init mode"
    );
  cover property (init_sweep_clear_sideband_property);

  init_req_transition_clear_sideband_assertion :
  assert property (init_req_transition_clear_sideband_property)
  else
    $error(
        "Assertion failed: sideband signals should be cleared on REQ_HANDSHAKE transition in init mode"
    );
  cover property (init_req_transition_clear_sideband_property);

  init_lfsr_transition_clear_sideband_assertion :
  assert property (init_lfsr_transition_clear_sideband_property)
  else
    $error(
        "Assertion failed: sideband signals should be cleared on LFSR_HANDSHAKE transition in init mode"
    );
  cover property (init_lfsr_transition_clear_sideband_property);

  init_data_transition_clear_sideband_assertion :
  assert property (init_data_transition_clear_sideband_property)
  else
    $error(
        "Assertion failed: sideband signals should be cleared on DATA_DETECTION transition in init mode"
    );
  cover property (init_data_transition_clear_sideband_property);

  init_result_retry_clear_sideband_assertion :
  assert property (init_result_retry_clear_sideband_property)
  else
    $error(
        "Assertion failed: sideband signals should be cleared on RESULT_HANDSHAKE retry transition in init mode"
    );
  cover property (init_result_retry_clear_sideband_property);

  init_result_sweep_clear_sideband_assertion :
  assert property (init_result_sweep_clear_sideband_property)
  else
    $error(
        "Assertion failed: sideband signals should be cleared on RESULT_HANDSHAKE to SWEEP transition in init mode"
    );
  cover property (init_result_sweep_clear_sideband_property);

  req_stays_without_match_init_assertion :
  assert property (req_stays_without_match_init_property)
  else $error("Assertion failed: REQ_HANDSHAKE should stay without matching request in init mode");
  cover property (req_stays_without_match_init_property);

  lfsr_stays_without_done_init_assertion :
  assert property (lfsr_stays_without_done_init_property)
  else $error("Assertion failed: LFSR_HANDSHAKE should stay without done in init mode");
  cover property (lfsr_stays_without_done_init_property);

  result_stays_without_match_init_assertion :
  assert property (result_stays_without_match_init_property)
  else
    $error("Assertion failed: RESULT_HANDSHAKE should stay without matching request in init mode");
  cover property (result_stays_without_match_init_property);

  count_max_value_assertion :
  assert property (count_max_value_property)
  else $error("Assertion failed: count should not exceed MAXIMUM_ITERATIONS-1");
  cover property (count_max_value_property);

  init_done_low_at_sweep_assertion :
  assert property (init_done_low_at_sweep_property)
  else $error("Assertion failed: done should be low at SWEEP_RESULT_HANDSHAKE in init mode");
  cover property (init_done_low_at_sweep_property);

  init_done_low_at_result_assertion :
  assert property (init_done_low_at_result_property)
  else $error("Assertion failed: done should be low at RESULT_HANDSHAKE in init mode");
  cover property (init_done_low_at_result_property);

  init_done_low_at_data_assertion :
  assert property (init_done_low_at_data_property)
  else $error("Assertion failed: done should be low at DATA_DETECTION in init mode");
  cover property (init_done_low_at_data_property);

  init_done_low_at_lfsr_assertion :
  assert property (init_done_low_at_lfsr_property)
  else $error("Assertion failed: done should be low at LFSR_HANDSHAKE in init mode");
  cover property (init_done_low_at_lfsr_property);

  init_done_low_at_req_assertion :
  assert property (init_done_low_at_req_property)
  else $error("Assertion failed: done should be low at REQ_HANDSHAKE in init mode");
  cover property (init_done_low_at_req_property);

  init_end_done_low_without_rsp_assertion :
  assert property (init_end_done_low_without_rsp_property)
  else
    $error(
        "Assertion failed: done should be low at END_HANDSHAKE without matching response in init mode"
    );
  cover property (init_end_done_low_without_rsp_property);

`endif

endmodule
