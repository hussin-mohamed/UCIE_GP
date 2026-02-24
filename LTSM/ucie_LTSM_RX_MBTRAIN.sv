//================================================================================
// Module: ucie_LTSM_RX_MBTRAIN
// Description: UCIe RX Link Training State Machine for Mainband Training
//              Implements the receiver side of the UCIe link training sequence
//              including eye sweep calibration and handshake protocols
//================================================================================

module ucie_LTSM_RX_MBTRAIN #(
    parameter DECODING_WIDTH = 9,    // Width of encoding/decoding signals
    parameter DATA_WIDTH = 64,       // Width of data bus
    parameter INFO_WIDTH = 16,       // Width of info/control bus
    parameter ERROR_THRESHOLD = 0    // Threshold for acceptable training errors
) (
    // Clock and reset
    input i_clk,
    input i_reset,
    
    // RX interface inputs - data coming from remote TX
    input [DECODING_WIDTH-1:0] i_rx_decoding,    // Decoded command from TX
    input [DATA_WIDTH-1:0] i_rx_data,            // Data from TX
    input [INFO_WIDTH-1:0] i_rx_info,            // Info/control from TX
    input [DATA_WIDTH-1:0] result,               // Results from eye sweep tests (could be multiple signals or a bus of results)
    input [7:0] i_rx_sweep_result,               // Eye sweep test results
    
    // Sideband control inputs
    input i_sb_rx_req,     // Sideband request from TX
    input i_sb_rx_rsp,     // Sideband response from TX
    input i_sb_rx_done,    // Sideband done from TX
    input i_rx_done,       // RX operation complete
    input i_tx_done,       // TX operation complete
    
    // Training control inputs
    input init_train_en,   // Enable training initialization
    input timeout,         // Training timeout error
    input [2:0] o_pl_speedmode,  // Physical layer speed mode

    input [DECODING_WIDTH-1:0] encoding_rsp_sent,      // Encoding value when response sent
    input [DECODING_WIDTH-1:0] encoding_rsp_received,  // Encoding value when response received
    input rsp_received,               // Response sent flag
    input rsp_sent,                   // Response sent flag
    
    // RX interface outputs - data going to remote TX
    output logic [DECODING_WIDTH-1:0] o_rx_encoding,  // Encoded command to send
    output logic [DATA_WIDTH-1:0] o_rx_data,          // Data to send
    output logic [INFO_WIDTH-1:0] o_rx_info,          // Info/control to send
    
    // Sideband control outputs
    output logic o_rx_sb_req,   // Sideband request to TX
    output logic o_rx_sb_rsp,   // Sideband response to TX
    output logic o_rx_sb_done,  // Sideband done to TX
    
    // Status outputs
    output logic train_error,      // Training error occurred
    output logic train_active_en   // Training is active
);

//================================================================================
// State Machine Definitions
//================================================================================

// Current State and Next State registers
logic [6:0] CS;  // Current state
logic [6:0] NS;  // Next state

// UCIe Training State Definitions (per UCIe specification)
localparam VALVREF = 4'b0000;            // Valid reference voltage calibration
localparam DATAVREF = 4'b0001;           // Data reference voltage calibration
localparam SPEEDIDLE = 4'b0011;          // Speed idle state
localparam TXSELFCAL = 4'b0010;          // TX self-calibration
localparam RXCLKCAL = 4'b0110;           // RX clock calibration
localparam VALTRAINCENTER = 4'b0111;     // Valid training center
localparam VALTRAINVREF = 4'b0101;       // Valid training voltage reference
localparam DATATRAINCENTER1 = 4'b0100;   // Data training center phase 1
localparam DATATRAINVREF = 4'b1100;      // Data training voltage reference
localparam RXDESKEW = 4'b1101;           // RX deskew calibration
localparam DATATRAINCENTER2 = 4'b1111;   // Data training center phase 2
localparam LINKSPEED = 4'b1110;          // Link speed negotiation
localparam REPAIR = 4'b1010;             // Link repair state

//================================================================================
// Internal Signals
//================================================================================

