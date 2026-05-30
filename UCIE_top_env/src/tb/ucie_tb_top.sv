//=============================================================================
// File       : ucie_tb_top.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Top-level Testbench. Instantiates the UCIe_phy DUT, generates
//              clocks and reset, and registers all interfaces in the UVM 
//              config_db.
//=============================================================================

`timescale 1ns / 1ps

module ucie_tb_top;

  import uvm_pkg::*;
  import ucie_pkg::*;

  // -------------------------------------------------------------------------
  //  Clock & Reset Generation
  // -------------------------------------------------------------------------
  logic clk_32 = 0;
  logic clk_24 = 0;
  logic clk_16 = 0;
  logic clk_12 = 0;
  logic clk_8 = 0;
  logic clk_4 = 0;
  logic clk_sb_800_m = 0;
  logic clk_sb_100_m = 0;
  logic reset;

  // Assume standard clock periods (just arbitrary examples for the PLL)
  always #15.625ns clk_32 = ~clk_32;
  always #20.833ns clk_24 = ~clk_24;
  always #31.250ns clk_16 = ~clk_16;
  always #41.666ns clk_12 = ~clk_12;
  always #62.500ns clk_8 = ~clk_8;
  always #125.00ns clk_4 = ~clk_4;
  always #0.625ns clk_sb_800_m = ~clk_sb_800_m;
  always #5.000ns clk_sb_100_m = ~clk_sb_100_m;

  initial begin
    reset = 1;
    #100ns;
    reset = 0;
  end

  // -------------------------------------------------------------------------
  //  PLL & Supply Stable Logic (Reactive)
  // -------------------------------------------------------------------------
  logic pll_stable = 0;
  logic supply_stable = 0;

  // Reactively drive stable signals based on the LTSM encoding
  always @(DUT.tx_fsm_sb_if.o_tx_encoding or posedge reset) begin
    if (reset) begin
      pll_stable = 0;
      supply_stable = 0;
    end else if (DUT.tx_fsm_sb_if.o_tx_encoding == 9'b00_0000_000) begin  // RESET_Reset_TX
      pll_stable = 0;
      supply_stable = 0;
      #50ns;
      pll_stable = 1;
      supply_stable = 1;
    end
  end

  // -------------------------------------------------------------------------
  //  TX-Path Interfaces (Not inside DUT)
  // -------------------------------------------------------------------------
  rdi_if tx_rdi_vif (
      clk_8,
      reset
  );
  ltsm_if tx_ltsm_vif (
      clk_8,
      reset
  );
  tx2link_if tx2link_vif (
      clk_8,
      clk_16,
      reset
  );

  // -------------------------------------------------------------------------
  //  RX-Path Interfaces (Not inside DUT)
  // -------------------------------------------------------------------------
  rp_reset_intf rp_rst_vif (
      clk_sb_100_m
      // reset
  );
  rp_rdi_bfm rp_rdi_vif (
      clk_16,
      reset
  );
  rp_ltsmc_bfm rp_ltsmc_vif (
      clk_16,
      reset
  );
  rp_rmblink_bfm rp_rmblink_vif (
      clk_32,
      clk_16,
      clk_8,
      reset
  );

  // -------------------------------------------------------------------------
  //  DUT Instantiation
  // -------------------------------------------------------------------------
  UCIe_phy DUT (
      .i_clk_32(clk_32),
      .i_clk_24(clk_24),
      .i_clk_16(clk_16),
      .i_clk_12(clk_12),
      .i_clk_8(clk_8),
      .i_clk_4(clk_4),
      .i_clk_sb_800_m(clk_sb_800_m),
      .i_clk_sb_100_m(clk_sb_100_m),
      .i_reset(reset),
      .i_pll_stable(pll_stable),
      .i_supply_stable(supply_stable),

      // RX Mainband Inputs from Partner (Driven by RP rmblink_bfm)
      .i_clk_p  (rp_rmblink_vif.i_clk_p),
      .i_clk_n  (rp_rmblink_vif.i_clk_n),
      .i_track  (rp_rmblink_vif.i_track),
      .i_valid  (rp_rmblink_vif.i_valid),
      .i_data_in(rp_rmblink_vif.i_data),

      // SB Partner Inputs (Routed internally in DUT via its own SB BFMs)
      .i_rx_sb_clk (1'b0),  // Dummy connection, driven internally by sb bfms
      .i_rx_sb_data(1'b0),  // Dummy connection, driven internally by sb bfms

      // TX RDI Inputs (Driven by TX rdi_vif)
      .i_lp_irdy (tx_rdi_vif.lp_irdy),
      .i_lp_valid(tx_rdi_vif.lp_valid),
      .i_lp_data (tx_rdi_vif.lp_data),

      // LTSM RDI Inputs (Routed internally via ltsm_rdi_if_inst)
      // Connecting to dummy signals since ltsm_rdi_if_inst inside DUT will be driven directly by UVM agent
      .i_lp_state_req(4'b0),
      .i_lp_linkerror(1'b0),
      .i_lp_stallack (1'b0),
      .i_lp_clk_ack  (1'b0),
      .i_lp_wake_req (1'b0),

      // Outputs to Adapter
`ifdef UCIE_SYS_LVL
      .o_pl_state_sts(tx_rdi_vif.pl_state_sts),
