//================================================================================
// Module: ucie_LTSM_TX_phyretrain
// Description: UCIe TX Link Training State Machine for PHY retraining.
//              Initiates PL_STALL handshake, negotiates retrain type, and routes
//              to SPEEDIDLE, REPAIR, or TXSELFCAL based on the agreed retrain info.
//
// *** KNOWN DESIGN NOTE (not changed per request) ***
//     In START_REQ_HANDSHAKE, the second else-if branch checks
//     i_tx_info[2:0] == 3'b010 (same condition as the first branch) and sets
//     repair_state_enable. This condition can never be true when execution reaches
//     the else-if, so repair_state_enable can never be asserted from this path.
//     The likely intent was i_tx_info[2:0] == 3'b100 (lane-repair code).
//================================================================================
module ucie_LTSM_TX_phyretrain #(
    parameter DECODING_WIDTH = 9,    // Width of encoding/decoding signals
    parameter INFO_WIDTH = 16       // Width of info/control bus
) (
    input i_clk,
    input i_reset,
    input [DECODING_WIDTH-1:0] i_tx_decoding,
    input [INFO_WIDTH-1:0] i_tx_info,
    input i_lp_stallack,
    input i_sb_tx_req,
    input i_sb_tx_rsp,
    input i_sb_tx_done,
    input state_enable,
    input link_speed_state_enable,
    input [2:0] Lane_map_code,
    input [36:0] i_Runtime_Link_Test_Control_register,
    input i_Runtime_Link_Test_status_register,

    input [DECODING_WIDTH-1:0] encoding_rsp_sent,      // Encoding value when response sent
    input [DECODING_WIDTH-1:0] encoding_rsp_received,  // Encoding value when response received
    input rsp_received,               // Response sent flag
    input rsp_sent,                   // Response sent flag

    output logic [DECODING_WIDTH-1:0] o_tx_encoding,
    output logic [INFO_WIDTH-1:0] o_tx_info,
    output logic [3:0] o_pl_state_sts,
    output logic o_pl_stallreq,
    output logic o_tx_sb_req,
    output logic o_tx_sb_rsp,
    output logic o_tx_sb_done,
    output logic speed_idle_state_enable,
    output logic repair_state_enable,
    output logic tx_self_cal_state_enable,
    output logic [36:0] o_Runtime_Link_Test_Control_register,
    output logic o_Runtime_Link_Test_status_register
);

localparam PL_STALL_HANDSHAKE = 2'b00;
localparam RETRAIN_HANDSHAKE = 2'b01;
localparam START_REQ_HANDSHAKE = 2'b10;

logic [DECODING_WIDTH-1:0] o_tx_encoding_reg;
logic o_tx_sb_req_reg;
logic o_tx_sb_rsp_reg;
logic idle;
logic idle_reg;

logic done_ack;
logic [DECODING_WIDTH-1:0] o_tx_encoding_old;

logic [1:0] CS, NS;  // Current State, Next State

logic previous_state_done;  // High when both rsp_sent and rsp_received are asserted (handshake complete)

always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        CS <= PL_STALL_HANDSHAKE;
        o_tx_encoding <= 0;
        o_tx_sb_req <= 0;
        o_tx_sb_rsp <= 0;
        idle <= 1;
    end else begin
        if (!(state_enable || link_speed_state_enable)) begin
            CS <= PL_STALL_HANDSHAKE;
            o_tx_encoding <= 0;
            o_tx_sb_req <= 0;
            o_tx_sb_rsp <= 0;
            idle <= 1;
        end else begin
            CS <= NS;
            o_tx_encoding <= o_tx_encoding_reg;
            o_tx_sb_req <= o_tx_sb_req_reg;
            o_tx_sb_rsp <= o_tx_sb_rsp_reg;
            idle <= idle_reg;
        end
    end
end

//================================================================================
// Done Acknowledgement Logic
//================================================================================
// Tracks when done signal has been acknowledged in handshake protocol
always_comb begin
    if (i_reset) done_ack = 0;
    else if (o_tx_encoding[2:0] != o_tx_encoding_old[2:0]) done_ack = 0;
    else if (i_sb_tx_done) begin
        done_ack = 1;  // Set when done received
    end else if (i_sb_tx_rsp) begin
        done_ack = 0;  // Clear on response to allow next transaction
    end
end

always_ff @(posedge i_clk) begin
    o_tx_encoding_old <= o_tx_encoding;  // Register to track previous encoding for done_ack logic
end

assign previous_state_done = (i_reset)? 0 : (rsp_sent & rsp_received);

//================================================================================
// Sideband Done Signal Logic
//================================================================================
// Generates done pulse for sideband protocol
always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        o_tx_sb_done <= 0;;
    end else begin
        if (o_tx_sb_done) begin
            o_tx_sb_done <= 0;  // Self-clearing pulse
        end else if (i_sb_tx_rsp || i_sb_tx_req) begin
            o_tx_sb_done <= 1;  // Assert on request or response
        end
    end
end

assign o_pl_state_sts = 4'b1011;

