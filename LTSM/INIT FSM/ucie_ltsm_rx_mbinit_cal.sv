`define SIM
module ucie_ltsm_rx_mbinit_cal #(
    parameter DECODING_WIDTH = 9,
    parameter DATA_WIDTH     = 64,
    parameter INFO_WIDTH     = 16
) (
    input                               i_clk,
    input                               i_reset,
    input   [DECODING_WIDTH-1:0]        i_rx_decoding,
    input   [DATA_WIDTH-1:0]            i_rx_data,
    input   [INFO_WIDTH-1:0]            i_rx_info,
    input                               i_sb_rx_req,
    input                               i_sb_rx_rsp,
    input                               i_sb_rx_done,
    input                               i_rx_done,
    input                               init_train_en,
    input   [3:0]                       i_current_state,
    input                               o_timer_8ms,
    output  logic [DECODING_WIDTH-1:0]  o_rx_encoding,
    output  logic [DATA_WIDTH-1:0]      o_rx_data,
    output  logic [INFO_WIDTH-1:0]      o_rx_info,
    output  logic                       o_rx_sb_req,
    output  logic                       o_rx_sb_rsp,
    output  logic                       o_rx_sb_done,
    output  logic                       o_train_error,
    output  logic                       o_done_mbinit_cal_rx
);

    // -------------------------------------------------------------------------
    // Local parameters
    // -------------------------------------------------------------------------
    localparam logic [3:0] MBINIT_CAL     = 4'b0011;
    localparam logic [2:0] DONE_HANDSHAKE = 3'b000;

    // -------------------------------------------------------------------------
    // Internal signals
    // -------------------------------------------------------------------------
    logic [2:0] current_substate;
    logic [2:0] next_substate;
    logic       done_ack;
    logic       substates_done;

    // -------------------------------------------------------------------------
    // State memory
    // -------------------------------------------------------------------------
    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset || i_current_state != MBINIT_CAL) begin
            current_substate <= DONE_HANDSHAKE;
            substates_done   <= 0;
        end else begin
            current_substate <= next_substate;
            if (current_substate == DONE_HANDSHAKE &&
                i_sb_rx_req && i_rx_decoding == 9'h18)
                substates_done <= 1;
        end
    end

    // -------------------------------------------------------------------------
    // RSP / Done handshake register
    // -------------------------------------------------------------------------
    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset)
            done_ack <= 0;
        else if (i_sb_rx_done)
            done_ack <= 1;
        else if (i_sb_rx_req)
            done_ack <= 0;
    end

    // -------------------------------------------------------------------------
    // Next-state / output combinational logic
    // CAL is simple: single DONE_HANDSHAKE substate.
    // Wait for TX REQ + encoding 0x18, send RSP, assert done.
    // -------------------------------------------------------------------------
    always_comb begin
        o_rx_encoding        = 9'h18;
        o_rx_data            = '0;
        o_rx_info            = '0;
        o_rx_sb_req          = 0;
        o_rx_sb_rsp          = 0;
        o_rx_sb_done         = 0;
        o_train_error        = 0;
        o_done_mbinit_cal_rx = 0;
        next_substate        = DONE_HANDSHAKE;

        if (o_timer_8ms) begin
            o_train_error = 1;
            next_substate = DONE_HANDSHAKE;
        end
        else if (i_current_state == MBINIT_CAL && !substates_done) begin
            case (current_substate)

                // --------------------------------------------------------------
                // DONE_HANDSHAKE
                // Wait for TX REQ with encoding 0x18.
                // Send RSP until done_ack (our RSP accepted), then drop.
                // Assert done on REQ + 0x18 arrival.
                // --------------------------------------------------------------
                DONE_HANDSHAKE: begin
                    o_rx_encoding = 9'h18;
                    o_rx_sb_rsp   = done_ack ? 0 : 1;

                    if (i_sb_rx_req && i_rx_decoding == 9'h18) begin
                        o_done_mbinit_cal_rx = 1;
                        next_substate        = DONE_HANDSHAKE;
                    end else begin
                        next_substate = DONE_HANDSHAKE;
                    end
                end

                default: next_substate = DONE_HANDSHAKE;

            endcase
        end
    end

    // =========================================================================
    // Assertions
    // =========================================================================
`ifdef SIM

    property enc_done_handshake;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_CAL && current_substate == DONE_HANDSHAKE)
        |-> o_rx_encoding == 9'h18;
    endproperty
    ENC_DONE_HANDSHAKE : assert property (enc_done_handshake)
        else $error("ASSERT FAIL [ENC_DONE_HANDSHAKE]: wrong encoding in DONE_HANDSHAKE");

    property timeout_error;
        @(posedge i_clk) disable iff (i_reset)
        o_timer_8ms |-> o_train_error;
    endproperty
    TIMEOUT_TRAIN_ERROR : assert property (timeout_error)
        else $error("ASSERT FAIL [TIMEOUT_TRAIN_ERROR]: train_error not set on timeout");

    property rsp_raised;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_CAL &&
         current_substate == DONE_HANDSHAKE &&
         !done_ack && !substates_done)
        |-> o_rx_sb_rsp;
    endproperty
    RSP_RAISED : assert property (rsp_raised)
        else $error("ASSERT FAIL [RSP_RAISED]: rx_sb_rsp not asserted in DONE_HANDSHAKE");

    property rsp_dropped;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_CAL &&
         current_substate == DONE_HANDSHAKE && done_ack)
        |-> !o_rx_sb_rsp;
    endproperty
    RSP_DROPPED : assert property (rsp_dropped)
        else $error("ASSERT FAIL [RSP_DROPPED]: rx_sb_rsp still high after done_ack");

    property done_on_req;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_CAL &&
         current_substate == DONE_HANDSHAKE &&
         i_sb_rx_req && i_rx_decoding == 9'h18)
        |-> o_done_mbinit_cal_rx;
    endproperty
    DONE_CAL_RX : assert property (done_on_req)
        else $error("ASSERT FAIL [DONE_CAL_RX]: done not asserted on REQ + 0x18");

    property done_only_in_state;
        @(posedge i_clk) disable iff (i_reset)
        i_current_state != MBINIT_CAL |-> !o_done_mbinit_cal_rx;
    endproperty
    DONE_ONLY_IN_STATE : assert property (done_only_in_state)
        else $error("ASSERT FAIL [DONE_ONLY_IN_STATE]: done asserted outside MBINIT_CAL");

`endif

endmodule