`else
      .o_pl_state_sts(),
`endif
      .o_pl_data(rp_rdi_vif.pl_data),
      .o_pl_trdy(),

      // Outputs to Partner (Monitored by TX tx2link_vif)
      .o_data_out(tx2link_vif.tx_data),
      .o_clk_p(tx2link_vif.tx_clkp),
      .o_clk_n(tx2link_vif.tx_clkn),
      .o_track(tx2link_vif.tx_track),
      .o_valid(tx2link_vif.tx_valid)
  );

  // -------------------------------------------------------------------------
  //  UVM Configuration DB Registration
  // -------------------------------------------------------------------------
  initial begin
    // LTSM Environment Interfaces (Located INSIDE the DUT)
    uvm_config_db#(virtual ltsm_rdi_if)::set(null, "*", "ltsm_rdi_vif", DUT.ltsm_rdi_if_inst);
    uvm_config_db#(virtual TX_FSM_SB)::set(null, "*", "tx_fsm_sb_vif", DUT.tx_fsm_sb_if);
    uvm_config_db#(virtual RX_FSM_SB)::set(null, "*", "rx_fsm_sb_vif", DUT.rx_fsm_sb_if);
    uvm_config_db#(virtual LTSM_controllers_if)::set(null, "*", "ltsm_ctrl_vif",
                                                     DUT.LTSM_controllers_vif);

    // Sideband Environment Interfaces (Located INSIDE the DUT)
    uvm_config_db#(virtual sb_reset_intf)::set(null, "*", "sb_reset_vif", DUT.reset_intf);
    uvm_config_db#(virtual sb_ltsm_ctrl_bfm)::set(null, "*", "sb_ltsm_ctrl_bfm", DUT.ltsm_ctrl_bfm);
    uvm_config_db#(virtual sb_tx_bfm)::set(null, "*", "sb_tx_bfm", DUT.tx_bfm);
    uvm_config_db#(virtual sb_rx_bfm)::set(null, "*", "sb_rx_bfm", DUT.rx_bfm);
    uvm_config_db#(virtual sb_phylink_bfm)::set(null, "*", "sb_phylink_bfm", DUT.phylink_bfm);

    // RX-Path Environment Interfaces (Instantiated HERE)
    uvm_config_db#(virtual rp_reset_intf)::set(null, "*", "rp_reset_vif", rp_rst_vif);
    uvm_config_db#(virtual rp_rdi_bfm)::set(null, "*", "rp_rdi_bfm", rp_rdi_vif);
    uvm_config_db#(virtual rp_ltsmc_bfm)::set(null, "*", "rp_ltsmc_bfm", rp_ltsmc_vif);
    uvm_config_db#(virtual rp_rmblink_bfm)::set(null, "*", "rp_rmblink_bfm", rp_rmblink_vif);

    // TX-Path Environment Interfaces (Instantiated HERE)
    uvm_config_db#(virtual rdi_if)::set(null, "*", "tx_rdi_vif", tx_rdi_vif);
    uvm_config_db#(virtual ltsm_if)::set(null, "*", "tx_ltsm_vif", tx_ltsm_vif);
    uvm_config_db#(virtual tx2link_if)::set(null, "*", "tx2link_vif", tx2link_vif);

    // Run Test
    run_test();
  end

endmodule