// Register outputs - used for combinational logic assignment
logic [DECODING_WIDTH-1:0] o_rx_encoding_reg;
logic [DECODING_WIDTH-1:0] o_rx_encoding_old;
logic [DATA_WIDTH-1:0] o_rx_data_reg;
logic [INFO_WIDTH-1:0] o_rx_info_reg;
logic o_rx_sb_req_reg;
logic o_rx_sb_rsp_reg;
logic o_rx_sb_done_reg;
logic train_error_reg;
logic train_active_en_reg;
logic failed_test;  // Indicates if current test failed

// Signals from eye sweep test module
logic [DECODING_WIDTH-1:0] o_rx_encoding_data_to_clock_test;
logic [DATA_WIDTH-1:0] o_rx_data_data_to_clock_test;
logic [INFO_WIDTH-1:0] o_rx_info_data_to_clock_test;
logic o_rx_sb_req_data_to_clock_test;
logic o_rx_sb_rsp_data_to_clock_test;
logic o_rx_sb_done_data_to_clock_test;
logic train_error_data_to_clock_test;

// Substate machine signals
logic [2:0] current_substate;  // Current substate within main state
logic [2:0] next_substate;     // Next substate

// Handshake control signals
logic state_enb;                  // Enable signal for current state operations
logic done_ack;                   // Acknowledge that done was received
logic substates_done;             // All substates completed
logic previous_state_done;        // Previous state handshake complete
logic req_received;               // Request received flag
logic SPEEDIDLE_trainerror;               // Request received flag
logic [DECODING_WIDTH-1:0] encoding_req_received;  // Encoding value when request received

logic init;        // Initialization mode for eye sweep test
logic no_retry;    // No retry mode for eye sweep test
logic clock_to_test_enable;       // Enable the eye sweep test module
logic clock_to_test_done;         // Eye sweep test complete

//================================================================================
// Eye Sweep Test Module Instantiation
//================================================================================
// This module performs data-to-clock eye diagram sweeping for signal integrity
ucie_RX_Data_to_Clock_eye_sweep ucie_RX_Data_to_Clock_eye_sweep_inst (
    .i_clk(i_clk),
    .i_reset(i_reset || !clock_to_test_enable),  // Reset when enabled (inverted logic vs TX)
    .i_xx_decoding(i_rx_decoding),
    .i_xx_data(i_rx_data),
    .i_sb_xx_req(i_sb_rx_req),
    .i_sb_xx_rsp(i_sb_rx_rsp),
    .i_sb_xx_done(i_sb_rx_done),
    .i_xx_done(i_rx_done),
    .done_ack(done_ack),
    .init(init),
    .no_retry(no_retry),
    .result(result),
    .o_xx_encoding(o_rx_encoding_data_to_clock_test),
    .o_xx_data(o_rx_data_data_to_clock_test),
    .o_xx_info(o_rx_info_data_to_clock_test),
    .o_xx_sweep_result(o_xx_sweep_result),
    .o_xx_sb_req(o_rx_sb_req_data_to_clock_test), 
    .o_xx_sb_rsp(o_rx_sb_rsp_data_to_clock_test),
    .train_error(train_error_data_to_clock_test),
    .failed_test(failed_test),
    .done(clock_to_test_done)
);

//================================================================================
// Combinational Logic
//================================================================================

// Previous state completion logic - checks if handshake is complete
// Note: RX side only checks sent/received, not both like TX
assign previous_state_done = (i_reset)? 0 : (rsp_sent & rsp_received);

// Training error aggregation - timeout, eye sweep error, or speed idle error
assign train_error_reg = timeout || train_error_data_to_clock_test || SPEEDIDLE_trainerror;

//================================================================================
// State Machine Sequential Logic
//================================================================================

