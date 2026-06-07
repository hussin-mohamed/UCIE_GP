module ucie_ltsm_tx_mbinit_reversal #(
    parameter DECODING_WIDTH = 9,
    parameter DATA_WIDTH = 64,
    parameter INFO_WIDTH = 16
) (

    input                      i_clk,
    input                      i_reset,
    input [DECODING_WIDTH-1:0] i_tx_decoding,
    input [    DATA_WIDTH-1:0] i_tx_data,
    input [    INFO_WIDTH-1:0] i_tx_info,
    input                      i_sb_tx_req,
    input                      i_sb_tx_rsp,
    input                      i_sb_tx_done,
    input                      i_tx_done,
    input                      init_train_en,
    input                      o_rx_sb_rsp,
    input [               3:0] i_current_state,
    input                      o_timer_8ms,

    output logic [DECODING_WIDTH-1:0] o_tx_encoding,
    output logic [    DATA_WIDTH-1:0] o_tx_data,
    output logic [    INFO_WIDTH-1:0] o_tx_info,
    output logic                      o_tx_sb_req,
    output logic                      o_tx_sb_rsp,
    output logic                      o_tx_sb_done,
    output logic                      o_train_error,
    output logic                      o_done_mbinit_reversal_tx
);

  logic [               2:0] current_substate;
  logic [               2:0] next_substate;
  logic                      done_ack;
  logic                      substates_done;
  logic [DECODING_WIDTH-1:0] o_tx_encoding_old;

  // -------------------------------------------------------------------------
  // Combinational popcount of i_tx_data[15:0]
  //   Counts the number of '1' bits in the first 16 lanes of the result word
  //   delivered by the far end in the RESULT_HANDSHAKE RSP.
  //   5 bits required: maximum value is 16 (all lanes good).
  //   Threshold: count <= 8 → majority bad → apply reversal
  //              count >  8 → majority good → proceed to DONE_HANDSHAKE
  // -------------------------------------------------------------------------
  logic [               4:0] w_popcount;

  always_comb begin
    w_popcount = '0;
    for (int i = 0; i < 16; i++) w_popcount = w_popcount + {4'b0, i_tx_data[i]};
  end

  // -------------------------------------------------------------------------
  // Local Parameters
  // -------------------------------------------------------------------------
  localparam MBINIT_REVERSAL = 4'b0110;

  localparam INIT_HANDSHAKE = 3'b000;
  localparam CLEAR_LOG_HANDSHAKE = 3'b001;
  localparam LANE_ID_GENERATION = 3'b010;
  localparam RESULT_HANDSHAKE = 3'b011;
  localparam APPLY_REVERSAL = 3'b100;
  localparam DONE_HANDSHAKE = 3'b101;

  // -------------------------------------------------------------------------
  // State memory
  // -------------------------------------------------------------------------
  always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
      current_substate <= INIT_HANDSHAKE;
      substates_done   <= 0;
    end else if (i_current_state != MBINIT_REVERSAL) begin
      current_substate <= INIT_HANDSHAKE;
      substates_done   <= 0;
    end else begin
      if (current_substate == DONE_HANDSHAKE && i_sb_tx_rsp && i_tx_decoding == 9'h35) begin
        substates_done   <= 1;
        current_substate <= DONE_HANDSHAKE;
      end else begin
        current_substate <= next_substate;
      end
    end
  end

  always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
      o_tx_encoding_old <= 0;
    end else begin
      o_tx_encoding_old <= o_tx_encoding;
    end
  end


  // REQ & Done Handshake 
  always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) done_ack <= 1;
    else if (o_tx_encoding[2:0] != o_tx_encoding_old[2:0]) done_ack = 0;
    else if (i_sb_tx_done) begin
      done_ack <= 1;
    end else if (i_sb_tx_rsp || i_sb_tx_req) begin
      done_ack <= 0;
    end
  end
  // -------------------------------------------------------------------------
  // Combinational next-state / output logic
  // -------------------------------------------------------------------------
  always_comb begin
    o_tx_encoding             = 9'h30;
    o_tx_data                 = '0;
    o_tx_info                 = '0;
    o_tx_sb_req               = 0;
    o_tx_sb_rsp               = 0;
    o_tx_sb_done              = 0;
    o_train_error             = 0;
    o_done_mbinit_reversal_tx = 0;
    next_substate             = INIT_HANDSHAKE;

    if (!substates_done && o_timer_8ms) begin
      o_train_error = 1;
      next_substate = INIT_HANDSHAKE;
    end else if (i_current_state == MBINIT_REVERSAL) begin
      case (current_substate)

        INIT_HANDSHAKE: begin
          o_tx_encoding = 9'h30;
          if (!substates_done) begin
            o_tx_sb_req = ~done_ack;
            if (i_sb_tx_rsp && i_tx_decoding == 9'h30) next_substate = CLEAR_LOG_HANDSHAKE;
            else next_substate = INIT_HANDSHAKE;
          end
        end

        CLEAR_LOG_HANDSHAKE: begin
          o_tx_encoding = 9'h31;
          if (!substates_done) begin
            o_tx_sb_req = ~done_ack;
            if (i_sb_tx_rsp && i_tx_decoding == 9'h31) next_substate = LANE_ID_GENERATION;
            else next_substate = CLEAR_LOG_HANDSHAKE;
          end
        end

        LANE_ID_GENERATION: begin
          o_tx_encoding = 9'h32;
          if (!substates_done) begin
            // o_tx_sb_req = ~done_ack;
            if (i_tx_done) next_substate = RESULT_HANDSHAKE;
            else next_substate = LANE_ID_GENERATION;
          end
        end

        RESULT_HANDSHAKE: begin
          o_tx_encoding = 9'h33;
          if (!substates_done) begin
            o_tx_sb_req = ~done_ack;
            // w_popcount is always valid; only use it when RSP arrives
            if (i_sb_tx_rsp && i_tx_decoding == 9'h33) begin
              if (w_popcount <= 5'd8) next_substate = APPLY_REVERSAL;
              else next_substate = DONE_HANDSHAKE;
            end else begin
              next_substate = RESULT_HANDSHAKE;
            end
          end
        end

        APPLY_REVERSAL: begin
          o_tx_encoding = 9'h34;
          if (!substates_done) begin
            // o_tx_sb_req = ~done_ack;
            if (i_tx_done) next_substate = CLEAR_LOG_HANDSHAKE;
            else next_substate = APPLY_REVERSAL;
          end
        end

        DONE_HANDSHAKE: begin
          o_tx_encoding = 9'h35;
          if (!substates_done) begin
            o_tx_sb_req = ~done_ack;
            if (i_sb_tx_rsp && i_tx_decoding == 9'h35) begin
              o_done_mbinit_reversal_tx = 1;
              next_substate             = INIT_HANDSHAKE;
            end else begin
              next_substate = DONE_HANDSHAKE;
            end
          end
        end

        default: next_substate = INIT_HANDSHAKE;
      endcase
    end
  end

  // ==========================================================================
  // Assertions
  // ==========================================================================
  /*
`ifdef SIM

    property encoding_check(substate, logic [8:0] expected_enc);
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REVERSAL && current_substate == substate)
        |-> o_tx_encoding == expected_enc;
    endproperty

    ENC_INIT_HANDSHAKE      : assert property (encoding_check(INIT_HANDSHAKE,      9'h30))
        else $error("ASSERT FAIL [ENC_INIT_HANDSHAKE]: wrong encoding");
    ENC_CLEAR_LOG_HANDSHAKE : assert property (encoding_check(CLEAR_LOG_HANDSHAKE, 9'h31))
        else $error("ASSERT FAIL [ENC_CLEAR_LOG_HANDSHAKE]: wrong encoding");
    ENC_LANE_ID_GENERATION  : assert property (encoding_check(LANE_ID_GENERATION,  9'h32))
        else $error("ASSERT FAIL [ENC_LANE_ID_GENERATION]: wrong encoding");
    ENC_RESULT_HANDSHAKE    : assert property (encoding_check(RESULT_HANDSHAKE,    9'h33))
        else $error("ASSERT FAIL [ENC_RESULT_HANDSHAKE]: wrong encoding");
    ENC_APPLY_REVERSAL      : assert property (encoding_check(APPLY_REVERSAL,      9'h34))
        else $error("ASSERT FAIL [ENC_APPLY_REVERSAL]: wrong encoding");
    ENC_DONE_HANDSHAKE      : assert property (encoding_check(DONE_HANDSHAKE,      9'h35))
        else $error("ASSERT FAIL [ENC_DONE_HANDSHAKE]: wrong encoding");

    property timeout_sets_train_error;
        @(posedge i_clk) disable iff (i_reset)
        o_timer_8ms |-> o_train_error;
    endproperty
    TIMEOUT_TRAIN_ERROR : assert property (timeout_sets_train_error)
        else $error("ASSERT FAIL [TIMEOUT_TRAIN_ERROR]: train_error not set on 8ms timeout");

    property timeout_resets_substate;
        @(posedge i_clk) disable iff (i_reset)
        o_timer_8ms |=> current_substate == INIT_HANDSHAKE;
    endproperty
    TIMEOUT_RESETS_SUBSTATE : assert property (timeout_resets_substate)
        else $error("ASSERT FAIL [TIMEOUT_RESETS_SUBSTATE]: substate not reset after timeout");

    // count <= 8 → reversal needed → APPLY_REVERSAL
    property reversal_needed;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REVERSAL &&
         current_substate == RESULT_HANDSHAKE &&
         i_sb_tx_rsp && i_tx_decoding == 9'h33 && w_popcount <= 5'd8)
        |=> current_substate == APPLY_REVERSAL;
    endproperty
    REVERSAL_NEEDED : assert property (reversal_needed)
        else $error("ASSERT FAIL [REVERSAL_NEEDED]: did not enter APPLY_REVERSAL when popcount<=8");

    // count > 8 → no reversal → DONE_HANDSHAKE
    property reversal_not_needed;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REVERSAL &&
         current_substate == RESULT_HANDSHAKE &&
         i_sb_tx_rsp && i_tx_decoding == 9'h33 && w_popcount > 5'd8)
        |=> current_substate == DONE_HANDSHAKE;
    endproperty
    REVERSAL_NOT_NEEDED : assert property (reversal_not_needed)
        else $error("ASSERT FAIL [REVERSAL_NOT_NEEDED]: did not advance to DONE when popcount>8");

    property apply_reversal_loops_back;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REVERSAL &&
         current_substate == APPLY_REVERSAL && i_tx_done)
        |=> current_substate == CLEAR_LOG_HANDSHAKE;
    endproperty
    APPLY_REVERSAL_LOOPS_BACK : assert property (apply_reversal_loops_back)
        else $error("ASSERT FAIL [APPLY_REVERSAL_LOOPS_BACK]: did not return to CLEAR_LOG after reversal");

    property done_on_rsp;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REVERSAL &&
         current_substate == DONE_HANDSHAKE &&
         i_sb_tx_rsp && i_tx_decoding == 9'h35)
        |-> o_done_mbinit_reversal_tx;
    endproperty
    DONE_REVERSAL : assert property (done_on_rsp)
        else $error("ASSERT FAIL [DONE_REVERSAL]: done not asserted on RSP + 0x35");

    property req_raised_when_needed;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REVERSAL && !done_ack && !substates_done)
        |-> o_tx_sb_req;
    endproperty
    REQ_RAISED : assert property (req_raised_when_needed)
        else $error("ASSERT FAIL [REQ_RAISED]: tx_sb_req not asserted when handshake pending");

    property req_dropped_after_done_ack;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REVERSAL && done_ack)
        |-> !o_tx_sb_req;
    endproperty
    REQ_DROPPED : assert property (req_dropped_after_done_ack)
        else $error("ASSERT FAIL [REQ_DROPPED]: tx_sb_req still high after done_ack");

    property done_only_in_state;
        @(posedge i_clk) disable iff (i_reset)
        i_current_state != MBINIT_REVERSAL |-> !o_done_mbinit_reversal_tx;
    endproperty
    DONE_ONLY_IN_STATE : assert property (done_only_in_state)
        else $error("ASSERT FAIL [DONE_ONLY_IN_STATE]: done asserted outside MBINIT_REVERSAL");

`endif
*/
endmodule
