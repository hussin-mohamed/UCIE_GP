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
    parameter MAXIMUM_ITERATIONS = 4,      // Width of info/control output
    parameter ERROR_THRESHOLD = 1   // Error threshold for test pass/fail
) (
    // Clock and reset
    input i_clk,
    input i_reset,
    
    // Interface inputs - from remote side
    input [DECODING_WIDTH-1:0] i_xx_decoding,  // Decoded command from remote
    input [DATA_WIDTH-1:0] i_xx_data,          // Data from remote
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
    
    // Interface outputs - to remote side
    output logic [DECODING_WIDTH-1:0] o_xx_encoding,  // Encoded command to send
    output logic [DATA_WIDTH-1:0] o_xx_data,          // Data to send
    output logic [INFO_WIDTH-1:0] o_xx_info,          // Info/control to send
    
    // Sideband control outputs
    output logic o_xx_sb_req,   // Sideband request to remote
    output logic o_xx_sb_rsp,   // Sideband response to remote
    output logic o_xx_sb_done,  // Sideband done to remote
    
    // Status outputs
    output logic train_error,   // Training error occurred
    output logic failed_test,   // Current test failed
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

logic [1:0] count;
logic [1:0] count_reg;

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

//================================================================================
// Sideband Done Signal Logic
//================================================================================
// Generates done pulse for sideband protocol
always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        o_xx_sb_done <= 0;;
    end else begin
        if (o_xx_sb_done) begin
            o_xx_sb_done <= 0;  // Self-clearing pulse
        end else if (i_sb_xx_rsp || i_sb_xx_req) begin
            o_xx_sb_done <= 1;  // Assert on request or response
        end
    end
end

//================================================================================
// Main State Machine Combinational Logic
//================================================================================
always @(*) begin
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

                // Request handshake with acknowledge
                if (done_ack) o_xx_sb_req = 0;
                else o_xx_sb_req = 1;

                o_xx_info = ERROR_THRESHOLD;  // Send error threshold parameter

                // Wait for matching response
                if (i_sb_xx_rsp && i_xx_decoding == 'h180) NS = LFSR_HANDSHAKE;
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
                    count_reg = count + 1;  // Increment count for retries
                    NS = DATA_GENERATE;
                end 
                else NS = LFSR_HANDSHAKE;
            end 

            // State 2: Generate test data patterns
            DATA_GENERATE: begin
                o_xx_encoding = 'h182;  // Data generation encoding
                done = 0;

                // Wait for data generation to complete
                if (i_xx_done) NS = RESULT_HANDSHAKE;
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
                    // Retry if failed and retries allowed, otherwise complete
                    if (failed_test && !no_retry)
                        if (count == MAXIMUM_ITERATIONS-1) begin
                            train_error = 1;  // Mark training error if max retries reached
                        end else begin
                            NS = LFSR_HANDSHAKE;
                            train_error = 0;  // Clear training error for retry
                        end 
                    else NS = END_HANDSHAKE;
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
                o_xx_encoding = 'h185;  // Response encoding
                done = 0;
                count_reg = 0;  // Reset retry count

                // Response handshake
                if (done_ack) o_xx_sb_rsp = 0;
                else if (i_sb_xx_req) o_xx_sb_rsp = 1;

                // Wait for done signal
                if (i_sb_xx_done && i_xx_decoding == 'h185) NS = LFSR_HANDSHAKE;
                else NS = REQ_HANDSHAKE;
            end 
    
            // State 1: Setup LFSR for pattern generation
            LFSR_HANDSHAKE: begin
                o_xx_encoding = 'h186;  // LFSR setup encoding
                done = 0;
                

                if (done_ack) o_xx_sb_req = 0;
                else o_xx_sb_req = 1;

                if (i_sb_xx_rsp && i_xx_decoding == 'h186) begin
                    count_reg = count + 1;  // Increment count for retries
                    NS = DATA_GENERATE;
                end 
                else NS = LFSR_HANDSHAKE;
            end 
    
            // State 2: Generate test data patterns
            DATA_GENERATE: begin
                o_xx_encoding = 'h187;  // Data generation encoding
                done = 0;

                if (i_xx_done) NS = RESULT_HANDSHAKE;
                else NS = DATA_GENERATE;
            end
    
            // State 3: Collect test results
            RESULT_HANDSHAKE: begin
                o_xx_encoding = 'h188;  // Result collection encoding
                done = 0;

                if (done_ack) o_xx_sb_req = 0;
                else o_xx_sb_req = 1;

                // Check result and decide on retry
                if (i_sb_xx_rsp && i_xx_decoding == 'h188) begin
                    failed_test = !(&i_xx_data);  // Test fails if any bit is 0
                    // Retry if failed and retries allowed, otherwise get sweep result
                    if (failed_test && !no_retry) 
                        if (count == MAXIMUM_ITERATIONS-1) begin
                            train_error = 1;  // Mark training error if max retries reached
                        end else begin
                            NS = LFSR_HANDSHAKE;
                            train_error = 0;  // Clear training error for retry
                        end
                    else NS = SWEEP_RESULT_HANDSHAKE;
                end else NS = RESULT_HANDSHAKE;
            end 

            // State 4: Send sweep parameter results
            SWEEP_RESULT_HANDSHAKE: begin
                o_xx_encoding = 'h189;  // Sweep result encoding
                done = 0;
                o_xx_data = i_xx_sweep_result;  // Send sweep measurement data

                if (done_ack) o_xx_sb_req = 0;
                else o_xx_sb_req = 1;

                // Wait for acknowledgement
                if (done_ack && i_xx_decoding == 'h189) NS = END_HANDSHAKE;
                else NS = SWEEP_RESULT_HANDSHAKE;
            end 
    
            // State 5: Final handshake to complete test
            END_HANDSHAKE: begin
                o_xx_encoding = 'h189;  // End encoding
                o_xx_data = 0;          // Clear data
    
                // Response handshake
                if (done_ack) o_xx_sb_rsp = 0;
                else if (i_sb_xx_req) o_xx_sb_rsp = 1;
    
                // Signal completion when done received
                if (i_sb_xx_done && i_xx_decoding == 'h189) done = 1;
                else done = 0;
            end 
        endcase
    end
end
    
endmodule
