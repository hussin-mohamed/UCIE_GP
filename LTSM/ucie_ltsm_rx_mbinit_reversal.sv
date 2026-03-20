`define SIM
module ucie_ltsm_rx_mbinit_reversal #(
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
    input   [DATA_WIDTH-1:0]            i_pattern_detection_results,
    output  logic [DECODING_WIDTH-1:0]  o_rx_encoding,
    output  logic [DATA_WIDTH-1:0]      o_rx_data,
    output  logic [INFO_WIDTH-1:0]      o_rx_info,
    output  logic                       o_rx_sb_req,
    output  logic                       o_rx_sb_rsp,
    output  logic                       o_rx_sb_done,
    output  logic                       o_train_error,
    output  logic                       o_done_mbinit_reversal_rx
);

    // -------------------------------------------------------------------------
    // Local parameters
    // -------------------------------------------------------------------------
    localparam logic [3:0] MBINIT_REVERSAL = 4'b0110;

    // REVERSAL RX substates:
    //   INIT_HANDSHAKE      : wait for TX REQ 0x30, send RSP
    //   CLEAR_LOG_HANDSHAKE : wait for TX REQ 0x31, send RSP (re-entered after reversal)
    //   LANE_ID_DETECTION   : RX detects lane IDs; on i_rx_done or early TX REQ →
    //                         go to WAIT_RESULT_REQ / SEND_RESP
    //   WAIT_RESULT_REQ     : hold results, wait for TX to ask (0x33)
    //   SEND_RESP           : send lane count in o_rx_data, RSP on 0x33
    //                         count<=8 → TX will apply reversal → loop back to CLEAR_LOG
    //                         count>8  → TX proceeds → DONE_HANDSHAKE
    //   DONE_HANDSHAKE      : wait for TX REQ 0x35, send RSP, assert done
    localparam logic [2:0] INIT_HANDSHAKE      = 3'b000;
    localparam logic [2:0] CLEAR_LOG_HANDSHAKE = 3'b001;
    localparam logic [2:0] LANE_ID_DETECTION   = 3'b010;
    localparam logic [2:0] WAIT_RESULT_REQ     = 3'b011;
    localparam logic [2:0] SEND_RESP           = 3'b100;
    localparam logic [2:0] DONE_HANDSHAKE      = 3'b101;

    // -------------------------------------------------------------------------
    // Internal signals
    // -------------------------------------------------------------------------
    logic [2:0] current_substate;
    logic [2:0] next_substate;
    logic       done_ack;
    logic       substates_done;

    logic [DATA_WIDTH-1:0] i_pattern_detection_results_reg;
    logic [3:0]            count;   // number of good lanes counted from i_rx_data

    // -------------------------------------------------------------------------
    // State memory + result latch
    // -------------------------------------------------------------------------
    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset || i_current_state != MBINIT_REVERSAL) begin
            current_substate                <= INIT_HANDSHAKE;
            substates_done                  <= 0;
            i_pattern_detection_results_reg <= '0;
        end else begin
            current_substate <= next_substate;

            // Latch detection results when LANE_ID_DETECTION finishes
            if ((current_substate == LANE_ID_DETECTION && i_rx_done) ||
                (current_substate == LANE_ID_DETECTION &&
                 i_sb_rx_req && i_rx_decoding == 9'h34))
                i_pattern_detection_results_reg <= i_pattern_detection_results;

            // Latch substates_done on DONE_HANDSHAKE completion
            if (current_substate == DONE_HANDSHAKE &&
                i_sb_rx_req && i_rx_decoding == 9'h35)
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
    // Count good lanes from i_rx_data[14:0] when RSP arrives with 0x33
    // (mirrors TX reversal count logic — determines if reversal is needed)
    // count <= 8: majority bad → TX will apply reversal → RX loops to CLEAR_LOG
    // count >  8: majority good → TX proceeds to done → RX goes to DONE_HANDSHAKE
    // -------------------------------------------------------------------------
    always_comb begin
        count = 4'd0;
        if (i_sb_rx_done && i_rx_decoding == 9'h33)
            for (int i = 0; i < 15; i++)
                count = count + i_pattern_detection_results_reg[i];
                // add done signal here
    end

    // -------------------------------------------------------------------------
    // Next-state / output combinational logic
    //
    // Encoding map:
    //   INIT_HANDSHAKE      : 0x30
    //   CLEAR_LOG_HANDSHAKE : 0x31
    //   LANE_ID_DETECTION   : 0x32
    //   WAIT_RESULT_REQ     : 0x33
    //   SEND_RESP           : 0x33 (send lane data, count determines TX's next move)
    //   DONE_HANDSHAKE      : 0x35 (FIX 16: original had 0x34 which is APPLY_REVERSAL on TX)
    // -------------------------------------------------------------------------
    always_comb begin
        o_rx_encoding             = 9'h30;
        o_rx_data                 = '0;
        o_rx_info                 = '0;
        o_rx_sb_req               = 0;
        o_rx_sb_rsp               = 0;
        o_rx_sb_done              = 0;
        o_train_error             = 0;
        o_done_mbinit_reversal_rx = 0;
        next_substate             = INIT_HANDSHAKE;

        if (o_timer_8ms) begin
            o_train_error = 1;
            next_substate = INIT_HANDSHAKE;
        end
        else if (i_current_state == MBINIT_REVERSAL && !substates_done) begin
            case (current_substate)

                INIT_HANDSHAKE: begin
                    o_rx_encoding = 9'h30;
                    o_rx_sb_rsp   = done_ack ? 0 : 1;

                    if (i_sb_rx_req && i_rx_decoding == 9'h30)
                        next_substate = CLEAR_LOG_HANDSHAKE;
                    else
                        next_substate = INIT_HANDSHAKE;
                end

                // Re-entered from SEND_RESP when TX applies reversal
                CLEAR_LOG_HANDSHAKE: begin
                    o_rx_encoding = 9'h31;
                    o_rx_sb_rsp   = done_ack ? 0 : 1;

                    if (i_sb_rx_req && i_rx_decoding == 9'h31)
                        next_substate = LANE_ID_DETECTION;
                    else
                        next_substate = CLEAR_LOG_HANDSHAKE;
                end

                LANE_ID_DETECTION: begin
                    o_rx_encoding = 9'h32;

                    if (i_rx_done) begin
                        next_substate = WAIT_RESULT_REQ;
                    end else if (i_sb_rx_req && i_rx_decoding == 9'h32) begin
                        o_rx_sb_rsp   = 1;
                        next_substate = SEND_RESP;
                    end else begin
                        next_substate = LANE_ID_DETECTION;
                    end
                end

                WAIT_RESULT_REQ: begin
                    o_rx_encoding = 9'h33;
                    o_rx_sb_rsp   = done_ack ? 0 : 1;

                    if (i_sb_rx_req && i_rx_decoding == 9'h33)
                        next_substate = SEND_RESP;
                    else
                        next_substate = WAIT_RESULT_REQ;
                end

                // Send lane detection data so TX can compute count and decide
                // whether to apply reversal. RX mirrors TX's decision:
                //   count <= 8: reversal will be applied → loop back to CLEAR_LOG
                //   count >  8: no reversal → proceed to DONE_HANDSHAKE
                // count is computed combinatorially above.
                SEND_RESP: begin
                    o_rx_encoding = 9'h34;
                    o_rx_data     = i_pattern_detection_results_reg;
                    o_rx_sb_rsp   = 1;

                  if (i_sb_rx_done && i_rx_decoding == 9'h34) begin
                    // dont look at count till done is asserted
//                         if (count <= 8)
//                             next_substate = CLEAR_LOG_HANDSHAKE; // reversal applied, retry
//                         else
                            next_substate = DONE_HANDSHAKE;      // majority good, proceed
                    end else begin
                        next_substate = SEND_RESP;
                    end
                end

                DONE_HANDSHAKE: begin
                    o_rx_encoding = 9'h35;
                    o_rx_sb_rsp   = done_ack ? 0 : 1;

                    if (i_sb_rx_req && i_rx_decoding == 9'h35) begin
                        o_done_mbinit_reversal_rx = 1;
                        next_substate             = INIT_HANDSHAKE;
                    end else begin
                        next_substate = DONE_HANDSHAKE;
                    end
                end

                default: next_substate = INIT_HANDSHAKE;

            endcase
        end
    end

    // =========================================================================
    // Assertions
    // =========================================================================
`ifdef SIM

    property enc_check(substate, logic [8:0] enc);
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REVERSAL && current_substate == substate)
        |-> o_rx_encoding == enc;
    endproperty

    ENC_INIT_HANDSHAKE      : assert property (enc_check(INIT_HANDSHAKE,      9'h30))
        else $error("ASSERT FAIL [ENC_INIT_HANDSHAKE]: wrong encoding");
    ENC_CLEAR_LOG_HANDSHAKE : assert property (enc_check(CLEAR_LOG_HANDSHAKE, 9'h31))
        else $error("ASSERT FAIL [ENC_CLEAR_LOG_HANDSHAKE]: wrong encoding");
    ENC_LANE_ID_DETECTION   : assert property (enc_check(LANE_ID_DETECTION,   9'h32))
        else $error("ASSERT FAIL [ENC_LANE_ID_DETECTION]: wrong encoding");
    ENC_WAIT_RESULT_REQ     : assert property (enc_check(WAIT_RESULT_REQ,     9'h33))
        else $error("ASSERT FAIL [ENC_WAIT_RESULT_REQ]: wrong encoding");
    ENC_DONE_HANDSHAKE      : assert property (enc_check(DONE_HANDSHAKE,      9'h35))
        else $error("ASSERT FAIL [ENC_DONE_HANDSHAKE]: wrong encoding");

    property timeout_error;
        @(posedge i_clk) disable iff (i_reset)
        o_timer_8ms |-> o_train_error;
    endproperty
    TIMEOUT_TRAIN_ERROR : assert property (timeout_error)
        else $error("ASSERT FAIL [TIMEOUT_TRAIN_ERROR]: train_error not set on timeout");

    property timeout_reset_sub;
        @(posedge i_clk) disable iff (i_reset)
        o_timer_8ms |=> current_substate == INIT_HANDSHAKE;
    endproperty
    TIMEOUT_RESETS_SUBSTATE : assert property (timeout_reset_sub)
        else $error("ASSERT FAIL [TIMEOUT_RESETS_SUBSTATE]: substate not reset after timeout");

    // count <= 8 → loop back to CLEAR_LOG (reversal needed)
    property reversal_loops_back;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REVERSAL &&
         current_substate == SEND_RESP &&
         i_sb_rx_done && i_rx_decoding == 9'h33 && count <= 8)
        |=> current_substate == CLEAR_LOG_HANDSHAKE;
    endproperty
    REVERSAL_LOOPS_BACK : assert property (reversal_loops_back)
        else $error("ASSERT FAIL [REVERSAL_LOOPS_BACK]: did not loop to CLEAR_LOG when count<=8");

    // count > 8 → proceed to DONE_HANDSHAKE
    property reversal_not_needed;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REVERSAL &&
         current_substate == SEND_RESP &&
         i_sb_rx_done && i_rx_decoding == 9'h33 && count > 8)
        |=> current_substate == DONE_HANDSHAKE;
    endproperty

    property done_on_req;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REVERSAL &&
         current_substate == DONE_HANDSHAKE &&
         i_sb_rx_req && i_rx_decoding == 9'h35)
        |-> o_done_mbinit_reversal_rx;
    endproperty
    DONE_REVERSAL_RX : assert property (done_on_req)
        else $error("ASSERT FAIL [DONE_REVERSAL_RX]: done not asserted on REQ + 0x35");

    property done_only_in_state;
        @(posedge i_clk) disable iff (i_reset)
        i_current_state != MBINIT_REVERSAL |-> !o_done_mbinit_reversal_rx;
    endproperty
    DONE_ONLY_IN_STATE : assert property (done_only_in_state)
        else $error("ASSERT FAIL [DONE_ONLY_IN_STATE]: done asserted outside MBINIT_REVERSAL");

`endif

endmodule