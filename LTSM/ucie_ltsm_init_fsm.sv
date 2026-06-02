// =============================================================================
// Module  : ucie_ltsm_init_fsm
// Description: Top-level UCIe Link Training State Machine (LTSM) for the
//              Initialization sequence.  Instantiates 9 TX sub-FSMs and 9 RX
//              sub-FSMs and sequences them through:
//
//   RESET ? SBINIT ? MBINIT_PARAM ? MBINIT_CAL ? MBINIT_REPAIRCLK ?
//   MBINIT_REPAIRVAL ? MBINIT_REVERSAL ? MBINIT_REPAIRMB --(stay)--
//                                                              �
//                                        i_train_active_error  �
//                                                              ?
//                                                        TRAINERROR ? RESET
//
// Any o_train_error from any sub-FSM immediately forces TRAINERROR, EXCEPT
// errors from SBINIT (TX or RX) which jump directly back to RESET.
//
// When MBINIT_REPAIRMB completes (both TX & RX done) the module asserts
// o_init_train_en and parks there until i_train_active_error or i_reset.
// =============================================================================

`define SIM 

module ucie_ltsm_init_fsm #(
    parameter DECODING_WIDTH = 9,
    parameter DATA_WIDTH     = 64,
    parameter INFO_WIDTH     = 16
) (
    // -------------------------------------------------------------------------
    // Global clock & reset
    // -------------------------------------------------------------------------
    input logic i_clk,
    input logic i_reset,

    // -------------------------------------------------------------------------
    // TX-side inputs  (shared across all TX sub-FSMs)
    // -------------------------------------------------------------------------
    input logic [DECODING_WIDTH-1:0] i_tx_decoding,
    input logic [    DATA_WIDTH-1:0] i_tx_data,
    input logic [    INFO_WIDTH-1:0] i_tx_info,
    input logic                      i_sb_tx_req,
    input logic                      i_sb_tx_rsp,
    input logic                      i_sb_tx_done,
    input logic                      i_tx_done,

    // -------------------------------------------------------------------------
    // RX-side inputs  (shared across all RX sub-FSMs)
    // -------------------------------------------------------------------------
    input logic [DECODING_WIDTH-1:0] i_rx_decoding,
    input logic [    DATA_WIDTH-1:0] i_rx_data,
    input logic [    INFO_WIDTH-1:0] i_rx_info,
    input logic                      i_sb_rx_req,
    input logic                      i_sb_rx_rsp,
    input logic                      i_sb_rx_done,
    input logic                      i_rx_done,
    input logic                      i_sb_cur_msg_done,

    // -------------------------------------------------------------------------
    // RESET sub-FSM specific inputs
    // -------------------------------------------------------------------------
    input logic i_pll_stable,
    input logic i_supply_stable,
    input logic i_timer_4ms,
    input logic i_lp_linkerror,

    // -------------------------------------------------------------------------
    // SBINIT sub-FSM specific inputs
    // -------------------------------------------------------------------------
    input logic i_sb_ready,  // TX SBINIT pattern-gen stop

    // -------------------------------------------------------------------------
    // REPAIRCLK / REPAIRVAL pattern-detection results
    // -------------------------------------------------------------------------
    input logic [           2:0] i_rx_repairclk_pattern_results,
    input logic                  i_rx_repairval_pattern_results,
    input logic [DATA_WIDTH-1:0] i_rx_reversal_pattern_results,

    // -------------------------------------------------------------------------
    // REPAIRMB eye-sweep inputs
    // -------------------------------------------------------------------------
    input logic [7:0] i_tx_sweep_result,
    input logic [7:0] i_rx_sweep_result,

    // -------------------------------------------------------------------------
    // 8ms timeout (generated externally, fed into every sub-FSM that needs it)
    // -------------------------------------------------------------------------
    input logic        o_timer_8ms,
    input       [15:0] r_local_cap,

    // -------------------------------------------------------------------------
    // Active-training error (post-init): forces TRAINERROR when asserted
    // while o_init_train_en is high
    // -------------------------------------------------------------------------
    input logic i_train_active_error,

    // -------------------------------------------------------------------------
    // TX output bus  (muxed from whichever TX sub-FSM is currently active)
    // -------------------------------------------------------------------------
    output logic [DECODING_WIDTH-1:0] o_tx_encoding,
    output logic [    DATA_WIDTH-1:0] o_tx_data,
    output logic [    INFO_WIDTH-1:0] o_tx_info,
    output logic                      o_tx_sb_req,
    output logic                      o_tx_sb_rsp,
    output logic                      o_tx_sb_done,

    // -------------------------------------------------------------------------
    // RX output bus  (muxed from whichever RX sub-FSM is currently active)
    // -------------------------------------------------------------------------
    output logic [DECODING_WIDTH-1:0] o_rx_encoding,
    output logic [    DATA_WIDTH-1:0] o_rx_data,
    output logic [    INFO_WIDTH-1:0] o_rx_info,
    output logic                      o_rx_sb_req,
    output logic                      o_rx_sb_rsp,
    output logic                      o_rx_sb_done,

    // Lane code map
    output logic [2:0] rx_lane_map,
    output logic [2:0] tx_lane_map,

    // -------------------------------------------------------------------------
    // Status outputs
    // -------------------------------------------------------------------------
    output logic       o_init_train_en,  // init complete, PHY active
    output logic       o_sb_init_start,  // from SBINIT TX sub-FSM
    output logic [3:0] o_current_state   // current LTSM state (debug/monitor)
);

  // =========================================================================
  // Main FSM state encoding  (4-bit, matches i_current_state fed to sub-FSMs)
  // =========================================================================
  localparam logic [3:0] RESET = 4'b0000;
  localparam logic [3:0] SBINIT = 4'b0001;
  localparam logic [3:0] MBINIT_PARAM = 4'b0010;
  localparam logic [3:0] MBINIT_CAL = 4'b0011;
  localparam logic [3:0] MBINIT_REPAIRCLK = 4'b0100;
  localparam logic [3:0] MBINIT_REPAIRVAL = 4'b0101;
  localparam logic [3:0] MBINIT_REVERSAL = 4'b0110;
  localparam logic [3:0] MBINIT_REPAIRMB = 4'b0111;
  localparam logic [3:0] TRAINERROR = 4'b1000;

  // =========================================================================
  // Current / next state registers
  // =========================================================================
  logic [3:0] current_state;

  assign o_current_state = current_state;

  // =========================================================================
  // Done latches � per state, for TX and RX independently
  // Each sub-FSM asserts its done for exactly one cycle; we latch here and
  // clear on state transition.
  // =========================================================================
  logic done_tx_reset, done_rx_reset;
  logic done_tx_sbinit, done_rx_sbinit;
  logic done_tx_param, done_rx_param;
  logic done_tx_cal, done_rx_cal;
  logic done_tx_repairclk, done_rx_repairclk;
  logic done_tx_repairval, done_rx_repairval;
  logic done_tx_reversal, done_rx_reversal;
  logic done_tx_repairmb, done_rx_repairmb;
  logic done_tx_trainerror, done_rx_trainerror;

  // Raw done pulses from sub-FSMs
  logic raw_done_tx_reset, raw_done_rx_reset;
  logic raw_done_tx_sbinit, raw_done_rx_sbinit;
  logic raw_done_tx_param, raw_done_rx_param;
  logic raw_done_tx_cal, raw_done_rx_cal;
  logic raw_done_tx_repairclk, raw_done_rx_repairclk;
  logic raw_done_tx_repairval, raw_done_rx_repairval;
  logic raw_done_tx_reversal, raw_done_rx_reversal;
  logic raw_done_tx_repairmb, raw_done_rx_repairmb;
  logic raw_done_tx_trainerror, raw_done_rx_trainerror;

  // Train error signals from each sub-FSM
  logic te_tx_reset;  // TX reset has no train-error port, tie to 0
  logic te_rx_reset;  // RX reset has no train-error port, tie to 0
  logic te_tx_sbinit, te_rx_sbinit;
  logic te_tx_param, te_rx_param;
  logic te_tx_cal, te_rx_cal;
  logic te_tx_repairclk, te_rx_repairclk;
  logic te_tx_repairval, te_rx_repairval;
  logic te_tx_reversal, te_rx_reversal;
  logic te_tx_repairmb, te_rx_repairmb;
  logic te_tx_trainerror, te_rx_trainerror;

  assign te_tx_reset = 1'b0;
  assign te_rx_reset = 1'b0;

  // =========================================================================
  // SBINIT-specific
  // =========================================================================
  logic sb_init_start_tx;  // o_sb_init_start from TX SBINIT sub-FSM

  // =========================================================================
  // init_train_en latch
  // =========================================================================
  logic init_train_en_reg;
  assign o_init_train_en = init_train_en_reg;

  // =========================================================================
  // Aggregate train error detection
  // -  SBINIT errors     ? jump to RESET   (skip TRAINERROR)
  // -  All other errors  ? jump to TRAINERROR
  // =========================================================================
  logic any_sbinit_error;
  logic any_other_error;
  // logic i_train_active_error_reg;

  // always_ff @(posedge i_clk or posedge i_reset) begin
  //   if (i_reset) begin
  //     i_train_active_error_reg <= 1'b0;
  //   end else begin
  //     i_train_active_error_reg <= i_train_active_error;
  //   end
  // end



  // always_ff @(posedge i_clk or posedge i_reset) begin
  //   if (i_reset) begin
  //     any_sbinit_error <= 1'b0;
  //   end else begin
  assign any_sbinit_error = te_tx_sbinit | te_rx_sbinit;
  //   end
  // end

  // Gate "other" errors so they are only relevant in the state they belong to
  always_comb begin
    case (current_state)
      MBINIT_PARAM:     any_other_error = te_tx_param | te_rx_param;
      MBINIT_CAL:       any_other_error = te_tx_cal | te_rx_cal;
      MBINIT_REPAIRCLK: any_other_error = te_tx_repairclk | te_rx_repairclk;
      MBINIT_REPAIRVAL: any_other_error = te_tx_repairval | te_rx_repairval;
      MBINIT_REVERSAL:  any_other_error = te_tx_reversal | te_rx_reversal;
      MBINIT_REPAIRMB:  any_other_error = te_tx_repairmb | te_rx_repairmb;
      TRAINERROR:       any_other_error = te_tx_trainerror | te_rx_trainerror;
      default:          any_other_error = 1'b0;
    endcase
  end

  // =========================================================================
  // Done latch always_ff  � latch each raw done pulse; clear on state exit
  // =========================================================================
  always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
      done_tx_reset      <= 0;
      done_rx_reset      <= 0;
      done_tx_sbinit     <= 0;
      done_rx_sbinit     <= 0;
      done_tx_param      <= 0;
      done_rx_param      <= 0;
      done_tx_cal        <= 0;
      done_rx_cal        <= 0;
      done_tx_repairclk  <= 0;
      done_rx_repairclk  <= 0;
      done_tx_repairval  <= 0;
      done_rx_repairval  <= 0;
      done_tx_reversal   <= 0;
      done_rx_reversal   <= 0;
      done_tx_repairmb   <= 0;
      done_rx_repairmb   <= 0;
      done_tx_trainerror <= 0;
      done_rx_trainerror <= 0;
    end else begin
      // ---- RESET ----
      if (current_state != RESET) begin
        done_tx_reset <= 0;
        done_rx_reset <= 0;
      end else begin
        if (raw_done_tx_reset) done_tx_reset <= 1;
        if (raw_done_rx_reset) done_rx_reset <= 1;
      end

      // ---- SBINIT ----
      if (current_state != SBINIT) begin
        done_tx_sbinit <= 0;
        done_rx_sbinit <= 0;
      end else begin
        if (raw_done_tx_sbinit) done_tx_sbinit <= 1;
        if (raw_done_rx_sbinit) done_rx_sbinit <= 1;
      end

      // ---- MBINIT_PARAM ----
      if (current_state != MBINIT_PARAM) begin
        done_tx_param <= 0;
        done_rx_param <= 0;
      end else begin
        if (raw_done_tx_param) done_tx_param <= 1;
        if (raw_done_rx_param) done_rx_param <= 1;
      end

      // ---- MBINIT_CAL ----
      if (current_state != MBINIT_CAL) begin
        done_tx_cal <= 0;
        done_rx_cal <= 0;
      end else begin
        if (raw_done_tx_cal) done_tx_cal <= 1;
        if (raw_done_rx_cal) done_rx_cal <= 1;
      end

      // ---- MBINIT_REPAIRCLK ----
      if (current_state != MBINIT_REPAIRCLK) begin
        done_tx_repairclk <= 0;
        done_rx_repairclk <= 0;
      end else begin
        if (raw_done_tx_repairclk) done_tx_repairclk <= 1;
        if (raw_done_rx_repairclk) done_rx_repairclk <= 1;
      end

      // ---- MBINIT_REPAIRVAL ----
      if (current_state != MBINIT_REPAIRVAL) begin
        done_tx_repairval <= 0;
        done_rx_repairval <= 0;
      end else begin
        if (raw_done_tx_repairval) done_tx_repairval <= 1;
        if (raw_done_rx_repairval) done_rx_repairval <= 1;
      end

      // ---- MBINIT_REVERSAL ----
      if (current_state != MBINIT_REVERSAL) begin
        done_tx_reversal <= 0;
        done_rx_reversal <= 0;
      end else begin
        if (raw_done_tx_reversal) done_tx_reversal <= 1;
        if (raw_done_rx_reversal) done_rx_reversal <= 1;
      end

      // ---- MBINIT_REPAIRMB ----
      if (current_state != MBINIT_REPAIRMB) begin
        done_tx_repairmb <= 0;
        done_rx_repairmb <= 0;
      end else begin
        if (raw_done_tx_repairmb) done_tx_repairmb <= 1;
        if (raw_done_rx_repairmb) done_rx_repairmb <= 1;
      end

      // ---- TRAINERROR ----
      if (current_state != TRAINERROR) begin
        done_tx_trainerror <= 0;
        done_rx_trainerror <= 0;
      end else begin
        if (raw_done_tx_trainerror) done_tx_trainerror <= 1;
        if (raw_done_rx_trainerror) done_rx_trainerror <= 1;
      end
    end
  end
  logic repair_done; // tracks whether we've completed REPAIRMB (both TX & RX done) and thus should assert o_init_train_en
  // =========================================================================
  // init_train_en latch
  // =========================================================================
  always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) init_train_en_reg <= 0;
    else if (current_state == MBINIT_REPAIRMB && repair_done) init_train_en_reg <= 1;
    else if (current_state != MBINIT_REPAIRMB) init_train_en_reg <= 0;
  end

  always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) repair_done <= 0;
    else if (current_state == MBINIT_REPAIRMB && i_rx_decoding == 'h80 && i_sb_rx_req)
      repair_done <= 0;
    else if (done_tx_repairmb && done_rx_repairmb) repair_done <= 1;
    else repair_done <= 0;
  end

  // =========================================================================
  // Main FSM  � sequential
  // =========================================================================
  // always_ff @(posedge i_clk or posedge i_reset) begin
  //   if (i_reset) current_state <= RESET;
  //   else current_state <= next_state;
  // end

  // always_comb begin
  //   if (i_reset) current_state = RESET;
  //   else current_state = next_state;
  // end

  // =========================================================================
  // Main FSM  � combinational next-state logic
  // Priority (highest first):
  //   1. SBINIT train error       ? RESET
  //   2. Any other train error    ? TRAINERROR
  //   3. Active-training error while init_train_en is high ? TRAINERROR
  //   4. Both TX & RX done        ? advance
  //   5. Stay
  // =========================================================================
  // The original code creates a combinational loop by updating current_state 
  // within an always_comb block, but also using current_state as the selector in the case. 
  // The proper approach is to introduce a next_state signal, perform all logic/writes 
  // to next_state in always_comb, and update current_state on the clock edge. 
  // Below is the safe, systematic way to rewrite this FSM logic 
  // (keeping current_state as a flop, next_state as combinational):

  logic [3:0] next_state;  // Set STATE_WIDTH appropriately, or `typedef` your enum

  always_comb begin
    // Default hold value
    next_state = current_state;

    // ---- Global error overrides ----
    if (any_sbinit_error && current_state == SBINIT) begin
      next_state = RESET;
    end else if (any_other_error) begin
      next_state = TRAINERROR;
    end else if (init_train_en_reg && i_train_active_error) begin
      next_state = TRAINERROR;
    end else begin
      // Normal sequencing � only override next_state if transition
      case (current_state)
        RESET: begin
          // Next state if:
          // (done_tx_reset && raw_done_rx_reset) OR (done_rx_reset && raw_done_tx_reset)
          // OR (done_tx_reset && done_rx_reset) OR (raw_done_tx_reset && raw_done_rx_reset)
          if ((done_tx_reset && raw_done_rx_reset) ||
              (done_rx_reset && raw_done_tx_reset) ||
              (done_tx_reset && done_rx_reset) ||
              (raw_done_tx_reset && raw_done_rx_reset))
            next_state = SBINIT;
        end

        SBINIT: begin
          if ((done_tx_sbinit && raw_done_rx_sbinit) ||
              (done_rx_sbinit && raw_done_tx_sbinit) ||
              (done_tx_sbinit && done_rx_sbinit) ||
              (raw_done_tx_sbinit && raw_done_rx_sbinit))
            next_state = MBINIT_PARAM;
        end

        MBINIT_PARAM: begin
          if ((done_tx_param && raw_done_rx_param) ||
              (done_rx_param && raw_done_tx_param) ||
              (done_tx_param && done_rx_param) ||
              (raw_done_tx_param && raw_done_rx_param))
            next_state = MBINIT_CAL;
        end

        MBINIT_CAL: begin
          if ((done_tx_cal && raw_done_rx_cal) ||
              (done_rx_cal && raw_done_tx_cal) ||
              (done_tx_cal && done_rx_cal) ||
              (raw_done_tx_cal && raw_done_rx_cal))
            next_state = MBINIT_REPAIRCLK;
        end

        MBINIT_REPAIRCLK: begin
          if ((done_tx_repairclk && raw_done_rx_repairclk) ||
              (done_rx_repairclk && raw_done_tx_repairclk) ||
              (done_tx_repairclk && done_rx_repairclk) ||
              (raw_done_tx_repairclk && raw_done_rx_repairclk))
            next_state = MBINIT_REPAIRVAL;
        end

        MBINIT_REPAIRVAL: begin
          if ((done_tx_repairval && raw_done_rx_repairval) ||
              (done_rx_repairval && raw_done_tx_repairval) ||
              (done_tx_repairval && done_rx_repairval) ||
              (raw_done_tx_repairval && raw_done_rx_repairval))
            next_state = MBINIT_REVERSAL;
        end

        MBINIT_REVERSAL: begin
          if ((done_tx_reversal && raw_done_rx_reversal) ||
              (done_rx_reversal && raw_done_tx_reversal) ||
              (done_tx_reversal && done_rx_reversal) ||
              (raw_done_tx_reversal && raw_done_rx_reversal))
            next_state = MBINIT_REPAIRMB;
        end

        MBINIT_REPAIRMB: begin
          // Stay here once both done; init_train_en will be asserted
          // Active-training error handled in the global override above
          next_state = MBINIT_REPAIRMB;
        end

        TRAINERROR: begin
          if ((done_tx_trainerror && raw_done_rx_trainerror) ||
              (done_rx_trainerror && raw_done_tx_trainerror) ||
              (done_tx_trainerror && done_rx_trainerror) ||
              (raw_done_tx_trainerror && raw_done_rx_trainerror))
            next_state = RESET;
        end

        default: next_state = RESET;
      endcase
    end
  end

  // Add a registered always_ff process to update current_state
  always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) current_state <= RESET;
    else current_state <= next_state;
  end

  // =========================================================================
  // Sub-FSM outputs  (per-state wires)
  // =========================================================================

  // ---- RESET ----
  logic [DECODING_WIDTH-1:0] tx_enc_reset;
  logic [DECODING_WIDTH-1:0] rx_enc_reset;

  // ---- SBINIT ----
  logic [DECODING_WIDTH-1:0] tx_enc_sbinit;
  logic tx_sb_req_sbinit, tx_sb_rsp_sbinit, tx_sb_done_sbinit;
  logic [DECODING_WIDTH-1:0] rx_enc_sbinit;
  logic [    DATA_WIDTH-1:0] rx_data_sbinit;
  logic [    INFO_WIDTH-1:0] rx_info_sbinit;
  logic rx_sb_req_sbinit, rx_sb_rsp_sbinit, rx_sb_done_sbinit;

  // ---- MBINIT_PARAM ----
  logic [DECODING_WIDTH-1:0] tx_enc_param;
  logic [    DATA_WIDTH-1:0] tx_data_param;
  logic [    INFO_WIDTH-1:0] tx_info_param;
  logic tx_sb_req_param, tx_sb_rsp_param, tx_sb_done_param;
  logic [DECODING_WIDTH-1:0] rx_enc_param;
  logic [    DATA_WIDTH-1:0] rx_data_param;
  logic [    INFO_WIDTH-1:0] rx_info_param;
  logic rx_sb_req_param, rx_sb_rsp_param, rx_sb_done_param;

  // ---- MBINIT_CAL ----
  logic [DECODING_WIDTH-1:0] tx_enc_cal;
  logic [    DATA_WIDTH-1:0] tx_data_cal;
  logic [    INFO_WIDTH-1:0] tx_info_cal;
  logic tx_sb_req_cal, tx_sb_rsp_cal, tx_sb_done_cal;
  logic [DECODING_WIDTH-1:0] rx_enc_cal;
  logic [    DATA_WIDTH-1:0] rx_data_cal;
  logic [    INFO_WIDTH-1:0] rx_info_cal;
  logic rx_sb_req_cal, rx_sb_rsp_cal, rx_sb_done_cal;

  // ---- MBINIT_REPAIRCLK ----
  logic [DECODING_WIDTH-1:0] tx_enc_repairclk;
  logic [    DATA_WIDTH-1:0] tx_data_repairclk;
  logic [    INFO_WIDTH-1:0] tx_info_repairclk;
  logic tx_sb_req_repairclk, tx_sb_rsp_repairclk, tx_sb_done_repairclk;
  logic [DECODING_WIDTH-1:0] rx_enc_repairclk;
  logic [    DATA_WIDTH-1:0] rx_data_repairclk;
  logic [    INFO_WIDTH-1:0] rx_info_repairclk;
  logic rx_sb_req_repairclk, rx_sb_rsp_repairclk, rx_sb_done_repairclk;

  // ---- MBINIT_REPAIRVAL ----
  logic [DECODING_WIDTH-1:0] tx_enc_repairval;
  logic [    DATA_WIDTH-1:0] tx_data_repairval;
  logic [    INFO_WIDTH-1:0] tx_info_repairval;
  logic tx_sb_req_repairval, tx_sb_rsp_repairval, tx_sb_done_repairval;
  logic [DECODING_WIDTH-1:0] rx_enc_repairval;
  logic [    DATA_WIDTH-1:0] rx_data_repairval;
  logic [    INFO_WIDTH-1:0] rx_info_repairval;
  logic rx_sb_req_repairval, rx_sb_rsp_repairval, rx_sb_done_repairval;

  // ---- MBINIT_REVERSAL ----
  logic [DECODING_WIDTH-1:0] tx_enc_reversal;
  logic [    DATA_WIDTH-1:0] tx_data_reversal;
  logic [    INFO_WIDTH-1:0] tx_info_reversal;
  logic tx_sb_req_reversal, tx_sb_rsp_reversal, tx_sb_done_reversal;
  logic [DECODING_WIDTH-1:0] rx_enc_reversal;
  logic [    DATA_WIDTH-1:0] rx_data_reversal;
  logic [    INFO_WIDTH-1:0] rx_info_reversal;
  logic rx_sb_req_reversal, rx_sb_rsp_reversal, rx_sb_done_reversal;

  // ---- MBINIT_REPAIRMB ----
  logic [DECODING_WIDTH-1:0] tx_enc_repairmb;
  logic [    DATA_WIDTH-1:0] tx_data_repairmb;
  logic [    INFO_WIDTH-1:0] tx_info_repairmb;
  logic tx_sb_req_repairmb, tx_sb_rsp_repairmb, tx_sb_done_repairmb;
  logic [DECODING_WIDTH-1:0] rx_enc_repairmb;
  logic [    DATA_WIDTH-1:0] rx_data_repairmb;
  logic [    INFO_WIDTH-1:0] rx_info_repairmb;
  logic rx_sb_req_repairmb, rx_sb_rsp_repairmb, rx_sb_done_repairmb;

  // ---- TRAINERROR ----
  logic [DECODING_WIDTH-1:0] tx_enc_trainerror;
  logic [    DATA_WIDTH-1:0] tx_data_trainerror;
  logic [    INFO_WIDTH-1:0] tx_info_trainerror;
  logic tx_sb_req_trainerror, tx_sb_rsp_trainerror, tx_sb_done_trainerror;
  logic [DECODING_WIDTH-1:0] rx_enc_trainerror;
  logic [    DATA_WIDTH-1:0] rx_data_trainerror;
  logic [    INFO_WIDTH-1:0] rx_info_trainerror;
  logic rx_sb_req_trainerror, rx_sb_rsp_trainerror, rx_sb_done_trainerror;

  //================================================================================
  // Sideband Done Signal Logic
  //================================================================================
  // Generates done pulse for sideband protocol
  always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
      o_tx_sb_done <= 0;
    end else begin
      if (o_tx_sb_done && !(i_sb_tx_rsp || i_sb_tx_req)) begin
        o_tx_sb_done <= 0;  // Self-clearing pulse
      end else if (i_sb_tx_rsp || i_sb_tx_req) begin
        o_tx_sb_done <= 1;  // Assert on request or response
      end
    end
  end

  always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
      o_rx_sb_done <= 0;
    end else begin
      if (o_rx_sb_done && !(i_sb_rx_rsp || i_sb_rx_req)) begin
        o_rx_sb_done <= 0;  // Self-clearing pulse
      end else if (i_sb_rx_rsp || i_sb_rx_req) begin
        o_rx_sb_done <= 1;  // Assert on request or response
      end
    end
  end



  // =========================================================================
  // Sub-FSM Instantiations
  // =========================================================================

  // ----- TX RESET -----
  ucie_ltsm_tx_reset #(
      .DECODING_WIDTH(DECODING_WIDTH)
  ) u_tx_reset (
      .i_clk          (i_clk),
      .i_reset        (i_reset),
      .i_pll_stable   (i_pll_stable),
      .i_supply_stable(i_supply_stable),
      .i_timer_4ms    (i_timer_4ms),
      .i_current_state(current_state),
      .o_tx_encoding  (tx_enc_reset),
      .o_done_reset_tx(raw_done_tx_reset)
  );

  // ----- RX RESET -----
  ucie_ltsm_rx_reset #(
      .DECODING_WIDTH(DECODING_WIDTH)
  ) u_rx_reset (
      .i_clk          (i_clk),
      .i_reset        (i_reset),
      .init_train_en  (init_train_en_reg),
      .i_pll_stable   (i_pll_stable),
      .i_supply_stable(i_supply_stable),
      .i_timer_4ms    (i_timer_4ms),
      .i_current_state(current_state),
      .o_rx_encoding  (rx_enc_reset),
      .o_done_reset_rx(raw_done_rx_reset)
  );

  // ----- TX SBINIT -----
  ucie_ltsm_tx_sbinit #(
      .DECODING_WIDTH(DECODING_WIDTH),
      .DATA_WIDTH    (DATA_WIDTH)
  ) u_tx_sbinit (
      .i_clk           (i_clk),
      .i_rx_decoding   (i_rx_decoding),
      .i_reset         (i_reset),
      .i_tx_decoding   (i_tx_decoding),
      .i_sb_tx_req     (i_sb_tx_req),
      .i_sb_tx_rsp     (i_sb_tx_rsp),
      .i_sb_tx_done    (i_sb_tx_done),
      .i_sb_ready      (i_sb_ready),
      .i_current_state (current_state),
      .o_timer_8ms     (o_timer_8ms),
      .o_tx_encoding   (tx_enc_sbinit),
      .o_tx_sb_req     (tx_sb_req_sbinit),
      .o_tx_sb_rsp     (tx_sb_rsp_sbinit),
      .o_tx_sb_done    (tx_sb_done_sbinit),
      .o_train_error   (te_tx_sbinit),
      .o_sb_init_start (sb_init_start_tx),
      .o_done_sbinit_tx(raw_done_tx_sbinit)
  );
  assign o_sb_init_start = sb_init_start_tx;

  // ----- RX SBINIT -----
  ucie_ltsm_rx_sbinit #(
      .DECODING_WIDTH(DECODING_WIDTH),
      .DATA_WIDTH    (DATA_WIDTH),
      .INFO_WIDTH    (INFO_WIDTH)
  ) u_rx_sbinit (
      .i_clk           (i_clk),
      .i_reset         (i_reset),
      .i_rx_decoding   (i_rx_decoding),
      .i_rx_data       (i_rx_data),
      .i_rx_info       (i_rx_info),
      .i_sb_rx_req     (i_sb_rx_req),
      .i_sb_rx_rsp     (i_sb_rx_rsp),
      .i_sb_rx_done    (i_sb_rx_done),
      .i_rx_done       (i_rx_done),
      .init_train_en   (init_train_en_reg),
      .i_sb_ready      (i_sb_ready),
      .i_current_state (current_state),
      .o_timer_8ms     (o_timer_8ms),
      .o_rx_encoding   (rx_enc_sbinit),
      .o_rx_data       (rx_data_sbinit),
      .o_rx_info       (rx_info_sbinit),
      .o_rx_sb_req     (rx_sb_req_sbinit),
      .o_rx_sb_rsp     (rx_sb_rsp_sbinit),
      .o_rx_sb_done    (rx_sb_done_sbinit),
      .o_train_error   (te_rx_sbinit),
      .o_sb_init_start (  /* open � TX drives this */),
      .o_done_sbinit_rx(raw_done_rx_sbinit)
  );

  // ----- TX MBINIT_PARAM -----
  ucie_ltsm_tx_mbinit_param #(
      .DECODING_WIDTH(DECODING_WIDTH),
      .DATA_WIDTH    (DATA_WIDTH),
      .INFO_WIDTH    (INFO_WIDTH)
  ) u_tx_param (
      .i_clk                 (i_clk),
      .i_reset               (i_reset),
      .i_tx_decoding         (i_tx_decoding),
      .i_tx_data             (i_tx_data),
      .r_local_cap           (r_local_cap),
      .i_tx_info             (i_tx_info),
      .i_sb_tx_req           (i_sb_tx_req),
      .i_sb_tx_rsp           (i_sb_tx_rsp),
      .i_sb_tx_done          (i_sb_tx_done),
      .i_tx_done             (i_tx_done),
      .i_current_state       (current_state),
      .o_timer_8ms           (o_timer_8ms),
      .o_tx_encoding         (tx_enc_param),
      .o_tx_data             (tx_data_param),
      .o_tx_info             (tx_info_param),
      .o_tx_sb_req           (tx_sb_req_param),
      .o_tx_sb_rsp           (tx_sb_rsp_param),
      .o_tx_sb_done          (tx_sb_done_param),
      .o_train_error         (te_tx_param),
      .o_done_mbinit_param_tx(raw_done_tx_param)
  );

  // ----- RX MBINIT_PARAM -----
  ucie_ltsm_rx_mbinit_param #(
      .DECODING_WIDTH(DECODING_WIDTH),
      .DATA_WIDTH    (DATA_WIDTH),
      .INFO_WIDTH    (INFO_WIDTH)
  ) u_rx_param (
      .i_clk                 (i_clk),
      .i_reset               (i_reset),
      .i_rx_decoding         (i_rx_decoding),
      .i_rx_data             (i_rx_data),
      .i_rx_info             (i_rx_info),
      .i_sb_rx_req           (i_sb_rx_req),
      .i_sb_rx_rsp           (i_sb_rx_rsp),
      .i_sb_rx_done          (i_sb_rx_done),
      .i_rx_done             (i_rx_done),
      .init_train_en         (init_train_en_reg),
      .i_current_state       (current_state),
      .o_timer_8ms           (o_timer_8ms),
      .o_rx_encoding         (rx_enc_param),
      .o_rx_data             (rx_data_param),
      .o_rx_info             (rx_info_param),
      .o_rx_sb_req           (rx_sb_req_param),
      .o_rx_sb_rsp           (rx_sb_rsp_param),
      .o_rx_sb_done          (rx_sb_done_param),
      .o_train_error         (te_rx_param),
      .o_done_mbinit_param_rx(raw_done_rx_param)
  );

  // ----- TX MBINIT_CAL -----
  ucie_ltsm_tx_mbinit_cal #(
      .DECODING_WIDTH(DECODING_WIDTH),
      .DATA_WIDTH    (DATA_WIDTH),
      .INFO_WIDTH    (INFO_WIDTH)
  ) u_tx_cal (
      .i_clk               (i_clk),
      .i_reset             (i_reset),
      .i_tx_decoding       (i_tx_decoding),
      .i_tx_data           (i_tx_data),
      .i_tx_info           (i_tx_info),
      .i_sb_tx_req         (i_sb_tx_req),
      .i_sb_tx_rsp         (i_sb_tx_rsp),
      .i_sb_tx_done        (i_sb_tx_done),
      .i_tx_done           (i_tx_done),
      .i_current_state     (current_state),
      .o_timer_8ms         (o_timer_8ms),
      .o_tx_encoding       (tx_enc_cal),
      .o_tx_data           (tx_data_cal),
      .o_tx_info           (tx_info_cal),
      .o_tx_sb_req         (tx_sb_req_cal),
      .o_tx_sb_rsp         (tx_sb_rsp_cal),
      .o_tx_sb_done        (tx_sb_done_cal),
      .o_train_error       (te_tx_cal),
      .o_done_mbinit_cal_tx(raw_done_tx_cal)
  );

  // ----- RX MBINIT_CAL -----
  ucie_ltsm_rx_mbinit_cal #(
      .DECODING_WIDTH(DECODING_WIDTH),
      .DATA_WIDTH    (DATA_WIDTH),
      .INFO_WIDTH    (INFO_WIDTH)
  ) u_rx_cal (
      .i_clk               (i_clk),
      .i_reset             (i_reset),
      .i_rx_decoding       (i_rx_decoding),
      .i_rx_data           (i_rx_data),
      .i_rx_info           (i_rx_info),
      .i_sb_rx_req         (i_sb_rx_req),
      .i_sb_rx_rsp         (i_sb_rx_rsp),
      .i_sb_rx_done        (i_sb_rx_done),
      .i_rx_done           (i_rx_done),
      .init_train_en       (init_train_en_reg),
      .i_current_state     (current_state),
      .o_timer_8ms         (o_timer_8ms),
      .o_rx_encoding       (rx_enc_cal),
      .o_rx_data           (rx_data_cal),
      .o_rx_info           (rx_info_cal),
      .o_rx_sb_req         (rx_sb_req_cal),
      .o_rx_sb_rsp         (rx_sb_rsp_cal),
      .o_rx_sb_done        (rx_sb_done_cal),
      .o_train_error       (te_rx_cal),
      .o_done_mbinit_cal_rx(raw_done_rx_cal)
  );

  // ----- TX MBINIT_REPAIRCLK -----
  ucie_ltsm_tx_mbinit_repairclk #(
      .DECODING_WIDTH(DECODING_WIDTH),
      .DATA_WIDTH    (DATA_WIDTH),
      .INFO_WIDTH    (INFO_WIDTH)
  ) u_tx_repairclk (
      .i_clk                     (i_clk),
      .i_reset                   (i_reset),
      .i_tx_decoding             (i_tx_decoding),
      .i_tx_data                 (i_tx_data),
      .i_tx_info                 (i_tx_info),
      .i_sb_tx_req               (i_sb_tx_req),
      .i_sb_tx_rsp               (i_sb_tx_rsp),
      .i_sb_tx_done              (i_sb_tx_done),
      .i_tx_done                 (i_tx_done),
      .i_current_state           (current_state),
      .o_timer_8ms               (o_timer_8ms),
      .o_tx_encoding             (tx_enc_repairclk),
      .o_tx_data                 (tx_data_repairclk),
      .o_tx_info                 (tx_info_repairclk),
      .o_tx_sb_req               (tx_sb_req_repairclk),
      .o_tx_sb_rsp               (tx_sb_rsp_repairclk),
      .o_tx_sb_done              (tx_sb_done_repairclk),
      .o_train_error             (te_tx_repairclk),
      .o_done_mbinit_repairclk_tx(raw_done_tx_repairclk)
  );

  // ----- RX MBINIT_REPAIRCLK -----
  ucie_ltsm_rx_mbinit_repairclk #(
      .DECODING_WIDTH(DECODING_WIDTH),
      .DATA_WIDTH    (DATA_WIDTH),
      .INFO_WIDTH    (INFO_WIDTH)
  ) u_rx_repairclk (
      .i_clk                     (i_clk),
      .i_reset                   (i_reset),
      .i_rx_decoding             (i_rx_decoding),
      .i_rx_data                 (i_rx_data),
      .i_rx_info                 (i_rx_info),
      .i_sb_rx_req               (i_sb_rx_req),
      .i_sb_rx_rsp               (i_sb_rx_rsp),
      .i_sb_rx_done              (i_sb_rx_done),
      .i_rx_done                 (i_rx_done),
      .init_train_en             (init_train_en_reg),
      .i_current_state           (current_state),
      .o_timer_8ms               (o_timer_8ms),
      .i_rx_clk_results          (i_rx_repairclk_pattern_results),
      .o_rx_encoding             (rx_enc_repairclk),
      .o_rx_data                 (rx_data_repairclk),
      .o_rx_info                 (rx_info_repairclk),
      .o_rx_sb_req               (rx_sb_req_repairclk),
      .o_rx_sb_rsp               (rx_sb_rsp_repairclk),
      .o_rx_sb_done              (rx_sb_done_repairclk),
      .o_train_error             (te_rx_repairclk),
      .o_done_mbinit_repairclk_rx(raw_done_rx_repairclk)
  );

  // ----- TX MBINIT_REPAIRVAL -----
  ucie_ltsm_tx_mbinit_repairval #(
      .DECODING_WIDTH(DECODING_WIDTH),
      .DATA_WIDTH    (DATA_WIDTH),
      .INFO_WIDTH    (INFO_WIDTH)
  ) u_tx_repairval (
      .i_clk                     (i_clk),
      .i_reset                   (i_reset),
      .i_tx_decoding             (i_tx_decoding),
      .i_tx_data                 (i_tx_data),
      .i_tx_info                 (i_tx_info),
      .i_sb_tx_req               (i_sb_tx_req),
      .i_sb_tx_rsp               (i_sb_tx_rsp),
      .i_sb_tx_done              (i_sb_tx_done),
      .i_tx_done                 (i_tx_done),
      .init_train_en             (init_train_en_reg),
      .o_rx_sb_rsp               (o_rx_sb_rsp),
      .i_current_state           (current_state),
      .o_timer_8ms               (o_timer_8ms),
      .o_tx_encoding             (tx_enc_repairval),
      .o_tx_data                 (tx_data_repairval),
      .o_tx_info                 (tx_info_repairval),
      .o_tx_sb_req               (tx_sb_req_repairval),
      .o_tx_sb_rsp               (tx_sb_rsp_repairval),
      .o_tx_sb_done              (tx_sb_done_repairval),
      .o_train_error             (te_tx_repairval),
      .o_done_mbinit_repairval_tx(raw_done_tx_repairval)
  );

  // ----- RX MBINIT_REPAIRVAL -----
  ucie_ltsm_rx_mbinit_repairval #(
      .DECODING_WIDTH(DECODING_WIDTH),
      .DATA_WIDTH    (DATA_WIDTH),
      .INFO_WIDTH    (INFO_WIDTH)
  ) u_rx_repairval (
      .i_clk                     (i_clk),
      .i_reset                   (i_reset),
      .i_rx_decoding             (i_rx_decoding),
      .i_rx_data                 (i_rx_data),
      .i_rx_info                 (i_rx_info),
      .i_sb_rx_req               (i_sb_rx_req),
      .i_sb_rx_rsp               (i_sb_rx_rsp),
      .i_sb_rx_done              (i_sb_rx_done),
      .i_rx_done                 (i_rx_done),
      .init_train_en             (init_train_en_reg),
      .i_current_state           (current_state),
      .o_timer_8ms               (o_timer_8ms),
      .i_rx_valid_results        (i_rx_repairval_pattern_results),
      .o_rx_encoding             (rx_enc_repairval),
      .o_rx_data                 (rx_data_repairval),
      .o_rx_info                 (rx_info_repairval),
      .o_rx_sb_req               (rx_sb_req_repairval),
      .o_rx_sb_rsp               (rx_sb_rsp_repairval),
      .o_rx_sb_done              (rx_sb_done_repairval),
      .o_train_error             (te_rx_repairval),
      .o_done_mbinit_repairval_rx(raw_done_rx_repairval)
  );

  // ----- TX MBINIT_REVERSAL -----
  ucie_ltsm_tx_mbinit_reversal #(
      .DECODING_WIDTH(DECODING_WIDTH),
      .DATA_WIDTH    (DATA_WIDTH),
      .INFO_WIDTH    (INFO_WIDTH)
  ) u_tx_reversal (
      .i_clk                    (i_clk),
      .i_reset                  (i_reset),
      .i_tx_decoding            (i_tx_decoding),
      .i_tx_data                (i_tx_data),
      .i_tx_info                (i_tx_info),
      .i_sb_tx_req              (i_sb_tx_req),
      .i_sb_tx_rsp              (i_sb_tx_rsp),
      .i_sb_tx_done             (i_sb_tx_done),
      .i_tx_done                (i_tx_done),
      .init_train_en            (init_train_en_reg),
      .o_rx_sb_rsp              (o_rx_sb_rsp),
      .i_current_state          (current_state),
      .o_timer_8ms              (o_timer_8ms),
      .o_tx_encoding            (tx_enc_reversal),
      .o_tx_data                (tx_data_reversal),
      .o_tx_info                (tx_info_reversal),
      .o_tx_sb_req              (tx_sb_req_reversal),
      .o_tx_sb_rsp              (tx_sb_rsp_reversal),
      .o_tx_sb_done             (tx_sb_done_reversal),
      .o_train_error            (te_tx_reversal),
      .o_done_mbinit_reversal_tx(raw_done_tx_reversal)
  );

  // ----- RX MBINIT_REVERSAL -----
  ucie_ltsm_rx_mbinit_reversal #(
      .DECODING_WIDTH(DECODING_WIDTH),
      .DATA_WIDTH    (DATA_WIDTH),
      .INFO_WIDTH    (INFO_WIDTH)
  ) u_rx_reversal (
      .i_clk                    (i_clk),
      .i_reset                  (i_reset),
      .i_rx_decoding            (i_rx_decoding),
      .i_rx_data                (i_rx_data),
      .i_rx_info                (i_rx_info),
      .i_sb_rx_req              (i_sb_rx_req),
      .i_sb_rx_rsp              (i_sb_rx_rsp),
      .i_sb_rx_done             (i_sb_rx_done),
      .i_rx_done                (i_rx_done),
      .init_train_en            (init_train_en_reg),
      .i_current_state          (current_state),
      .o_timer_8ms              (o_timer_8ms),
      .i_rx_data_results        (i_rx_reversal_pattern_results),
      .o_rx_encoding            (rx_enc_reversal),
      .o_rx_data                (rx_data_reversal),
      .o_rx_info                (rx_info_reversal),
      .o_rx_sb_req              (rx_sb_req_reversal),
      .o_rx_sb_rsp              (rx_sb_rsp_reversal),
      .o_rx_sb_done             (rx_sb_done_reversal),
      .o_train_error            (te_rx_reversal),
      .o_done_mbinit_reversal_rx(raw_done_rx_reversal)
  );

  // ----- TX MBINIT_REPAIRMB -----
  ucie_ltsm_tx_mbinit_repairmb #(
      .DECODING_WIDTH(DECODING_WIDTH),
      .DATA_WIDTH    (DATA_WIDTH),
      .INFO_WIDTH    (INFO_WIDTH)
  ) u_tx_repairmb (
      .i_clk                    (i_clk),
      .i_reset                  (i_reset),
      .i_tx_decoding            (i_tx_decoding),
      .i_tx_data                (i_tx_data),
      .i_tx_info                (i_tx_info),
      .i_sb_tx_req              (i_sb_tx_req),
      .i_sb_tx_rsp              (i_sb_tx_rsp),
      .i_sb_tx_done             (i_sb_tx_done),
      .i_tx_done                (i_tx_done),
      .init_train_en            (init_train_en_reg),
      .o_rx_sb_rsp              (o_rx_sb_rsp),
      .i_current_state          (current_state),
      .o_timer_8ms              (o_timer_8ms),
      .i_tx_sweep_result        (i_tx_sweep_result),
      .o_tx_encoding            (tx_enc_repairmb),
      .r_lane_map               (tx_lane_map),
      .o_tx_data                (tx_data_repairmb),
      .o_tx_info                (tx_info_repairmb),
      .o_tx_sb_req              (tx_sb_req_repairmb),
      .o_tx_sb_rsp              (tx_sb_rsp_repairmb),
      .o_tx_sb_done             (tx_sb_done_repairmb),
      .o_train_error            (te_tx_repairmb),
      .o_done_mbinit_repairmb_tx(raw_done_tx_repairmb)
  );

  // ----- RX MBINIT_REPAIRMB -----
  ucie_ltsm_rx_mbinit_repairmb #(
      .DECODING_WIDTH(DECODING_WIDTH),
      .DATA_WIDTH    (DATA_WIDTH),
      .INFO_WIDTH    (INFO_WIDTH)
  ) u_rx_repairmb (
      .i_clk                    (i_clk),
      .i_reset                  (i_reset),
      .i_rx_decoding            (i_rx_decoding),
      .i_rx_data                (i_rx_data),
      .i_rx_info                (i_rx_info),
      .i_sb_rx_req              (i_sb_rx_req),
      .i_sb_rx_rsp              (i_sb_rx_rsp),
      .i_sb_rx_done             (i_sb_rx_done),
      .i_rx_done                (i_rx_done),
      .init_train_en            (init_train_en_reg),
      .i_current_state          (current_state),
      .o_timer_8ms              (o_timer_8ms),
      .i_rx_sweep_result        (i_rx_sweep_result),
      .o_rx_encoding            (rx_enc_repairmb),
      .o_rx_data                (rx_data_repairmb),
      .r_lane_map               (rx_lane_map),
      .o_rx_info                (rx_info_repairmb),
      .o_rx_sb_req              (rx_sb_req_repairmb),
      .o_rx_sb_rsp              (rx_sb_rsp_repairmb),
      .o_rx_sb_done             (rx_sb_done_repairmb),
      .o_train_error            (te_rx_repairmb),
      .o_done_mbinit_repairmb_rx(raw_done_rx_repairmb)
  );

  // ----- TX TRAINERROR -----
  ucie_ltsm_tx_trainerror #(
      .DECODING_WIDTH(DECODING_WIDTH),
      .DATA_WIDTH    (DATA_WIDTH),
      .INFO_WIDTH    (INFO_WIDTH)
  ) u_tx_trainerror (
      .i_clk               (i_clk),
      .i_reset             (i_reset),
      .i_tx_decoding       (i_tx_decoding),
      .i_tx_data           (i_tx_data),
      .i_tx_info           (i_tx_info),
      .i_sb_tx_req         (i_sb_tx_req),
      .i_sb_cur_msg_done   (i_sb_cur_msg_done),
      .i_sb_tx_rsp         (i_sb_tx_rsp),
      .i_sb_tx_done        (i_sb_tx_done),
      .i_tx_done           (i_tx_done),
      .i_current_state     (current_state),
      .o_timer_8ms         (o_timer_8ms),
      .i_lp_linkerror      (i_lp_linkerror),
      .o_tx_encoding       (tx_enc_trainerror),
      .o_tx_data           (tx_data_trainerror),
      .o_tx_info           (tx_info_trainerror),
      .o_tx_sb_req         (tx_sb_req_trainerror),
      .o_tx_sb_rsp         (tx_sb_rsp_trainerror),
      .o_tx_sb_done        (tx_sb_done_trainerror),
      .o_train_error       (te_tx_trainerror),
      .o_done_trainerror_tx(raw_done_tx_trainerror)
  );

  // ----- RX TRAINERROR -----
  ucie_ltsm_rx_trainerror #(
      .DECODING_WIDTH(DECODING_WIDTH),
      .DATA_WIDTH    (DATA_WIDTH),
      .INFO_WIDTH    (INFO_WIDTH)
  ) u_rx_trainerror (
      .i_clk               (i_clk),
      .i_reset             (i_reset),
      .i_rx_decoding       (i_rx_decoding),
      .i_rx_data           (i_rx_data),
      .i_rx_info           (i_rx_info),
      .i_sb_cur_msg_done   (i_sb_cur_msg_done),
      .i_sb_rx_req         (i_sb_rx_req),
      .i_sb_rx_rsp         (i_sb_rx_rsp),
      .i_lp_linkerror      (i_lp_linkerror),
      .i_sb_rx_done        (i_sb_rx_done),
      .i_rx_done           (i_rx_done),
      .i_current_state     (current_state),
      .o_timer_8ms         (o_timer_8ms),
      .o_rx_encoding       (rx_enc_trainerror),
      .o_rx_data           (rx_data_trainerror),
      .o_rx_info           (rx_info_trainerror),
      .o_rx_sb_req         (rx_sb_req_trainerror),
      .o_rx_sb_rsp         (rx_sb_rsp_trainerror),
      .o_rx_sb_done        (rx_sb_done_trainerror),
      .o_train_error       (te_rx_trainerror),
      .o_done_trainerror_rx(raw_done_rx_trainerror)
  );

  // =========================================================================
  // Output MUX  � select active sub-FSM outputs based on current_state
  // =========================================================================

  // Internal wire needed for feedback to TX REPAIRVAL/REVERSAL/REPAIRMB
  // logic o_rx_sb_rsp;

  always_comb begin
    // TX defaults
    o_tx_encoding = tx_enc_reset;
    o_tx_data     = '0;
    o_tx_info     = '0;
    o_tx_sb_req   = 0;
    o_tx_sb_rsp   = 0;

    // RX defaults
    o_rx_encoding = rx_enc_reset;
    o_rx_data     = '0;
    o_rx_info     = '0;
    o_rx_sb_req   = 0;
    o_rx_sb_rsp   = 0;
    // o_rx_sb_done  = 0;

    case (current_state)
      RESET: begin
        o_tx_encoding = tx_enc_reset;
        o_rx_encoding = rx_enc_reset;
        // RESET sub-FSMs have no data/sideband outputs
      end

      SBINIT: begin
        o_tx_encoding = tx_enc_sbinit;
        o_tx_sb_req   = tx_sb_req_sbinit;
        o_tx_sb_rsp   = tx_sb_rsp_sbinit;


        o_rx_encoding = rx_enc_sbinit;
        o_rx_data     = rx_data_sbinit;
        o_rx_info     = rx_info_sbinit;
        o_rx_sb_req   = rx_sb_req_sbinit;
        o_rx_sb_rsp   = rx_sb_rsp_sbinit;
        // o_rx_sb_done  = rx_sb_done_sbinit;
      end

      MBINIT_PARAM: begin
        o_tx_encoding = tx_enc_param;
        o_tx_data     = tx_data_param;
        o_tx_info     = tx_info_param;
        o_tx_sb_req   = tx_sb_req_param;
        o_tx_sb_rsp   = tx_sb_rsp_param;


        o_rx_encoding = rx_enc_param;
        o_rx_data     = rx_data_param;
        o_rx_info     = rx_info_param;
        o_rx_sb_req   = rx_sb_req_param;
        o_rx_sb_rsp   = rx_sb_rsp_param;
        // o_rx_sb_done  = rx_sb_done_param;
      end

      MBINIT_CAL: begin
        o_tx_encoding = tx_enc_cal;
        o_tx_data     = tx_data_cal;
        o_tx_info     = tx_info_cal;
        o_tx_sb_req   = tx_sb_req_cal;
        o_tx_sb_rsp   = tx_sb_rsp_cal;


        o_rx_encoding = rx_enc_cal;
        o_rx_data     = rx_data_cal;
        o_rx_info     = rx_info_cal;
        o_rx_sb_req   = rx_sb_req_cal;
        o_rx_sb_rsp   = rx_sb_rsp_cal;
        // o_rx_sb_done  = rx_sb_done_cal;
      end

      MBINIT_REPAIRCLK: begin
        o_tx_encoding = tx_enc_repairclk;
        o_tx_data     = tx_data_repairclk;
        o_tx_info     = tx_info_repairclk;
        o_tx_sb_req   = tx_sb_req_repairclk;
        o_tx_sb_rsp   = tx_sb_rsp_repairclk;


        o_rx_encoding = rx_enc_repairclk;
        o_rx_data     = rx_data_repairclk;
        o_rx_info     = rx_info_repairclk;
        o_rx_sb_req   = rx_sb_req_repairclk;
        o_rx_sb_rsp   = rx_sb_rsp_repairclk;
        // o_rx_sb_done  = rx_sb_done_repairclk;
      end

      MBINIT_REPAIRVAL: begin
        o_tx_encoding = tx_enc_repairval;
        o_tx_data     = tx_data_repairval;
        o_tx_info     = tx_info_repairval;
        o_tx_sb_req   = tx_sb_req_repairval;
        o_tx_sb_rsp   = tx_sb_rsp_repairval;


        o_rx_encoding = rx_enc_repairval;
        o_rx_data     = rx_data_repairval;
        o_rx_info     = rx_info_repairval;
        o_rx_sb_req   = rx_sb_req_repairval;
        o_rx_sb_rsp   = rx_sb_rsp_repairval;
        // o_rx_sb_done  = rx_sb_done_repairval;
      end

      MBINIT_REVERSAL: begin
        o_tx_encoding = tx_enc_reversal;
        o_tx_data     = tx_data_reversal;
        o_tx_info     = tx_info_reversal;
        o_tx_sb_req   = tx_sb_req_reversal;
        o_tx_sb_rsp   = tx_sb_rsp_reversal;


        o_rx_encoding = rx_enc_reversal;
        o_rx_data     = rx_data_reversal;
        o_rx_info     = rx_info_reversal;
        o_rx_sb_req   = rx_sb_req_reversal;
        o_rx_sb_rsp   = rx_sb_rsp_reversal;
        // o_rx_sb_done  = rx_sb_done_reversal;
      end

      MBINIT_REPAIRMB: begin
        o_tx_encoding = tx_enc_repairmb;
        o_tx_data     = tx_data_repairmb;
        o_tx_info     = tx_info_repairmb;
        o_tx_sb_req   = tx_sb_req_repairmb;
        o_tx_sb_rsp   = tx_sb_rsp_repairmb;


        o_rx_encoding = rx_enc_repairmb;
        o_rx_data     = rx_data_repairmb;
        o_rx_info     = rx_info_repairmb;
        o_rx_sb_req   = rx_sb_req_repairmb;
        o_rx_sb_rsp   = rx_sb_rsp_repairmb;
        // o_rx_sb_done  = rx_sb_done_repairmb;
      end

      TRAINERROR: begin
        o_tx_encoding = tx_enc_trainerror;
        o_tx_data     = tx_data_trainerror;
        o_tx_info     = tx_info_trainerror;
        o_tx_sb_req   = tx_sb_req_trainerror;
        o_tx_sb_rsp   = tx_sb_rsp_trainerror;


        o_rx_encoding = rx_enc_trainerror;
        o_rx_data     = rx_data_trainerror;
        o_rx_info     = rx_info_trainerror;
        o_rx_sb_req   = rx_sb_req_trainerror;
        o_rx_sb_rsp   = rx_sb_rsp_trainerror;
        // o_rx_sb_done  = rx_sb_done_trainerror;
      end

      default: begin
        o_tx_encoding = tx_enc_reset;
        o_rx_encoding = rx_enc_reset;
      end
    endcase

    // Feed RX RSP back to TX REPAIRVAL / REVERSAL / REPAIRMB (internal signal)
    // Removed self-assignment that caused a combinational loop warning.
  end

  // =========================================================================
  // Assertions
  // =========================================================================
`ifdef SIM

  // State must be one-hot valid
  property valid_state;
    @(posedge i_clk) disable iff (i_reset)
        (current_state inside {RESET, SBINIT, MBINIT_PARAM,
                               MBINIT_CAL, MBINIT_REPAIRCLK,
                               MBINIT_REPAIRVAL, MBINIT_REVERSAL,
                               MBINIT_REPAIRMB, TRAINERROR});
  endproperty
  VALID_STATE :
  assert property (valid_state)
  else $error("ASSERT FAIL [VALID_STATE]: main FSM in illegal state %0h", current_state);

  // SBINIT error ? must be in RESET next cycle
  property sbinit_error_to_reset;
    @(posedge i_clk) disable iff (i_reset)
        (current_state == SBINIT && any_sbinit_error)
        |=> current_state == RESET;
  endproperty
  SBINIT_ERR_TO_RESET :
  assert property (sbinit_error_to_reset)
  else $error("ASSERT FAIL [SBINIT_ERR_TO_RESET]: did not return to RESET on SBINIT error");

  // Any other error ? must enter TRAINERROR next cycle
  property other_error_to_trainerror;
    @(posedge i_clk) disable iff (i_reset)
        (any_other_error && !any_sbinit_error)
        |=> current_state == TRAINERROR;
  endproperty
  OTHER_ERR_TO_TRAINERROR :
  assert property (other_error_to_trainerror)
  else $error("ASSERT FAIL [OTHER_ERR_TO_TRAINERROR]: did not enter TRAINERROR on error");

  // TRAINERROR done ? must return to RESET
  property trainerror_done_to_reset;
    @(posedge i_clk) disable iff (i_reset)
        (current_state == TRAINERROR && done_tx_trainerror && done_rx_trainerror)
        |=> current_state == RESET;
  endproperty
  TRAINERROR_TO_RESET :
  assert property (trainerror_done_to_reset)
  else $error("ASSERT FAIL [TRAINERROR_TO_RESET]: did not return to RESET after TRAINERROR");

  // init_train_en can only be high in MBINIT_REPAIRMB
  property init_train_en_gated;
    @(posedge i_clk) disable iff (i_reset) o_init_train_en |-> current_state == MBINIT_REPAIRMB;
  endproperty
  INIT_TRAIN_EN_GATED :
  assert property (init_train_en_gated)
  else $error("ASSERT FAIL [INIT_TRAIN_EN_GATED]: init_train_en asserted outside REPAIRMB");

  // Active training error while init_train_en ? must enter TRAINERROR
  property active_error_to_trainerror;
    @(posedge i_clk) disable iff (i_reset)
        (init_train_en_reg && i_train_active_error)
        |=> current_state == TRAINERROR;
  endproperty
  ACTIVE_ERR_TO_TRAINERROR :
  assert property (active_error_to_trainerror)
  else
    $error(
        "ASSERT FAIL [ACTIVE_ERR_TO_TRAINERROR]: did not enter TRAINERROR on active training error"
    );

`endif

endmodule
