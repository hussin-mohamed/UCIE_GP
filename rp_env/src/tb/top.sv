// ****************************************************************************
// *                                                                          *
// * Copyright (c) 2014-2015 Synopsys Inc. All rights reserved.               *
// *                                                                          *
// * Synopsys Proprietary and Confidential. This file contains confidential   *
// * information and the trade secrets of Synopsys Inc. Use, disclosure, or   *
// * reproduction is prohibited without the prior express written permission  *
// * of Synopsys, Inc.                                                        *
// *                                                                          *
// * Synopsys, Inc.                                                           *
// * 700 East Middlefield Road                                                *
// * Mountain View, California 94043                                          *
// * (800) 541-7737                                                           *
// *                                                                          *
// ****************************************************************************

// Module: rp_tb_top
// Description: Top-level testbench module for RX-Path block verification
//              Instantiates DUT and all verification interfaces
//******************************************************************************

module rp_tb_top;
  import uvm_pkg::*;
  import rp_pkg::*;
  `include "uvm_macros.svh"

  //============================================================================
  // Clock and Reset Generation (Testbench Infrastructure)
  //============================================================================
  bit   clk;
  bit   hclk;
  bit   dclk;
  logic reset_wire;
  bit   rx_error_dummy;

  // Clock generation
  initial forever #(T_CLK_L) clk   = ~clk;
  initial forever #(T_CLK_H) hclk = ~hclk;
  initial forever #(T_CLK_D) dclk = ~dclk;

  //============================================================================
  // Interface Instantiations
  //============================================================================
  // Reset interface - generates reset signal
  rp_reset_intf  reset_intf(
     .clk(clk)
    ,.reset(reset_wire)
  );

  // D2D Adapter interface (RDI)
  rp_rdi_bfm     rdi_bfm(
     .clk(clk)
    ,.reset(reset_wire)
  );

  // LTSM controller interface
  rp_ltsmc_bfm    ltsmc_bfm(
     .clk(clk)
    ,.reset(reset_wire)
  );
  
  // Physical link interface
  rp_rmblink_bfm rmblink_bfm(
     .clk(clk)
    ,.reset(reset_wire)
    ,.i_hclk(hclk)
    ,.i_dclk(dclk)
  );

  //============================================================================
  // Assign Statements
  //============================================================================
  assign rmblink_bfm.i_rx_encoding = ltsmc_bfm.i_rx_encoding;

  //============================================================================
  // DUT Instantiation
  //============================================================================
  rx_path dut (
    // Clocks & resets
    .i_clk_l           (clk),
    .i_clk_p           (rmblink_bfm.i_clk_p),
    .i_clk_n           (rmblink_bfm.i_clk_n),
    .i_hclk            (hclk),
    .i_dclk            (dclk),
    .i_track           (rmblink_bfm.i_track),
    .i_reset           (reset_wire),

    // Data inputs
    .i_lanes           (rmblink_bfm.i_data),
    .i_valid           (rmblink_bfm.i_valid),
    .i_halfrate        (ltsmc_bfm.i_half_rate),

    // Configuration
    .i_rx_encoding     (ltsmc_bfm.i_rx_encoding),
    .i_lane_map_code   (ltsmc_bfm.i_lane_map_code),
    .i_error_threshold (ltsmc_bfm.i_error_threshold),

    // Outputs
    .o_pl_data         (rdi_bfm.pl_data),
    .o_pl_valid        (rdi_bfm.pl_valid),
    .o_rx_done         (ltsmc_bfm.o_rx_done),
    .o_rx_data_results (ltsmc_bfm.o_rx_data_results),
    .o_rx_error        (rx_error_dummy),
    .o_clk_results     (ltsmc_bfm.o_clk_result),
    .o_valid_results   (ltsmc_bfm.o_valid_result)
  );


  //============================================================================
  // Binding Assertions Interface
  //============================================================================
  bind rx_path rp_sva rp_sva_inst (
      // Clocks & resets
    .i_clk_l           (dut.i_clk_l),
    .i_clk_p           (rmblink_bfm.i_clk_p),
    .i_clk_n           (rmblink_bfm.i_clk_n),
    .i_hclk            (dut.i_hclk),
    .i_dclk            (dut.i_dclk),
    .i_track           (rmblink_bfm.i_track),
    .i_reset           (dut.i_reset),

    // Data inputs
    .i_lanes           (rmblink_bfm.i_data),
    .i_valid           (rmblink_bfm.i_valid),
    .i_halfrate        (ltsmc_bfm.i_half_rate),

    // Configuration
    .i_rx_encoding     (ltsmc_bfm.i_rx_encoding),
    .i_lane_map_code   (ltsmc_bfm.i_lane_map_code),
    .i_error_threshold (ltsmc_bfm.i_error_threshold),

    // Outputs
    .o_pl_data         (rdi_bfm.pl_data),
    .o_pl_valid        (rdi_bfm.pl_valid),
    .o_rx_done         (ltsmc_bfm.o_rx_done),
    .o_rx_data_results (ltsmc_bfm.o_rx_data_results),
    .o_rx_error        (rx_error_dummy),
    .o_clk_results     (ltsmc_bfm.o_clk_result),
    .o_valid_results   (ltsmc_bfm.o_valid_result)
  );

  initial begin
    // Set virtual interfaces in UVM config database
    uvm_config_db#(virtual rp_reset_intf)::set  (null, "uvm_test_top", "reset_intf",   reset_intf);
    uvm_config_db#(virtual rp_rdi_bfm)::set     (null, "uvm_test_top", "rdi_bfm",      rdi_bfm);
    uvm_config_db#(virtual rp_ltsmc_bfm)::set    (null, "uvm_test_top", "ltsmc_bfm",     ltsmc_bfm);
    uvm_config_db#(virtual rp_rmblink_bfm)::set (null, "uvm_test_top", "rmblink_bfm",  rmblink_bfm);
  
    // Run UVM test
    run_test();
  end

endmodule : rp_tb_top
