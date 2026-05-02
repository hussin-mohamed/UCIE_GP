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

`timescale 1ns/1ps

module tx_tb_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import tx_defs_pkg::*;
  import tx_tb_pkg::*;

  // -------------------------------------------------------------------------
  //  Clock and Reset Generation
  // -------------------------------------------------------------------------

  // Logical clock (for RDI + LTSM agents)
  logic clk;
  initial clk = 0;
  always #5 clk = ~clk;  // 100 MHz (10ns period)

  // Fast UI clock (for egress agent) — half-rate, 1 fast clk = 2 UI
  logic ui_clk;
  initial ui_clk = 0;
  always #0.5 ui_clk = ~ui_clk;  // 1 GHz (1ns period) — placeholder

  // Active-low reset
  logic rst_n;
  initial begin
    rst_n = 0;
    #100;
    rst_n = 1;
  end

  // -------------------------------------------------------------------------
  //  Interface Instantiations
  // -------------------------------------------------------------------------

  rdi_if  #(.NBYTES(256)) rdi_intf  (.clk(clk), .rst_n(rst_n));
  ltsm_if                 ltsm_intf (.clk(clk), .rst_n(rst_n));
  tx2link_if              tx2link_intf (.ui_clk(ui_clk), .rst_n(rst_n));

  // -------------------------------------------------------------------------
  //  DUT Stub — replace with actual RTL when available
  // -------------------------------------------------------------------------
  //
  //  This stub provides minimal connectivity:
  //  - pl_trdy is always asserted (no backpressure by default)
  //  - pll_stable and supply_stable assert after a delay
  //  - tx_done pulses after a fixed latency
  //  - Egress outputs are driven to Hi-Z

  // Stub signals
  initial begin
    // RDI stub: always ready
    rdi_intf.pl_trdy = 1'b1;

    // LTSM stub: PLL/supply stable after 50ns
    ltsm_intf.pll_stable    = 1'b0;
    ltsm_intf.supply_stable = 1'b0;
    ltsm_intf.tx_done       = 1'b0;

    #50;
    ltsm_intf.pll_stable    = 1'b1;
    ltsm_intf.supply_stable = 1'b1;
  end

  // Stub tx_done: pulse after every encoding change
  always @(ltsm_intf.tx_encoding) begin
    ltsm_intf.tx_done = 1'b0;
    #20;  // Simulate some processing latency
    ltsm_intf.tx_done = 1'b1;
    #10;
    ltsm_intf.tx_done = 1'b0;
  end

  // Egress stub: all outputs Hi-Z by default
  assign tx2link_intf.tx_data  = 16'bz;
  assign tx2link_intf.tx_clkp  = 1'bz;
  assign tx2link_intf.tx_clkn  = 1'bz;
  assign tx2link_intf.tx_valid = 1'bz;
  assign tx2link_intf.tx_track = 1'bz;

  // -------------------------------------------------------------------------
  //  SVA Bind (uncomment when DUT is integrated)
  // -------------------------------------------------------------------------

  // bind tx_dut tx_sva sva_inst (
  //   .ui_clk      (egr_intf.ui_clk),
  //   .rst_n       (rst_n),
  //   .tx_data     (egr_intf.tx_data),
  //   .tx_clkp     (egr_intf.tx_clkp),
  //   .tx_clkn     (egr_intf.tx_clkn),
  //   .tx_valid    (egr_intf.tx_valid),
  //   .tx_track    (egr_intf.tx_track),
  //   .clk         (clk),
  //   .tx_encoding (ltsm_intf.tx_encoding),
  //   .lp_valid    (rdi_intf.lp_valid),
  //   .lp_irdy     (rdi_intf.lp_irdy),
  //   .pl_trdy     (rdi_intf.pl_trdy)
  // );

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
