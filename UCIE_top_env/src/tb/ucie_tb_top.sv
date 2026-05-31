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
  always #3ns clk_32 = ~clk_32;
  always #4ns clk_24 = ~clk_24;
  always #6ns clk_16 = ~clk_16;
  always #8ns clk_12 = ~clk_12;
  always #12ns clk_8 = ~clk_8;
  always #24ns clk_4 = ~clk_4;
  always #120ns clk_sb_800_m = ~clk_sb_800_m;
  always #960ns clk_sb_100_m = ~clk_sb_100_m;

  initial begin
    reset = 1;
    #100ns;
    reset = 0;
  end

  // -------------------------------------------------------------------------
  //  PLL & Supply Stable Logic (Reactive)
  // -------------------------------------------------------------------------
  logic pll_stable = 1;
  logic supply_stable = 1;

  // Reactively drive stable signals based on the LTSM encoding
  // always @(DUT.tx_fsm_sb_if.o_tx_encoding or posedge reset) begin
  //   if (reset) begin
  //     pll_stable = 0;
  //     supply_stable = 0;
  //   end else if (DUT.tx_fsm_sb_if.o_tx_encoding == 9'b00_0000_000) begin  // RESET_Reset_TX
  //     pll_stable = 0;
  //     supply_stable = 0;
  //     #50ns;
  //     pll_stable = 1;
  //     supply_stable = 1;
  //   end
  // end



  rp_rmblink_bfm rp_rmblink_bfm_inst (
      .clk(DUT.clk_l)
      , .reset(reset)
      , .i_hclk(DUT.clk_mb_h)
      , .i_dclk(DUT.clk_mb_f)
  );

  sb_phylink_bfm phylink_bfm (
      .clk(clk_sb_100_m)
      , .clk_800MHz(clk_sb_800_m)
      , .reset(reset)
      , .o_sb_ready(DUT.sb_ready)
  );

  tx2link_if tx2link_intf (
      .clk(DUT.clk_l),
      .ui_clk(DUT.clk_mb_f),
      .rst(reset)
  );

  ltsm_rdi_if ltsm_rdi_if_inst (.clk(clk_l));

  rdi_if #(
      .NBYTES(256)
  ) rdi_intf (
      .clk(DUT.clk_l),
      .rst(reset)
  );

  rp_rdi_bfm rp_rdi_bfm_inst (
        .clk  (DUT.clk_l)
      , .reset(reset)
  );

    assign  phylink_bfm.tms     = DUT.ltsm_ctrl_bfm.tms;
    assign  phylink_bfm.timeout = DUT.ltsm_ctrl_bfm.timeout;
    assign  phylink_bfm.start   = DUT.ltsm_ctrl_bfm.i_sb_init_start;
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
      .i_clk_p  (rp_rmblink_bfm_inst.i_clk_p),
      .i_clk_n  (rp_rmblink_bfm_inst.i_clk_n),
      .i_track  (rp_rmblink_bfm_inst.i_track),
      .i_valid  (rp_rmblink_bfm_inst.i_valid),
      .i_data_in(rp_rmblink_bfm_inst.i_data),

      // SB Partner Inputs (Routed internally in DUT via its own SB BFMs)
      .i_rx_sb_clk (phylink_bfm.i_rx_sb_clk),  // Dummy connection, driven internally by sb bfms
      .i_rx_sb_data(phylink_bfm.i_rx_sb_data),  // Dummy connection, driven internally by sb bfms
      .o_tx_sb_data(phylink_bfm.o_tx_sb_data),  // Dummy connection, driven internally by sb bfms
      .o_tx_sb_clk(phylink_bfm.o_tx_sb_clk),  // Dummy connection, driven internally by sb bfms

      // TX RDI Inputs (Driven by TX rdi_vif)
      .i_lp_irdy (rdi_intf.lp_irdy),
      .i_lp_valid(rdi_intf.lp_valid),
      .i_lp_data (rdi_intf.lp_data),
      .o_pl_trdy (rdi_intf.pl_trdy),

      // LTSM RDI Inputs (Routed internally via ltsm_rdi_if_inst)
      // Connecting to dummy signals since ltsm_rdi_if_inst inside DUT will be driven directly by UVM agent
      .i_lp_state_req(ltsm_rdi_if_inst.i_lp_state_req),
      .i_lp_linkerror(ltsm_rdi_if_inst.i_lp_linkerror),
      .i_lp_stallack (ltsm_rdi_if_inst.i_lp_stallack),
      .i_lp_clk_ack  (ltsm_rdi_if_inst.i_lp_clk_ack),
      .i_lp_wake_req (ltsm_rdi_if_inst.i_lp_wake_req),

      // Outputs to Adapter

      .o_pl_state_sts(ltsm_rdi_if_inst.o_pl_state_sts),

      .o_pl_data     (rp_rdi_bfm_inst.pl_data),
      .o_pl_valid     (rp_rdi_bfm_inst.pl_valid),

      // Outputs to Partner (Monitored by TX tx2link_vif)
      .o_data_out(tx2link_intf.tx_data),
      .o_clk_p(tx2link_intf.tx_clkp),
      .o_clk_n(tx2link_intf.tx_clkn),
      .o_track(tx2link_intf.tx_track),
      .o_valid(tx2link_intf.tx_valid)
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

    // RX-Path Environment Interfaces (Located INSIDE the DUT)
    uvm_config_db#(virtual rp_reset_intf)::set(null, "*", "rp_reset_vif", DUT.rp_reset_intf_inst);
    uvm_config_db#(virtual rp_rdi_bfm)::set(null, "*", "rp_rdi_bfm", DUT.rp_rdi_bfm_inst);
    uvm_config_db#(virtual rp_ltsmc_bfm)::set(null, "*", "rp_ltsmc_bfm", DUT.rp_ltsmc_bfm_inst);
    uvm_config_db#(virtual rp_rmblink_bfm)::set(null, "*", "rp_rmblink_bfm", DUT.rp_rmblink_bfm_inst);

    // TX-Path Environment Interfaces (Located INSIDE the DUT)
    uvm_config_db#(virtual rdi_if)::set(null, "*", "tx_rdi_vif", DUT.rdi_intf);
    uvm_config_db#(virtual ltsm_if)::set(null, "*", "tx_ltsm_vif", DUT.ltsm_intf);
    uvm_config_db#(virtual tx2link_if)::set(null, "*", "tx2link_vif", DUT.tx2link_intf);

    // drive interfaces only not needed for the monitor the monitors will take the internal interfaces instantiated here
    uvm_config_db#(virtual rp_rmblink_bfm)::set(null, "*", "rp_rmblink_bfm_driver_only", rp_rmblink_bfm_inst);
    uvm_config_db#(virtual sb_phylink_bfm)::set(null, "*", "sb_phylink_bfm_driver_only", phylink_bfm);
    uvm_config_db#(virtual rdi_if)::set(null, "*", "rdi_if_driver_only", rdi_intf);
    uvm_config_db#(virtual ltsm_rdi_if)::set(null, "*", "ltsm_rdi_if_driver_only", ltsm_rdi_if_inst);
    // Run Test
    run_test();
  end

endmodule
