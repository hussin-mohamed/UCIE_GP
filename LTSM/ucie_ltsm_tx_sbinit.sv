module ucie_ltsm_tx_sbinit #(
    parameter DECODING_WIDTH = 9,
    parameter DATA_WIDTH = 64
) (

    input                      i_clk,
    input                      i_reset,
    input [DECODING_WIDTH-1:0] i_tx_decoding,
    input                      i_sb_tx_req,
    input                      i_sb_tx_rsp,
    input                      i_sb_tx_done,
    input                      i_sb_ready,
    input [               3:0] i_current_state,
    input                      o_timer_8ms,
    input [DECODING_WIDTH-1:0] i_rx_decoding,

    output logic [DECODING_WIDTH-1:0] o_tx_encoding,
    output logic                      o_tx_sb_req,
    output logic                      o_tx_sb_rsp,      // we dont need this
    output logic                      o_tx_sb_done,
    output logic                      o_train_error,
    output logic                      o_sb_init_start,
    output logic                      o_done_sbinit_tx


);

  // Local Parameters for states names
  localparam SBINIT = 4'b0001;

  // Local Parameters for substates names
  localparam PATTERN_GENERATION = 3'b000;
  localparam OUT_OF_RESET_MSG = 3'b001;
  localparam DONE_HANDSHAKE = 3'b010;


  logic [               2:0] current_substate;  // current substate 
  logic [               2:0] next_substate;  // next substate

  logic                      done_ack;
  logic                      substates_done;
  logic [DECODING_WIDTH-1:0] o_tx_encoding_old;


  // State Memory Logic
  always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
      current_substate <= PATTERN_GENERATION;
      substates_done   <= 0;
    end else if (i_current_state != SBINIT) begin
      current_substate <= PATTERN_GENERATION;
      substates_done   <= 0;
    end else begin
      if (current_substate == DONE_HANDSHAKE && i_sb_tx_rsp && i_tx_decoding == 9'h0A) begin
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
    else if (o_tx_encoding[2:0] != o_tx_encoding_old[2:0]) done_ack <= 0;
    else if (i_sb_tx_done) done_ack <= 1;
    else if (i_sb_tx_rsp || i_sb_tx_req) begin
      done_ack <= 0;
    end
  end


  always_comb begin
    // add default case for latches
    o_tx_encoding = 9'h08;
    o_tx_sb_req = 0;
    o_tx_sb_rsp = 0;
    o_tx_sb_done = 0;
    o_train_error = 0;
    o_sb_init_start = 0;
    o_done_sbinit_tx = 0;
    next_substate = PATTERN_GENERATION;

    // TIMEOUT
    if (!substates_done && o_timer_8ms == 1) begin
      o_train_error = 1;
      next_substate = PATTERN_GENERATION;
    end else if (i_current_state == SBINIT) begin
      case (current_substate)
        PATTERN_GENERATION: begin
          o_tx_encoding = 9'h08;
          if (!substates_done) begin
            o_sb_init_start = 1'b1;

            if (i_sb_ready == 1) begin
              o_sb_init_start = 1'b0;
              next_substate   = OUT_OF_RESET_MSG;
            end else begin
              next_substate = PATTERN_GENERATION;
            end
          end
        end

        OUT_OF_RESET_MSG: begin
          o_tx_encoding = 9'h09;

          if (!substates_done) begin
            if (done_ack) o_tx_sb_req = 0;
            else o_tx_sb_req = 1;

            if (i_tx_decoding == 9'h09 || i_rx_decoding == 9'h08) next_substate = DONE_HANDSHAKE;
            else next_substate = OUT_OF_RESET_MSG;
          end
        end

        DONE_HANDSHAKE: begin
          o_tx_encoding = 9'h0A;

          if (!substates_done) begin
            if (done_ack) o_tx_sb_req = 0;
            else o_tx_sb_req = 1;

            if (i_sb_tx_rsp && i_tx_decoding == 9'h0A) begin
              next_substate    = PATTERN_GENERATION;
              o_done_sbinit_tx = 1;
            end else begin
              next_substate = DONE_HANDSHAKE;
            end
          end
        end
      endcase
    end
  end


  // Assertions 
  /*
`ifdef SIM

    // --------------------------------------------------------------------------
    // Encoding is correct for each substate
    // --------------------------------------------------------------------------
    property encoding_pattern_gen;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == SBINIT && current_substate == PATTERN_GENERATION)
        |-> o_tx_encoding == 9'h08;
    endproperty
    ENC_PATTERN_GEN : assert property (encoding_pattern_gen)
        else $error("ASSERT FAIL [ENC_PATTERN_GEN]: wrong encoding in PATTERN_GENERATION");

    property encoding_out_of_reset;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == SBINIT && current_substate == OUT_OF_RESET_MSG)
        |-> o_tx_encoding == 9'h09;
    endproperty
    ENC_OUT_OF_RESET : assert property (encoding_out_of_reset)
        else $error("ASSERT FAIL [ENC_OUT_OF_RESET]: wrong encoding in OUT_OF_RESET_MSG");

    property encoding_done_handshake;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == SBINIT && current_substate == DONE_HANDSHAKE)
        |-> o_tx_encoding == 9'h0A;
    endproperty
    ENC_DONE_HANDSHAKE : assert property (encoding_done_handshake)
        else $error("ASSERT FAIL [ENC_DONE_HANDSHAKE]: wrong encoding in DONE_HANDSHAKE");

    // --------------------------------------------------------------------------
    // Train error asserted on 8ms timeout, substate returns to start
    // --------------------------------------------------------------------------
    property timeout_sets_train_error;
        @(posedge i_clk) disable iff (i_reset)
        o_timer_8ms |-> o_train_error;
    endproperty
    TIMEOUT_TRAIN_ERROR : assert property (timeout_sets_train_error)
        else $error("ASSERT FAIL [TIMEOUT_TRAIN_ERROR]: train_error not set on 8ms timeout");

    property timeout_resets_substate;
        @(posedge i_clk) disable iff (i_reset)
        o_timer_8ms |=> current_substate == PATTERN_GENERATION;
    endproperty
    TIMEOUT_RESETS_SUBSTATE : assert property (timeout_resets_substate)
        else $error("ASSERT FAIL [TIMEOUT_RESETS_SUBSTATE]: substate not reset to PATTERN_GEN after timeout");

    // --------------------------------------------------------------------------
    // sb_init_start high in PATTERN_GENERATION while i_sb_ready not asserted
    // --------------------------------------------------------------------------
    property sb_init_start_active;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == SBINIT &&
         current_substate == PATTERN_GENERATION &&
         !i_sb_ready && !substates_done)
        |-> o_sb_init_start;
    endproperty
    SB_INIT_START_ACTIVE : assert property (sb_init_start_active)
        else $error("ASSERT FAIL [SB_INIT_START_ACTIVE]: sb_init_start not asserted in PATTERN_GEN");

    // --------------------------------------------------------------------------
    // done_sbinit_tx asserted when DONE_HANDSHAKE gets RSP + correct decoding
    // --------------------------------------------------------------------------
    property done_sbinit_condition;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == SBINIT &&
         current_substate == DONE_HANDSHAKE &&
         i_sb_tx_rsp && i_tx_decoding == 9'h0A)
        |-> o_done_sbinit_tx;
    endproperty
    DONE_SBINIT_TX : assert property (done_sbinit_condition)
        else $error("ASSERT FAIL [DONE_SBINIT_TX]: done_sbinit_tx not asserted at handshake completion");

    // --------------------------------------------------------------------------
    // REQ handshake:
    //   tx_sb_req must be high when in OUT_OF_RESET_MSG or DONE_HANDSHAKE
    //   and done_ack has not yet been received.
    //   tx_sb_req must drop the cycle after done_ack is set.
    // --------------------------------------------------------------------------
    property req_raised_when_needed;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == SBINIT &&
         (current_substate == OUT_OF_RESET_MSG || current_substate == DONE_HANDSHAKE) &&
         !done_ack)
        |-> o_tx_sb_req;
    endproperty
    REQ_RAISED : assert property (req_raised_when_needed)
        else $error("ASSERT FAIL [REQ_RAISED]: tx_sb_req not asserted when handshake pending");

    property req_dropped_after_done_ack;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == SBINIT &&
         (current_substate == OUT_OF_RESET_MSG || current_substate == DONE_HANDSHAKE) &&
         done_ack)
        |-> !o_tx_sb_req;
    endproperty
    REQ_DROPPED : assert property (req_dropped_after_done_ack)
        else $error("ASSERT FAIL [REQ_DROPPED]: tx_sb_req still high after done_ack received");

`endif

*/
endmodule
