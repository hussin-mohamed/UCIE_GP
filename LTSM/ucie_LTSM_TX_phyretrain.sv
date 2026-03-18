module ucie_LTSM_TX_phyretrain #(
    parameter DECODING_WIDTH = 9,    // Width of encoding/decoding signals
    parameter INFO_WIDTH = 16       // Width of info/control bus
) (
    input i_clk,
    input i_reset,
    input [DECODING_WIDTH-1:0] i_tx_decoding,
    input [INFO_WIDTH-1:0] i_tx_info,
    input [3:0] i_lp_state_req,
    input i_lp_stallack,
    input i_sb_tx_req,
    input i_sb_tx_rsp,
    input i_sb_tx_done,
    input i_rx_valid_results,
    input state_enable,
    input link_speed_state_enable,
    input L1_rx_rsp_sent,
    input [2:0] Lane_map_code,
    input [36:0] i_Runtime_Link_Test_Control_register,
    input i_Runtime_Link_Test_status_register,
    input phyretrain_req_sent,

    output logic [DECODING_WIDTH-1:0] o_tx_encoding,
    output logic [INFO_WIDTH-1:0] o_tx_info,
    output logic [3:0] o_pl_state_sts,
    output logic o_pl_stallreq,
    output logic o_pl_error,
    output logic o_tx_sb_req,
    output logic o_tx_sb_rsp,
    output logic o_tx_sb_done,
    output logic speed_idle_state_enable,
    output logic repair_state_enable,
    output logic tx_self_cal_state_enable,
    output logic active_state_enable,
    output logic [36:0] o_Runtime_Link_Test_Control_register,
    output logic o_Runtime_Link_Test_status_register
);

localparam PL_STALL_HANDSHAKE = 2'b00;
localparam RETRAIN_HANDSHAKE = 2'b01;
localparam START_REQ_HANDSHAKE = 2'b10;

logic [DECODING_WIDTH-1:0] o_tx_encoding_reg;
logic o_tx_sb_req_reg;
logic o_tx_sb_rsp_reg;
logic L1_rsp_recieved;

logic done_ack;
logic [DECODING_WIDTH-1:0] o_tx_encoding_old;

logic [1:0] CS, NS;  // Current State, Next State

always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        CS <= PL_STALL_HANDSHAKE;
    end else begin
        if (state_enable) begin
            CS <= PL_STALL_HANDSHAKE;
        end else if (link_speed_state_enable) begin
            CS <= START_REQ_HANDSHAKE;
        end else begin
            CS <= NS;
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

always_comb begin
    if (i_reset) begin
        o_tx_sb_req_reg = 0;
        o_tx_sb_rsp_reg = 0;
        o_tx_encoding = 0;
        o_pl_stallreq = 0;
        o_Runtime_Link_Test_Control_register = 0;
        o_Runtime_Link_Test_status_register = 0;
        speed_idle_state_enable = 0;
        repair_state_enable = 0;
        tx_self_cal_state_enable = 0;
    end else case (CS)
        PL_STALL_HANDSHAKE: begin
            NS = PL_STALL_HANDSHAKE;
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
        end

        RETRAIN_HANDSHAKE: begin
            NS = RETRAIN_HANDSHAKE;
            o_tx_encoding_reg = 'hD9;
            o_tx_sb_rsp_reg = 0;
            
            if (done_ack) o_tx_sb_req = 0;
            else o_tx_sb_req = 1;

            if (i_sb_tx_rsp && i_tx_decoding == 'hD9) begin
                NS = START_REQ_HANDSHAKE;
                o_tx_encoding_reg = 'hDA;
                o_tx_sb_req_reg = 0;
                o_tx_sb_rsp_reg = 0;  
            end else NS = RETRAIN_HANDSHAKE;
        end

        START_REQ_HANDSHAKE: begin
            NS = START_REQ_HANDSHAKE;
            o_tx_encoding_reg = 'hDA;
            o_tx_sb_rsp_reg = 0;

            if (i_Runtime_Link_Test_status_register) begin
                if (i_Runtime_Link_Test_Control_register[2]) begin
                    if (Lane_map_code) o_tx_info[2:0] = 3'b100;
                    else o_tx_info[2:0] = 3'b010;
                end else o_tx_info[2:0] = 3'b001;
            end o_tx_info[2:0] = 3'b001;
            
            if (done_ack) o_tx_sb_req = 0;
            else o_tx_sb_req = 1;

            if (i_sb_tx_rsp && i_tx_decoding == 'hDA) begin
                if (i_tx_info[2:0] == 3'b010) begin
                    speed_idle_state_enable = 1;
                    o_tx_encoding_reg = 'hC8;
                    o_tx_sb_req_reg = 0;
                    o_tx_sb_rsp_reg = 0;  
                end else if (i_tx_info[2:0] == 3'b010) begin
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
                NS = PL_STALL_HANDSHAKE;
            end else NS = RETRAIN_HANDSHAKE;
        end
    endcase
end
endmodule