//=============================================================================
// File       : tx_tb_top.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: Top-level testbench module. Instantiates the DUT (or stub),
//              all interfaces, generates clocks and reset, sets virtual
//              interfaces in the config DB, and calls run_test().
//
//              Since the DUT is being developed in parallel, a placeholder
//              stub is used. Replace with actual DUT when available.
//=============================================================================

`timescale 1ns/1fs

module tx_tb_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import tx_defs_pkg::*;
  import tx_tb_pkg::*;

  // -------------------------------------------------------------------------
  //  Clock and Reset Generation
  // -------------------------------------------------------------------------

  // Logical clock (for RDI + LTSM agents)
  realtime clk_period = 10;
  logic clk;
  initial clk = 0;
  always #(clk_period/2) clk = ~clk;  // 100 MHz (10ns period)

  // Fast UI clock (for egress agent) — half-rate, 1 fast clk = 2 UI
  // Ratio: clk / ui_clk = 64
  // Starts at 1 so posedge ui_clk aligns with posedge clk
  realtime ui_clk_period = clk_period / 64;
  logic ui_clk;
  initial ui_clk = 1;
  always #(ui_clk_period/2) ui_clk = ~ui_clk;  // 6.4 GHz (156.25ps period)

  // Active-high reset
  logic rst;
  initial begin
    rst = 1;
    #100;
    rst = 0;
  end

  // -------------------------------------------------------------------------
  //  Interface Instantiations
  // -------------------------------------------------------------------------

  rdi_if  #(.NBYTES(256)) rdi_intf  (.clk(clk), .rst(rst));
  ltsm_if                 ltsm_intf (.clk(clk), .rst(rst));
  tx2link_if              tx2link_intf (.clk(clk), .ui_clk(ui_clk), .rst(rst));

  // -------------------------------------------------------------------------
  //  DUT — TX Path RTL wrapper
  // -------------------------------------------------------------------------
  //
  //  The wrapper adapts the tx_path RTL to the testbench interface:
  //  - Converts unpacked/packed array formats for data signals
  //  - Generates pll_stable and supply_stable (not in RTL)
  //  - Ties off i_halfrate to 1'b1 (half-rate mode)

  tx_dut_rtl_wrapper #(
    .NBYTES(256),
    .DATA_WIDTH(64),
    .LANES_NUMBER(16)
  ) dut_rtl (
    .clk(clk),
    .ui_clk(ui_clk),
    .rst(rst),

    // RDI
    .lp_data(rdi_intf.lp_data),
    .lp_valid(rdi_intf.lp_valid),
    .lp_irdy(rdi_intf.lp_irdy),
    .pl_trdy(rdi_intf.pl_trdy),

    // LTSM
    .tx_encoding(ltsm_intf.tx_encoding),
    .lane_map(ltsm_intf.lane_map),
    .pll_stable(ltsm_intf.pll_stable),
    .supply_stable(ltsm_intf.supply_stable),
    .tx_done(ltsm_intf.tx_done),

    // TX2LINK
    .tx_data(tx2link_intf.tx_data),
    .tx_clkp(tx2link_intf.tx_clkp),
    .tx_clkn(tx2link_intf.tx_clkn),
    .tx_valid(tx2link_intf.tx_valid),
    .tx_track(tx2link_intf.tx_track)
  );

  // -------------------------------------------------------------------------
  //  SVA — Protocol Assertions
  // -------------------------------------------------------------------------

  // Pack tx_data from unpacked [0:15] to packed [15:0] for SVA module
  logic [15:0] tx_data_packed;
  always_comb begin
    for (int i = 0; i < 16; i++)
      tx_data_packed[i] = tx2link_intf.tx_data[i];
  end

  tx_sva sva_inst (
    // Egress interface signals
    .ui_clk        (tx2link_intf.ui_clk),
    .d_clk         (ui_clk),
    .rst           (rst),
    .tx_data       (tx_data_packed),
    .tx_clkp       (tx2link_intf.tx_clkp),
    .tx_clkn       (tx2link_intf.tx_clkn),
    .tx_valid      (tx2link_intf.tx_valid),
    .tx_track      (tx2link_intf.tx_track),

    // LTSM interface signals
    .clk           (clk),
    .tx_encoding   (ltsm_intf.tx_encoding),

    // LTSM DUT status outputs
    .pll_stable    (ltsm_intf.pll_stable),
    .supply_stable (ltsm_intf.supply_stable),
    .tx_done       (ltsm_intf.tx_done),

    // RDI interface signals (covers only)
    .lp_valid      (rdi_intf.lp_valid),
    .lp_irdy       (rdi_intf.lp_irdy),
    .pl_trdy       (rdi_intf.pl_trdy)
  );

  // -------------------------------------------------------------------------
  //  Config DB — publish virtual interfaces
  // -------------------------------------------------------------------------

  initial begin
    uvm_config_db#(virtual rdi_if)::set(null, "*", "rdi_vif", rdi_intf);
    uvm_config_db#(virtual ltsm_if)::set(null, "*", "ltsm_vif", ltsm_intf);
    uvm_config_db#(virtual tx2link_if)::set(null, "*", "tx2link_vif", tx2link_intf);

    // Start UVM test (test name from +UVM_TESTNAME plusarg)
    run_test();
  end

endmodule : tx_tb_top
