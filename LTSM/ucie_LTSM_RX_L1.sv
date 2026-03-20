//================================================================================
// Module: ucie_LTSM_rx_L1
// Description: UCIe RX Link Training State Machine for the L1 low-power state.
//              Manages entry into and exit from the L1 power state, handling
//              PL_STATE_REQ handshakes and enabling SPEEDIDLE on exit.
//================================================================================
module ucie_LTSM_rx_L1 #(
    parameter DECODING_WIDTH = 9    // Width of encoding/decoding signals
) (
    input i_clk,
    input i_reset,
    input [DECODING_WIDTH-1:0] i_rx_decoding,
    input [3:0] i_lp_state_req,
    input i_sb_rx_req,
    input i_sb_rx_rsp,
    input i_sb_rx_done,
    input state_enable,
    input i_timer_1us,

    output logic [DECODING_WIDTH-1:0] o_rx_encoding,
    output logic [3:0] o_pl_state_sts,
    output logic o_rx_sb_req,
    output logic o_rx_sb_rsp,
    output logic o_rx_sb_done,
    output logic speed_idle_state_enable,
    output logic wait_1us_en,
    output logic active_state_enable
);

localparam WAIT_1US = 2'b00;
localparam L1 = 2'b01;
localparam L1_REQ_END = 2'b10;
localparam START_HANDSHAKE = 2'b11;

logic [DECODING_WIDTH-1:0] o_rx_encoding_reg;
logic o_rx_sb_req_reg;
logic o_rx_sb_rsp_reg;
logic o_rx_sb_done_reg;
logic L1_rsp_recieved;

logic idle;
logic idle_reg;

logic done_ack;
logic [DECODING_WIDTH-1:0] o_rx_encoding_old;

logic [1:0] CS, NS;  // Current State, Next State

always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        CS <= WAIT_1US;
        idle <= 1;
        o_rx_encoding <= 0;
        o_rx_sb_req <= 0;
        o_rx_sb_rsp <= 0;
    end else begin
        if (state_enable) begin
            CS <= NS;
            idle <= idle_reg;
            o_rx_encoding <= o_rx_encoding_reg;
            o_rx_sb_req <= o_rx_sb_req_reg;
            o_rx_sb_rsp <= o_rx_sb_rsp_reg;
        end else begin
            CS <= WAIT_1US;
            idle <= 1;
            o_rx_encoding <= 0;
            o_rx_sb_req <= 0;
            o_rx_sb_rsp <= 0;
        end
    end
end

//================================================================================
// Done Acknowledgement Logic
//================================================================================
// Tracks when done signal has been acknowledged in handshake protocol
always_comb begin
    if (i_reset) done_ack = 0;
    else if ((o_rx_encoding_reg[2:0] != o_rx_encoding_old[2:0]) || !state_enable) done_ack = 0;
    else if (i_sb_rx_done) begin
        done_ack = 1;  // Set when done received
    end else if (i_sb_rx_rsp) begin
        done_ack = 0;  // Clear on response to allow next transaction
    end
end

always_ff @(posedge i_clk) begin
    o_rx_encoding_old <= o_rx_encoding_reg;  // Register to track previous encoding for done_ack logic
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