always @(*) begin
    if (i_reset) begin
        o_tx_sb_req_reg = 0;
        o_tx_sb_rsp_reg = 0;
        o_tx_encoding_reg = 0;
        o_pl_stallreq = 0;
        o_Runtime_Link_Test_Control_register = 0;
        o_Runtime_Link_Test_status_register = 0;
        speed_idle_state_enable = 0;
        repair_state_enable = 0;
        tx_self_cal_state_enable = 0;
        idle_reg = 1;
    end else if (!(state_enable || link_speed_state_enable)) begin
            o_tx_encoding_reg = 0;
            o_tx_sb_req_reg = 0;
            o_tx_sb_rsp_reg = 0;
            tx_self_cal_state_enable = 0;
            speed_idle_state_enable = 0;
            repair_state_enable = 0;
            idle_reg = 1;
            NS = PL_STALL_HANDSHAKE;
    end else begin
        case (CS)
            // PL_STALL_HANDSHAKE: TX initiates the retrain by asserting o_pl_stallreq
            // and encoding 'hD8. Once the PL acknowledges the stall (i_lp_stallack),
            // TX advances to RETRAIN_HANDSHAKE to notify RX.
            // When link_speed_state_enable is asserted (retrain triggered from LINKSPEED),
            // TX skips the stall and jumps directly to START_REQ_HANDSHAKE.
            PL_STALL_HANDSHAKE: begin

                if (!idle) begin
                    o_tx_encoding_reg = 'hD8;
                    o_tx_sb_req_reg = 0;
                    o_tx_sb_rsp_reg = 0;
                    o_pl_stallreq = 1;

                    if (i_lp_stallack) begin
                        NS = RETRAIN_HANDSHAKE;
                        o_tx_encoding_reg = 'hD9;
                        o_tx_sb_req_reg = 0;
                        o_tx_sb_rsp_reg = 0;  
                        o_pl_stallreq = 0;
                    end else NS = PL_STALL_HANDSHAKE;
                end else begin
                    if (state_enable) begin
                        NS = PL_STALL_HANDSHAKE;
                        o_tx_encoding_reg = 'hD8;
                        idle_reg = 0;
                    end else if (link_speed_state_enable) begin
                        NS = START_REQ_HANDSHAKE;
                        o_tx_encoding_reg = 'hD9;
                        idle_reg = 0;
                    end
                end
            end

            // RETRAIN_HANDSHAKE: TX announces the retrain to RX with encoding 'hD9.
            // Once RX responds with 'hD9, TX advances to START_REQ_HANDSHAKE
            // to exchange the retrain type codes.
            RETRAIN_HANDSHAKE: begin
                NS = RETRAIN_HANDSHAKE;
                o_tx_encoding_reg = 'hD9;
                o_tx_sb_rsp_reg = 0;

                if (done_ack) o_tx_sb_req_reg = 0;
                else o_tx_sb_req_reg = 1;

                if (i_sb_tx_rsp && i_tx_decoding == 'hD9) begin
                    NS = START_REQ_HANDSHAKE;
                    o_tx_encoding_reg = 'hDA;
                    o_tx_sb_req_reg = 0;
                    o_tx_sb_rsp_reg = 0;  
                end else NS = RETRAIN_HANDSHAKE;
            end

            // START_REQ_HANDSHAKE: TX and RX exchange retrain type codes via o_tx_info[2:0].
            // TX sets its preference from the runtime test control register, then waits
            // for both sides to have confirmed encoding 'hDA before selecting the recovery path:
            //   3'b010 → SPEEDIDLE  (speed re-negotiation)
            //   3'b100 → REPAIR     (lane repair)  — *** see module header warning ***
            //   3'b001 → TXSELFCAL  (TX self-calibration, default)
            START_REQ_HANDSHAKE: begin
                NS = START_REQ_HANDSHAKE;
                o_tx_encoding_reg = 'hDA;
                o_tx_sb_rsp_reg = 0;

                // Encode TX retrain preference from the runtime test control register.
                // Bit[2] of the control register selects lane-remap (100) vs speed-change (010).
                // If the runtime test status is inactive the default is standard retrain (001).
                if (i_Runtime_Link_Test_status_register) begin
                    if (i_Runtime_Link_Test_Control_register[2]) begin
                        if (Lane_map_code) o_tx_info[2:0] = 3'b100;
                        else o_tx_info[2:0] = 3'b010;
                    end else o_tx_info[2:0] = 3'b001;
                end else o_tx_info[2:0] = 3'b001;

                if (done_ack) o_tx_sb_req_reg = 0;
                else o_tx_sb_req_reg = 1;

                if (previous_state_done && encoding_rsp_sent == 'hDA && encoding_rsp_received == 'hDA) begin
                    if (i_tx_info[2:0] == 3'b010) begin
                        speed_idle_state_enable = 1;
                        o_tx_encoding_reg = 'hC8;
                        o_tx_sb_req_reg = 0;
                        o_tx_sb_rsp_reg = 0;  
                    end else if (i_tx_info[2:0] == 3'b010) begin  // WARNING: duplicate condition — repair_state_enable can never assert here; intended condition is likely 3'b100
                        repair_state_enable = 1;
                        o_tx_encoding_reg = 'hC0;
                        o_tx_sb_req_reg = 0;
                        o_tx_sb_rsp_reg = 0;  
                    end else begin
                        tx_self_cal_state_enable = 1;
                        o_tx_encoding_reg = 'hD0;
                        o_tx_sb_req_reg = 0;
                        o_tx_sb_rsp_reg = 0; 
                    end
                end else NS = START_REQ_HANDSHAKE;
            end
        endcase
    end 
end
endmodule