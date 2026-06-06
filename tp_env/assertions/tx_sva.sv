//=============================================================================
// File       : tx_sva.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: SystemVerilog Assertions — protocol invariants on DUT outputs.
//              Checks egress tri-state, LTSM handshake timing (pll_stable,
//              supply_stable, tx_done), and RDI backpressure covers.
//
//              Only asserts on DUT-driven signals, NOT DV-driven stimulus.
//              Designed to be bound to the DUT interfaces.
//=============================================================================

module tx_sva (
  // Egress interface signals (DUT outputs)
  input logic        ui_clk,
  input logic        d_clk,
  input logic        rst,
  input logic [15:0] tx_data,
  input logic        tx_clkp,
  input logic        tx_clkn,
  input logic        tx_valid,
  input logic        tx_track,

  // LTSM interface signals
  input logic        clk,
  input logic [8:0]  tx_encoding,

  // LTSM DUT status outputs
  input logic        pll_stable,
  input logic        supply_stable,
  input logic        tx_done,

  // RDI interface signals (for cover properties only — DV drives lp_*, DUT drives pl_trdy)
  input logic        lp_valid,
  input logic        lp_irdy,
  input logic        pl_trdy
);

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import tx_defs_pkg::*;

    // ---- Per-state tx_done timing ----
  localparam int REPAIRCLK_ITERATIONS      = 128;
  localparam int REPAIRCLK_CYCLES_PER_ITER = 24;
  localparam int REPAIRCLK_TOTAL_CYCLES    = REPAIRCLK_ITERATIONS * REPAIRCLK_CYCLES_PER_ITER;

  localparam int REPAIRVAL_ITERATIONS      = 128;
  localparam int REPAIRVAL_CYCLES_PER_ITER = 8;
  localparam int REPAIRVAL_TOTAL_CYCLES    = REPAIRVAL_ITERATIONS * REPAIRVAL_CYCLES_PER_ITER;

  localparam int REVERSAL_ID_ITERATIONS      = 128;
  localparam int REVERSAL_ID_CYCLES_PER_ITER = 16;
  localparam int REVERSAL_ID_TOTAL_CYCLES    = REVERSAL_ID_ITERATIONS * REVERSAL_ID_CYCLES_PER_ITER;

  localparam int D2C_TX_ITERATIONS      = 128;
  localparam int D2C_TX_CYCLES_PER_ITER = 8;
  localparam int D2C_TX_TOTAL_CYCLES    = D2C_TX_ITERATIONS * D2C_TX_CYCLES_PER_ITER;

  localparam int D2C_RX_TOTAL_CYCLES = 4000;

  // =========================================================================
  //  Helpers — use package functions for state classification
  // =========================================================================

  wire is_tristate   = is_tristate_state(ltsm_encoding_e'(tx_encoding));
  wire is_pattern_gen = is_pattern_gen_state(ltsm_encoding_e'(tx_encoding));
  wire is_active     = is_active_data(ltsm_encoding_e'(tx_encoding));

  logic busy_clkp;
  logic busy_clkn;
  logic pattern_done_clkp;
  logic pattern_done_clkn;
  logic valid_state;

  always @(posedge d_clk or posedge rst) begin
      if (rst)
          busy_clkp <= 0;
      else if (!busy_clkp && (tx_encoding == REPAIRCLK_CLK_PATTERN_GEN) && $rose(tx_clkp))
          busy_clkp <= 1;
      else if (busy_clkp && pattern_done_clkp) begin // assert pattern_done from your DUT or a monitor
          busy_clkp <= 0;
          pattern_done_clkp <= 0;
      end    
  end

  always @(posedge d_clk or posedge rst) begin
      if (rst)
          busy_clkn <= 0;
      else if (!busy_clkn && (tx_encoding == REPAIRCLK_CLK_PATTERN_GEN) && $fell(tx_clkn))
          busy_clkn <= 1;
      else if (busy_clkn && pattern_done_clkn) begin  // assert pattern_done from your DUT or a monitor
          busy_clkn <= 0;
          pattern_done_clkn <= 0;
      end
          
  end

  // Operation states: pattern gen + apply/reversal (states that expect tx_done)
  wire is_tx_done_state = is_pattern_gen ||
    (tx_encoding == REVERSAL_APPLY)              ||
    (tx_encoding == REPAIRMB_APPLY_DEGRADE_HND)  ||
    (tx_encoding == REPAIR_APPLY_DEGRADE_HND);

  // =========================================================================
  //  Egress Tri-State Assertions
  // =========================================================================
  //
  //  During RESET, SBINIT, PARAM, and CAL states, all egress outputs
  //  must be High-Z.

  property p_data_tristate;
    @(posedge ui_clk) disable iff (rst)
    is_tristate |-> (tx_data === 16'hzzzz);
  endproperty

  assert_data_tristate: assert property (p_data_tristate)
    else `uvm_error("SVA", $sformatf("tx_data not Hi-Z during tri-state state (enc=9'h%03h)", tx_encoding))

  property p_valid_tristate;
    @(posedge ui_clk) disable iff (rst)
    is_tristate |-> (tx_valid === 1'bz);
  endproperty

  assert_valid_tristate: assert property (p_valid_tristate)
    else `uvm_error("SVA", $sformatf("tx_valid not Hi-Z during tri-state state (enc=9'h%03h)", tx_encoding))

  property p_track_tristate;
    @(posedge ui_clk) disable iff (rst)
    is_tristate |-> (tx_track === 1'bz);
  endproperty

  assert_track_tristate: assert property (p_track_tristate)
    else `uvm_error("SVA", $sformatf("tx_track not Hi-Z during tri-state state (enc=9'h%03h)", tx_encoding))

  property p_clk_tristate;
    @(posedge ui_clk) disable iff (rst)
    is_tristate |-> (tx_clkp === 1'bz && tx_clkn === 1'bz);
  endproperty

  assert_clk_tristate: assert property (p_clk_tristate)
    else `uvm_error("SVA", $sformatf("tx_clk not Hi-Z during tri-state state (enc=9'h%03h)", tx_encoding))

  // =========================================================================
  //  LTSM DUT Output Assertions — pll_stable & supply_stable
  // =========================================================================

  // pll_stable must assert 1 cycle after being in RESET
  property p_pll_stable_in_reset;
    @(posedge clk) disable iff (rst)
    (tx_encoding == RESET) |=> pll_stable;
  endproperty

  assert_pll_stable: assert property (p_pll_stable_in_reset)
    else `uvm_error("SVA", "pll_stable not asserted 1 cycle after RESET")

  // supply_stable must assert 1 cycle after being in RESET
  property p_supply_stable_in_reset;
    @(posedge clk) disable iff (rst)
    (tx_encoding == RESET) |=> supply_stable;
  endproperty

  assert_supply_stable: assert property (p_supply_stable_in_reset)
    else `uvm_error("SVA", "supply_stable not asserted 1 cycle after RESET")


  // =========================================================================
  //  LTSM DUT Output Assertions — tx_done
  // =========================================================================

  // tx_done must only rise during operation states (pattern gen + apply)
  property p_tx_done_only_in_op_states;
    @(posedge clk) disable iff (rst)
    $rose(tx_done) |-> is_tx_done_state;
  endproperty

  assert_tx_done_valid_state: assert property (p_tx_done_only_in_op_states)
    else `uvm_error("SVA", $sformatf("tx_done asserted in non-operation state (enc=9'h%03h)", tx_encoding))


  property p_tx_done_repairclk_clk;
    @(posedge clk) disable iff (rst)
    $rose(tx_encoding == REPAIRCLK_CLK_PATTERN_GEN) |=> ##(REPAIRCLK_TOTAL_CYCLES) tx_done;
  endproperty

  assert_tx_done_repairclk: assert property (p_tx_done_repairclk_clk)
    else `uvm_error("SVA", $sformatf("tx_done not asserted %0d cycles after REPAIRCLK_CLK_PATTERN_GEN", REPAIRCLK_TOTAL_CYCLES))

  property p_tx_done_repairval_valid;
    @(posedge clk) disable iff (rst)
    $rose(tx_encoding == REPAIRVAL_VALID_PATTERN_GEN) |=> ##(REPAIRVAL_TOTAL_CYCLES) tx_done;
  endproperty

  assert_tx_done_repairval: assert property (p_tx_done_repairval_valid)
    else `uvm_error("SVA", $sformatf("tx_done not asserted %0d cycles after REPAIRVAL_VALID_PATTERN_GEN", REPAIRVAL_TOTAL_CYCLES))

  property p_tx_done_reversal_id;
    @(posedge clk) disable iff (rst)
    $rose(tx_encoding == REVERSAL_PER_LANE_ID_GEN) |=> ##(REVERSAL_ID_TOTAL_CYCLES) tx_done;
  endproperty

  assert_tx_done_reversal_id: assert property (p_tx_done_reversal_id)
    else `uvm_error("SVA", $sformatf("tx_done not asserted %0d cycles after REVERSAL_PER_LANE_ID_GEN", REVERSAL_ID_TOTAL_CYCLES))

  property p_tx_done_d2c_tx;
    @(posedge clk) disable iff (rst)
    $rose(tx_encoding == D2C_TX_PATTERN_GEN) |=> ##(D2C_TX_TOTAL_CYCLES) tx_done;
  endproperty

  assert_tx_done_d2c_tx: assert property (p_tx_done_d2c_tx)
    else `uvm_error("SVA", $sformatf("tx_done not asserted %0d cycles after D2C_TX_PATTERN_GEN", D2C_TX_TOTAL_CYCLES))

  property p_tx_done_d2c_rx;
    @(posedge clk) disable iff (rst)
    $rose(tx_encoding == D2C_RX_PATTERN_GEN) |=> ##(D2C_RX_TOTAL_CYCLES) tx_done;
  endproperty

  assert_tx_done_d2c_rx: assert property (p_tx_done_d2c_rx)
    else `uvm_error("SVA", $sformatf("tx_done not asserted %0d cycles after D2C_RX_PATTERN_GEN", D2C_RX_TOTAL_CYCLES))

  property p_tx_done_reversal_apply;
    @(posedge clk) disable iff (rst)
    $rose(tx_encoding == REVERSAL_APPLY) |=> tx_done;
  endproperty

  assert_tx_done_reversal_apply: assert property (p_tx_done_reversal_apply)
    else `uvm_error("SVA", "tx_done not asserted 1 cycle after REVERSAL_APPLY")

  property p_tx_done_repairmb_degrade;
    @(posedge clk) disable iff (rst)
    $rose(tx_encoding == REPAIRMB_APPLY_DEGRADE_HND) |=> tx_done;
  endproperty

  assert_tx_done_repairmb: assert property (p_tx_done_repairmb_degrade)
    else `uvm_error("SVA", "tx_done not asserted 1 cycle after REPAIRMB_APPLY_DEGRADE_HND")

  property p_tx_done_repair_degrade;
    @(posedge clk) disable iff (rst)
    $rose(tx_encoding == REPAIR_APPLY_DEGRADE_HND) |=> tx_done;
  endproperty

  assert_tx_done_repair: assert property (p_tx_done_repair_degrade)
    else `uvm_error("SVA", "tx_done not asserted 1 cycle after REPAIR_APPLY_DEGRADE_HND")

  // =========================================================================
  //  Cover Properties
  // =========================================================================

  // Backpressure: in ACTIVE state, all signals high then pl_trdy drops
  cover_backpressure: cover property (
    @(posedge clk) disable iff (rst)
    is_active && lp_valid && lp_irdy && pl_trdy ##1 !pl_trdy
  );

  // Successful flit transfer in ACTIVE state
  cover_flit_transfer: cover property (
    @(posedge clk) disable iff (rst)
    is_active && lp_valid && lp_irdy && pl_trdy
  );

  // =========================================================================
  //  Pattern Generator Properties
  // =========================================================================

  sequence clockp_pattern_gen;
    ((tx_clkp == 1 ##1 tx_clkp == 0) [*16] ##1 (tx_clkp == 0) [*16]) [*128];
  endsequence

  property clockp_pattern_property;
    @(posedge d_clk) disable iff (rst)
    ((tx_encoding == REPAIRCLK_CLK_PATTERN_GEN) && $rose(tx_clkp)) && !busy_clkp |-> clockp_pattern_gen;
  endproperty

  clkp_assertion: assert property (clockp_pattern_property) begin
    pattern_done_clkp = 1;
  end
    else `uvm_error("SVA", "Clock_P pattern not generated correctly during REPAIRCLK_CLK_PATTERN_GEN")

  sequence clockn_pattern_gen;
    ((tx_clkn == 0 ##1 tx_clkn == 1) [*16] ##1 (tx_clkn == 1) [*16] ) [*128];
  endsequence

  property clockn_pattern_property;
    @(posedge d_clk) disable iff (rst)
    ((tx_encoding == REPAIRCLK_CLK_PATTERN_GEN) && $fell(tx_clkn)) && !busy_clkn |-> clockn_pattern_gen;
  endproperty

  clkn_assertion: assert property (clockn_pattern_property) begin
    pattern_done_clkn = 1;
  end
    else `uvm_error("SVA", "Clock_N pattern not generated correctly during REPAIRCLK_CLK_PATTERN_GEN")

  sequence valid_pattern_gen;
    ((tx_valid == 1) [*4] ##1 (tx_valid == 0) [*4]);
  endsequence

  property valid_pattern_property;
    @(posedge d_clk) disable iff (rst || tx_done)
    $rose(tx_valid) && !tx_done |-> valid_pattern_gen;
  endproperty

  valid_assertion: assert property (valid_pattern_property)
  else
    `uvm_error("SVA", "tx_valid pattern not generated correctly during REPAIRVAL_VALID_PATTERN_GEN or D2C pattern gen states")

  always_comb begin
    assert (tx_track === tx_clkp);
  end


  always @(*) begin
    if (is_valid_gen_state(ltsm_encoding_e'(tx_encoding))) begin
      valid_state = 1;
    end else if (is_pattern_gen_state(ltsm_encoding_e'(tx_encoding))) begin
      valid_state = valid_state;
    end else begin
      valid_state = 0;
    end
  end



endmodule : tx_sva
