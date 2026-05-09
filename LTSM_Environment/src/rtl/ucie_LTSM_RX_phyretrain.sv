//================================================================================
// Module: ucie_LTSM_RX_phyretrain
// Description: UCIe RX Link Training State Machine for PHY retraining.
//              Handles PL_STALL handshake, retrain negotiation, and routes to
//              SPEEDIDLE, REPAIR, or TXSELFCAL based on the agreed retrain info.
//================================================================================
module ucie_LTSM_RX_phyretrain #(
    parameter DECODING_WIDTH = 9,    // Width of encoding/decoding signals
    parameter INFO_WIDTH = 16       // Width of info/control bus
) (
    input i_clk,
    input i_reset,
    input [DECODING_WIDTH-1:0] i_rx_decoding,
    input [INFO_WIDTH-1:0] i_rx_info,
    input [3:0] i_lp_state_req,
    input i_lp_stallack,
    input i_sb_rx_req,
    input i_sb_rx_rsp,
    input i_sb_rx_done,
    input state_enable,
    input link_speed_state_enable,
    input [2:0] Lane_map_code,
    input [36:0] i_Runtime_Link_Test_Control_register,
    input i_Runtime_Link_Test_status_register,

    input [DECODING_WIDTH-1:0] encoding_rsp_sent,      // Encoding value when response sent
    input [DECODING_WIDTH-1:0] encoding_rsp_received,  // Encoding value when response received
    input rsp_received,               // Response sent flag
    input rsp_sent,                   // Response sent flag

    output logic [DECODING_WIDTH-1:0] o_rx_encoding,
    output logic [INFO_WIDTH-1:0] o_rx_info,
    output logic o_rx_sb_req,
    output logic o_rx_sb_rsp,
    output logic o_rx_sb_done,
    output logic speed_idle_state_enable,
    output logic repair_state_enable,
    output logic tx_self_cal_state_enable
);

localparam PL_STALL_HANDSHAKE = 2'b00;
localparam RETRAIN_HANDSHAKE = 2'b01;
localparam START_REQ_HANDSHAKE = 2'b10;

logic [DECODING_WIDTH-1:0] o_rx_encoding_reg;
logic o_rx_sb_req_reg;
logic o_rx_sb_rsp_reg;
logic L1_rsp_recieved;

logic idle;
logic idle_reg;

logic done_ack;
logic [DECODING_WIDTH-1:0] o_rx_encoding_old;
logic tx_self_cal_state_enable_old;
logic speed_idle_state_enable_old;
logic repair_state_enable_old;

logic [2:0] Retrain_encoding;

logic [1:0] CS, NS;  // Current State, Next State

logic previous_state_done;  // High when both rsp_sent and rsp_received are asserted (handshake complete)

always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        CS <= PL_STALL_HANDSHAKE;
        o_rx_encoding <= 0;
        o_rx_sb_req <= 0;
        o_rx_sb_rsp <= 0;
        idle <= 1;
    end else begin
        if (!(state_enable || link_speed_state_enable)) begin
            CS <= PL_STALL_HANDSHAKE;
            o_rx_encoding <= 0;
            o_rx_sb_req <= 0;
            o_rx_sb_rsp <= 0;
            idle <= 1;
        end else begin
            CS <= NS;
            o_rx_encoding <= o_rx_encoding_reg;
            o_rx_sb_req <= o_rx_sb_req_reg;
            o_rx_sb_rsp <= o_rx_sb_rsp_reg;
            idle <= idle_reg;
        end
    end
end

//================================================================================
// Done Acknowledgement Logic
//================================================================================
// Tracks when done signal has been acknowledged in handshake protocol
always_comb begin
    done_ack = 0;
    if (o_rx_encoding[2:0] != o_rx_encoding_old[2:0]) done_ack = 0;
    else if (i_sb_rx_done) begin
        done_ack = 1;  // Set when done received
    end else if (i_sb_rx_rsp) begin
        done_ack = 0;  // Clear on response to allow next transaction
    end
end

always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        o_rx_encoding_old <= 0;
        tx_self_cal_state_enable_old <= 0;
        speed_idle_state_enable_old <= 0;
        repair_state_enable_old <= 0;
    end else begin
        o_rx_encoding_old <= o_rx_encoding;  // Update previous encoding only when state is enabled
        tx_self_cal_state_enable_old <= tx_self_cal_state_enable;  // Track previous state of TX self-cal enable for done_ack logic
        speed_idle_state_enable_old <= speed_idle_state_enable;  // Track previous state of speed idle enable for done_ack logic
        repair_state_enable_old <= repair_state_enable;  // Track previous state of repair enable for done_ack logic
    end
end

assign previous_state_done = (rsp_sent & rsp_received);

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

