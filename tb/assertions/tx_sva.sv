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
  input logic        rst_n,
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

  // =========================================================================
  //  Helpers — use package functions for state classification
  // =========================================================================

  wire is_tristate   = is_tristate_state(ltsm_encoding_e'(tx_encoding));
  wire is_pattern_gen = is_pattern_gen_state(ltsm_encoding_e'(tx_encoding));
  wire is_active     = is_active_data(ltsm_encoding_e'(tx_encoding));

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
    @(posedge ui_clk) disable iff (!rst_n)
    is_tristate |-> (tx_data === 16'hzzzz);
  endproperty

  assert_data_tristate: assert property (p_data_tristate)
    else `uvm_error("SVA", $sformatf("tx_data not Hi-Z during tri-state state (enc=9'h%03h)", tx_encoding))

  property p_valid_tristate;
    @(posedge ui_clk) disable iff (!rst_n)
    is_tristate |-> (tx_valid === 1'bz);
  endproperty

  assert_valid_tristate: assert property (p_valid_tristate)
    else `uvm_error("SVA", $sformatf("tx_valid not Hi-Z during tri-state state (enc=9'h%03h)", tx_encoding))

  property p_track_tristate;
    @(posedge ui_clk) disable iff (!rst_n)
    is_tristate |-> (tx_track === 1'bz);
  endproperty

  assert_track_tristate: assert property (p_track_tristate)
    else `uvm_error("SVA", $sformatf("tx_track not Hi-Z during tri-state state (enc=9'h%03h)", tx_encoding))

  property p_clk_tristate;
    @(posedge ui_clk) disable iff (!rst_n)
    is_tristate |-> (tx_clkp === 1'bz && tx_clkn === 1'bz);
  endproperty

  assert_clk_tristate: assert property (p_clk_tristate)
    else `uvm_error("SVA", $sformatf("tx_clk not Hi-Z during tri-state state (enc=9'h%03h)", tx_encoding))

  // =========================================================================
  //  LTSM DUT Output Assertions — pll_stable & supply_stable
  // =========================================================================

  // pll_stable must assert 1 cycle after being in RESET
  property p_pll_stable_in_reset;
    @(posedge clk) disable iff (!rst_n)
    (tx_encoding == RESET) |=> pll_stable;
  endproperty

  assert_pll_stable: assert property (p_pll_stable_in_reset)
    else `uvm_error("SVA", "pll_stable not asserted 1 cycle after RESET")

  // supply_stable must assert 1 cycle after being in RESET
  property p_supply_stable_in_reset;
    @(posedge clk) disable iff (!rst_n)
    (tx_encoding == RESET) |=> supply_stable;
  endproperty

  assert_supply_stable: assert property (p_supply_stable_in_reset)
    else `uvm_error("SVA", "supply_stable not asserted 1 cycle after RESET")


  // =========================================================================
  //  LTSM DUT Output Assertions — tx_done
  // =========================================================================

  // tx_done must only rise during operation states (pattern gen + apply)
  property p_tx_done_only_in_op_states;
    @(posedge clk) disable iff (!rst_n)
    $rose(tx_done) |-> is_tx_done_state;
  endproperty

  assert_tx_done_valid_state: assert property (p_tx_done_only_in_op_states)
    else `uvm_error("SVA", $sformatf("tx_done asserted in non-operation state (enc=9'h%03h)", tx_encoding))

  // ---- Per-state tx_done timing (128 cycles placeholder — update per spec) ----

  property p_tx_done_repairclk_clk;
    @(posedge clk) disable iff (!rst_n)
    $rose(tx_encoding == REPAIRCLK_CLK_PATTERN_GEN) |-> ##128 tx_done;
  endproperty

  assert_tx_done_repairclk: assert property (p_tx_done_repairclk_clk)
    else `uvm_error("SVA", "tx_done not asserted 128 cycles after REPAIRCLK_CLK_PATTERN_GEN")

  property p_tx_done_repairval_valid;
    @(posedge clk) disable iff (!rst_n)
    $rose(tx_encoding == REPAIRVAL_VALID_PATTERN_GEN) |-> ##128 tx_done;
  endproperty

  assert_tx_done_repairval: assert property (p_tx_done_repairval_valid)
    else `uvm_error("SVA", "tx_done not asserted 128 cycles after REPAIRVAL_VALID_PATTERN_GEN")

  property p_tx_done_reversal_id;
    @(posedge clk) disable iff (!rst_n)
    $rose(tx_encoding == REVERSAL_PER_LANE_ID_GEN) |-> ##128 tx_done;
  endproperty

  assert_tx_done_reversal_id: assert property (p_tx_done_reversal_id)
    else `uvm_error("SVA", "tx_done not asserted 128 cycles after REVERSAL_PER_LANE_ID_GEN")

  property p_tx_done_d2c_tx;
    @(posedge clk) disable iff (!rst_n)
    $rose(tx_encoding == D2C_TX_PATTERN_GEN) |-> ##128 tx_done;
  endproperty

  assert_tx_done_d2c_tx: assert property (p_tx_done_d2c_tx)
    else `uvm_error("SVA", "tx_done not asserted 128 cycles after D2C_TX_PATTERN_GEN")

  property p_tx_done_d2c_rx;
    @(posedge clk) disable iff (!rst_n)
    $rose(tx_encoding == D2C_RX_PATTERN_GEN) |-> ##128 tx_done;
  endproperty

  assert_tx_done_d2c_rx: assert property (p_tx_done_d2c_rx)
    else `uvm_error("SVA", "tx_done not asserted 128 cycles after D2C_RX_PATTERN_GEN")

  property p_tx_done_reversal_apply;
    @(posedge clk) disable iff (!rst_n)
    $rose(tx_encoding == REVERSAL_APPLY) |-> ##128 tx_done;
  endproperty

  assert_tx_done_reversal_apply: assert property (p_tx_done_reversal_apply)
    else `uvm_error("SVA", "tx_done not asserted 128 cycles after REVERSAL_APPLY")

  property p_tx_done_repairmb_degrade;
    @(posedge clk) disable iff (!rst_n)
    $rose(tx_encoding == REPAIRMB_APPLY_DEGRADE_HND) |-> ##128 tx_done;
  endproperty

  assert_tx_done_repairmb: assert property (p_tx_done_repairmb_degrade)
    else `uvm_error("SVA", "tx_done not asserted 128 cycles after REPAIRMB_APPLY_DEGRADE_HND")

  property p_tx_done_repair_degrade;
    @(posedge clk) disable iff (!rst_n)
    $rose(tx_encoding == REPAIR_APPLY_DEGRADE_HND) |-> ##128 tx_done;
  endproperty

  assert_tx_done_repair: assert property (p_tx_done_repair_degrade)
    else `uvm_error("SVA", "tx_done not asserted 128 cycles after REPAIR_APPLY_DEGRADE_HND")

  // =========================================================================
  //  Cover Properties
  // =========================================================================

  // Backpressure: in ACTIVE state, all signals high then pl_trdy drops
  cover_backpressure: cover property (
    @(posedge clk) disable iff (!rst_n)
    is_active && lp_valid && lp_irdy && pl_trdy ##1 !pl_trdy
  );

  // Successful flit transfer in ACTIVE state
  cover_flit_transfer: cover property (
    @(posedge clk) disable iff (!rst_n)
    is_active && lp_valid && lp_irdy && pl_trdy
  );

endmodule : tx_sva
