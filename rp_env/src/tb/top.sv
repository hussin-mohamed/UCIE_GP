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
  bit   clk_p = 1;
  bit   clk_n = 0;
  logic reset_wire;

  // Clock generation
  initial forever #(T_CLK_L) clk   = ~clk;
  initial forever #(T_CLK_P) clk_p = ~clk_p;
  initial forever #(T_CLK_N) clk_n = ~clk_n;

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
  rp_ltsm_bfm    ltsm_bfm(
     .clk(clk)
    ,.reset(reset_wire)
  );
  
  // Physical link interface
  rp_rmblink_bfm rmblink_bfm(
     .clk(clk)
    ,.reset(reset_wire)
  );

  //============================================================================
  // DUT Instantiation
  //============================================================================
  
  //============================================================================
  // Binding Assertions Interface
  //============================================================================

  initial begin
    // Set virtual interfaces in UVM config database
    uvm_config_db#(virtual rp_reset_intf)::set  (null, "uvm_test_top", "reset_intf",   reset_intf);
    uvm_config_db#(virtual rp_rdi_bfm)::set     (null, "uvm_test_top", "rdi_bfm",      rdi_bfm);
    uvm_config_db#(virtual rp_ltsm_bfm)::set    (null, "uvm_test_top", "ltsm_bfm",     ltsm_bfm);
    uvm_config_db#(virtual rp_rmblink_bfm)::set (null, "uvm_test_top", "rmblink_bfm",  rmblink_bfm);
  
    // Run UVM test
    run_test();
  end

endmodule : rp_tb_top