// Main state machine and substate registers
always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        CS <= VALVREF;           // Reset to initial training state
        current_substate <= 0;   // Reset substate
        o_rx_encoding <= 0;
        o_rx_data <= 0;
        o_rx_info <= 0;
        o_rx_sb_req <= 0;
        o_rx_sb_rsp <= 0;
        o_rx_sb_done <= 0;
        train_error <= 0;
        train_active_en <= 0;
    end else if (!state_enb) begin
        CS <= VALVREF;           // Reset to initial training state
        current_substate <= 0;   // Reset substate
        o_rx_encoding <= 0;
        o_rx_data <= 0;
        o_rx_info <= 0;
        o_rx_sb_req <= 0;
        o_rx_sb_rsp <= 0;
        train_error <= 0;
        train_active_en <= train_active_en_reg; 
    end else begin
        CS <= NS;                // Advance to next state
        current_substate <= next_substate;
        o_rx_encoding <= o_rx_encoding_reg;
        o_rx_data <= o_rx_data_reg;
        o_rx_info <= o_rx_info_reg;
        o_rx_sb_req <= o_rx_sb_req_reg;
        o_rx_sb_rsp <= o_rx_sb_rsp_reg;
        train_error <= train_error_reg;
        train_active_en <= train_active_en_reg;
    end 
end

//================================================================================
// Done Acknowledgement Logic
//================================================================================
// Tracks when done signal has been acknowledged in handshake protocol
always @(*) begin
    if (i_reset) done_ack <= 0;
    else if (o_rx_encoding[3:0] != o_rx_encoding_old[3:0]) done_ack = 0;
    else if (i_sb_rx_done) begin
        done_ack = 1;  // Set when done received
    end else if (i_sb_rx_rsp) begin
        done_ack = 0;  // Clear on response to allow next transaction
    end
end

always @(posedge i_clk) begin
    o_rx_encoding_old <= o_rx_encoding;  // Register to track previous encoding for done_ack logic
end

//================================================================================
// State Enable Logic
//================================================================================
always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        state_enb <= 0; // Disable state operations until training is initialized
    end else if (init_train_en) begin
        if (train_active_en_reg) state_enb <= 0;  // If training is active, keep state operations disabled to prevent interference
        else state_enb <= 1;  // Enable state operations when training is initialized
    end else if (train_active_en_reg) state_enb <= 0;
end

//================================================================================
// Sideband Done Signal Logic
//================================================================================
// Generates done pulse for sideband protocol
always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        o_rx_sb_done <= 0;;
    end else begin
        if (o_rx_sb_done) begin
            o_rx_sb_done <= 0;  // Self-clearing pulse
        end else if (i_sb_rx_rsp || i_sb_rx_req) begin
            o_rx_sb_done <= 1;  // Assert on request or response
        end
    end
end

//================================================================================
// Request Reception Tracking
//================================================================================
// Tracks received requests with their encoding values (RX side logic)
always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        req_received <= 0;
        encoding_req_received <= 0;
    end else begin
        // Capture request when received
        if (i_sb_rx_req) begin
            req_received <= 1;
            encoding_req_received <= i_rx_decoding;
        end
    end
end

