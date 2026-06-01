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
    parameter ERROR_THRESHOLD = 1    // Threshold for acceptable training errors
) (
    // Clock and reset
    input i_clk,
    input i_reset,
    input  tx_trainerror,
    // RX interface inputs - data coming from remote TX
    input [DECODING_WIDTH-1:0] i_rx_decoding,    // Decoded command from TX
    input [DATA_WIDTH-1:0] i_rx_data,            // Data from TX
    input [INFO_WIDTH-1:0] i_rx_info,            // Info/control from TX
    input [DATA_WIDTH-1:0] i_rx_data_results,               // Per-lane results from eye sweep tests
    input [2:0] i_lane_map,               // Per-lane results from eye sweep tests
    input i_rx_valid_results,               // Valid strobe for i_rx_data_results

    // Sideband control inputs
    input i_sb_rx_req,     // Sideband request from TX
    input i_sb_rx_rsp,     // Sideband response from TX
    input i_sb_rx_done,    // Sideband done from TX
    input i_rx_done,       // RX operation complete
    input i_tx_done,       // TX operation complete
    input i_tx_error,      // TX error flag
    
    // Training control inputs
    input init_train_en,   // Enable training initialization
    input speed_idle_state_enable,   // Enable SPEEDIDLE state
    input tx_self_cal_state_enable,   // Enable TX self-calibration state
    input timeout,         // Training timeout error
    input [2:0] o_pl_speedmode,  // Physical layer speed mode

    input [DECODING_WIDTH-1:0] encoding_rsp_sent,      // Encoding value when response sent
    input [DECODING_WIDTH-1:0] encoding_rsp_received,  // Encoding value when response received
    input rsp_received,               // Response received flag
    input rsp_sent,                   // Response sent flag
    
    // RX interface outputs - data going to remote TX
    output logic [DECODING_WIDTH-1:0] o_rx_encoding,  // Encoded command to send
    output logic [DATA_WIDTH-1:0] o_rx_data,          // Data to send
    output logic [INFO_WIDTH-1:0] o_rx_info,          // Info/control to send
    output logic [2:0] o_lane_map_rx,          // Info/control to send
    
    // Sideband control outputs
    output logic o_rx_sb_req,   // Sideband request to TX
    output logic o_rx_sb_rsp,   // Sideband response to TX
    output logic o_rx_sb_done,  // Sideband done to TX
    
    // Status outputs
    output logic train_error,      // Training error occurred
    output logic train_link_init_en,   // Training is active
    output logic train_phyretrain_en   // Training is active
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
logic train_link_init_en_reg;
logic train_phyretrain_en_reg;
logic failed_test;  // Indicates if current test failed

// Signals from eye sweep test module
logic [DECODING_WIDTH-1:0] o_rx_encoding_data_to_clock_test;
logic [DATA_WIDTH-1:0] o_rx_data_data_to_clock_test;
logic [INFO_WIDTH-1:0] o_rx_info_data_to_clock_test;
logic o_rx_sb_req_data_to_clock_test;
logic o_rx_sb_rsp_data_to_clock_test;
logic o_rx_sb_done_data_to_clock_test;
logic train_error_data_to_clock_test;
logic [7:0] o_rx_sweep_result_data_to_clock_test;  // Captured sweep result from RX eye sweep module

// Substate machine signals
logic [2:0] current_substate;  // Current substate within main state
logic [2:0] next_substate;     // Next substate

// Handshake control signals
logic state_enb;                  // Enable signal for current state operations
logic done_ack;                   // Acknowledge that done was received
logic done_ack_old;               // Previous value of done_ack
logic substates_done;             // All substates completed
logic substates_done_old;             // All substates completed
logic previous_state_done;        // Previous state handshake complete
logic req_received;               // Request received flag
logic trainerror;               // Internal error flag for SPEEDIDLE/LINKSPEED speed negotiation
logic [DECODING_WIDTH-1:0] encoding_req_received;  // Encoding value when request received

logic init;        // Initialization mode for eye sweep test
logic comparison_type;        // Initialization mode for eye sweep test
logic no_retry;    // No retry mode for eye sweep test
logic clock_to_test_enable;       // Enable the eye sweep test module
logic clock_to_test_done;         // Eye sweep test complete

logic r_eye_sweep_reset;
logic train_error_pip;

//================================================================================
// Eye Sweep Test Module Instantiation
//================================================================================
// This module performs data-to-clock eye diagram sweeping for signal integrity
ucie_RX_Data_to_Clock_eye_sweep ucie_RX_Data_to_Clock_eye_sweep_inst (
    .i_clk(i_clk),
    .i_reset(r_eye_sweep_reset),  // Reset when enabled (inverted logic vs TX)
    .i_xx_decoding(i_rx_decoding),
    .i_xx_data(i_rx_data),
    .i_xx_info(i_rx_info),
    .i_sb_xx_req(i_sb_rx_req),
    .i_sb_xx_rsp(i_sb_rx_rsp),
    .i_sb_xx_done(i_sb_rx_done),
    .i_xx_done(i_rx_done),
    .done_ack(done_ack),
    .init(init),
    .no_retry(no_retry),
    .comparison_type(comparison_type),
    .data_result(i_rx_data_results),
    .valid_result(i_rx_valid_results),
    .o_xx_encoding(o_rx_encoding_data_to_clock_test),
    .o_xx_data(o_rx_data_data_to_clock_test),
    .o_xx_info(o_rx_info_data_to_clock_test),
    .o_xx_sweep_result(o_rx_sweep_result_data_to_clock_test),  // Routed to internal wire; sweep result not forwarded upstream from this module
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
assign previous_state_done = (rsp_sent & rsp_received);

// Training error aggregation - timeout, eye sweep error, or speed idle error
assign train_error = (timeout || train_error_data_to_clock_test || trainerror || (i_sb_rx_req && i_rx_decoding == 'h40));

always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        train_error_pip <= 0;
    end else begin
        train_error_pip <= train_error;
    end
end

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
        train_link_init_en <= 0;
        train_phyretrain_en <= 0;
    end else if (!init_train_en) begin
        CS <= VALVREF;           // Reset to initial training state
        current_substate <= 0;   // Reset substate
        o_rx_encoding <= 'h80;
        o_rx_data <= 0;
        o_rx_info <= 0;
        o_rx_sb_req <= 0;
        o_rx_sb_rsp <= 0;
        train_link_init_en <= train_link_init_en_reg;
        train_phyretrain_en <= train_phyretrain_en_reg;
    end else begin
        CS <= NS;                // Advance to next state
        current_substate <= next_substate;
        o_rx_encoding <= o_rx_encoding_reg;
        o_rx_data <= o_rx_data_reg;
        o_rx_info <= o_rx_info_reg;
        o_rx_sb_req <= o_rx_sb_req_reg;
        o_rx_sb_rsp <= o_rx_sb_rsp_reg;
        train_link_init_en <= train_link_init_en_reg;
        train_phyretrain_en <= train_phyretrain_en_reg;
    end 
end


assign r_eye_sweep_reset = !clock_to_test_enable && !i_reset;

//================================================================================
// Done Acknowledgement Logic
//================================================================================
// Tracks when done signal has been acknowledged in handshake protocol.
// done_ack is cleared whenever the encoding changes (new state/substate),
// ensuring the handshake re-arms for each distinct transaction.
always @(*) begin
    done_ack = done_ack_old;
    if (!init_train_en) done_ack = 0;
    else if (o_rx_encoding != o_rx_encoding_old) done_ack = 0;  // New encoding → reset ack
    else if (i_sb_rx_done) begin
        done_ack = 1;  // Set when done received
    end else if (i_sb_rx_rsp) begin
        done_ack = 0;  // Clear on response to allow next transaction
    end
end

always @(posedge i_clk) begin
    o_rx_encoding_old <= o_rx_encoding;  // Register to track previous encoding for done_ack logic
    substates_done_old <= substates_done;  // Register to track previous substates_done for state transition logic
    done_ack_old <= done_ack;  // Register to track previous substates_done for state transition logic
end

//================================================================================
// Sideband Done Signal Logic
//================================================================================
// Generates a one-cycle done pulse in response to any sideband request or response.
// The pulse self-clears the next cycle, so done is always a single-cycle strobe.
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
// Latches the most-recently-seen sideband request and its decoding value.
// The combinational FSM uses req_received + encoding_req_received to decide
// when to advance to the next major training state, decoupling the advance
// check from the exact clock cycle the request arrived.
always @(*) begin
    req_received = 0;
    encoding_req_received = 0;
    // Capture request when received
    if (i_sb_rx_req) begin
        req_received = 1;
        encoding_req_received = i_rx_decoding;
    end
end

//================================================================================
// Main State Machine Combinational Logic
//================================================================================
// Each MBTRAIN state follows the same 3-substate pattern (RX mirror of TX):
//   Substate 0 — Initial handshake: assert sideband response; wait for TX done.
//   Substate 1 — Eye sweep: enable clock_to_test module (init=1); pipe outputs.
//   Substate 2 — Completion handshake: de-assert eye sweep; wait for TX done
//                before advancing via req_received / previous_state_done.
// States without an embedded eye sweep (e.g. TXSELFCAL, RXCLKCAL) skip substate 1.
//================================================================================
always @(*) begin
    o_rx_sb_req_reg = 0;
    o_rx_sb_rsp_reg = 0;
    o_rx_info_reg = 0;
    o_rx_data_reg = 0;
    comparison_type = 0;
    o_rx_data_reg = 0;
    o_rx_info_reg = 0;
    init = 0;
    no_retry = 0;
    trainerror = 0;
    o_lane_map_rx = 0;
    clock_to_test_enable = 0;
    train_link_init_en_reg = train_link_init_en;
    train_phyretrain_en_reg = train_phyretrain_en;
    o_rx_encoding_reg = o_rx_encoding;
    NS = CS;
    substates_done = substates_done_old;
    next_substate = current_substate;
    if (!init_train_en) begin
        substates_done = 0;
    end else 
        // On training error (timeout, eye sweep failure, or speed mismatch),
        // abort immediately back to VALVREF so the full calibration sequence restarts.
        if (train_error_pip) begin
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
                                trainerror = 0;

                                // Response handshake - wait for both TX and RX done
                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else o_rx_sb_rsp_reg = 1;

                                // Wait for matching done signal
                                if (i_sb_rx_done) begin
                                    o_rx_encoding_reg = 'h188;
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

                                
                                init = 1;        // Not initialization mode
                                comparison_type = 1;        // Valid signal training         // Initialization mode (different from TX)
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
                                else o_rx_sb_rsp_reg = o_rx_sb_rsp;

                                // Wait for matching done signal to complete substates
                                if (i_sb_rx_done) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 2;
                                end 
                            end  
                        default:begin
                                
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
                                    o_rx_encoding_reg = 'h188;
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

                                init = 1;        // Not initialization mode
                                comparison_type = 0;        // Valid signal training 
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
                                else o_rx_sb_rsp_reg = o_rx_sb_rsp;

                                if (i_sb_rx_done) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 2;
                                end 
                            end  
                        default:begin
                                
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
                                o_rx_encoding_reg = 'hC8;

                                if (i_sb_rx_req && i_rx_decoding == 'hCA) begin
                                    o_rx_encoding_reg = 'hCA;
                                    next_substate = 1;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                end
                            end  

                            1: begin
                                o_rx_encoding_reg = 'hCA;
                                NS = SPEEDIDLE; 

                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else if (i_tx_done && i_rx_done) o_rx_sb_rsp_reg = 1;
                                else o_rx_sb_rsp_reg = o_rx_sb_rsp;

                                if (i_sb_rx_done) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 1;
                                end 
                            end  
                        default:begin
                                
                            end
                        endcase
                    end
                    if (i_sb_rx_req && i_rx_decoding == 'hD1) begin
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
                                else o_rx_sb_rsp_reg = o_rx_sb_rsp;

                                if (i_sb_rx_done) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                end
                            end  
                        default:begin
                                
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

                                if (i_sb_rx_req && i_rx_decoding == 'h9A) begin
                                    o_rx_encoding_reg = 'h9A;
                                    next_substate = 1;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                end
                                else next_substate = 0;
                            end  

                            1: begin
                                o_rx_encoding_reg = 'h9A;
                                NS = RXCLKCAL; 

                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else if (i_tx_done && i_rx_done) o_rx_sb_rsp_reg = 1;
                                else o_rx_sb_rsp_reg = o_rx_sb_rsp;

                                if (i_sb_rx_done) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 1;
                                end 
                            end  
                        default:begin
                                
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
                                    o_rx_encoding_reg = 'h188;
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

                                init = 1;        // Not initialization mode
                                comparison_type = 1;        // Valid signal training 
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
                                else o_rx_sb_rsp_reg = o_rx_sb_rsp;

                                if (i_sb_rx_done) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 2;
                                end 
                            end  
                        default:begin
                                
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
                                    o_rx_encoding_reg = 'h188;
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

                                init = 1;        // Not initialization mode
                                comparison_type = 1;        // Valid signal training 
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
                                else o_rx_sb_rsp_reg = o_rx_sb_rsp;

                                if (i_sb_rx_done) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 2;
                                end 
                            end  
                        default:begin
                                
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
                                    o_rx_encoding_reg = 'h188;
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

                                init = 1;        // Not initialization mode
                                comparison_type = 0;        // Valid signal training 
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
                                else o_rx_sb_rsp_reg = o_rx_sb_rsp;

                                if (i_sb_rx_done) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 2;
                                end 
                            end  
                        default:begin
                                
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
                                    o_rx_encoding_reg = 'h188;
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

                                init = 1;        // Not initialization mode
                                comparison_type = 0;  
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
                                else o_rx_sb_rsp_reg = o_rx_sb_rsp;

                                if (i_sb_rx_done) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 2;
                                end 
                            end  
                        default:begin
                                
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
                                else o_rx_sb_rsp_reg = o_rx_sb_rsp;

                                if (i_sb_rx_done) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 1;
                                end 
                            end  
                        default:begin
                                
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
                                    o_rx_encoding_reg = 'h188;
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

                                init = 1;        // Not initialization mode
                                comparison_type = 0;
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
                                else o_rx_sb_rsp_reg = o_rx_sb_rsp;

                                if (i_sb_rx_done) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 2;
                                end 
                            end  
                        default:begin
                                
                            end
                        endcase
                    end
                    if (req_received && encoding_req_received == 'hB8) begin
                        NS = LINKSPEED;
                        o_rx_encoding_reg = 'hB8;
                        substates_done = 0;
                        o_rx_sb_req_reg = 0;
                        o_rx_sb_rsp_reg = 0;
                    end else begin
                        NS = DATATRAINCENTER2;
                    end 
                end

                //====================================================================
                // LINKSPEED State: Final Speed Negotiation and Link-Up Handshake
                // This is the most complex state. After the eye sweep (substate 1),
                // the outcome branches into one of four substates:
                //   2 → DONE       : TX and RX both passed → assert train_link_init_en
                //   3 → PHYRETRAIN : TX or RX initiated retrain → assert train_phyretrain_en
                //   4 → ERROR RESP : Both TX and RX errored → wait for SPEEDDEGRADE or REPAIR
                //   5 → SPEEDDEGRADE: Re-enter SPEEDIDLE at a lower speed
                //   6 → REPAIR     : Lane repair handshake before re-entering REPAIR state
                //====================================================================
                LINKSPEED: begin
                    if (!substates_done) begin
                        case (current_substate)
                            0: begin
                                o_rx_encoding_reg = 'hB8;
                                NS = LINKSPEED;
                                substates_done = 0;

                                // should'nt I wait a REQ ??
                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else o_rx_sb_rsp_reg = 1;

                                if (i_sb_rx_req && i_rx_decoding == 'h180) begin
                                    o_rx_encoding_reg = 'h180;
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

                                init = 0;        // Not initialization mode
                                comparison_type = 0;
                                no_retry = 1;
                                substates_done = 0;

                                // Branch 1: TX reports DONE ('hBA) and no local TX error → link-up path
                                if (i_sb_rx_req && i_rx_decoding == 'hBA && !i_tx_error) begin 
                                    next_substate = 2;  // DONE path
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                    o_rx_encoding_reg = 'hBA; 

                                // Branch 2: TX reports ERROR ('hBB) with no local TX error,
                                // or TX reports DONE but local TX path has an error → phyretrain
                                end else if ((i_sb_rx_req && i_rx_decoding == 'hBB && !i_tx_error) || (i_sb_rx_req && i_rx_decoding == 'hBA && i_tx_error)) begin 
                                    next_substate = 3;  // PHYRETRAIN REQ path
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                    o_rx_encoding_reg = 'hBC; 

                                // Branch 3: TX reports ERROR and local TX path also has an error
                                // → full error response, then await SPEEDDEGRADE or REPAIR decision
                                end else if (i_sb_rx_req && i_rx_decoding == 'hBB && i_tx_error) begin 
                                    next_substate = 4;  // ERROR RESP path
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                    o_rx_encoding_reg = 'hBF; 

                                end else next_substate = 1;
                            end  

                            2: begin  // DONE path: confirm link-up and hand off to ACTIVE state
                                clock_to_test_enable = 0;
                                o_rx_encoding_reg = 'hBA; 
                                NS = LINKSPEED;

                               if (done_ack) o_rx_sb_rsp_reg = 0;
                               else o_rx_sb_rsp_reg = 1;

                                // Both sides confirmed 'hBA: assert train_link_init_en to enable
                                // the ACTIVE state handoff in the top-level LTSM.
                                if (previous_state_done && encoding_rsp_sent == 'hBA && encoding_rsp_received == 'hBA) begin
                                    substates_done = 1;
                                    train_link_init_en_reg = 1;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 2;
                                    train_link_init_en_reg = 0;
                                end 
                            end  

                            3: begin  // PHYRETRAIN path: assert train_phyretrain_en to trigger retrain
                                clock_to_test_enable = 0;
                                o_rx_encoding_reg = 'hBC; 
                                NS = LINKSPEED;

                               if (done_ack) o_rx_sb_req_reg = 0;
                               else o_rx_sb_req_reg = 1;

                                if (i_sb_rx_rsp && i_rx_decoding == 'hBC) begin
                                    substates_done = 1;
                                    train_phyretrain_en_reg = 1;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 3;
                                    train_phyretrain_en_reg = 0;
                                end 
                            end

                            4: begin  // ERROR RESP path: await TX decision on recovery action
                                o_rx_encoding_reg = 'hBF;
                                NS = LINKSPEED;
                                substates_done = 0;

                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else o_rx_sb_rsp_reg = 1;

                                // TX selects SPEEDDEGRADE ('hBE) → drop to next lower link speed
                                if (i_sb_rx_req && i_rx_decoding == 'hBE) begin 
                                    next_substate = 5;  // SPEEDDEGRADE
                                    o_rx_encoding_reg = 'hBE; 
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                // TX selects REPAIR ('hBD) with a valid lane-map → request lane repair
                                end else if (i_sb_rx_req && i_rx_decoding == 'hBD) begin 
                                    if (i_lane_map) begin
                                        next_substate = 6;  // REPAIR
                                        o_rx_encoding_reg = 'hBD; 
                                        o_rx_sb_req_reg = 0;
                                        o_rx_sb_rsp_reg = 0;
                                    end else begin
                                        next_substate = 5;  // SPEEDDEGRADE
                                        o_rx_encoding_reg = 'hBE; 
                                        o_rx_sb_req_reg = 0;
                                        o_rx_sb_rsp_reg = 0;
                                    end
                                end else next_substate = 4;
                            end

                            5: begin
                                clock_to_test_enable = 0;
                                o_rx_encoding_reg = 'hBE; 
                                NS = LINKSPEED;

                               if (done_ack) o_rx_sb_rsp_reg = 0;
                               else o_rx_sb_rsp_reg = 1;

                                if ((previous_state_done && encoding_rsp_sent == 'hBE && encoding_rsp_received == 'hBE) || (i_rx_decoding == 'hBD && encoding_rsp_received == 'hBE)) begin
                                    NS = SPEEDIDLE;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                    o_rx_encoding_reg = 'hC8;
                                    substates_done = 0;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 5;
                                end 
                            end

                            6: begin
                                clock_to_test_enable = 0;
                                o_rx_encoding_reg = 'hBD; 
                                NS = LINKSPEED;

                               if (done_ack) o_rx_sb_rsp_reg = 0;
                               else o_rx_sb_rsp_reg = 1;

                                if (i_sb_rx_req && i_rx_decoding == 'hC0) begin
                                    NS = REPAIR;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                    o_rx_encoding_reg = 'hC0;
                                    substates_done = 0;
                                    next_substate = 0;
                                 end else begin
                                    substates_done = 0;
                                    next_substate = 6;
                                end 
                            end
                            default:begin
                                
                            end
                        endcase
                    end else if (i_sb_rx_req && i_rx_decoding == 'hC0) begin
                            // Phyretrain module asserted repair while link was active → re-enter REPAIR
                            NS = REPAIR;
                            o_rx_sb_req_reg = 0;
                            o_rx_sb_rsp_reg = 0;
                            o_rx_encoding_reg = 'hC0;
                            train_phyretrain_en_reg = 0;
                            train_link_init_en_reg = 0;
                            substates_done = 0;
                            next_substate = 0;
                         end else if (speed_idle_state_enable) begin
                            // Phyretrain module selected speed-change path → re-enter SPEEDIDLE
                            NS = SPEEDIDLE;
                            o_rx_sb_req_reg = 0;
                            o_rx_sb_rsp_reg = 0;
                            o_rx_encoding_reg = 'hC8;
                            train_phyretrain_en_reg = 0;
                            train_link_init_en_reg = 0;
                            substates_done = 0;
                            next_substate = 0;
                         end else if (tx_self_cal_state_enable && i_sb_rx_req && i_rx_decoding == 'hD1) begin
                            // Phyretrain module selected TX self-cal path → re-enter TXSELFCAL
                            NS = TXSELFCAL;
                            o_rx_sb_req_reg = 0;
                            o_rx_sb_rsp_reg = 0;
                            o_rx_encoding_reg = 'hD0;
                            train_phyretrain_en_reg = 0;
                            train_link_init_en_reg = 0;
                            substates_done = 0;
                            next_substate = 0;
                         end else begin
                            o_rx_sb_req_reg = 0;
                            o_rx_sb_rsp_reg = 0;
                            substates_done = 1;
                            train_phyretrain_en_reg = train_phyretrain_en;
                            train_link_init_en_reg = train_link_init_en;
                        end 
                end
                
                //====================================================================
                // REPAIR State: Lane Repair Handshake
                // TX drives the repair sequence; RX responds and waits for the
                // outcome. Encoding 'h40 from TX signals an unrecoverable error
                // (all lanes failed repair) → abort to VALVREF via trainerror.
                //====================================================================
                REPAIR: begin
                    if (!substates_done) begin
                        case (current_substate)
                            0: begin
                                o_rx_encoding_reg = 'hC0;
                                NS = REPAIR;
                                substates_done = 0;

                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else o_rx_sb_rsp_reg = 1;

                                if (i_sb_rx_req && i_rx_decoding == 'h40) begin
                                    trainerror = 1;
                                    substates_done = 1;
                                    next_substate = 0;
                                end else if (i_sb_rx_req && i_rx_decoding == 'hC1 && i_rx_info[2:0]) begin
                                    o_rx_encoding_reg = 'hC1;
                                    o_rx_sb_rsp_reg = 0;
                                    o_rx_sb_req_reg = 0;
                                    next_substate = 1;
                                end
                                else next_substate = 0;
                            end  

                            1: begin
                                clock_to_test_enable = 0;
                                o_rx_encoding_reg = 'hC1;
                                NS = REPAIR;

                                o_lane_map_rx = i_rx_info[2:0];  // Capture repaired lane map from RX info field

                                if (done_ack) o_rx_sb_rsp_reg = 0;
                                else o_rx_sb_rsp_reg = 1;

                                if (i_sb_rx_req && i_rx_decoding == 'hC2) begin
                                    o_rx_info_reg = 0;
                                    o_rx_encoding_reg = 'hC2;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_sb_rsp_reg = 0;
                                    substates_done = 0;
                                    next_substate = 2;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 1;
                                end 
                            end  

                            2: begin
                                clock_to_test_enable = 0;
                                o_rx_encoding_reg = 'hC2; 
                                NS = REPAIR;

                               if (done_ack) o_rx_sb_rsp_reg = 0;
                               else o_rx_sb_rsp_reg = 1;

                                if (i_sb_rx_req && i_rx_decoding == 'hD1) begin
                                    NS = TXSELFCAL;
                                    o_rx_sb_req_reg = 0;
                                    o_rx_encoding_reg = 'hD0;
                                    o_rx_sb_rsp_reg = 0;
                                    substates_done = 0;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 2;
                                end 
                            end  
                            default:begin
                                
                            end
                        endcase
                    end
                end

                default: begin
                    train_link_init_en_reg = 0;
                    train_phyretrain_en_reg = 0;
                    o_rx_encoding_reg = 0;
                    o_rx_data_reg = 0;
                    o_rx_info_reg = 0;
                    o_rx_sb_req_reg = 0;
                    o_rx_sb_rsp_reg = 0;
                    o_rx_sb_done_reg = 0;
                    substates_done = 0;
                    next_substate = 0;
                    no_retry = 0;
                    init = 0;
                    NS = VALVREF;
                end 
            endcase
        end
    end

`ifdef ASSERT_ON

    property done_ack_assert_property;
        @(posedge i_clk) disable iff (i_reset)
        i_sb_rx_done |-> done_ack;
    endproperty

    property done_ack_deassert_property;
        @(posedge i_clk) disable iff (i_reset)
        i_sb_rx_rsp || (o_rx_encoding != o_rx_encoding_old) |-> !done_ack;
    endproperty

    property previous_state_done_property;
        @(posedge i_clk) disable iff (i_reset)
        (rsp_received && rsp_sent) |-> previous_state_done;
    endproperty

    property reset_state_property;
        @(posedge i_clk)
        i_reset |=> (CS == VALVREF);
    endproperty

    property reset_substate_property;
        @(posedge i_clk)
        i_reset |=> (current_substate == 0);
    endproperty

    property reset_encoding_property;
        @(posedge i_clk)
        i_reset |=> (o_rx_encoding == 0);
    endproperty

    property reset_data_property;
        @(posedge i_clk)
        i_reset |=> (o_rx_data == 0);
    endproperty

    property reset_info_property;
        @(posedge i_clk)
        i_reset |=> (o_rx_info == 0);
    endproperty

    property reset_sb_req_property;
        @(posedge i_clk)
        i_reset |=> (o_rx_sb_req == 0);
    endproperty

    property reset_sb_rsp_property;
        @(posedge i_clk)
        i_reset |=> (o_rx_sb_rsp == 0);
    endproperty


    property reset_sb_done_property;
        @(posedge i_clk)
        i_reset |=> (o_rx_sb_done == 0);
    endproperty


    property reset_req_received_property;
        @(posedge i_clk)
        i_reset |=> (req_received == 0);
    endproperty

    property reset_encoding_req_received_property;
        @(posedge i_clk)
        i_reset |=> (encoding_req_received == 0);
    endproperty

    property sb_done_self_clearing_property;
        @(posedge i_clk) disable iff (i_reset)
        o_rx_sb_done |=> (!o_rx_sb_done);
    endproperty

    property sb_done_assert_on_req_property;
        @(posedge i_clk) disable iff (i_reset)
        (i_sb_rx_req && !o_rx_sb_done) |=> o_rx_sb_done;
    endproperty

    property sb_done_assert_on_rsp_property;
        @(posedge i_clk) disable iff (i_reset)
        (i_sb_rx_rsp && !o_rx_sb_done) |=> o_rx_sb_done;
    endproperty

    property not_state_enb_resets_to_valvref_property;
        @(posedge i_clk) disable iff (i_reset)
        (!state_enb) |=> (CS == VALVREF);
    endproperty

    property not_state_enb_resets_substate_property;
        @(posedge i_clk) disable iff (i_reset)
        (!state_enb) |=> (current_substate == 0);
    endproperty

    property valvref_to_datavref_property;
        @(posedge i_clk) disable iff (i_reset || train_error_reg)
        (CS == VALVREF && req_received && encoding_req_received == 'h88 && init_train_en) |=> (CS == DATAVREF);
    endproperty

    property datavref_to_speedidle_property;
        @(posedge i_clk) disable iff (i_reset || train_error_reg)
        (CS == DATAVREF && previous_state_done && encoding_rsp_sent == 'h8A && encoding_rsp_received == 'h8A && init_train_en) |=> (CS == SPEEDIDLE);
    endproperty

    property speedidle_to_txselfcal_property;
        @(posedge i_clk) disable iff (i_reset || train_error_reg)
        (CS == SPEEDIDLE && i_sb_rx_req && i_rx_decoding == 'hD0 && init_train_en) |=> (CS == TXSELFCAL);
    endproperty

    property txselfcal_to_rxclkcal_property;
        @(posedge i_clk) disable iff (i_reset || train_error_reg)
        (CS == TXSELFCAL && req_received && encoding_req_received == 'h98 && init_train_en) |=> (CS == RXCLKCAL);
    endproperty

    property rxclkcal_to_valtraincenter_property;
        @(posedge i_clk) disable iff (i_reset || train_error_reg)
        (CS == RXCLKCAL && req_received && encoding_req_received == 'hA0 && init_train_en) |=> (CS == VALTRAINCENTER);
    endproperty

    property valtraincenter_to_valtrainvref_property;
        @(posedge i_clk) disable iff (i_reset || train_error_reg)
        (CS == VALTRAINCENTER && req_received && encoding_req_received == 'hE8 && init_train_en) |=> (CS == VALTRAINVREF);
    endproperty

    property valtrainvref_to_datatraincenter1_property;
        @(posedge i_clk) disable iff (i_reset || train_error_reg)
        (CS == VALTRAINVREF && req_received && encoding_req_received == 'h90 && init_train_en) |=> (CS == DATATRAINCENTER1);
    endproperty

    property datatraincenter1_to_datatrainvref_property;
        @(posedge i_clk) disable iff (i_reset || train_error_reg)
        (CS == DATATRAINCENTER1 && req_received && encoding_req_received == 'hF0 && init_train_en) |=> (CS == DATATRAINVREF);
    endproperty

    property datatrainvref_to_rxdeskew_property;
        @(posedge i_clk) disable iff (i_reset || train_error_reg)
        (CS == DATATRAINVREF && req_received && encoding_req_received == 'hA8 && init_train_en) |=> (CS == RXDESKEW);
    endproperty

    property rxdeskew_to_datatraincenter2_property;
        @(posedge i_clk) disable iff (i_reset || train_error_reg)
        (CS == RXDESKEW && req_received && encoding_req_received == 'hB0 && init_train_en) |=> (CS == DATATRAINCENTER2);
    endproperty

    property datatraincenter2_completes_training_property;
        @(posedge i_clk) disable iff (i_reset || train_error_reg)
        (CS == DATATRAINCENTER2 && current_substate == 2 && !substates_done && i_sb_rx_done) |-> (train_link_init_en || train_phyretrain_en);
    endproperty

    property previous_state_done_reset_property;
        @(posedge i_clk)
        i_reset |-> !previous_state_done;
    endproperty

    property mutual_exclusive_req_rsp_property;
        @(posedge i_clk) disable iff (i_reset)
        !(o_rx_sb_req && o_rx_sb_rsp);
    endproperty

    property clock_test_enable_only_in_substate1_valvref_property;
        @(posedge i_clk) disable iff (i_reset)
        (CS == VALVREF && current_substate == 0) |-> !clock_to_test_enable;
    endproperty

    property txselfcal_waits_for_sb_done_property;
        @(posedge i_clk) disable iff (i_reset)
        (CS == TXSELFCAL && current_substate == 0 && !i_sb_rx_done && !substates_done && NS == TXSELFCAL) |=> (CS == TXSELFCAL && current_substate == 0);
    endproperty

    property req_received_captures_encoding_property;
        @(posedge i_clk) disable iff (i_reset)
        i_sb_rx_req |=> (req_received && encoding_req_received == $past(i_rx_decoding));
    endproperty

    property valid_state_property;
        @(posedge i_clk) disable iff (i_reset)
        (CS == VALVREF) || (CS == DATAVREF) || (CS == SPEEDIDLE) || (CS == TXSELFCAL) ||
        (CS == RXCLKCAL) || (CS == VALTRAINCENTER) || (CS == VALTRAINVREF) || (CS == DATATRAINCENTER1) ||
        (CS == DATATRAINVREF) || (CS == RXDESKEW) || (CS == DATATRAINCENTER2) || (CS == LINKSPEED) || (CS == REPAIR);
    endproperty
    
    property substates_done_clears_on_transition_property;
        @(posedge i_clk) disable iff (i_reset)
        (CS != $past(CS)) |-> !substates_done;
    endproperty

    property state_transition_values_property;
        @(posedge i_clk) disable iff (i_reset)
        (CS != NS) |-> (!substates_done && !o_rx_sb_req_reg && !o_rx_sb_rsp_reg);
    endproperty

    property state_transition_property;
        @(posedge i_clk) disable iff (i_reset)
        (CS != NS) |=> (CS == $past(NS));
    endproperty

    done_ack_assert_assertion: assert property (done_ack_assert_property)
        else $error("Assertion failed: done_ack should be set when i_sb_rx_done is asserted");
    cover property (done_ack_assert_property);

    done_ack_deassert_assertion: assert property (done_ack_deassert_property)
        else $error("Assertion failed: done_ack should be low when i_sb_rx_rsp is asserted");
    cover property (done_ack_deassert_property);

    previous_state_done_assertion: assert property (previous_state_done_property)
        else $error("Assertion failed: previous_state_done should be set when both rsp_received and rsp_sent are true");
    cover property (previous_state_done_property);

    reset_state_assertion: assert property (reset_state_property)
        else $error("Assertion failed: CS should be VALVREF after reset");
    cover property (reset_state_property);

    reset_substate_assertion: assert property (reset_substate_property)
        else $error("Assertion failed: current_substate should be 0 after reset");
    cover property (reset_substate_property);

    reset_encoding_assertion: assert property (reset_encoding_property)
        else $error("Assertion failed: o_rx_encoding should be 0 after reset");
    cover property (reset_encoding_property);

        reset_data_assertion: assert property (reset_data_property)
        else $error("Assertion failed: o_rx_data should be 0 after reset");
    cover property (reset_data_property);

    reset_info_assertion: assert property (reset_info_property)
        else $error("Assertion failed: o_rx_info should be 0 after reset");
    cover property (reset_info_property);

    reset_sb_req_assertion: assert property (reset_sb_req_property)
        else $error("Assertion failed: o_rx_sb_req should be 0 after reset");
    cover property (reset_sb_req_property);

    reset_sb_rsp_assertion: assert property (reset_sb_rsp_property)
        else $error("Assertion failed: o_rx_sb_rsp should be 0 after reset");
    cover property (reset_sb_rsp_property);

    reset_sb_done_assertion: assert property (reset_sb_done_property)
        else $error("Assertion failed: o_rx_sb_done should be 0 after reset");
    cover property (reset_sb_done_property);

    reset_req_received_assertion: assert property (reset_req_received_property)
        else $error("Assertion failed: req_received should be 0 after reset");
    cover property (reset_req_received_property);

    reset_encoding_req_received_assertion: assert property (reset_encoding_req_received_property)
        else $error("Assertion failed: encoding_req_received should be 0 after reset");
    cover property (reset_encoding_req_received_property);

    sb_done_self_clearing_assertion: assert property (sb_done_self_clearing_property)
        else $error("Assertion failed: o_rx_sb_done should self-clear on the next cycle");
    cover property (sb_done_self_clearing_property);

    sb_done_assert_on_req_assertion: assert property (sb_done_assert_on_req_property)
        else $error("Assertion failed: o_rx_sb_done should assert on sideband request");
    cover property (sb_done_assert_on_req_property);

    sb_done_assert_on_rsp_assertion: assert property (sb_done_assert_on_rsp_property)
        else $error("Assertion failed: o_rx_sb_done should assert on sideband response");
    cover property (sb_done_assert_on_rsp_property);

    valvref_to_datavref_assertion: assert property (valvref_to_datavref_property)
        else $error("Assertion failed: state should transition from VALVREF to DATAVREF");
    cover property (valvref_to_datavref_property);

    datavref_to_speedidle_assertion: assert property (datavref_to_speedidle_property)
        else $error("Assertion failed: state should transition from DATAVREF to SPEEDIDLE");
    cover property (datavref_to_speedidle_property);

    speedidle_to_txselfcal_assertion: assert property (speedidle_to_txselfcal_property)
        else $error("Assertion failed: state should transition from SPEEDIDLE to TXSELFCAL");
    cover property (speedidle_to_txselfcal_property);

    txselfcal_to_rxclkcal_assertion: assert property (txselfcal_to_rxclkcal_property)
        else $error("Assertion failed: state should transition from TXSELFCAL to RXCLKCAL");
    cover property (txselfcal_to_rxclkcal_property);

    rxclkcal_to_valtraincenter_assertion: assert property (rxclkcal_to_valtraincenter_property)
        else $error("Assertion failed: state should transition from RXCLKCAL to VALTRAINCENTER");
    cover property (rxclkcal_to_valtraincenter_property);

    valtraincenter_to_valtrainvref_assertion: assert property (valtraincenter_to_valtrainvref_property)
        else $error("Assertion failed: state should transition from VALTRAINCENTER to VALTRAINVREF");
    cover property (valtraincenter_to_valtrainvref_property);

    valtrainvref_to_datatraincenter1_assertion: assert property (valtrainvref_to_datatraincenter1_property)
        else $error("Assertion failed: state should transition from VALTRAINVREF to DATATRAINCENTER1");
    cover property (valtrainvref_to_datatraincenter1_property);

    datatraincenter1_to_datatrainvref_assertion: assert property (datatraincenter1_to_datatrainvref_property)
        else $error("Assertion failed: state should transition from DATATRAINCENTER1 to DATATRAINVREF");
    cover property (datatraincenter1_to_datatrainvref_property);

    datatrainvref_to_rxdeskew_assertion: assert property (datatrainvref_to_rxdeskew_property)
        else $error("Assertion failed: state should transition from DATATRAINVREF to RXDESKEW");
    cover property (datatrainvref_to_rxdeskew_property);

    rxdeskew_to_datatraincenter2_assertion: assert property (rxdeskew_to_datatraincenter2_property)
        else $error("Assertion failed: state should transition from RXDESKEW to DATATRAINCENTER2");
    cover property (rxdeskew_to_datatraincenter2_property);

    datatraincenter2_completes_training_assertion: assert property (datatraincenter2_completes_training_property)
        else $error("Assertion failed: (train_link_init_en || train_phyretrain_en) should be set when DATATRAINCENTER2 completes");
    cover property (datatraincenter2_completes_training_property);

    previous_state_done_reset_assertion: assert property (previous_state_done_reset_property)
        else $error("Assertion failed: previous_state_done should be low during reset");
    cover property (previous_state_done_reset_property);

    mutual_exclusive_req_rsp_assertion: assert property (mutual_exclusive_req_rsp_property)
        else $error("Assertion failed: o_rx_sb_req and o_rx_sb_rsp should not be asserted simultaneously");
    cover property (mutual_exclusive_req_rsp_property);

    clock_test_enable_only_in_substate1_valvref_assertion: assert property (clock_test_enable_only_in_substate1_valvref_property)
        else $error("Assertion failed: clock_to_test_enable should not be active in VALVREF substate 0");
    cover property (clock_test_enable_only_in_substate1_valvref_property);

    txselfcal_waits_for_sb_done_assertion: assert property (txselfcal_waits_for_sb_done_property)
        else $error("Assertion failed: TXSELFCAL should remain in substate 0 until i_sb_rx_done is asserted");
    cover property (txselfcal_waits_for_sb_done_property);

    req_received_captures_encoding_assertion: assert property (req_received_captures_encoding_property)
        else $error("Assertion failed: req_received should be set and encoding_req_received should capture i_rx_decoding when i_sb_rx_req is asserted");
    cover property (req_received_captures_encoding_property);

    valid_state_assertion: assert property (valid_state_property)
        else $error("Assertion failed: CS contains an invalid state value");
    cover property (valid_state_property);

    substates_done_clears_on_transition_assertion: assert property (substates_done_clears_on_transition_property)
        else $error("Assertion failed: substates_done should be cleared on state transition");
    cover property (substates_done_clears_on_transition_property);

    state_transition_values_assertion: assert property (state_transition_values_property)
        else $error("Assertion failed: on state transition, substates_done should be 0, o_rx_sb_req should be 0, and o_rx_sb_rsp should be 0");
    cover property (state_transition_values_property);

    state_transition_assertion: assert property (state_transition_property)
        else $error("Assertion failed: state should transition to NS on state change");
    cover property (state_transition_property);

`endif

endmodule