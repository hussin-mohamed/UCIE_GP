//================================================================================
// Module: ucie_RX_Data_to_Clock_eye_sweep
// Description: RX-side eye sweep test module for UCIe link training
//              Performs data-to-clock eye diagram measurement by detecting test
//              patterns from TX and reporting results back
//================================================================================

module ucie_RX_Data_to_Clock_eye_sweep (
    // Clock and reset
    input i_clk,
    input i_reset,
    
    // Interface inputs - from remote TX
    input [DECODING_WIDTH-1:0] i_xx_decoding,  // Decoded command from TX
    input [DATA_WIDTH-1:0] i_xx_data,          // Data from TX
    
    // Sideband control inputs
    input i_sb_xx_req,     // Sideband request from TX
    input i_sb_xx_rsp,     // Sideband response from TX
    input i_sb_xx_done,    // Sideband done from TX
    input i_xx_done,       // Operation complete
    
    // Control inputs
    input done_ack,        // Acknowledgement of done signal
    input init,            // Initialize mode flag
    input no_retry,        // Disable retry on test failure
    input result,          // Test result from pattern detector
    
    // Interface outputs - to remote TX
    output logic [DECODING_WIDTH-1:0] o_xx_encoding,  // Encoded command to send
    output logic [DATA_WIDTH-1:0] o_xx_data,          // Data to send
    output logic [INFO_WIDTH-1:0] o_xx_info,          // Info/control to send
    output logic [7:0] o_xx_sweep_result,             // Eye sweep results to send
    
    // Sideband control outputs
    output logic o_xx_sb_req,   // Sideband request to TX
    output logic o_xx_sb_rsp,   // Sideband response to TX
    output logic o_xx_sb_done,  // Sideband done to TX
    
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
localparam DATA_DETECTION = 3'b010;           // Data pattern detection state
localparam RESULT_HANDSHAKE = 3'b011;         // Result reporting handshake
localparam SWEEP_RESULT_HANDSHAKE = 3'b100;   // Sweep parameter result handshake
localparam END_HANDSHAKE = 3'b101;            // Final completion handshake

// State registers
logic [2:0] CS;  // Current state
logic [2:0] NS;  // Next state

//================================================================================
// Combinational Logic
//================================================================================

// Test fails if any bit in result is 0 (all bits should be 1 for pass)
assign failed_test = !(&result);

//================================================================================
// State Machine Sequential Logic
//================================================================================

// State register update
always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        CS <= REQ_HANDSHAKE;  // Reset to initial state
    end else begin
        CS <= NS;             // Advance to next state
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
        // INITIALIZATION MODE - RX initiates the test
        //====================================================================
        case (CS)
            // State 0: Send initial test request
            REQ_HANDSHAKE: begin
                o_xx_encoding = 'h180;  // Request encoding
                done = 0;

                // Request handshake with acknowledge
                if (done_ack) o_xx_sb_req = 0;
                else o_xx_sb_req = 1;

                o_xx_info = ERROR_THRESHOLD;  // Send error threshold parameter

                // Wait for matching response
                if (i_sb_xx_rsp && i_xx_decoding == 'h180) NS = LFSR_HANDSHAKE;
                else NS = REQ_HANDSHAKE;
            end 

            // State 1: Setup LFSR (Linear Feedback Shift Register) for pattern detection
            LFSR_HANDSHAKE: begin
                o_xx_encoding = 'h181;  // LFSR setup encoding
                done = 0;

                // Response handshake
                if (done_ack) o_xx_sb_rsp = 0;
                else if (i_sb_xx_req) o_xx_sb_rsp = 1

                // Wait for LFSR setup done signal
                if (i_sb_xx_done && i_xx_decoding == 'h181) NS = DATA_DETECTION;
                else NS = LFSR_HANDSHAKE;
            end 

            // State 2: Detect incoming test data patterns
            DATA_DETECTION: begin
                o_xx_encoding = 'h182;  // Data detection encoding
                done = 0;

                // Wait for data detection to complete
                if (i_xx_done) NS = RESULT_HANDSHAKE;
                else NS = DATA_DETECTION;
            end 

            // State 3: Report test results back to TX
            RESULT_HANDSHAKE: begin
                o_xx_encoding = 'h183;  // Result reporting encoding
                done = 0;
                o_xx_data = result;     // Send detection result

                // Response handshake
                if (done_ack) o_xx_sb_rsp = 0;
                else if (i_sb_xx_req) o_xx_sb_rsp = 1

                // Check if we need to retry or send sweep results
                if (i_sb_xx_rsp && i_xx_decoding == 'h183) begin
                    // Retry if failed and retries allowed, otherwise get sweep result
                    if (failed_test && !no_retry) NS = LFSR_HANDSHAKE;
                    else NS = SWEEP_RESULT_HANDSHAKE;
                end else NS = RESULT_HANDSHAKE;
            end 

            // State 4: Receive sweep parameter results from TX
            SWEEP_RESULT_HANDSHAKE: begin
                o_xx_encoding = 'h184;  // Sweep result encoding
                done = 0;
                o_xx_sweep_result = i_xx_data[7:0];  // Extract sweep measurement data
                
                // Wait for done signal
                if (i_sb_xx_done && i_xx_decoding == 'h184) NS = END_HANDSHAKE;
                else NS = SWEEP_RESULT_HANDSHAKE;
            end

            // State 5: Final handshake to complete test
            END_HANDSHAKE: begin
                o_xx_encoding = 'h185;  // End encoding

                if (done_ack) o_xx_sb_req = 0;
                else o_xx_sb_req = 1;

                // Signal completion when acknowledged
                if (i_sb_xx_rsp && i_xx_decoding == 'h185) done = 1;
                else done = 0;
            end 
            default: 
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

                // Response handshake
                if (done_ack) o_xx_sb_rsp = 0;
                else if (i_sb_xx_req) o_xx_sb_rsp = 1;

                // Wait for done signal
                if (i_sb_xx_done && i_xx_decoding == 'h180) NS = LFSR_HANDSHAKE;
                else NS = REQ_HANDSHAKE;
            end 
    
            // State 1: Setup LFSR for pattern detection
            LFSR_HANDSHAKE: begin
                o_xx_encoding = 'h181;  // LFSR setup encoding
                done = 0;

                // Response handshake
                if (done_ack) o_xx_sb_rsp = 0;
                else if (i_sb_xx_req) o_xx_sb_rsp = 1;

                // Wait for done signal
                if (i_sb_xx_done && i_xx_decoding == 'h181) NS = DATA_DETECTION;
                else NS = LFSR_HANDSHAKE;
            end 
    
            // State 2: Detect incoming test data patterns
            DATA_DETECTION: begin
                o_xx_encoding = 'h182;  // Data detection encoding
                done = 0;

                // Wait for data detection to complete
                if (i_xx_done) NS = RESULT_HANDSHAKE;
                else NS = DATA_DETECTION;
            end
    
            // State 3: Report test results back to TX
            RESULT_HANDSHAKE: begin
                o_xx_encoding = 'h183;  // Result reporting encoding
                done = 0;
                o_xx_data = result;     // Send detection result

                // Response handshake
                if (done_ack) o_xx_sb_rsp = 0;
                else if (i_sb_xx_req) o_xx_sb_rsp = 1

                // Check if we need to retry or complete
                if (i_sb_xx_rsp && i_xx_decoding == 'h183) begin
                    // Retry if failed and retries allowed, otherwise get sweep result
                    if (failed_test && !no_retry) NS = LFSR_HANDSHAKE;
                    else NS = SWEEP_RESULT_HANDSHAKE;
                end else NS = RESULT_HANDSHAKE;
            end 
    
            // State 4: Final handshake to complete test
            END_HANDSHAKE: begin
                o_xx_encoding = 'h184;  // End encoding
    
                // Response handshake
                if (done_ack) o_xx_sb_rsp = 0;
                else if (i_sb_xx_req) o_xx_sb_rsp = 1;
    
                // Signal completion when done received
                if (i_sb_xx_done && i_xx_decoding == 'h184) done = 1;
                else done = 0;
            end 
            default: 
        endcase
    end
end
    
endmodule
