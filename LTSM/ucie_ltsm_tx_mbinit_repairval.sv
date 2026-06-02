module ucie_ltsm_tx_mbinit_repairval #(
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
    output logic                      o_done_mbinit_repairval_tx


);


  logic [               2:0] current_substate;  // current substate 
  logic [               2:0] next_substate;  // next substate

  logic                      done_ack;
  logic                      substates_done;
  logic [DECODING_WIDTH-1:0] o_tx_encoding_old;


  // Local Parameters for states names
  localparam MBINIT_REPAIRVAL = 4'b0101;


  // Local Parameters for states names (REAPIRVAL)
  localparam INIT_HANDSHAKE = 3'b000;
  localparam PATTERN_GENERATION = 3'b001;
  localparam RESULT_HANDSHAKE = 3'b010;
  localparam DONE_HANDSHAKE = 3'b011;


  // State Memory Logic
  always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
      current_substate <= INIT_HANDSHAKE;
      substates_done   <= 0;
    end else if (i_current_state != MBINIT_REPAIRVAL) begin
      current_substate <= INIT_HANDSHAKE;
      substates_done   <= 0;
    end else begin
      if (current_substate == DONE_HANDSHAKE && i_sb_tx_rsp && i_tx_decoding == 9'h2B) begin
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


  always_comb begin

    o_tx_encoding = 9'h28;
    o_tx_sb_req = 0;
    o_tx_sb_rsp = 0;
    o_tx_sb_done = 0;
    o_train_error = 0;
    o_tx_info = 0;
    o_done_mbinit_repairval_tx = 0;
    next_substate = INIT_HANDSHAKE;

    // TIMEOUT
    if (!substates_done && o_timer_8ms == 1) begin
      o_train_error = 1;
      next_substate = INIT_HANDSHAKE;
    end else if (i_current_state == MBINIT_REPAIRVAL) begin
      case (current_substate)
        INIT_HANDSHAKE: begin
          o_tx_encoding = 9'h28;
          o_tx_info = 0;  // added

          if (!substates_done) begin
            if (done_ack) o_tx_sb_req = 0;
            else o_tx_sb_req = 1;

            if (i_sb_tx_rsp && i_tx_decoding == 9'h28) next_substate = PATTERN_GENERATION;
            else next_substate = INIT_HANDSHAKE;
          end
        end

        PATTERN_GENERATION: begin
          o_tx_encoding = 9'h29;

          if (!substates_done) begin
            // if (done_ack) o_tx_sb_req = 0;
            // else o_tx_sb_req = 1;

            if (i_tx_done) next_substate = RESULT_HANDSHAKE;
            else next_substate = PATTERN_GENERATION;
          end
        end

        RESULT_HANDSHAKE: begin
          o_tx_encoding = 9'h2A;
          o_tx_info = 0;  //added

          if (!substates_done) begin
            if (done_ack) o_tx_sb_req = 0;
            else o_tx_sb_req = 1;

            if (i_sb_tx_rsp && i_tx_decoding == 9'h2A) begin
              if (!(&i_tx_info[0])) begin
                o_train_error = 1;
                next_substate = INIT_HANDSHAKE;
              end else begin
                o_train_error = 0;
                next_substate = DONE_HANDSHAKE;
              end
            end else next_substate = RESULT_HANDSHAKE;
          end
        end

        DONE_HANDSHAKE: begin
          o_tx_encoding = 9'h2B;

          if (!substates_done) begin
            if (done_ack) o_tx_sb_req = 0;
            else o_tx_sb_req = 1;

            if (i_sb_tx_rsp && i_tx_decoding == 9'h2B) begin
              next_substate              = INIT_HANDSHAKE;
              o_done_mbinit_repairval_tx = 1;
            end else next_substate = DONE_HANDSHAKE;
          end
        end
      endcase
    end


  end

  // ==========================================================================
  // Assertions
  // ==========================================================================
  /*
`ifdef SIM

    // --------------------------------------------------------------------------
    // Encoding correct per substate
    // --------------------------------------------------------------------------
    property encoding_check(substate, logic [8:0] expected_enc);
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRVAL && current_substate == substate)
        |-> o_tx_encoding == expected_enc;
    endproperty

    ENC_INIT_HANDSHAKE     : assert property (encoding_check(INIT_HANDSHAKE,     9'h28))
        else $error("ASSERT FAIL [ENC_INIT_HANDSHAKE]: wrong encoding in INIT_HANDSHAKE");
    ENC_PATTERN_GENERATION : assert property (encoding_check(PATTERN_GENERATION, 9'h29))
        else $error("ASSERT FAIL [ENC_PATTERN_GENERATION]: wrong encoding in PATTERN_GENERATION");
    ENC_RESULT_HANDSHAKE   : assert property (encoding_check(RESULT_HANDSHAKE,   9'h2A))
        else $error("ASSERT FAIL [ENC_RESULT_HANDSHAKE]: wrong encoding in RESULT_HANDSHAKE");
    ENC_DONE_HANDSHAKE     : assert property (encoding_check(DONE_HANDSHAKE,     9'h2B))
        else $error("ASSERT FAIL [ENC_DONE_HANDSHAKE]: wrong encoding in DONE_HANDSHAKE");

    // --------------------------------------------------------------------------
    // Train error on 8ms timeout — substate resets next cycle
    // --------------------------------------------------------------------------
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

    // --------------------------------------------------------------------------
    // Train error on bad lane result in RESULT_HANDSHAKE
    // i_tx_info[1:0] covers 2 data lanes — any 0 bit means a lane failed
    // --------------------------------------------------------------------------
    property result_bad_lanes_train_error;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRVAL &&
         current_substate == RESULT_HANDSHAKE &&
         i_sb_tx_rsp && i_tx_decoding == 9'h2A &&
         !(&i_tx_info[1:0]))
        |-> o_train_error;
    endproperty
    RESULT_BAD_LANES_ERROR : assert property (result_bad_lanes_train_error)
        else $error("ASSERT FAIL [RESULT_BAD_LANES_ERROR]: train_error not set on bad lane result");

    property result_bad_lanes_restart;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRVAL &&
         current_substate == RESULT_HANDSHAKE &&
         i_sb_tx_rsp && i_tx_decoding == 9'h2A &&
         !(&i_tx_info[1:0]))
        |=> current_substate == INIT_HANDSHAKE;
    endproperty
    RESULT_BAD_LANES_RESTART : assert property (result_bad_lanes_restart)
        else $error("ASSERT FAIL [RESULT_BAD_LANES_RESTART]: did not restart after bad lane result");

    // --------------------------------------------------------------------------
    // Done asserted as combinational pulse on RSP + correct decoding
    // --------------------------------------------------------------------------
    property done_on_rsp;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRVAL &&
         current_substate == DONE_HANDSHAKE &&
         i_sb_tx_rsp && i_tx_decoding == 9'h2B)
        |-> o_done_mbinit_repairval_tx;
    endproperty
    DONE_REPAIRVAL : assert property (done_on_rsp)
        else $error("ASSERT FAIL [DONE_REPAIRVAL]: done not asserted on RSP + 0x2B");

    // --------------------------------------------------------------------------
    // REQ raised when no done_ack; dropped once done_ack received
    // --------------------------------------------------------------------------
    property req_raised_when_needed;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRVAL && !done_ack && !substates_done)
        |-> o_tx_sb_req;
    endproperty
    REQ_RAISED : assert property (req_raised_when_needed)
        else $error("ASSERT FAIL [REQ_RAISED]: tx_sb_req not asserted when handshake pending");

    property req_dropped_after_done_ack;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRVAL && done_ack)
        |-> !o_tx_sb_req;
    endproperty
    REQ_DROPPED : assert property (req_dropped_after_done_ack)
        else $error("ASSERT FAIL [REQ_DROPPED]: tx_sb_req still high after done_ack received");

    // --------------------------------------------------------------------------
    // Done never asserts outside MBINIT_REPAIRVAL
    // --------------------------------------------------------------------------
    property done_only_in_state;
        @(posedge i_clk) disable iff (i_reset)
        i_current_state != MBINIT_REPAIRVAL |-> !o_done_mbinit_repairval_tx;
    endproperty
    DONE_ONLY_IN_STATE : assert property (done_only_in_state)
        else $error("ASSERT FAIL [DONE_ONLY_IN_STATE]: done asserted outside MBINIT_REPAIRVAL");

`endif
*/
endmodule
