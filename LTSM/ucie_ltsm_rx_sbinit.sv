`define SIM
module ucie_ltsm_rx_sbinit #(
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
    input                               i_sb_ready,
    input   [3:0]                       i_current_state,
    input                               o_timer_8ms,    

    output  logic [DECODING_WIDTH-1:0]  o_rx_encoding, 
    output  logic [DATA_WIDTH-1:0]      o_rx_data,
    output  logic [INFO_WIDTH-1:0]      o_rx_info,
    output  logic                       o_rx_sb_req,
    output  logic                       o_rx_sb_rsp,
    output  logic                       o_rx_sb_done,
    output  logic                       o_train_error,  
    output  logic                       o_sb_init_start,
    output  logic                       o_done_sbinit_rx
);

    // -------------------------------------------------------------------------
    // Local parameters
    // -------------------------------------------------------------------------
    localparam logic [3:0] SBINIT = 4'b0001;

    // RX SBINIT has only two substates — RX does not generate patterns,
    // it waits for TX to finish then completes the handshake
    localparam logic [2:0] WAIT_OUT_OF_RESET_MSG = 3'b000;
    localparam logic [2:0] DONE_HANDSHAKE        = 3'b001;

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
        if (i_reset) begin
            current_substate <= WAIT_OUT_OF_RESET_MSG;
            substates_done   <= 0;
        end else if (i_current_state != SBINIT) begin
            current_substate <= WAIT_OUT_OF_RESET_MSG;
            substates_done   <= 0;
        end else begin
            if (current_substate == DONE_HANDSHAKE &&
                i_rx_decoding == 9'h09 && i_sb_rx_req) begin
                substates_done   <= 1;
                current_substate <= DONE_HANDSHAKE;
            end else begin
                current_substate <= next_substate;
            end
        end
    end

    // -------------------------------------------------------------------------
    // RSP / Done handshake register
    // RX mirror of TX done_ack: latches when i_sb_rx_done arrives
    // (our RSP was accepted by sideband), clears when next i_sb_rx_req comes in
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
    // -------------------------------------------------------------------------
    always_comb begin
        o_rx_encoding   = 9'h08;
        o_rx_data       = '0;       // FIX 9: was never driven
        o_rx_info       = '0;       // FIX 9: was never driven
        o_rx_sb_req     = 0;
        o_rx_sb_rsp     = 0;
        o_rx_sb_done    = 0;
        o_train_error   = 0;
        o_sb_init_start = 0;
        o_done_sbinit_rx = 0;
        next_substate   = WAIT_OUT_OF_RESET_MSG;

        if (!substates_done && o_timer_8ms) begin
            o_train_error = 1;
            next_substate = WAIT_OUT_OF_RESET_MSG;
        end
        else if (i_current_state == SBINIT) begin
            case (current_substate)

                // --------------------------------------------------------------
                // WAIT_OUT_OF_RESET_MSG
                // RX waits for TX to send its out-of-reset message (encoding 0x09).
                // Encoding held at 0x08 while waiting.
                // --------------------------------------------------------------
                WAIT_OUT_OF_RESET_MSG: begin
                    o_rx_encoding = 9'h08;

                    if (!substates_done) begin
                        if (i_rx_decoding == 9'h08) next_substate = DONE_HANDSHAKE;
                        else next_substate = WAIT_OUT_OF_RESET_MSG;
                    end
                end

                // --------------------------------------------------------------
                // DONE_HANDSHAKE
                // RX sends RSP to acknowledge the done message from TX.
                // --------------------------------------------------------------
                DONE_HANDSHAKE: begin
                    o_rx_encoding = 9'h09;
                    if (!substates_done) begin
                        o_rx_sb_rsp = (done_ack && i_rx_decoding == 9'h09) ? 0 : 1;

                        if (i_rx_decoding == 9'h09 && i_sb_rx_req) begin
                            next_substate    = WAIT_OUT_OF_RESET_MSG;
                            o_done_sbinit_rx = 1;
                        end else begin
                            next_substate = DONE_HANDSHAKE;
                        end
                    end
                end

                default: next_substate = WAIT_OUT_OF_RESET_MSG;

            endcase
        end
    end

    // =========================================================================
    // Assertions
    // =========================================================================
    /*
`ifdef SIM

    // --------------------------------------------------------------------------
    // Encoding correct per substate
    // --------------------------------------------------------------------------
    property encoding_wait;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == SBINIT && current_substate == WAIT_OUT_OF_RESET_MSG)
        |-> o_rx_encoding == 9'h08;
    endproperty
    ENC_WAIT_OUT_OF_RESET : assert property (encoding_wait)
        else $error("ASSERT FAIL [ENC_WAIT_OUT_OF_RESET]: wrong encoding in WAIT_OUT_OF_RESET_MSG");

    property encoding_done_handshake;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == SBINIT && current_substate == DONE_HANDSHAKE)
        |-> o_rx_encoding == 9'h09;
    endproperty
    ENC_DONE_HANDSHAKE : assert property (encoding_done_handshake)
        else $error("ASSERT FAIL [ENC_DONE_HANDSHAKE]: wrong encoding in DONE_HANDSHAKE");

    // --------------------------------------------------------------------------
    // Train error on 8ms timeout — substate resets to start
    // --------------------------------------------------------------------------
    property timeout_sets_train_error;
        @(posedge i_clk) disable iff (i_reset)
        o_timer_8ms |-> o_train_error;
    endproperty
    TIMEOUT_TRAIN_ERROR : assert property (timeout_sets_train_error)
        else $error("ASSERT FAIL [TIMEOUT_TRAIN_ERROR]: train_error not set on 8ms timeout");

    property timeout_resets_substate;
        @(posedge i_clk) disable iff (i_reset)
        o_timer_8ms |=> current_substate == WAIT_OUT_OF_RESET_MSG;
    endproperty
    TIMEOUT_RESETS_SUBSTATE : assert property (timeout_resets_substate)
        else $error("ASSERT FAIL [TIMEOUT_RESETS_SUBSTATE]: substate not reset after timeout");

    // --------------------------------------------------------------------------
    // RSP raised while in DONE_HANDSHAKE and done_ack not yet received;
    // RSP dropped once done_ack latches (i_sb_rx_done received)
    // --------------------------------------------------------------------------
    property rsp_raised_when_needed;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == SBINIT &&
         current_substate == DONE_HANDSHAKE &&
         !done_ack && !substates_done)
        |-> o_rx_sb_rsp;
    endproperty
    RSP_RAISED : assert property (rsp_raised_when_needed)
        else $error("ASSERT FAIL [RSP_RAISED]: rx_sb_rsp not asserted when handshake pending");

    property rsp_dropped_after_done_ack;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == SBINIT &&
         current_substate == DONE_HANDSHAKE &&
         done_ack)
        |-> !o_rx_sb_rsp;
    endproperty
    RSP_DROPPED : assert property (rsp_dropped_after_done_ack)
        else $error("ASSERT FAIL [RSP_DROPPED]: rx_sb_rsp still high after done_ack received");

    // --------------------------------------------------------------------------
    // Done asserted as combinational pulse when REQ + correct decoding arrive
    // --------------------------------------------------------------------------
    property done_on_req;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == SBINIT &&
         current_substate == DONE_HANDSHAKE &&
         i_rx_decoding == 9'h09 && i_sb_rx_req)
        |-> o_done_sbinit_rx;
    endproperty
    DONE_SBINIT_RX : assert property (done_on_req)
        else $error("ASSERT FAIL [DONE_SBINIT_RX]: done not asserted on REQ + 0x09");

    // --------------------------------------------------------------------------
    // Done never asserts outside SBINIT state
    // --------------------------------------------------------------------------
    property done_only_in_state;
        @(posedge i_clk) disable iff (i_reset)
        i_current_state != SBINIT |-> !o_done_sbinit_rx;
    endproperty
    DONE_ONLY_IN_STATE : assert property (done_only_in_state)
        else $error("ASSERT FAIL [DONE_ONLY_IN_STATE]: done asserted outside SBINIT");

`endif
*/
endmodule