always_comb begin
    if (i_reset) begin
        o_rx_encoding_reg = WAIT_1US;
        o_rx_sb_req_reg = 0;
        o_rx_sb_rsp_reg = 0;
        o_rx_sb_done_reg = 0;
        idle_reg = 1;
        speed_idle_state_enable = 0;
        wait_1us_en = 0;
    end else if (!state_enable) begin
        o_rx_encoding_reg = WAIT_1US;
        o_rx_sb_req_reg = 0;
        o_rx_sb_rsp_reg = 0;
        o_rx_sb_done_reg = 0;
        idle_reg = 1;
        speed_idle_state_enable = 0;
        wait_1us_en = 0;
    end else begin
        case (CS)
            // WAIT_1US: idle until a sideband L1 request arrives from TX.
            // If the local LP_STATE_REQ also requests L1 ('h04) the module
            // moves to L1; if 1us has elapsed and L1 was not confirmed it
            // signals L1_REQ_END to abort and return to ACTIVE.
            WAIT_1US: begin
                if (!idle) begin
                    o_rx_encoding_reg = 'h112;
                    NS =  WAIT_1US;
                    idle_reg = 0;

                    wait_1us_en = 1;

                    if (i_lp_state_req == 4'b0100) begin
                        NS =  L1;
                        o_rx_encoding_reg = 'h111;
                        o_rx_sb_req_reg = 0;
                        o_rx_sb_rsp_reg = 0;
                        o_pl_state_sts = 4'b0100;
                    end else if (i_timer_1us && i_lp_state_req != 4'b0100) begin
                        NS =  L1_REQ_END;
                        o_rx_encoding_reg = 'h113;
                        o_rx_sb_req_reg = 0;
                        o_rx_sb_rsp_reg = 0;
                    end
                end else begin
                    if (i_sb_rx_req && i_rx_decoding == 'h110) begin
                        if (i_lp_state_req == 4'b0100) begin
                            NS = START_HANDSHAKE;
                            o_rx_encoding_reg = 'h110;
                            idle_reg = 0;
                            wait_1us_en = 0;
                        end else begin
                            NS = WAIT_1US;
                            o_rx_encoding_reg = 'h112;
                            idle_reg = 0;
                            wait_1us_en = 0;
                        end
                    end else begin
                        NS = WAIT_1US;  // NOTE: original used '<=' in always_comb; corrected to '=' — behaviour is identical in simulation but '<=' is illegal in synthesis-clean always_comb
                        idle_reg = 1;
                    end 
                end
            end 

            // L1: link is in low-power state. Exit is triggered either by a
            // local wake request (i_lp_state_req == 0001) or by a TX-driven
            // ACTIVE request ('h108). Either path enables SPEEDIDLE to
            // re-negotiate the link speed before resuming data transfer.
            L1: begin
                o_rx_encoding_reg = 'h111;
                NS = L1;
                o_pl_state_sts = 'b0100;

                if (i_lp_state_req == 'b0001 || (i_sb_rx_req && i_rx_decoding == 'h108)) begin
                    o_rx_encoding_reg = 'hC8;
                    speed_idle_state_enable = 1;
                    o_rx_sb_req_reg = 0;
                    o_rx_sb_rsp_reg = 0;
                    o_pl_state_sts = 'b0000;
                end
            end

            // L1_REQ_END: the 1us timer expired before L1 was confirmed.
            // Responds with 'h113 to acknowledge the abort, then enables the
            // ACTIVE state once the done pulse is received.
            L1_REQ_END: begin
                o_rx_encoding_reg = 'h113;
                NS = L1_REQ_END;

                if (done_ack) o_rx_sb_rsp_reg = 0;
                else o_rx_sb_rsp_reg = 1;

                if (i_sb_rx_done) begin
                    o_rx_encoding_reg = 'h108;
                    o_rx_sb_req_reg = 0;
                    o_rx_sb_rsp_reg = 0;
                    active_state_enable = 1;
                end
            end

            // START_HANDSHAKE: initial sideband exchange before entering L1.
            // RX responds to TX's 'h110 request and waits for the done pulse
            // before transitioning into the L1 low-power state.
            START_HANDSHAKE: begin
                o_rx_encoding_reg = 'h110;
                NS = START_HANDSHAKE;

                if (done_ack) o_rx_sb_rsp_reg = 0;
                else o_rx_sb_rsp_reg = 1;

                if (i_sb_rx_done) begin
                    NS = L1;
                    o_rx_encoding_reg = 'h111;
                    o_rx_sb_req_reg = 0;
                    o_rx_sb_rsp_reg = 0;
                    o_pl_state_sts = 'b0100;
                end
            end
        endcase
    end 
end
    
endmodule