//================================================================================
// Main State Machine Combinational Logic
//================================================================================
always @(*) begin
    if (i_reset) begin
        substates_done = 0;
        train_active_en_reg = 0;
    end else begin
        // On training error, return to initial state
        if (train_error_reg) begin
            NS = VALVREF;
            substates_done = 0;
        end else begin
            case (CS)
                //====================================================================
                // VALVREF State: Valid Signal Reference Voltage Calibration
                //====================================================================
                VALVREF: begin
                    if (!substates_done) begin
                        case (current_substate)
                            // Substate 0: Wait for and respond to initial handshake request
                            0: begin
                                o_rx_encoding_reg = 'h80;  // VALVREF response encoding
                                NS = VALVREF;
                                substates_done = 0;
                                clock_to_test_enable = 0;
                                SPEEDIDLE_trainerror = 0;

                                // Response handshake - wait for both TX and RX done
                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else if (i_sb_rx_req) o_rx_sb_rsp_reg = 1;

                                // Wait for matching done signal
                                if (i_sb_rx_done) begin
                                    o_rx_encoding_reg = 'h185;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                    next_substate = 1;
                                end 
                                else next_substate = 0;
                            end  

                            // Substate 1: Run eye sweep test
                            1:begin
                                clock_to_test_enable = 1;  // Enable eye sweep module
                                // Connect eye sweep outputs to RX outputs
                                o_rx_encoding_reg = o_rx_encoding_data_to_clock_test;
                                o_rx_data_reg = o_rx_data_data_to_clock_test;
                                o_rx_info_reg = o_rx_info_data_to_clock_test;
                                o_rx_sb_req_reg = o_rx_sb_req_data_to_clock_test;
                                o_rx_sb_rsp_reg = o_rx_sb_rsp_data_to_clock_test;
                                o_rx_sb_done_reg = o_rx_sb_done_data_to_clock_test;
                                
                                init = 1;        // Initialization mode (different from TX)
                                no_retry = 0;    // Allow retries
                                substates_done = 0;

                                // Wait for eye sweep completion
                                if (i_sb_rx_req && i_rx_decoding == 'h82) begin
                                    o_rx_encoding_reg = 'h82;
                                    next_substate = 2;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                end else next_substate = 1;
                            end

                            // Substate 2: Send completion response
                            2: begin
                                clock_to_test_enable = 0;
                                o_rx_encoding_reg = 'h82;  // VALVREF complete encoding
                                NS = VALVREF;

                                // Response handshake
                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else if (i_tx_done && i_rx_done) o_rx_sb_rsp_reg = 1;

                                // Wait for matching done signal to complete substates
                                if (i_sb_rx_done) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 2;
                                end 
                            end  
                        endcase
                    end
                    // Check if request with correct encoding received
                    if (req_received && encoding_req_received == 'h88) begin
                        NS = DATAVREF;  // Move to next training state
                        o_rx_encoding_reg = 'h88;
                        substates_done = 0;
                        o_rx_sb_req_reg = 0;
                        o_rx_sb_rsp_reg = 0;
                    end else begin
                        NS = VALVREF;
                    end 
                end

                //====================================================================
                // DATAVREF State: Data Signal Reference Voltage Calibration
                //====================================================================
                DATAVREF: begin
                    if (!substates_done) begin
                        case (current_substate)
                            0: begin
                                o_rx_encoding_reg = 'h88;
                                NS = DATAVREF;
                                substates_done = 0;

                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else o_rx_sb_rsp_reg = 1;

                                if (i_sb_rx_done) begin
                                    o_rx_encoding_reg = 'h185;
                                    next_substate = 1;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                end else next_substate = 0;
                            end  

                            1: begin
                                clock_to_test_enable = 1;
                                o_rx_encoding_reg = o_rx_encoding_data_to_clock_test;
                                o_rx_data_reg = o_rx_data_data_to_clock_test;
                                o_rx_info_reg = o_rx_info_data_to_clock_test;
                                o_rx_sb_req_reg = o_rx_sb_req_data_to_clock_test;
                                o_rx_sb_rsp_reg = o_rx_sb_rsp_data_to_clock_test;
                                o_rx_sb_done_reg = o_rx_sb_done_data_to_clock_test;
                                init = 1;
                                no_retry = 0;
                                substates_done = 0;

                                if (i_sb_rx_req && i_rx_decoding == 'h8A) begin
                                    o_rx_encoding_reg = 'h8A;
                                    next_substate = 2;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                end else next_substate = 1;
                            end  

                            2: begin
                                clock_to_test_enable = 0;
                                

                                o_rx_encoding_reg = 'h8A;
                                NS = DATAVREF; 

                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else if (i_tx_done && i_rx_done) o_rx_sb_rsp_reg = 1;

                                if (i_sb_rx_done) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 2;
                                end 
                            end  
                        endcase
                    end

                    if (previous_state_done && encoding_rsp_sent == 'h8A && encoding_rsp_received == 'h8A) begin
                        NS = SPEEDIDLE;
                        o_rx_sb_req_reg = 0;
                        o_rx_sb_rsp_reg = 0;
                        o_rx_encoding_reg = 'hC8;
                        substates_done = 0;
                    end else begin
                        NS = DATAVREF;
                    end 
                end

                //====================================================================
                // SPEEDIDLE State: Speed and Idle Configuration
                //====================================================================
                SPEEDIDLE: begin
                    if (!substates_done) begin
                        case (current_substate)
                            0: begin
                                NS = SPEEDIDLE;
                                substates_done = 0;

                                if (o_pl_speedmode && i_sb_rx_req && i_rx_decoding == 'hCA) begin
                                    o_rx_encoding_reg = 'hC8;
                                    next_substate = 1;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                end else if (!o_pl_speedmode) begin
                                    // Speed mismatch error
                                    SPEEDIDLE_trainerror = 1;
                                end
                            end  

                            1: begin
                                o_rx_encoding_reg = 'hCA;
                                NS = SPEEDIDLE; 

                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else if (i_tx_done && i_rx_done) o_rx_sb_rsp_reg = 1;

                                if (i_sb_rx_done) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 1;
                                end 
                            end  
                        endcase
                    end
                    if (i_sb_rx_req && i_rx_decoding == 'hD0) begin
                        NS = TXSELFCAL;
                        o_rx_sb_req_reg = 0;
                        o_rx_sb_rsp_reg = 0;
                        o_rx_encoding_reg = 'hD0;
                        substates_done = 0;
                    end else begin
                        NS = SPEEDIDLE;
                    end 
                end

                //====================================================================
                // TXSELFCAL State: TX Self-Calibration
                //====================================================================
                TXSELFCAL: begin
                    if (!substates_done) begin
                        case (current_substate)
                            0: begin
                                o_rx_encoding_reg = 'hD0;
                                NS = TXSELFCAL;
                                substates_done = 0;

                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else if (i_tx_done && i_rx_done) o_rx_sb_rsp_reg = 1;

                                if (i_sb_rx_done) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                end
                            end  
                        endcase
                    end
                    if (req_received && encoding_req_received == 'h98) begin
                        NS = RXCLKCAL;
                        o_rx_sb_req_reg = 0;
                        o_rx_sb_rsp_reg = 0;
                        o_rx_encoding_reg = 'h98;
                        substates_done = 0;
                    end else begin
                        NS = TXSELFCAL;
                    end 
                end

                //====================================================================
                // RXCLKCAL State: RX Clock Calibration
                //====================================================================
                RXCLKCAL: begin
                    if (!substates_done) begin
                        case (current_substate)
                            0: begin
                                o_rx_encoding_reg = 'h98;
                                NS = RXCLKCAL;
                                substates_done = 0;

                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else o_rx_sb_rsp_reg = 1;

                                if (i_sb_rx_done) begin
                                    o_rx_encoding_reg = 'h185;
                                    next_substate = 1;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                end
                                else next_substate = 0;
                            end  

                            1: begin
                                clock_to_test_enable = 1;
                                o_rx_encoding_reg = o_rx_encoding_data_to_clock_test;
                                o_rx_data_reg = o_rx_data_data_to_clock_test;
                                o_rx_info_reg = o_rx_info_data_to_clock_test;
                                o_rx_sb_req_reg = o_rx_sb_req_data_to_clock_test;
                                o_rx_sb_rsp_reg = o_rx_sb_rsp_data_to_clock_test;
                                o_rx_sb_done_reg = o_rx_sb_done_data_to_clock_test;
                                init = 1;        // Not initialization mode (different from TX)
                                no_retry = 0;
                                substates_done = 0;

                                if (i_sb_rx_req && i_rx_decoding == 'h9A) begin
                                    o_rx_encoding_reg = 'h9A;
                                    next_substate = 2;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                end else next_substate = 1;
                            end  

                            2: begin
                                clock_to_test_enable = 0;
                                

                                o_rx_encoding_reg = 'h9A;
                                NS = RXCLKCAL; 

                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else if (i_tx_done && i_rx_done) o_rx_sb_rsp_reg = 1;

                                if (i_sb_rx_done) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 2;
                                end 
                            end  
                        endcase
                    end
                    if (req_received && encoding_req_received == 'hA0) begin
                        NS = VALTRAINCENTER;
                        o_rx_encoding_reg = 'hA0;
                        o_rx_sb_req_reg = 0;
                        o_rx_sb_rsp_reg = 0;
                        substates_done = 0;
                    end else begin
                        NS = RXCLKCAL;
                    end 
                end

                //====================================================================
                // VALTRAINCENTER State: Valid Signal Training - Center Position
                //====================================================================
                VALTRAINCENTER: begin
                    if (!substates_done) begin
                        case (current_substate)
                            0: begin
                                o_rx_encoding_reg = 'hA0;
                                NS = VALTRAINCENTER;
                                substates_done = 0;

                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else o_rx_sb_rsp_reg = 1;

                                if (i_sb_rx_done) begin
                                    o_rx_encoding_reg = 'h185;
                                    next_substate = 1;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                end
                                else next_substate = 0;
                            end  

                            1: begin
                                clock_to_test_enable = 1;
                                o_rx_encoding_reg = o_rx_encoding_data_to_clock_test;
                                o_rx_data_reg = o_rx_data_data_to_clock_test;
                                o_rx_info_reg = o_rx_info_data_to_clock_test;
                                o_rx_sb_req_reg = o_rx_sb_req_data_to_clock_test;
                                o_rx_sb_rsp_reg = o_rx_sb_rsp_data_to_clock_test;
                                o_rx_sb_done_reg = o_rx_sb_done_data_to_clock_test;
                                init = 1;
                                no_retry = 0;
                                substates_done = 0;

                                if (i_sb_rx_req && i_rx_decoding == 'hA2) begin
                                    o_rx_encoding_reg = 'hA2;
                                    next_substate = 2;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                end else next_substate = 1;
                            end  

                            2: begin
                                clock_to_test_enable = 0;
                                

                                o_rx_encoding_reg = 'hA2;
                                NS = VALTRAINCENTER; 

                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else if (i_tx_done && i_rx_done) o_rx_sb_rsp_reg = 1;

                                if (i_sb_rx_done) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 2;
                                end 
                            end  
                        endcase
                    end
                    if (req_received && encoding_req_received == 'hE8) begin
                        NS = VALTRAINVREF;
                        o_rx_encoding_reg = 'hE8;
                        substates_done = 0;
                        o_rx_sb_req_reg = 0;
                        o_rx_sb_rsp_reg = 0;
                    end else begin
                        NS = VALTRAINCENTER;
                    end 
                end

                //====================================================================
                // VALTRAINVREF State: Valid Signal Training - Voltage Reference
                //====================================================================
                VALTRAINVREF: begin
                    if (!substates_done) begin
                        case (current_substate)
                            0: begin
                                o_rx_encoding_reg = 'hE8;
                                NS = VALTRAINVREF;
                                substates_done = 0;

                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else o_rx_sb_rsp_reg = 1;

                                if (i_sb_rx_done) begin
                                    o_rx_encoding_reg = 'h185;
                                    next_substate = 1;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                end
                                else next_substate = 0;
                            end  

                            1: begin
                                clock_to_test_enable = 1;
                                o_rx_encoding_reg = o_rx_encoding_data_to_clock_test;
                                o_rx_data_reg = o_rx_data_data_to_clock_test;
                                o_rx_info_reg = o_rx_info_data_to_clock_test;
                                o_rx_sb_req_reg = o_rx_sb_req_data_to_clock_test;
                                o_rx_sb_rsp_reg = o_rx_sb_rsp_data_to_clock_test;
                                o_rx_sb_done_reg = o_rx_sb_done_data_to_clock_test;
                                init = 1;
                                no_retry = 0;
                                substates_done = 0;

                                if (i_sb_rx_req && i_rx_decoding == 'hEA) begin
                                    o_rx_encoding_reg = 'hEA;
                                    next_substate = 2;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                end else next_substate = 1;
                            end  

                            2: begin
                                clock_to_test_enable = 0;
                                

                                o_rx_encoding_reg = 'hEA;
                                NS = VALTRAINVREF; 

                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else if (i_tx_done && i_rx_done) o_rx_sb_rsp_reg = 1;

                                if (i_sb_rx_done) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 2;
                                end 
                            end  
                        endcase
                    end
                    if (req_received && encoding_req_received == 'h90) begin
                        NS = DATATRAINCENTER1;
                        substates_done = 0;
                        o_rx_encoding_reg = 'h90;
                        o_rx_sb_req_reg = 0;
                        o_rx_sb_rsp_reg = 0;
                    end else begin
                        NS = VALTRAINVREF;
                    end 
                end

                //====================================================================
                // DATATRAINCENTER1 State: Data Training Center - Phase 1
                //====================================================================
                DATATRAINCENTER1: begin
                    if (!substates_done) begin
                        case (current_substate)
                            0: begin
                                o_rx_encoding_reg = 'h90;
                                NS = DATATRAINCENTER1;
                                substates_done = 0;

                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else o_rx_sb_rsp_reg = 1;

                                if (i_sb_rx_done) begin
                                    o_rx_encoding_reg = 'h185;
                                    next_substate = 1;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                end
                                else next_substate = 0;
                            end  

                            1: begin
                                clock_to_test_enable = 1;
                                o_rx_encoding_reg = o_rx_encoding_data_to_clock_test;
                                o_rx_data_reg = o_rx_data_data_to_clock_test;
                                o_rx_info_reg = o_rx_info_data_to_clock_test;
                                o_rx_sb_req_reg = o_rx_sb_req_data_to_clock_test;
                                o_rx_sb_rsp_reg = o_rx_sb_rsp_data_to_clock_test;
                                o_rx_sb_done_reg = o_rx_sb_done_data_to_clock_test;
                                init = 1;
                                no_retry = 1;    // No retries for this phase
                                substates_done = 0;


                                if (i_sb_rx_req && i_rx_decoding == 'h92) begin
                                    o_rx_encoding_reg = 'h92;
                                    next_substate = 2;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                end else next_substate = 1;
                            end  

                            2: begin
                                clock_to_test_enable = 0;
                                

                                o_rx_encoding_reg = 'h92; 
                                NS = DATATRAINCENTER1;

                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else if (i_tx_done && i_rx_done) o_rx_sb_rsp_reg = 1;

                                if (i_sb_rx_done) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 2;
                                end 
                            end  
                        endcase
                    end 
                    if (req_received && encoding_req_received == 'hF0) begin
                        NS = DATATRAINVREF;
                        o_rx_encoding_reg = 'hF0;
                        o_rx_sb_req_reg = 0;
                        o_rx_sb_rsp_reg = 0;
                        substates_done = 0;
                    end else begin
                        NS = DATATRAINCENTER1;
                    end
                end

                //====================================================================
                // DATATRAINVREF State: Data Training - Voltage Reference
                //====================================================================
                DATATRAINVREF: begin
                    if (!substates_done) begin
                        case (current_substate)
                            0: begin
                                o_rx_encoding_reg = 'hF0;
                                NS = DATATRAINVREF;
                                substates_done = 0;

                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else o_rx_sb_rsp_reg = 1;

                                if (i_sb_rx_done) begin
                                    o_rx_encoding_reg = 'h185;
                                    next_substate = 1;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                end
                                else next_substate = 0;
                            end  

                            1: begin
                                clock_to_test_enable = 1;
                                o_rx_encoding_reg = o_rx_encoding_data_to_clock_test;
                                o_rx_data_reg = o_rx_data_data_to_clock_test;
                                o_rx_info_reg = o_rx_info_data_to_clock_test;
                                o_rx_sb_req_reg = o_rx_sb_req_data_to_clock_test;
                                o_rx_sb_rsp_reg = o_rx_sb_rsp_data_to_clock_test;
                                o_rx_sb_done_reg = o_rx_sb_done_data_to_clock_test;
                                init = 1;
                                no_retry = 0;
                                substates_done = 0;

                                if (i_sb_rx_req && i_rx_decoding == 'hF2) begin
                                    o_rx_encoding_reg = 'hF2;
                                    next_substate = 2;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                end else next_substate = 1;
                            end  

                            2: begin
                                clock_to_test_enable = 0;
                                o_rx_encoding_reg = 'hF2;
                                NS = DATATRAINVREF; 

                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else if (i_tx_done && i_rx_done) o_rx_sb_rsp_reg = 1;

                                if (i_sb_rx_done) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 2;
                                end 
                            end  
                        endcase
                    end
                    if (req_received && encoding_req_received == 'hA8) begin
                        NS = RXDESKEW;
                        o_rx_encoding_reg = 'hA8;
                        substates_done = 0;
                        o_rx_sb_req_reg = 0;
                        o_rx_sb_rsp_reg = 0;
                    end else begin
                        NS = DATATRAINVREF;
                    end 
                end

                //====================================================================
                // RXDESKEW State: RX Deskew Calibration
                //====================================================================
                RXDESKEW: begin
                    if (!substates_done) begin
                        case (current_substate)
                            0: begin
                                o_rx_encoding_reg = 'hA8;
                                NS = RXDESKEW;
                                substates_done = 0;

                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else o_rx_sb_rsp_reg = 1;

                                if (i_sb_rx_req && i_rx_decoding == 'hAC) begin
                                    o_rx_encoding_reg = 'hAC;
                                    next_substate = 1;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                end
                                else next_substate = 0;
                            end  

                            1: begin
                                o_rx_encoding_reg = 'hAC; 
                                NS = RXDESKEW;

                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else if (i_tx_done && i_rx_done) o_rx_sb_rsp_reg = 1;

                                if (i_sb_rx_done) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 1;
                                end 
                            end  
                        endcase
                    end 
                    if (req_received && encoding_req_received == 'hB0) begin
                        NS = DATATRAINCENTER2;
                        o_rx_encoding_reg = 'hB0;
                        substates_done = 0;
                        o_rx_sb_req_reg = 0;
                        o_rx_sb_rsp_reg = 0;
                    end else begin
                        NS = RXDESKEW;
                    end 
                end

                //====================================================================
                // DATATRAINCENTER2 State: Data Training Center - Phase 2
                //====================================================================
                DATATRAINCENTER2: begin
                    if (!substates_done) begin
                        case (current_substate)
                            0: begin
                                o_rx_encoding_reg = 'hB0;
                                NS = DATATRAINCENTER2;
                                substates_done = 0;

                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else o_rx_sb_rsp_reg = 1;

                                if (i_sb_rx_done) begin
                                    o_rx_encoding_reg = 'h185;
                                    next_substate = 1;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                end
                                else next_substate = 0;
                            end  

                            1: begin
                                clock_to_test_enable = 1;
                                o_rx_encoding_reg = o_rx_encoding_data_to_clock_test;
                                o_rx_data_reg = o_rx_data_data_to_clock_test;
                                o_rx_info_reg = o_rx_info_data_to_clock_test;
                                o_rx_sb_req_reg = o_rx_sb_req_data_to_clock_test;
                                o_rx_sb_rsp_reg = o_rx_sb_rsp_data_to_clock_test;
                                o_rx_sb_done_reg = o_rx_sb_done_data_to_clock_test;
                                init = 1;
                                no_retry = 1;
                                substates_done = 0;

                                if (i_sb_rx_req && i_rx_decoding == 'hB2) begin
                                    o_rx_encoding_reg = 'hB2;
                                    next_substate = 2;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                end else next_substate = 1;
                            end  

                            2: begin
                                clock_to_test_enable = 0;
                                o_rx_encoding_reg = 'hB2; 
                                NS = DATATRAINCENTER2;

                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else if (i_tx_done && i_rx_done) o_rx_sb_rsp_reg = 1;

                                if (i_sb_rx_done) begin
                                    substates_done = 1;
                                    train_active_en_reg = 1;  // Mark training as active/complete
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                    substates_done = 0;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 2;
                                end 
                            end  
                        endcase
                    end
                end
            endcase
        end
    end
end

endmodule
