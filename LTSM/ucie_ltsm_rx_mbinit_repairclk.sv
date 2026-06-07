`define SIM 
module ucie_ltsm_rx_mbinit_repairclk #(
    parameter DECODING_WIDTH = 9,
    parameter DATA_WIDTH     = 64,
    parameter INFO_WIDTH     = 16
) (
    input                      i_clk,
    input                      i_reset,
    input [DECODING_WIDTH-1:0] i_rx_decoding,
    input [    DATA_WIDTH-1:0] i_rx_data,
    input [    INFO_WIDTH-1:0] i_rx_info,
    input                      i_sb_rx_req,
    input                      i_sb_rx_rsp,
    input                      i_sb_rx_done,
    input                      i_rx_done,
    input                      init_train_en,
    input [               3:0] i_current_state,
    input                      o_timer_8ms,

    // Pattern detection results from RX PHY path (3 clock lane health bits)
    input [2:0] i_rx_clk_results,

    output logic [DECODING_WIDTH-1:0] o_rx_encoding,
    output logic [    DATA_WIDTH-1:0] o_rx_data,
    output logic [    INFO_WIDTH-1:0] o_rx_info,
    output logic                      o_rx_sb_req,
    output logic                      o_rx_sb_rsp,
    output logic                      o_rx_sb_done,
    output logic                      o_train_error,
    output logic                      o_saw_trainerror_req,
    output logic                      o_done_mbinit_repairclk_rx
);

  // -------------------------------------------------------------------------
  // Local parameters
  // -------------------------------------------------------------------------
  localparam logic [3:0] MBINIT_REPAIRCLK = 4'b0100;

  // REPAIRCLK RX substates:
  // INIT_HANDSHAKE    : wait for TX INIT REQ (0x20), send RSP
  // PATTERN_DETECTION : wait for RX path to finish OR for TX to send result REQ early
  // WAIT_RESULT_REQ   : RX done before TX asked — hold results, wait for REQ
  // SEND_RESP         : send lane health results in o_rx_info[3:0]
  // DONE_HANDSHAKE    : wait for TX DONE REQ (0x23), send RSP, assert done
  localparam logic [2:0] INIT_HANDSHAKE = 3'b000;
  localparam logic [2:0] PATTERN_DETECTION = 3'b001;
  localparam logic [2:0] WAIT_RESULT_REQ = 3'b010;
  localparam logic [2:0] SEND_RESP = 3'b011;
  localparam logic [2:0] DONE_HANDSHAKE = 3'b100;

  // -------------------------------------------------------------------------
  // Internal signals
  // -------------------------------------------------------------------------
  logic [2:0] current_substate;
  logic [2:0] next_substate;
  logic       done_ack;
  logic       substates_done;

  logic [2:0] i_rx_clk_results_reg;

  // -------------------------------------------------------------------------
  // State memory + result latch
  // -------------------------------------------------------------------------
  always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
      current_substate     <= INIT_HANDSHAKE;
      substates_done       <= 0;
      i_rx_clk_results_reg <= '0;
    end else if (i_current_state != MBINIT_REPAIRCLK) begin
      current_substate     <= INIT_HANDSHAKE;
      substates_done       <= 0;
      i_rx_clk_results_reg <= '0;
    end else begin
      // Park in DONE_HANDSHAKE when local side completes (encoding hold until parent exits)
      if (current_substate == DONE_HANDSHAKE && i_sb_rx_req && i_rx_decoding == 9'h24) begin
        substates_done   <= 1;
        current_substate <= DONE_HANDSHAKE;
      end else begin
        current_substate <= next_substate;

        // Latch detection results when RX path finishes or when TX asks early
        if ((current_substate == WAIT_RESULT_REQ && i_rx_done) ||
                    (current_substate == PATTERN_DETECTION &&
                     i_sb_rx_req && i_rx_decoding == 9'h23)) // edited
          i_rx_clk_results_reg <= i_rx_clk_results;
      end
    end
  end

  // // -------------------------------------------------------------------------
  // // RSP / Done handshake register
  // // -------------------------------------------------------------------------
  // always_ff @(posedge i_clk or posedge i_reset) begin
  //   if (i_reset) done_ack <= 0;
  //   else if (i_sb_rx_done) done_ack <= 1;
  //   else if (i_sb_rx_req) done_ack <= 0;
  // end

  always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) done_ack <= 1;
    else if (i_sb_rx_done) done_ack <= 1;
    else if (i_sb_rx_req && (i_rx_decoding == 9'h20 || i_rx_decoding == 9'h22 || i_rx_decoding == 9'h23 || i_rx_decoding == 9'h24))
      done_ack <= 0;
  end

  always_comb begin
    o_rx_sb_rsp = done_ack ? 0 : 1;
  end

  // -------------------------------------------------------------------------
  // Next-state / output combinational logic
  //
  // Encoding map (RX mirrors TX encoding):
  //   INIT_HANDSHAKE    : 0x20
  //   PATTERN_DETECTION : 0x21
  //   WAIT_RESULT_REQ   : 0x22
  //   SEND_RESP         : 0x22  (result sent in o_rx_info[3:0])
  //   DONE_HANDSHAKE    : 0x23
  // -------------------------------------------------------------------------
  always_comb begin
    o_rx_encoding              = 9'h20;
    o_rx_data                  = '0;
    o_rx_info                  = '0;
    o_rx_sb_req                = 0;
    // o_rx_sb_rsp                = 0;
    o_rx_sb_done               = 0;
    o_train_error              = 0;
    o_saw_trainerror_req       = 0;
    o_done_mbinit_repairclk_rx = 0;
    next_substate              = DONE_HANDSHAKE;

    if (i_current_state == MBINIT_REPAIRCLK && i_sb_rx_req && i_rx_decoding == 9'h40) begin
      o_train_error        = 1;
      o_saw_trainerror_req = 1;
    end else if (!substates_done && o_timer_8ms) begin
      o_train_error = 1;
      next_substate = INIT_HANDSHAKE;
    end else if (i_current_state == MBINIT_REPAIRCLK) begin
      case (current_substate)

        // --------------------------------------------------------------
        // INIT_HANDSHAKE
        // Wait for TX REQ + 0x20, send RSP immediately, advance.
        // --------------------------------------------------------------
        INIT_HANDSHAKE: begin
          o_rx_encoding = 9'h20;
          if (!substates_done) begin
            // o_rx_sb_rsp = done_ack ? 0 : 1;

            if (i_sb_rx_req && i_rx_decoding == 9'h20) next_substate = PATTERN_DETECTION;
            else next_substate = INIT_HANDSHAKE;
          end
        end

        // --------------------------------------------------------------
        // PATTERN_DETECTION
        // RX path running pattern detection in background.
        // Two exit paths:
        //   (a) i_rx_done arrives first → go WAIT_RESULT_REQ, hold results
        //   (b) TX sends result REQ (0x22) before i_rx_done → grab results
        //       immediately and jump straight to SEND_RESP
        // FIX 11: was "i_rx_decoding = 9'h22" (assign not compare)
        // --------------------------------------------------------------
        PATTERN_DETECTION: begin
          o_rx_encoding = o_rx_sb_rsp ? 9'h20 : 9'h21;

          if (!substates_done) begin
            // if (i_rx_done) begin
            //   // Results ready, wait for TX to ask
            //   next_substate = WAIT_RESULT_REQ;
            // end else 
            if (i_sb_rx_req && i_rx_decoding == 9'h23) begin
              // TX asked before we finished — grab whatever we have now
              // o_rx_sb_rsp   = 1;
              next_substate = SEND_RESP;
            end else begin
              next_substate = PATTERN_DETECTION;
            end
          end
        end

        // --------------------------------------------------------------
        // WAIT_RESULT_REQ
        // RX finished detection before TX asked. Hold results and wait
        // for TX to send result REQ (0x22).
        // --------------------------------------------------------------
        WAIT_RESULT_REQ: begin
          o_rx_encoding = 9'h22;
          if (!substates_done) begin
            // Keep RSP asserted so TX knows we're ready
            // o_rx_sb_rsp = done_ack ? 0 : 1;

            if (i_sb_rx_req && i_rx_decoding == 9'h22)  // 
              next_substate = SEND_RESP;
            else next_substate = WAIT_RESULT_REQ;
          end
        end

        // --------------------------------------------------------------
        // SEND_RESP
        // Send lane health results in o_rx_info[3:0] (4 clock lanes).
        // Assert RSP, hold until i_sb_rx_done confirms sideband accepted.
        // FIX 16: original used 9'h23 here which belongs to DONE_HANDSHAKE
        // FIX 6/7: removed substates_done from comb, handled in ff
        // --------------------------------------------------------------
        SEND_RESP: begin
          o_rx_encoding  = 9'h23;
          o_rx_info[2:0] = i_rx_clk_results_reg;
          if (!substates_done) begin
            // o_rx_sb_rsp = 1;

            if (i_sb_rx_done && i_rx_clk_results_reg == 3'b111) next_substate = DONE_HANDSHAKE;
            else next_substate = SEND_RESP;
          end else next_substate = SEND_RESP;
        end

        // --------------------------------------------------------------
        // DONE_HANDSHAKE
        // Wait for TX DONE REQ (0x23), send RSP, assert done.
        // FIX 16: original used 9'h24 here
        // --------------------------------------------------------------
        DONE_HANDSHAKE: begin
          o_rx_encoding = 9'h24;
          if (!substates_done) begin
            // o_rx_sb_rsp = done_ack ? 0 : 1;

            if (i_sb_rx_req && i_rx_decoding == 9'h24) begin
              o_done_mbinit_repairclk_rx = 1;
              next_substate              = DONE_HANDSHAKE;
            end else begin
              next_substate = DONE_HANDSHAKE;
            end
          end
        end

        default: next_substate = INIT_HANDSHAKE;

      endcase
    end
  end

  // =========================================================================
  // Assertions
  // =========================================================================
  /*
`ifdef SIM

    property enc_check(substate, logic [8:0] enc);
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRCLK && current_substate == substate)
        |-> o_rx_encoding == enc;
    endproperty

    ENC_INIT_HANDSHAKE    : assert property (enc_check(INIT_HANDSHAKE,    9'h20))
        else $error("ASSERT FAIL [ENC_INIT_HANDSHAKE]: wrong encoding");
    ENC_PATTERN_DETECTION : assert property (enc_check(PATTERN_DETECTION, 9'h21))
        else $error("ASSERT FAIL [ENC_PATTERN_DETECTION]: wrong encoding");
    ENC_WAIT_RESULT_REQ   : assert property (enc_check(WAIT_RESULT_REQ,   9'h22))
        else $error("ASSERT FAIL [ENC_WAIT_RESULT_REQ]: wrong encoding");
    ENC_SEND_RESP         : assert property (enc_check(SEND_RESP,         9'h22))
        else $error("ASSERT FAIL [ENC_SEND_RESP]: wrong encoding");
    ENC_DONE_HANDSHAKE    : assert property (enc_check(DONE_HANDSHAKE,    9'h23))
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

    // Result latched before SEND_RESP is entered
    property result_latched;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRCLK && current_substate == SEND_RESP)
        |-> (o_rx_info[2:0] === i_rx_clk_results_reg[2:0]);
    endproperty
    RESULT_LATCHED : assert property (result_latched)
        else $error("ASSERT FAIL [RESULT_LATCHED]: wrong lane health bits in SEND_RESP");

    property done_on_req;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRCLK &&
         current_substate == DONE_HANDSHAKE &&
         i_sb_rx_req && i_rx_decoding == 9'h23)
        |-> o_done_mbinit_repairclk_rx;
    endproperty
    DONE_REPAIRCLK_RX : assert property (done_on_req)
        else $error("ASSERT FAIL [DONE_REPAIRCLK_RX]: done not asserted on REQ + 0x23");

    property done_only_in_state;
        @(posedge i_clk) disable iff (i_reset)
        i_current_state != MBINIT_REPAIRCLK |-> !o_done_mbinit_repairclk_rx;
    endproperty
    DONE_ONLY_IN_STATE : assert property (done_only_in_state)
        else $error("ASSERT FAIL [DONE_ONLY_IN_STATE]: done asserted outside MBINIT_REPAIRCLK");

`endif
*/
endmodule