always_comb begin
        o_rx_sb_req_reg = 0;
        o_rx_sb_rsp_reg = 0;
        o_rx_encoding_reg = 0;
        idle_reg = idle;
        o_rx_info = 0;
        NS = CS;
        tx_self_cal_state_enable = tx_self_cal_state_enable_old;
        speed_idle_state_enable = speed_idle_state_enable_old;
        repair_state_enable = repair_state_enable_old;
    if (!(state_enable || link_speed_state_enable)) begin
            o_rx_encoding_reg = 0;
            o_rx_sb_req_reg = 0;
            o_rx_sb_rsp_reg = 0;
            idle_reg = 1;
            tx_self_cal_state_enable = 0;
            speed_idle_state_enable = 0;
            repair_state_enable = 0;
            NS = PL_STALL_HANDSHAKE;
    end else begin
        case (CS)
            // PL_STALL_HANDSHAKE: waits for a PL_STALL request from TX ('hD8 when idle)
            // or a direct ACTIVE→RETRAIN jump ('hDA). Once a stall is agreed the FSM
            // moves to RETRAIN_HANDSHAKE to negotiate the retrain type.
            PL_STALL_HANDSHAKE: begin
                if (!idle) begin
                    o_rx_encoding_reg = 'hD8;
                    o_rx_sb_req_reg = 0;
                    o_rx_sb_rsp_reg = 0;

                    if (i_sb_rx_req && i_rx_decoding == 'hD9) begin
                        NS = RETRAIN_HANDSHAKE;
                        o_rx_encoding_reg = 'hD9;
                        o_rx_sb_req_reg = 0;
                        o_rx_sb_rsp_reg = 0;  
                    end else NS = PL_STALL_HANDSHAKE;
                end else begin
                    if (i_sb_rx_req && i_rx_decoding == 'hD8) begin
                        NS = PL_STALL_HANDSHAKE;
                        idle_reg = 0;
                    end else if (i_sb_rx_req && i_rx_decoding == 'hDA) begin
                        NS = START_REQ_HANDSHAKE;
                        idle_reg = 0;
                    end
                end
            end

            // RETRAIN_HANDSHAKE: RX responds to TX's 'hD9 retrain announcement.
            // Once TX advances to 'hDA (retrain type request) the FSM moves to
            // START_REQ_HANDSHAKE to agree on the retrain path.
            RETRAIN_HANDSHAKE: begin
                NS = RETRAIN_HANDSHAKE;
                o_rx_encoding_reg = 'hD9;
                o_rx_sb_rsp_reg = 0;

                if (done_ack) o_rx_sb_rsp_reg = 0;
                else o_rx_sb_rsp_reg = 1;

                if (i_sb_rx_req && i_rx_decoding == 'hDA) begin
                    NS = START_REQ_HANDSHAKE;
                    o_rx_encoding_reg = 'hDA;
                    o_rx_sb_req_reg = 0;
                    o_rx_sb_rsp_reg = 0;  
                end else NS = RETRAIN_HANDSHAKE;
            end

            // START_REQ_HANDSHAKE: TX and RX exchange retrain type codes via o_rx_info[2:0].
            // The agreed code selects the recovery path:
            //   3'b010 → SPEEDIDLE  (speed re-negotiation)
            //   3'b100 → REPAIR     (lane repair)
            //   3'b001 → TXSELFCAL  (TX self-calibration, default)
            // The local Retrain_encoding is merged with TX's i_rx_info to pick the
            // highest-priority action when both sides have non-default requests.
            START_REQ_HANDSHAKE: begin
                NS = START_REQ_HANDSHAKE;
                o_rx_encoding_reg = 'hDA;
                o_rx_sb_rsp_reg = 0;

                // Determine local retrain preference from the runtime test control register.
                // If the runtime test status is active, check bit[2] of the control register
                // to decide between lane-remap (100) and speed-change (010); otherwise default to
                // standard retrain (001).  The result is then merged with TX's preference below.
                if (i_Runtime_Link_Test_status_register) begin
                    if (i_Runtime_Link_Test_Control_register[2]) begin
                        if (Lane_map_code)  Retrain_encoding = 3'b100;
                        else Retrain_encoding = 3'b010;
                    end else Retrain_encoding = 3'b001;
                end Retrain_encoding = 3'b001;

                // Merge local and TX retrain preferences: REPAIR (100) > SPEEDIDLE (010) > TXSELFCAL (001).
                // The higher-priority path wins when the two sides disagree.
                if (i_rx_info == 3'b010 || Retrain_encoding == 3'b010) begin
                    o_rx_info[2:0] = 3'b010;
                end else if (i_rx_info == 3'b100 || Retrain_encoding == 3'b100) begin
                    o_rx_info[2:0] = 3'b100;
                end else begin
                    o_rx_info[2:0] = 3'b001;
                end

                if (done_ack) o_rx_sb_rsp_reg = 0;
                else o_rx_sb_rsp_reg = 1;

                if (previous_state_done && encoding_rsp_sent == 'hDA && encoding_rsp_received == 'hDA) begin
                    if (i_rx_info[2:0] == 3'b010) begin
                        speed_idle_state_enable = 1;
                        repair_state_enable = 0;
                        tx_self_cal_state_enable = 0;
                        o_rx_encoding_reg = 'hC8;
                        o_rx_sb_req_reg = 0;
                        o_rx_sb_rsp_reg = 0;  
                    end else if (i_rx_info[2:0] == 3'b100) begin
                        if (i_sb_rx_req && i_rx_decoding == 'hC0 ) begin
                            repair_state_enable = 1;
                            speed_idle_state_enable = 0;
                            tx_self_cal_state_enable = 0;
                            o_rx_encoding_reg = 'hC0;
                            o_rx_sb_req_reg = 0;
                            o_rx_sb_rsp_reg = 0; 
                        end     
                    end else begin
                        tx_self_cal_state_enable = 1;
                        speed_idle_state_enable = 0;
                        repair_state_enable = 0;
                        o_rx_encoding_reg = 'hD0;
                        o_rx_sb_req_reg = 0;
                        o_rx_sb_rsp_reg = 0; 
                    end
                end else NS = START_REQ_HANDSHAKE;
            end

            default: begin
                tx_self_cal_state_enable = 0;
                speed_idle_state_enable = 0;
                repair_state_enable = 0;
            end
        endcase
    end 
end
endmodule