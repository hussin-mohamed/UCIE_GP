module ucie_LTSM_TX_L1 #(
    parameter DECODING_WIDTH = 9    // Width of encoding/decoding signals
) (
    input i_clk,
    input i_reset,
    input [DECODING_WIDTH-1:0] i_tx_decoding,
    input [3:0] i_lp_state_req,
    input i_sb_tx_req,
    input i_sb_tx_rsp,
    input i_sb_tx_done,
    input state_enable,
    input L1_rx_rsp_sent,

    output logic [DECODING_WIDTH-1:0] o_tx_encoding,
    output logic [3:0] o_pl_state_sts,
    output logic o_tx_sb_req,
    output logic o_tx_sb_rsp,
    output logic o_tx_sb_done,
    output logic speed_idle_state_enable,
    output logic active_state_enable
);

localparam START_HANDSHAKE = 2'b00;
localparam L1 = 2'b01;
localparam PMNAK = 2'b10;

logic [DECODING_WIDTH-1:0] o_tx_encoding_reg;
logic o_tx_sb_req_reg;
logic o_tx_sb_rsp_reg;
logic L1_rsp_recieved;

logic done_ack;
logic [DECODING_WIDTH-1:0] o_tx_encoding_old;

logic [1:0] CS, NS;  // Current State, Next State

always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        CS <= START_HANDSHAKE;
    end else begin
        if (state_enable) begin
            CS <= NS;
        end else begin
            CS <= START_HANDSHAKE;  
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
        o_tx_encoding_reg = START_HANDSHAKE;
        o_tx_sb_req_reg = 0;
        o_tx_sb_rsp_reg = 0;
        L1_rsp_recieved = 0;
    end else case (CS)
        START_HANDSHAKE: begin
            o_tx_encoding_reg = 'h110;
            NS =  START_HANDSHAKE;

            if (done_ack) o_tx_sb_req_reg = 0;
            else o_tx_sb_req_reg = 1;

            if (i_sb_tx_rsp && i_tx_decoding == 'h111) begin
                L1_rsp_recieved = 1;
            end else if (L1_rsp_recieved && L1_rx_rsp_sent) begin
                NS = L1;
                o_tx_encoding_reg = 'h111;
                o_tx_sb_req_reg = 0;
                o_tx_sb_rsp_reg = 0;
                L1_rsp_recieved = 0;
                o_pl_state_sts = 'b0100;
            end else if (i_sb_tx_rsp && i_tx_decoding == 'h113) begin
                NS = PMNAK;
                o_tx_encoding_reg = 'h113;
                active_state_enable = 1;
                o_tx_sb_req_reg = 0;
                o_tx_sb_rsp_reg = 0;
                o_pl_state_sts = 'b0011;
            end else begin
                o_tx_encoding_reg = 'h110;
                NS =  START_HANDSHAKE;
            end
        end 

        L1: begin
            o_tx_encoding_reg = 'h111;
            NS = L1;
            o_pl_state_sts = 'b0100;

            if (i_lp_state_req == 'b0001) begin
                o_tx_encoding_reg = 'hC8;
                speed_idle_state_enable = 1;
                o_tx_sb_req_reg = 0;
                o_tx_sb_rsp_reg = 0;
                o_pl_state_sts = 'b0000;
            end
        end

        PMNAK: begin
            o_tx_encoding_reg = 'h113;
            NS = PMNAK;
            o_pl_state_sts = 'b0011;

            if (i_lp_state_req == 'b0001) begin
                o_tx_encoding_reg = 'h108;
                o_tx_sb_req_reg = 0;
                o_tx_sb_rsp_reg = 0;
                o_pl_state_sts = 'b0001;
            end
end
    endcase
end
    
endmodule