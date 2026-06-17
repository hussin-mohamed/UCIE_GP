//================================================================================
// Module: ucie_LTSM_TX_MBTRAIN
// Description: UCIe TX Link Training State Machine for Mainband Training
//              Implements the transmitter side of the UCIe link training sequence
//              including eye sweep calibration and handshake protocols
//================================================================================

module ucie_LTSM_TX_MBTRAIN #(
    parameter DECODING_WIDTH = 9,    // Width of encoding/decoding signals
    parameter DATA_WIDTH = 64,       // Width of data bus
    parameter INFO_WIDTH = 16,       // Width of info/control bus
    parameter ERROR_THRESHOLD = 0    // Threshold for acceptable training errors
) (
    // Clock and reset
    input i_clk,
    input i_reset,
    
    // TX interface inputs - data coming from remote RX
    input [DECODING_WIDTH-1:0] i_tx_decoding,    // Decoded command from RX
    input [DATA_WIDTH-1:0] i_tx_data,            // Data from RX
    input [INFO_WIDTH-1:0] i_tx_info,            // Info/control from RX
    input [7:0] i_tx_sweep_result,               // Eye sweep test results
    
    // Sideband control inputs
    input rx_trainerror,     // Sideband request from RX
    input i_sb_tx_req,     // Sideband request from RX
    input i_sb_tx_rsp,     // Sideband response from RX
    input i_sb_tx_done,    // Sideband done from RX
    input i_tx_done,       // TX operation complete
    input [2:0]i_lane_map_tx,   //lane map code
    
    // Training control inputs
    input init_train_en,   // Enable training initialization
    input speed_idle_state_enable,   // Enable SPEEDIDLE state
    input L1_SPEEDIDLE_en,   // Enable SPEEDIDLE state
    input repair_state_enable,   // Enable REPAIR state
    input tx_self_cal_state_enable,   // Enable TX self-calibration state
    input timeout,         // Training timeout error
    output logic [2:0] o_pl_speedmode,  // Physical layer speed mode

    input [2:0] i_speedreg,  // Physical layer speed mode
    output logic [2:0] o_speedreg,  // Physical layer speed mode

    input [DECODING_WIDTH-1:0] encoding_rsp_sent,      // Encoding value when response sent
    input [DECODING_WIDTH-1:0] encoding_rsp_received,  // Encoding value when response received
    input rsp_received,               // Response received flag
    input rsp_sent,                   // Response sent flag
    
    // TX interface outputs - data going to remote RX
    output logic [DECODING_WIDTH-1:0] o_tx_encoding,  // Encoded command to send
    output logic [DATA_WIDTH-1:0] o_tx_data,          // Data to send
    output logic [INFO_WIDTH-1:0] o_tx_info,          // Info/control to send
    output logic [2:0] o_lane_map_tx,          // Info/control to send
    output logic failed_test,                         // Indicates if current test failed
    
    // Sideband control outputs
    output logic o_tx_sb_req,   // Sideband request to RX
    output logic o_tx_sb_rsp,   // Sideband response to RX
    output logic o_tx_sb_done,  // Sideband done to RX
    
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
logic [DECODING_WIDTH-1:0] o_tx_encoding_reg;
logic [DECODING_WIDTH-1:0] o_tx_encoding_old;
logic [DATA_WIDTH-1:0] o_tx_data_reg;
logic [INFO_WIDTH-1:0] o_tx_info_reg;
logic o_tx_sb_req_reg;
logic o_tx_sb_rsp_reg;
logic o_tx_sb_done_reg;
logic train_error_reg;
logic train_link_init_en_reg;
logic train_phyretrain_en_reg;
logic [DATA_WIDTH-1:0] per_lane_result;  // Per-lane eye sweep results captured from RX

// Signals from eye sweep test module
logic [DECODING_WIDTH-1:0] o_tx_encoding_data_to_clock_test;
logic [DATA_WIDTH-1:0] o_tx_data_data_to_clock_test;
logic [INFO_WIDTH-1:0] o_tx_info_data_to_clock_test;
logic o_tx_sb_req_data_to_clock_test;
logic o_tx_sb_rsp_data_to_clock_test;
logic o_tx_sb_done_data_to_clock_test;
logic train_error_data_to_clock_test;

// Substate machine signals
logic [2:0] current_substate;  // Current substate within main state
logic [2:0] next_substate;     // Next substate

// Handshake control signals
logic trainerror;       // Indicates speed error in SPEEDIDLE state
logic done_ack;                   // Acknowledge that done was received
logic done_ack_old;               // Previous value of done_ack
logic substates_done;             // All substates completed
logic substates_done_old;             // All substates completed
logic [2:0] o_pl_speedmode_old;             // All substates completed
logic [2:0] o_speedreg_old;             // All substates completed
logic previous_state_done;        // Previous state handshake complete

logic clock_to_test_enable;       // Enable the eye sweep test module
logic lane_map_calc;       // Enable the eye sweep test module
logic init;        // Initialization mode for eye sweep test
logic comparison_type;        // Initialization mode for eye sweep test
logic no_retry;    // No retry mode for eye sweep test
logic clock_to_test_done;         // Eye sweep test complete
logic phyretrain_linkspeed_transition;
logic phyretrain_linkspeed_transition_old;


logic r_eye_sweep_reset;
logic first_attempt;
logic L1_access;

logic train_error_pip;
logic [2:0] lane_map_old;


//================================================================================
// Eye Sweep Test Module Instantiation
//================================================================================
// This module performs data-to-clock eye diagram sweeping for signal integrity
ucie_TX_Data_to_Clock_eye_sweep ucie_TX_Data_to_Clock_eye_sweep_inst (
    .i_clk(i_clk),
    .i_reset(r_eye_sweep_reset),  // Reset when disabled
    .i_xx_decoding(i_tx_decoding),
    .i_xx_data(i_tx_data),
    .i_xx_info(i_tx_info),
    .i_xx_sweep_result(i_tx_sweep_result),
    .i_sb_xx_req(i_sb_tx_req),
    .i_sb_xx_rsp(i_sb_tx_rsp),
    .i_sb_xx_done(i_sb_tx_done),
    .i_xx_done(i_tx_done),
    .done_ack(done_ack),
    .init(init),
    .no_retry(no_retry),
    .comparison_type(comparison_type),
    .o_xx_encoding(o_tx_encoding_data_to_clock_test),
    .o_xx_data(o_tx_data_data_to_clock_test),
    .o_xx_info(o_tx_info_data_to_clock_test),
    .o_xx_sb_req(o_tx_sb_req_data_to_clock_test), 
    .o_xx_sb_rsp(o_tx_sb_rsp_data_to_clock_test),
    .train_error(train_error_data_to_clock_test),
    .failed_test(failed_test),
    .per_lane_result(per_lane_result),
    .done(clock_to_test_done)
);

assign r_eye_sweep_reset = !clock_to_test_enable && !i_reset;

//================================================================================
// Combinational Logic
//================================================================================

// Previous state completion logic - checks if handshake is complete
assign previous_state_done = (rsp_sent & rsp_received);

// Training error aggregation - timeout, eye sweep error, or speed idle error
assign train_error = (timeout || train_error_data_to_clock_test || trainerror || rx_trainerror);


always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        train_error_pip <= 0;
    end else begin
        train_error_pip <= train_error;
    end
end

always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        lane_map_old <= i_lane_map_tx;
    end else if (!init_train_en) begin
        lane_map_old <= i_lane_map_tx;
    end else begin
        lane_map_old <= o_lane_map_tx;
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
        o_tx_encoding <= 'h80;
        o_tx_data <= 0;     
        o_tx_info <= 0;
        o_tx_sb_req <= 0; 
        o_tx_sb_rsp <= 0;
        train_link_init_en <= 0; 
        train_phyretrain_en <= 0; 
    end else begin
        if (!(init_train_en || speed_idle_state_enable || repair_state_enable || tx_self_cal_state_enable)) begin
            CS <= VALVREF;           // Reset to initial training state
            current_substate <= 0;   // Reset substate
            o_tx_encoding <= 'h80;
            o_tx_data <= 0;     
            o_tx_info <= 0;
            o_tx_sb_req <= 0; 
            o_tx_sb_rsp <= 0;
            train_link_init_en <= 1'b0; 
            train_phyretrain_en <= 1'b0; 
        end else begin
            CS <= NS;                // Advance to next state
            current_substate <= next_substate;
            o_tx_encoding <= o_tx_encoding_reg;
            o_tx_data <= o_tx_data_reg;     
            o_tx_info <= o_tx_info_reg;
            o_tx_sb_req <= o_tx_sb_req_reg; 
            o_tx_sb_rsp <= o_tx_sb_rsp_reg;
            train_link_init_en <= train_link_init_en_reg; 
            train_phyretrain_en <= train_phyretrain_en_reg; 
        end
    end 
end



//================================================================================
// Done Acknowledgement Logic
//================================================================================
// Tracks when done signal has been acknowledged in handshake protocol.
// done_ack is cleared whenever the encoding changes (new state/substate),
// ensuring the handshake re-arms for each distinct transaction.
always @(*) begin
    done_ack = done_ack_old;
    if (!init_train_en) done_ack = 0;
    else if (o_tx_encoding != o_tx_encoding_old) done_ack = 0;  // New encoding → reset ack
    else if (i_sb_tx_done) begin
        done_ack = 1;  // Set when done received
    end
end

always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        o_tx_encoding_old <= 0;  // Register to track previous encoding for done_ack logic
        substates_done_old <= 0;  // Register to track previous substate completion
        o_speedreg_old <= 0;
        o_pl_speedmode_old <= 0;
        phyretrain_linkspeed_transition_old <= 0;
        done_ack_old <= 0;
    end else if (!init_train_en) begin
        o_tx_encoding_old <= 0;  // Register to track previous encoding for done_ack logic
        substates_done_old <= 0;  // Register to track previous substate completion
        o_speedreg_old <= 0;
        o_pl_speedmode_old <= 0;
        phyretrain_linkspeed_transition_old <= 0;
        done_ack_old <= 0;
    end else begin
        o_tx_encoding_old <= o_tx_encoding;  // Register to track previous encoding for done_ack logic
        substates_done_old <= substates_done;  // Register to track previous substate completion
        o_speedreg_old <= o_speedreg;
        o_pl_speedmode_old <= o_pl_speedmode;
        phyretrain_linkspeed_transition_old <= phyretrain_linkspeed_transition;
        done_ack_old <= done_ack;
    end
end

//================================================================================
// Sideband Done Signal Logic
//================================================================================
// Generates done pulse for sideband protocol
always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        o_tx_sb_done <= 0;
    end else begin
        if (o_tx_sb_done && !(i_sb_tx_rsp || i_sb_tx_req)) begin
            o_tx_sb_done <= 0;  // Self-clearing pulse
        end else if (i_sb_tx_rsp || i_sb_tx_req) begin
            o_tx_sb_done <= 1;  // Assert on request or response
        end
    end
end

always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        first_attempt <= 1;
    end else if (!init_train_en) begin
        first_attempt <= 1;
    end else if (CS == TXSELFCAL) begin
        first_attempt <= 0;
    end
end

//================================================================================
// Main State Machine Combinational Logic
//================================================================================
// Each MBTRAIN state follows the same 3-substate pattern:
//   Substate 0 — Initial handshake: assert sideband request / wait for peer response.
//   Substate 1 — Eye sweep: enable clock_to_test module; pipe its outputs to TX outputs.
//   Substate 2 — Completion handshake: de-assert eye sweep; confirm with peer before
//                advancing to the next major state via previous_state_done.
// States without an embedded eye sweep (e.g. RXCLKCAL, RXDESKEW) skip substate 1.
//================================================================================
always @(*) begin
    L1_access = 0;
    comparison_type = 0;
    o_tx_data_reg = 0;
    o_tx_info_reg = 0;
    NS = CS;
    next_substate = current_substate;
    substates_done = substates_done_old;  // Default to retaining previous value
    o_speedreg = o_speedreg_old;
    o_pl_speedmode = o_pl_speedmode_old;
    train_link_init_en_reg = train_link_init_en;
    train_phyretrain_en_reg = train_phyretrain_en;
    train_phyretrain_en_reg = train_phyretrain_en;
    phyretrain_linkspeed_transition = phyretrain_linkspeed_transition_old;
    trainerror = 0;
    o_tx_sb_req_reg = 0;
    o_tx_sb_rsp_reg = 0;
    o_tx_encoding_reg = 0;
    o_tx_encoding_reg = 0;
    lane_map_calc = 0;
    clock_to_test_enable = 0;  // Default to eye sweep disabled
    init = 0;        // Default to not initialization mode
    comparison_type = 0;        // Default to data signal training
    no_retry = 0;    // Default to allowing retries
    if (!init_train_en) begin
        substates_done = 0;
    end else
        // On training error (timeout, eye sweep failure, or speed negotiation error),
        // abort immediately back to VALVREF so the full calibration sequence restarts.
    if (train_error_pip) begin
        NS = VALVREF;
        substates_done = 0;
        clock_to_test_enable = 0;
    end else begin
            case (CS)
                //====================================================================
                // VALVREF State: Valid Signal Reference Voltage Calibration
                //====================================================================
                VALVREF: begin
                    if (!substates_done) begin
                        case (current_substate)
                            // Substate 0: Send initial handshake request
                            0: begin
                                NS = VALVREF;
                                o_tx_encoding_reg = 'h80;  // VALVREF request encoding
                                next_substate = 0;

                                substates_done = 0;
                                clock_to_test_enable = 0;
                                o_tx_sb_rsp_reg = 0;
                                trainerror = 0;

                                // Request/acknowledge handshake
                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                // Wait for matching response
                                if (i_sb_tx_req && i_tx_decoding == 'h188) begin
                                    o_tx_encoding_reg = 'h188;
                                    o_tx_sb_req_reg = 0;
                                    o_tx_sb_rsp_reg = 0;
                                    next_substate = 1;
                                end else next_substate = 0;
                            end  
                            // Substate 1: Run eye sweep test
                            1:begin
                                clock_to_test_enable = 1;  // Enable eye sweep module
                                // Connect eye sweep outputs to TX outputs
                                o_tx_encoding_reg = o_tx_encoding_data_to_clock_test;
                                o_tx_data_reg = o_tx_data_data_to_clock_test;
                                o_tx_info_reg = o_tx_info_data_to_clock_test;
                                o_tx_sb_req_reg = o_tx_sb_req_data_to_clock_test;
                                o_tx_sb_rsp_reg = o_tx_sb_rsp_data_to_clock_test;
                                
                                init = 0;        // Not initialization mode
                                comparison_type = 1;        // Valid signal training        // Not initialization mode
                                no_retry = 0;    // Allow retries
                                substates_done = 0;

                                // Wait for eye sweep completion
                                if (clock_to_test_done) begin
                                    o_tx_encoding_reg = 'h82;
                                    next_substate = 2;
                                    o_tx_sb_req_reg = 0;
                                    o_tx_sb_rsp_reg = 0;
                                end else next_substate = 1;
                            end

                            // Substate 2: Send completion handshake
                            2: begin
                                clock_to_test_enable = 0;
                                o_tx_sb_rsp_reg = 0;

                                o_tx_encoding_reg = 'h82;  // VALVREF complete encoding
                                NS = VALVREF;

                                // Request/acknowledge handshake
                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                // Wait for matching response to complete substates
                                if (i_sb_tx_rsp && i_tx_decoding == 'h82) begin
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
                    // Check if both sides completed the state (handshake complete)
                    if (previous_state_done && encoding_rsp_sent == 'h82 && encoding_rsp_received == 'h82) begin
                        NS = DATAVREF;  // Move to next training state
                        o_tx_encoding_reg = 'h88;
                        substates_done = 0;
                        o_tx_sb_req_reg = 0;
                        o_tx_sb_rsp_reg = 0;
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
                                o_tx_encoding_reg = 'h88;
                                NS = DATAVREF;
                                substates_done = 0;

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (i_sb_tx_req && i_tx_decoding == 'h188) begin
                                    o_tx_encoding_reg = 'h188;
                                    next_substate = 1;
                                    o_tx_sb_req_reg = 0;
                                    o_tx_sb_rsp_reg = 0;
                                end else next_substate = 0;
                            end  

                            1: begin
                                clock_to_test_enable = 1;
                                o_tx_encoding_reg = o_tx_encoding_data_to_clock_test;
                                o_tx_data_reg = o_tx_data_data_to_clock_test;
                                o_tx_info_reg = o_tx_info_data_to_clock_test;
                                o_tx_sb_req_reg = o_tx_sb_req_data_to_clock_test;
                                o_tx_sb_rsp_reg = o_tx_sb_rsp_data_to_clock_test;
                                
                                init = 0;        // Not initialization mode
                                comparison_type = 0;        // Valid signal training
                                no_retry = 0;
                                substates_done = 0;

                                if (clock_to_test_done) begin
                                    o_tx_encoding_reg = 'h8A;
                                    next_substate = 2;
                                    o_tx_sb_req_reg = 0;
                                    o_tx_sb_rsp_reg = 0;
                                end else next_substate = 1;
                            end  

                            2: begin
                                clock_to_test_enable = 0;
                                o_tx_sb_rsp_reg = 0;
                                o_tx_encoding_reg = 'h8A;
                                NS = DATAVREF; 

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (i_sb_tx_rsp && i_tx_decoding == 'h8A) begin
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
                        o_tx_sb_req_reg = 0;
                        o_tx_sb_rsp_reg = 0;
                        o_tx_encoding_reg = 'hC8;
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
                                o_tx_encoding_reg = 'hC8;
                                substates_done = 0;

                                if (i_tx_done) begin
                                    if (i_speedreg) begin
                                        // Decrement speed register by 1 (step down to next lower rate)
                                        // and broadcast the agreed speed mode to the PL interface.
                                        o_tx_encoding_reg = 'hCA;
                                        next_substate = 1;
                                        o_tx_sb_req_reg = 0;
                                        o_tx_sb_rsp_reg = 0;
                                        if (!L1_access) begin
                                            o_pl_speedmode = i_speedreg - 1;
                                            o_speedreg = i_speedreg - 1;
                                        end else if (L1_access) begin
                                            o_pl_speedmode = i_speedreg;
                                            o_speedreg = i_speedreg;
                                            L1_access = 0;
                                        end else begin
                                            o_pl_speedmode = i_speedreg;
                                            o_speedreg = i_speedreg;
                                        end
                                    end else begin
                                        // Speed mismatch error
                                        if (first_attempt) begin
                                            o_speedreg = 'h5;
                                            o_pl_speedmode = 'h5;
                                            o_tx_encoding_reg = 'hCA;
                                            next_substate = 1;
                                            o_tx_sb_req_reg = 0;
                                            o_tx_sb_rsp_reg = 0;
                                        end
                                        else begin
                                            trainerror = 1;    
                                        end
                                    end
                                end
                            end  

                            1: begin
                                o_tx_encoding_reg = 'hCA;
                                NS = SPEEDIDLE; 

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (i_sb_tx_rsp && i_tx_decoding == 'hCA) begin
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
                    if (previous_state_done && encoding_rsp_sent == 'hCA && encoding_rsp_received == 'hCA) begin
                        NS = TXSELFCAL;
                        o_tx_sb_req_reg = 0;
                        o_tx_sb_rsp_reg = 0;
                        o_tx_encoding_reg = 'hD0;
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
                                o_tx_encoding_reg = 'hD0;
                                NS = TXSELFCAL;
                                substates_done = 0;

                                if (i_tx_done) begin
                                    o_tx_encoding_reg = 'hD1;
                                    next_substate = 1;
                                    o_tx_sb_req_reg = 0;
                                    o_tx_sb_rsp_reg = 0;
                                end else next_substate = 0;
                            end  

                            1: begin
                                o_tx_encoding_reg = 'hD1;
                                NS = TXSELFCAL; 

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (i_sb_tx_rsp && i_tx_decoding == 'hD1) begin
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
                    if (previous_state_done && encoding_rsp_sent == 'hD0 && encoding_rsp_received == 'hD1) begin
                        NS = RXCLKCAL;
                        o_tx_sb_req_reg = 0;
                        o_tx_sb_rsp_reg = 0;
                        o_tx_encoding_reg = 'h98;
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
                                o_tx_encoding_reg = 'h98;
                                NS = RXCLKCAL;
                                substates_done = 0;

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (i_sb_tx_rsp && i_tx_decoding == 'h98) begin
                                    o_tx_encoding_reg = 'h9A;
                                    next_substate = 1;
                                    o_tx_sb_req_reg = 0;
                                    o_tx_sb_rsp_reg = 0;
                                end else next_substate = 0;
                            end   
                            
                            1: begin
                                clock_to_test_enable = 0;
                                o_tx_sb_rsp_reg = 0;
                                o_tx_encoding_reg = 'h9A;
                                NS = RXCLKCAL; 

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (i_sb_tx_rsp && i_tx_decoding == 'h9A) begin
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
                    if (previous_state_done && encoding_rsp_sent == 'h9A && encoding_rsp_received == 'h9A) begin
                        NS = VALTRAINCENTER;
                        o_tx_encoding_reg = 'hA0;
                        o_tx_sb_req_reg = 0;
                        o_tx_sb_rsp_reg = 0;
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
                                o_tx_encoding_reg = 'hA0;
                                NS = VALTRAINCENTER;
                                substates_done = 0;

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (i_sb_tx_req && i_tx_decoding == 'h188) begin
                                    o_tx_encoding_reg = 'h188;
                                    next_substate = 1;
                                    o_tx_sb_req_reg = 0;
                                    o_tx_sb_rsp_reg = 0;
                                end else next_substate = 0;
                            end  

                            1: begin
                                clock_to_test_enable = 1;
                                o_tx_encoding_reg = o_tx_encoding_data_to_clock_test;
                                o_tx_data_reg = o_tx_data_data_to_clock_test;
                                o_tx_info_reg = o_tx_info_data_to_clock_test;
                                o_tx_sb_req_reg = o_tx_sb_req_data_to_clock_test;
                                o_tx_sb_rsp_reg = o_tx_sb_rsp_data_to_clock_test;
                                
                                init = 0;        // Not initialization mode
                                comparison_type = 1;        // Valid signal training
                                no_retry = 0;
                                substates_done = 0;

                                if (clock_to_test_done) begin
                                    o_tx_encoding_reg = 'hA2;
                                    next_substate = 2;
                                    o_tx_sb_req_reg = 0;
                                    o_tx_sb_rsp_reg = 0;
                                end else next_substate = 1;
                            end  

                            2: begin
                                clock_to_test_enable = 0;
                                o_tx_sb_rsp_reg = 0;

                                o_tx_encoding_reg = 'hA2;
                                NS = VALTRAINCENTER; 

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (i_sb_tx_rsp && i_tx_decoding == 'hA2) begin
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
                    if (previous_state_done && encoding_rsp_sent == 'hA2 && encoding_rsp_received == 'hA2) begin
                        NS = VALTRAINVREF;
                        o_tx_encoding_reg = 'hE8;
                        substates_done = 0;
                        o_tx_sb_req_reg = 0;
                        o_tx_sb_rsp_reg = 0;
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
                                o_tx_encoding_reg = 'hE8;
                                NS = VALTRAINVREF;
                                substates_done = 0;

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (i_sb_tx_req && i_tx_decoding == 'h188) begin
                                    o_tx_encoding_reg = 'h188;
                                    next_substate = 1;
                                    o_tx_sb_req_reg = 0;
                                    o_tx_sb_rsp_reg = 0;
                                end else next_substate = 0;
                            end  

                            1: begin
                                clock_to_test_enable = 1;
                                o_tx_encoding_reg = o_tx_encoding_data_to_clock_test;
                                o_tx_data_reg = o_tx_data_data_to_clock_test;
                                o_tx_info_reg = o_tx_info_data_to_clock_test;
                                o_tx_sb_req_reg = o_tx_sb_req_data_to_clock_test;
                                o_tx_sb_rsp_reg = o_tx_sb_rsp_data_to_clock_test;
                                
                                init = 0;        // Not initialization mode
                                comparison_type = 1;        // Valid signal training
                                no_retry = 0;
                                substates_done = 0;

                                if (clock_to_test_done) begin
                                    o_tx_encoding_reg = 'hEA;
                                    next_substate = 2;
                                    o_tx_sb_req_reg = 0;
                                    o_tx_sb_rsp_reg = 0;
                                end else next_substate = 1;
                            end  

                            2: begin
                                clock_to_test_enable = 0;
                                o_tx_sb_rsp_reg = 0;
                                o_tx_encoding_reg = 'hEA;
                                NS = VALTRAINVREF; 

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (i_sb_tx_rsp && i_tx_decoding == 'hEA) begin
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
                    if (previous_state_done && encoding_rsp_sent == 'hEA && encoding_rsp_received == 'hEA) begin
                        NS = DATATRAINCENTER1;
                        substates_done = 0;
                        o_tx_encoding_reg = 'h90;
                        o_tx_sb_req_reg = 0;
                        o_tx_sb_rsp_reg = 0;
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
                                o_tx_encoding_reg = 'h90;
                                NS = DATATRAINCENTER1;
                                substates_done = 0;

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (i_sb_tx_req && i_tx_decoding == 'h188) begin
                                    o_tx_encoding_reg = 'h188;
                                    next_substate = 1;
                                    o_tx_sb_req_reg = 0;
                                    o_tx_sb_rsp_reg = 0;
                                end else next_substate = 0;
                            end  

                            1: begin
                                clock_to_test_enable = 1;
                                o_tx_encoding_reg = o_tx_encoding_data_to_clock_test;
                                o_tx_data_reg = o_tx_data_data_to_clock_test;
                                o_tx_info_reg = o_tx_info_data_to_clock_test;
                                o_tx_sb_req_reg = o_tx_sb_req_data_to_clock_test;
                                o_tx_sb_rsp_reg = o_tx_sb_rsp_data_to_clock_test;
                                
                                init = 0;        // Not initialization mode
                                comparison_type = 0;        // Valid signal training
                                no_retry = 1;    // No retries for DATATRAINCENTER1: a single measurement pass
                                                 // is sufficient; the result feeds the Vref tuning stage next.
                                substates_done = 0;

                                if (clock_to_test_done) begin
                                    o_tx_encoding_reg = 'h92;
                                    next_substate = 2;
                                    o_tx_sb_req_reg = 0;
                                    o_tx_sb_rsp_reg = 0;
                                end else next_substate = 1;
                            end  

                            2: begin
                                clock_to_test_enable = 0;
                                o_tx_sb_rsp_reg = 0;
                                o_tx_encoding_reg = 'h92; 
                                NS = DATATRAINCENTER1;

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (i_sb_tx_rsp && i_tx_decoding == 'h92) begin
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
                    if (previous_state_done && encoding_rsp_sent == 'h92 && encoding_rsp_received == 'h92) begin
                        NS = DATATRAINVREF;
                        o_tx_encoding_reg = 'hF0;
                        o_tx_sb_req_reg = 0;
                        o_tx_sb_rsp_reg = 0;
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
                                o_tx_encoding_reg = 'hF0;
                                NS = DATATRAINVREF;
                                substates_done = 0;

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (i_sb_tx_req && i_tx_decoding == 'h188) begin
                                    o_tx_encoding_reg = 'h188;
                                    next_substate = 1;
                                    o_tx_sb_req_reg = 0;
                                    o_tx_sb_rsp_reg = 0;
                                end else next_substate = 0;
                            end  

                            1: begin
                                clock_to_test_enable = 1;
                                o_tx_encoding_reg = o_tx_encoding_data_to_clock_test;
                                o_tx_data_reg = o_tx_data_data_to_clock_test;
                                o_tx_info_reg = o_tx_info_data_to_clock_test;
                                o_tx_sb_req_reg = o_tx_sb_req_data_to_clock_test;
                                o_tx_sb_rsp_reg = o_tx_sb_rsp_data_to_clock_test;
                                
                                init = 0;        // Not initialization mode
                                comparison_type = 0;        // Valid signal training
                                no_retry = 0;
                                substates_done = 0;

                                if (clock_to_test_done) begin
                                    o_tx_encoding_reg = 'hF2;
                                    next_substate = 2;
                                    o_tx_sb_req_reg = 0;
                                    o_tx_sb_rsp_reg = 0;
                                end else next_substate = 1;
                            end  

                            2: begin
                                clock_to_test_enable = 0;
                                o_tx_sb_rsp_reg = 0;


                                o_tx_encoding_reg = 'hF2;
                                NS = DATATRAINVREF; 

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (i_sb_tx_rsp && i_tx_decoding == 'hF2) begin
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
                    if (previous_state_done && encoding_rsp_sent == 'hF2 && encoding_rsp_received == 'hF2) begin
                        NS = RXDESKEW;
                        o_tx_encoding_reg = 'hA8;
                        substates_done = 0;
                        o_tx_sb_req_reg = 0;
                        o_tx_sb_rsp_reg = 0;
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
                                o_tx_encoding_reg = 'hA8;
                                NS = RXDESKEW;
                                substates_done = 0;

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (i_sb_tx_rsp && i_tx_decoding == 'hA8) begin
                                    o_tx_encoding_reg = 'hAC;
                                    next_substate = 1;
                                    o_tx_sb_req_reg = 0;
                                    o_tx_sb_rsp_reg = 0;
                                end else next_substate = 0;
                            end  

                            1: begin
                                o_tx_encoding_reg = 'hAC; 
                                NS = RXDESKEW;

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (i_sb_tx_rsp && i_tx_decoding == 'hAC) begin
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
                    if (previous_state_done && encoding_rsp_sent == 'hAC && encoding_rsp_received == 'hAC) begin
                        NS = DATATRAINCENTER2;
                        o_tx_encoding_reg = 'hB0;
                        substates_done = 0;
                        o_tx_sb_req_reg = 0;
                        o_tx_sb_rsp_reg = 0;
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
                                o_tx_encoding_reg = 'hB0;
                                NS = DATATRAINCENTER2;
                                substates_done = 0;
                                o_tx_info_reg = ERROR_THRESHOLD;  // Set error threshold

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (i_sb_tx_req && i_tx_decoding == 'h188) begin
                                    o_tx_encoding_reg = 'h188;
                                    next_substate = 1;
                                    o_tx_sb_req_reg = 0;
                                    o_tx_sb_rsp_reg = 0;
                                end else next_substate = 0;
                            end  

                            1: begin
                                clock_to_test_enable = 1;
                                o_tx_encoding_reg = o_tx_encoding_data_to_clock_test;
                                o_tx_data_reg = o_tx_data_data_to_clock_test;
                                o_tx_info_reg = o_tx_info_data_to_clock_test;
                                o_tx_sb_req_reg = o_tx_sb_req_data_to_clock_test;
                                o_tx_sb_rsp_reg = o_tx_sb_rsp_data_to_clock_test;
                                
                                init = 0;        // Not initialization mode
                                comparison_type = 0;        // Valid signal training
                                no_retry = 1;
                                substates_done = 0;

                                if (clock_to_test_done) begin
                                    o_tx_encoding_reg = 'hB2;
                                    next_substate = 2;
                                    o_tx_sb_req_reg = 0;
                                    o_tx_sb_rsp_reg = 0;
                                end else next_substate = 1;
                            end  

                            2: begin
                                clock_to_test_enable = 0;
                                o_tx_sb_rsp_reg = 0;
                                o_tx_encoding_reg = 'hB2; 
                                NS = DATATRAINCENTER2;

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (i_sb_tx_rsp && i_tx_decoding == 'hB2) begin
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
                    // Training complete - return to VALVREF with training enabled
                    if (previous_state_done && encoding_rsp_sent == 'hB2 && encoding_rsp_received == 'hB2) begin
                        NS = LINKSPEED;
                        o_tx_encoding_reg = 'hB8;
                        substates_done = 0;
                        o_tx_sb_req_reg = 0;
                        o_tx_sb_rsp_reg = 0;
                    end else begin  
                        NS = DATATRAINCENTER2;
                    end
                end

                //====================================================================
                // LINKSPEED State
                //====================================================================
                LINKSPEED: begin
                    if (!substates_done) begin
                        case (current_substate)
                            0: begin
                                o_tx_encoding_reg = 'hB8;
                                NS = LINKSPEED;
                                substates_done = 0;

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (i_sb_tx_rsp && i_tx_decoding == 'hB8) begin
                                    o_tx_encoding_reg = 'h180;
                                    next_substate = 1;
                                    o_tx_sb_req_reg = 0;
                                    o_tx_sb_rsp_reg = 0;
                                end else next_substate = 0;
                            end  

                            1: begin
                                clock_to_test_enable = 1;
                                lane_map_calc = 1;
                                o_tx_encoding_reg = o_tx_encoding_data_to_clock_test;
                                o_tx_data_reg = o_tx_data_data_to_clock_test;
                                o_tx_info_reg = o_tx_info_data_to_clock_test;
                                o_tx_sb_req_reg = o_tx_sb_req_data_to_clock_test;
                                o_tx_sb_rsp_reg = o_tx_sb_rsp_data_to_clock_test;

                                init = 1;
                                comparison_type = 0;    // Data to clock comparison
                                no_retry = 1;
                                substates_done = 0;

                                if (clock_to_test_done) begin
                                    // data to clock test results
                                    if(&per_lane_result[15:0]) begin              
                                        o_tx_encoding_reg = 'hBA;
                                        next_substate = 2;  // Done HS
                                        o_tx_sb_req_reg = 0;
                                        o_tx_sb_rsp_reg = 0;
                                    end 
                                    else begin 
                                        o_tx_encoding_reg = 'hBB;
                                        next_substate = 3;     // Error REQ
                                        o_tx_sb_req_reg = 0;
                                        o_tx_sb_rsp_reg = 0;
                                    end 
                                end else next_substate = 1;
                            end  

                            2: begin
                                clock_to_test_enable = 0;
                                o_tx_sb_rsp_reg = 0;
                                o_tx_encoding_reg = 'hBA; 
                                NS = LINKSPEED;

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (i_sb_tx_rsp && i_tx_decoding == 'hBA) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else if (i_sb_tx_req && i_tx_decoding == 'hBC) begin
                                    substates_done = 0;
                                    next_substate = 5;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 2;
                                end
                            end  

                            3: begin
                                clock_to_test_enable = 0;
                                o_tx_sb_rsp_reg = 0;
                                o_tx_encoding_reg = 'hBB; 
                                NS = LINKSPEED;

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;   // send err req

                                if (i_sb_tx_rsp && i_tx_decoding == 'hBF && !o_lane_map_tx) begin
                                    substates_done = 0;
                                    next_substate = 4; // SPEEDIDLE
                                    o_tx_encoding_reg = 'hBE;
                                end else if(i_sb_tx_req && i_tx_decoding == 'hBC) begin 
                                    substates_done = 0;
                                    next_substate = 5; // PHYRETRAIN
                                end else if(i_sb_tx_rsp && i_tx_decoding == 'hBF && o_lane_map_tx) begin 
                                    substates_done = 0;
                                    next_substate = 6; // REPAIR
                                end else begin
                                    substates_done = 0;
                                    next_substate = 3;
                                end 
                            end

                            4: begin
                                clock_to_test_enable = 0;
                                o_tx_sb_rsp_reg = 0;
                                o_tx_encoding_reg = 'hBE; 
                                NS = LINKSPEED;

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (i_sb_tx_rsp && i_tx_decoding == 'hBE) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 4;
                                end 
                            end

                            5: begin
                                clock_to_test_enable = 0;
                                o_tx_sb_req_reg = 0;
                                o_tx_encoding_reg = 'hBC; 
                                NS = LINKSPEED;

                                if (done_ack) o_tx_sb_rsp_reg = 0;
                                else o_tx_sb_rsp_reg = 1;

                                if (done_ack) begin
                                    phyretrain_linkspeed_transition = 1;
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    phyretrain_linkspeed_transition = 0;
                                    substates_done = 0;
                                    next_substate = 5;
                                end 
                            end

                            6: begin
                                clock_to_test_enable = 0;
                                o_tx_sb_rsp_reg = 0;
                                o_tx_encoding_reg = 'hBD; 
                                NS = LINKSPEED;

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if ((i_sb_tx_rsp && i_tx_decoding == 'hBD) || (encoding_rsp_sent == 'hBE)) begin
                                    substates_done = 1;
                                    next_substate = 0;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 6;
                                end 
                            end
                            default:begin
                                
                            end
                        endcase
                    end else begin
                        if (speed_idle_state_enable) begin
                            NS = SPEEDIDLE;
                            o_tx_encoding_reg = 'hC8;  // VALVREF request encoding
                            train_link_init_en_reg = 0;
                            train_phyretrain_en_reg = 0;
                            phyretrain_linkspeed_transition = 0;
                            o_tx_sb_req_reg = 0;
                            o_tx_sb_rsp_reg = 0;
                            substates_done = 0;
                            if (L1_SPEEDIDLE_en) begin
                                L1_access = 1;
                            end else begin
                                L1_access = 0;
                            end
                        end else if (repair_state_enable) begin
                            NS = REPAIR;
                            o_tx_encoding_reg = 'hC0;  // VALVREF request encoding
                            train_link_init_en_reg = 0;
                            train_phyretrain_en_reg = 0;
                            phyretrain_linkspeed_transition = 0;
                            o_tx_sb_req_reg = 0;
                            o_tx_sb_rsp_reg = 0;
                            substates_done = 0;
                        end else if (tx_self_cal_state_enable) begin
                            NS = TXSELFCAL;
                            o_tx_encoding_reg = 'hD0;  // VALVREF request encoding
                            train_link_init_en_reg = 0;
                            train_phyretrain_en_reg = 0;
                            phyretrain_linkspeed_transition = 0;
                            o_tx_sb_req_reg = 0;
                            o_tx_sb_rsp_reg = 0;
                            substates_done = 0;
                        end else begin
                            o_tx_sb_req_reg = 0;
                            o_tx_sb_rsp_reg = 0;
                            substates_done = 1;
                            train_link_init_en_reg = train_link_init_en;
                            train_phyretrain_en_reg = train_phyretrain_en;
                        end
                    end

                    // need to add the priority flag for speed idle
                    if ((previous_state_done && encoding_rsp_sent == 'hBE && encoding_rsp_received == 'hBE)) begin
                        NS = SPEEDIDLE;
                        o_tx_encoding_reg = 'hC8;
                        train_link_init_en_reg = 0;
                        train_phyretrain_en_reg = 0;
                        o_tx_sb_req_reg = 0;
                        o_tx_sb_rsp_reg = 0;
                        substates_done = 0;
                    end else if (phyretrain_linkspeed_transition) begin
                        train_phyretrain_en_reg = 1;
                        train_link_init_en_reg = 0;
                        o_tx_sb_req_reg = 0;
                        o_tx_sb_rsp_reg = 0;
                        substates_done = 1;
                    end else if (previous_state_done && encoding_rsp_sent == 'hBD && encoding_rsp_received == 'hBD) begin
                        NS = REPAIR;
                        o_tx_encoding_reg = 'hC0;
                        train_link_init_en_reg = 0;
                        train_phyretrain_en_reg = 0;
                        o_tx_sb_req_reg = 0;
                        o_tx_sb_rsp_reg = 0;
                        substates_done = 0;
                    end else if (previous_state_done && encoding_rsp_sent == 'hBA && encoding_rsp_received == 'hBA) begin
                        train_link_init_en_reg = 1;
                        train_phyretrain_en_reg = 0;
                        o_tx_sb_req_reg = 0;
                        o_tx_sb_rsp_reg = 0;
                        substates_done = 1;
                    end else begin
                        train_link_init_en_reg = train_link_init_en;
                        train_phyretrain_en_reg = train_phyretrain_en;
                    end
                end

                //====================================================================
                // REPAIR State
                //====================================================================
                REPAIR: begin
                    if (!substates_done) begin
                        case (current_substate)
                            0: begin
                                o_tx_encoding_reg = 'hC0;
                                NS = REPAIR;
                                substates_done = 0;

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (i_sb_tx_rsp && i_tx_decoding == 'hC0) begin
                                    next_substate = 1;
                                    o_tx_sb_req_reg = 0;
                                    o_tx_sb_rsp_reg = 0;
                                    o_tx_encoding_reg = 'hC1; 
                                end else next_substate = 0;
                            end  

                            1: begin
                                clock_to_test_enable = 0;
                                o_tx_sb_rsp_reg = 0;
                                o_tx_encoding_reg = 'hC1; 
                                NS = REPAIR;

                                o_tx_info_reg[2:0] = o_lane_map_tx; 

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (!o_lane_map_tx) begin
                                    trainerror = 1;
                                    substates_done = 1;
                                    next_substate = 0;
                                    o_tx_encoding_reg = 'h40;
                                end else if (i_sb_tx_rsp && i_tx_decoding == 'hC1) begin
                                    o_tx_info_reg = 0;
                                    substates_done = 0;
                                    next_substate = 2;
                                    o_tx_encoding_reg = 'hC2;
                                end else begin
                                    substates_done = 0;
                                    next_substate = 1;
                                end 
                            end  

                            2: begin
                                clock_to_test_enable = 0;
                                o_tx_sb_rsp_reg = 0;
                                o_tx_encoding_reg = 'hC2; 
                                NS = REPAIR;

                                if (done_ack) o_tx_sb_req_reg = 0;
                                else o_tx_sb_req_reg = 1;

                                if (i_sb_tx_rsp && i_tx_decoding == 'hC2) begin
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

                    if (previous_state_done && encoding_rsp_sent == 'hC2 && encoding_rsp_received == 'hC2) begin
                        NS = TXSELFCAL;
                        o_tx_sb_req_reg = 0;
                        o_tx_sb_rsp_reg = 0;
                        o_tx_encoding_reg = 'hD0;
                        substates_done = 0;
                    end else begin  
                        NS = REPAIR;
                    end
                end

                default: begin
                    train_link_init_en_reg= 0;
                    train_phyretrain_en_reg= 0;
                    phyretrain_linkspeed_transition = 0;
                    o_tx_sb_req_reg = 0;
                    o_tx_sb_rsp_reg = 0;
                    substates_done = 0;
                    next_substate = 0;
                    NS = VALVREF;
                    o_tx_encoding_reg = 0;
                    o_tx_data_reg = 0;
                    o_tx_info_reg = 0;
                end
            endcase
        end
    end

    always @(*) begin
        o_lane_map_tx = lane_map_old;
        if (lane_map_calc) begin
             if (&per_lane_result[15:0] && (o_lane_map_tx == 3'b011))
            o_lane_map_tx = 3'b011;  // ALL_LANES_FUNCTIONAL
        else if (&per_lane_result[7:0] && !(&per_lane_result[15:8])) begin
            if (o_lane_map_tx == 3'b011) begin
                o_lane_map_tx = 3'b001;
            end else if (o_lane_map_tx == 3'b010) begin
                o_lane_map_tx = 3'b000;
            end else begin
                o_lane_map_tx = 3'b001;
            end
        end else if (!(&per_lane_result[7:0]) && &per_lane_result[15:8]) begin
            if (o_lane_map_tx == 3'b011) begin
                o_lane_map_tx = 3'b010;
            end else if (o_lane_map_tx == 3'b001) begin
                o_lane_map_tx = 3'b000;
            end else begin
                o_lane_map_tx = 3'b010;
            end
        end else if (!(&per_lane_result[7:0]) && !(&per_lane_result[15:8])) 
            o_lane_map_tx = 3'b000;
        else 
            o_lane_map_tx = 3'b011;  // DEGRADE_NOT_POSSIBLE
        end
    end

`ifdef ASSERT_ON

    property done_ack_assert_property;
        @(posedge i_clk) disable iff (i_reset)
        ((i_sb_tx_done) && (o_tx_encoding[2:0] == o_tx_encoding_old[2:0])) |-> done_ack;
    endproperty

    property done_ack_deassert_property;
        @(posedge i_clk) disable iff (i_reset)
        i_sb_tx_rsp |-> !done_ack;
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
        i_reset |=> (o_tx_encoding == 0);
    endproperty

    property reset_data_property;
        @(posedge i_clk)
        i_reset |=> (o_tx_data == 0);
    endproperty

    property reset_info_property;
        @(posedge i_clk)
        i_reset |=> (o_tx_info == 0);
    endproperty

    property reset_sb_req_property;
        @(posedge i_clk)
        i_reset |=> (o_tx_sb_req == 0);
    endproperty

    property reset_sb_rsp_property;
        @(posedge i_clk)
        i_reset |=> (o_tx_sb_rsp == 0);
    endproperty

    property reset_sb_done_property;
        @(posedge i_clk)
        i_reset |=> (o_tx_sb_done == 0);
    endproperty

    property sb_done_self_clearing_property;
        @(posedge i_clk) disable iff (i_reset)
        (o_tx_sb_done && !(i_sb_tx_rsp || i_sb_tx_req)) |=> (!o_tx_sb_done);
    endproperty

    property sb_done_assert_on_req_property;
        @(posedge i_clk) disable iff (i_reset)
        (i_sb_tx_req && !o_tx_sb_done) |=> o_tx_sb_done;
    endproperty

    property sb_done_assert_on_rsp_property;
        @(posedge i_clk) disable iff (i_reset)
        (i_sb_tx_rsp && !o_tx_sb_done) |=> o_tx_sb_done;
    endproperty

    property not_state_enb_resets_to_valvref_property;
        @(posedge i_clk) disable iff (i_reset)
        (!init_train_en) |=> (CS == VALVREF);
    endproperty

    property not_state_enb_resets_substate_property;
        @(posedge i_clk) disable iff (i_reset)
        (!init_train_en) |=> (current_substate == 0);
    endproperty

    property valvref_to_datavref_property;
        @(posedge i_clk) disable iff (i_reset || train_error_reg)
        (CS == VALVREF && previous_state_done && encoding_rsp_sent == 'h82 && encoding_rsp_received == 'h82 && init_train_en) |=> (CS == DATAVREF);
    endproperty

    property datavref_to_speedidle_property;
        @(posedge i_clk) disable iff (i_reset || train_error_reg)
        (CS == DATAVREF && previous_state_done && encoding_rsp_sent == 'h8A && encoding_rsp_received == 'h8A && init_train_en) |=> (CS == SPEEDIDLE);
    endproperty

    property speedidle_to_txselfcal_property;
        @(posedge i_clk) disable iff (i_reset || train_error_reg)
        (CS == SPEEDIDLE && previous_state_done && encoding_rsp_sent == 'hCA && encoding_rsp_received == 'hCA && init_train_en) |=> (CS == TXSELFCAL);
    endproperty

    property txselfcal_to_rxclkcal_property;
        @(posedge i_clk) disable iff (i_reset || train_error_reg)
        (CS == TXSELFCAL && previous_state_done && encoding_rsp_sent == 'hD1 && encoding_rsp_received == 'hD1 && init_train_en) |=> (CS == RXCLKCAL);
    endproperty

    property rxclkcal_to_valtraincenter_property;
        @(posedge i_clk) disable iff (i_reset || train_error_reg)
        (CS == RXCLKCAL && previous_state_done && encoding_rsp_sent == 'h9A && encoding_rsp_received == 'h9A && init_train_en) |=> (CS == VALTRAINCENTER);
    endproperty

    property valtraincenter_to_valtrainvref_property;
        @(posedge i_clk) disable iff (i_reset || train_error_reg)
        (CS == VALTRAINCENTER && previous_state_done && encoding_rsp_sent == 'hA2 && encoding_rsp_received == 'hA2 && init_train_en) |=> (CS == VALTRAINVREF);
    endproperty

    property valtrainvref_to_datatraincenter1_property;
        @(posedge i_clk) disable iff (i_reset || train_error_reg)
        (CS == VALTRAINVREF && previous_state_done && encoding_rsp_sent == 'hEA && encoding_rsp_received == 'hEA && init_train_en) |=> (CS == DATATRAINCENTER1);
    endproperty

    property datatraincenter1_to_datatrainvref_property;
        @(posedge i_clk) disable iff (i_reset || train_error_reg)
        (CS == DATATRAINCENTER1 && previous_state_done && encoding_rsp_sent == 'h92 && encoding_rsp_received == 'h92 && init_train_en) |=> (CS == DATATRAINVREF);
    endproperty

    property datatrainvref_to_rxdeskew_property;
        @(posedge i_clk) disable iff (i_reset || train_error_reg)
        (CS == DATATRAINVREF && previous_state_done && encoding_rsp_sent == 'hF2 && encoding_rsp_received == 'hF2 && init_train_en) |=> (CS == RXDESKEW);
    endproperty

    property rxdeskew_to_datatraincenter2_property;
        @(posedge i_clk) disable iff (i_reset || train_error_reg)
        (CS == RXDESKEW && previous_state_done && encoding_rsp_sent == 'hAC && encoding_rsp_received == 'hAC && init_train_en) |=> (CS == DATATRAINCENTER2);
    endproperty

    property datatraincenter2_completes_training_property;
        @(posedge i_clk) disable iff (i_reset || train_error_reg)
        (CS == DATATRAINCENTER2 && previous_state_done && encoding_rsp_sent == 'hBA && encoding_rsp_received == 'hBA) |-> train_link_init_en_reg;
    endproperty

    property previous_state_done_reset_property;
        @(posedge i_clk)
        i_reset |-> !previous_state_done;
    endproperty

    property mutual_exclusive_req_rsp_property;
        @(posedge i_clk) disable iff (i_reset)
        !(o_tx_sb_req && o_tx_sb_rsp);
    endproperty

    property clock_test_enable_only_in_substate1_valvref_property;
        @(posedge i_clk) disable iff (i_reset)
        (CS == VALVREF && current_substate == 0) |-> !clock_to_test_enable;
    endproperty

    property txselfcal_waits_for_done_property;
        @(posedge i_clk) disable iff (i_reset)
        (CS == TXSELFCAL && current_substate == 0 && !i_tx_done && !substates_done) |-> (next_substate == 0);
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
        (CS != NS) |-> (!substates_done && !o_tx_sb_req_reg && !o_tx_sb_rsp_reg);
    endproperty

    property state_transition_property;
        @(posedge i_clk) disable iff (i_reset)
        (CS != NS) |=> (CS == $past(NS));
    endproperty

    done_ack_assert_assertion: assert property (done_ack_assert_property)
        else $error("Assertion failed: done_ack should be set when i_sb_tx_done is asserted");
    cover property (done_ack_assert_property);

    done_ack_deassert_assertion: assert property (done_ack_deassert_property)
        else $error("Assertion failed: done_ack should be low when i_sb_tx_rsp is asserted");
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
        else $error("Assertion failed: o_tx_encoding should be 0 after reset");
    cover property (reset_encoding_property);

    reset_data_assertion: assert property (reset_data_property)
        else $error("Assertion failed: o_tx_data should be 0 after reset");
    cover property (reset_data_property);

    reset_info_assertion: assert property (reset_info_property)
        else $error("Assertion failed: o_tx_info should be 0 after reset");
    cover property (reset_info_property);

    reset_sb_req_assertion: assert property (reset_sb_req_property)
        else $error("Assertion failed: o_tx_sb_req should be 0 after reset");
    cover property (reset_sb_req_property);

    reset_sb_rsp_assertion: assert property (reset_sb_rsp_property)
        else $error("Assertion failed: o_tx_sb_rsp should be 0 after reset");
    cover property (reset_sb_rsp_property);

    reset_sb_done_assertion: assert property (reset_sb_done_property)
        else $error("Assertion failed: o_tx_sb_done should be 0 after reset");
    cover property (reset_sb_done_property);

    sb_done_self_clearing_assertion: assert property (sb_done_self_clearing_property)
        else $error("Assertion failed: o_tx_sb_done should self-clear when no request or response is active");
    cover property (sb_done_self_clearing_property);

    sb_done_assert_on_req_assertion: assert property (sb_done_assert_on_req_property)
        else $error("Assertion failed: o_tx_sb_done should assert on sideband request");
    cover property (sb_done_assert_on_req_property);

    sb_done_assert_on_rsp_assertion: assert property (sb_done_assert_on_rsp_property)
        else $error("Assertion failed: o_tx_sb_done should assert on sideband response");
    cover property (sb_done_assert_on_rsp_property);

    not_state_enb_resets_to_valvref_assertion: assert property (not_state_enb_resets_to_valvref_property)
        else $error("Assertion failed: CS should reset to VALVREF when init_train_en is low");
    cover property (not_state_enb_resets_to_valvref_property);

    not_state_enb_resets_substate_assertion: assert property (not_state_enb_resets_substate_property)
        else $error("Assertion failed: current_substate should reset to 0 when init_train_en is low");
    cover property (not_state_enb_resets_substate_property);

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
        else $error("Assertion failed: train_active_en_reg should be set when DATATRAINCENTER2 completes");
    cover property (datatraincenter2_completes_training_property);

    previous_state_done_reset_assertion: assert property (previous_state_done_reset_property)
        else $error("Assertion failed: previous_state_done should be low during reset");
    cover property (previous_state_done_reset_property);

    mutual_exclusive_req_rsp_assertion: assert property (mutual_exclusive_req_rsp_property)
        else $error("Assertion failed: o_tx_sb_req and o_tx_sb_rsp should not be asserted simultaneously");
    cover property (mutual_exclusive_req_rsp_property);

    clock_test_enable_only_in_substate1_valvref_assertion: assert property (clock_test_enable_only_in_substate1_valvref_property)
        else $error("Assertion failed: clock_to_test_enable should not be active in VALVREF substate 0");
    cover property (clock_test_enable_only_in_substate1_valvref_property);

    txselfcal_waits_for_done_assertion: assert property (txselfcal_waits_for_done_property)
        else $error("Assertion failed: TXSELFCAL should remain in substate 0 until i_tx_done is asserted");
    cover property (txselfcal_waits_for_done_property);

    valid_state_assertion: assert property (valid_state_property)
        else $error("Assertion failed: CS contains an invalid state value");
    cover property (valid_state_property);

    substates_done_clears_on_transition_assertion: assert property (substates_done_clears_on_transition_property)
        else $error("Assertion failed: substates_done should be cleared on state transition");
    cover property (substates_done_clears_on_transition_property);

    state_transition_values_assertion: assert property (state_transition_values_property)
        else $error("Assertion failed: on state transition, substates_done should be 0, o_tx_sb_req should be 0, and o_tx_sb_rsp should be 0");
    cover property (state_transition_values_property);

    state_transition_assertion: assert property (state_transition_property)
        else $error("Assertion failed: state should transition to NS on state change");
    cover property (state_transition_property);

`endif


endmodule