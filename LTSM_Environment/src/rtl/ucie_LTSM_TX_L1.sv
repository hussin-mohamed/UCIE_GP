//================================================================================
// Module: ucie_LTSM_TX_L1
// Description: UCIe TX Link Training State Machine for the L1 low-power state.
//              Manages entry into and exit from the L1 power state, handling
//              PL_STATE_REQ handshakes and enabling SPEEDIDLE on exit.
//================================================================================
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
    input i_rsp_sent,
    input i_rsp_received,
    input [DECODING_WIDTH-1 : 0] i_encoding_rsp_sent,
    input [DECODING_WIDTH-1 : 0] i_encoding_rsp_received,

    output logic [DECODING_WIDTH-1:0] o_tx_encoding,
    output logic [3:0] o_pl_state_sts,
    output logic o_tx_sb_req,
    output logic o_tx_sb_rsp,
    output logic o_tx_sb_done,
    output logic speed_idle_state_enable,
    output logic pmnak_enable
);

localparam START_HANDSHAKE = 2'b00;
localparam L1 = 2'b01;

logic [DECODING_WIDTH-1:0] o_tx_encoding_reg;
logic o_tx_sb_req_reg;
logic o_tx_sb_rsp_reg;
logic L1_rsp_recieved;

logic done_ack;
logic done_ack_old;
logic [DECODING_WIDTH-1:0] o_tx_encoding_old;
logic speed_idle_state_enable_old;
logic pmnak_enable_old;

logic [1:0] CS, NS;  // Current State, Next State

always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        CS <= START_HANDSHAKE;
        o_tx_sb_rsp <= 0;
        o_tx_sb_req <= 0;
        o_tx_encoding <= 0;
    end else begin
        if (state_enable) begin
            CS <= NS;
            o_tx_sb_rsp <= o_tx_sb_rsp_reg;
            o_tx_sb_req <= o_tx_sb_req_reg;
            o_tx_encoding <= o_tx_encoding_reg;
        end else begin
            CS <= START_HANDSHAKE; 
            o_tx_sb_rsp <= 0;
            o_tx_sb_req <= 0;
            o_tx_encoding <= 'h108;
        end
    end
end

//================================================================================
// Done Acknowledgement Logic
//================================================================================
// Tracks when done signal has been acknowledged in handshake protocol
always_comb begin
    done_ack = done_ack_old;
    if (o_tx_encoding != o_tx_encoding_old) done_ack = 0;
    else if (i_sb_tx_done) begin
        done_ack = 1;  // Set when done received
    end
end

always_ff @(posedge i_clk) begin
    if (i_reset) begin
        o_tx_encoding_old <= 0;
        done_ack_old <= 0;
        speed_idle_state_enable_old <= 0;
        pmnak_enable_old <= 0;
    end else begin
        o_tx_encoding_old <= o_tx_encoding;  // Register to track previous encoding for done_ack logic
        done_ack_old <= done_ack;  // Register to track previous encoding for done_ack logic
        speed_idle_state_enable_old <= speed_idle_state_enable;
        pmnak_enable_old <= pmnak_enable;
    end
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
        o_tx_encoding_reg = 'h110;
        o_tx_sb_req_reg = 0;
        o_tx_sb_rsp_reg = 0;
        L1_rsp_recieved = 0;
        speed_idle_state_enable = speed_idle_state_enable_old;
        pmnak_enable = pmnak_enable_old;
        NS = CS;
        o_pl_state_sts = 'b0001;  // Default to IDLE state status
    if (!state_enable) begin
        o_tx_encoding_reg = 'h108;
        o_tx_sb_req_reg = 0;
        o_tx_sb_rsp_reg = 0;
        L1_rsp_recieved = 0;
        speed_idle_state_enable = 0;
    end else begin
        case (CS)
            // START_HANDSHAKE: TX initiates the L1 entry by asserting 'h110.
            // If RX responds with 'h113 (PM NAK) the request was rejected;
            // pmnak_enable is asserted so the upper layer can retry or abort.
            START_HANDSHAKE: begin
                o_tx_encoding_reg = 'h110;
                NS =  START_HANDSHAKE;
    
                if (done_ack) o_tx_sb_req_reg = 0;
                else o_tx_sb_req_reg = 1;
    
                if ((i_rsp_sent && i_encoding_rsp_sent == 'h110) || (i_encoding_rsp_sent == 'h111 && i_encoding_rsp_received == 'h110 && i_rsp_received && i_rsp_sent)) begin
                    NS = L1;
                    o_tx_encoding_reg = 'h111;
                    o_tx_sb_req_reg = 0;
                    o_tx_sb_rsp_reg = 0;
                    L1_rsp_recieved = 0;
                    o_pl_state_sts = 'b0100;
                end else if (i_sb_tx_rsp && i_tx_decoding == 'h113) begin
                    pmnak_enable = 1;
                    o_tx_sb_req_reg = 0;
                    o_tx_sb_rsp_reg = 0;
                    o_pl_state_sts = 'b0011;
                end else begin
                    o_tx_encoding_reg = 'h110;
                    NS =  START_HANDSHAKE;
                end
            end 
    
            // L1: link is in low-power state. Exit is triggered either by a
            // local wake request (i_lp_state_req == 0001) or by an RX-driven
            // ACTIVE request ('h108). Either path enables SPEEDIDLE.
            L1: begin
                o_tx_encoding_reg = 'h111;
                NS = L1;
                o_pl_state_sts = 'b0100;
    
                if (i_lp_state_req == 'b0001 || (i_sb_tx_req && i_tx_decoding == 'h108)) begin
                    o_tx_encoding_reg = 'hC8;
                    speed_idle_state_enable = 1;
                    o_tx_sb_req_reg = 0;
                    o_tx_sb_rsp_reg = 0;
                    o_pl_state_sts = 'b0000;
                end
            end
        endcase
    end 
end
    
endmodule