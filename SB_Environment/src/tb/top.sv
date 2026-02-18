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

// Module: tb_top
// Description: Top-level testbench module for Sideband block verification
//              Instantiates DUT and all verification interfaces
//******************************************************************************

module tb_top;
  import uvm_pkg::*;
  import sb_pkg::*;
  `include "uvm_macros.svh"

  //============================================================================
  // Clock and Reset Generation (Testbench Infrastructure)
  //============================================================================

  logic clk;
  logic reset_wire;
  
  // Clock generation - 100 MHz (10ns period)
  initial begin
    clk = 1'b0;
    forever #5ns clk = ~clk;
  end

  //============================================================================
  // Interface Instantiations
  //============================================================================
  
  // LTSM control interface - generates reset signal
  sb_ltsm_ctrl_bfm  ltsm_ctrl_bfm(clk);
  
  // Connect reset from LTSM interface to top-level wire
  assign reset_wire = ltsm_ctrl_bfm.reset;
  
  // TX path interface
  sb_tx_path_bfm    tx_path_bfm(
    .clk(clk)
   ,.reset(reset_wire)
  );
  
  // RX path interface
  sb_rx_path_bfm    rx_path_bfm(
    .clk(clk)
   ,.reset(reset_wire)
  );
  
  // D2D Adapter interface (RDI)
  sb_rdi_bfm        rdi_bfm(
    .clk(clk)
   ,.reset(reset_wire)
  );
  
  // Physical link interface
  sb_phy_link_bfm   phy_link_bfm(
    .clk(clk)
   ,.reset(reset_wire)
  );

  //============================================================================
  // DUT Instantiation
  //============================================================================
  
  sideband dut(
    // Clock and reset
    .i_clk              (clk)
   ,.i_reset            (reset_wire)
    
    // TX path signals
   ,.i_tx_sb_req        (tx_path_bfm.i_tx_sb_req)
   ,.i_tx_sb_rsp        (tx_path_bfm.i_tx_sb_rsp)
   ,.i_tx_sb_done       (tx_path_bfm.i_tx_sb_done)
   ,.i_tx_encoding      (tx_path_bfm.i_tx_encoding)
   ,.i_tx_data          (tx_path_bfm.i_tx_data)
   ,.o_sb_tx_req        (tx_path_bfm.o_sb_tx_req)
   ,.o_sb_tx_rsp        (tx_path_bfm.o_sb_tx_rsp)
   ,.o_sb_tx_done       (tx_path_bfm.o_sb_tx_done)
   ,.o_tx_decoding      (tx_path_bfm.o_tx_decoding)
   ,.o_tx_data          (tx_path_bfm.o_tx_data)
    
    // RX path signals
   ,.i_rx_sb_req        (rx_path_bfm.i_rx_sb_req)
   ,.i_rx_sb_rsp        (rx_path_bfm.i_rx_sb_rsp)
   ,.i_rx_sb_done       (rx_path_bfm.i_rx_sb_done)
   ,.i_rx_encoding      (rx_path_bfm.i_rx_encoding)
   ,.i_rx_data          (rx_path_bfm.i_rx_data)
   ,.o_sb_rx_req        (rx_path_bfm.o_sb_rx_req)
   ,.o_sb_rx_rsp        (rx_path_bfm.o_sb_rx_rsp)
   ,.o_sb_rx_done       (rx_path_bfm.o_sb_rx_done)
   ,.o_rx_decoding      (rx_path_bfm.o_rx_decoding)
   ,.o_rx_data          (rx_path_bfm.o_rx_data)
    
    // D2D Adapter interface (RDI)
   ,.i_lp_cfg_vld       (rdi_bfm.i_lp_cfg_vld)
   ,.i_lp_cfg_crd       (rdi_bfm.i_lp_cfg_crd)
   ,.i_lp_cfg           (rdi_bfm.i_lp_cfg)
   ,.o_pl_cfg_vld       (rdi_bfm.o_pl_cfg_vld)
   ,.o_pl_cfg_crd       (rdi_bfm.o_pl_cfg_crd)
   ,.o_pl_cfg           (rdi_bfm.o_pl_cfg)
    
    // Physical link interface
   ,.i_rx_sb_data       (phy_link_bfm.i_rx_sb_data)
   ,.i_rx_sb_clk        (phy_link_bfm.i_rx_sb_clk)
   ,.o_tx_sb_data       (phy_link_bfm.o_tx_sb_data)
    
    // LTSM control signals
   ,.i_sb_init_start    (ltsm_ctrl_bfm.i_sb_init_start)
   ,.i_t1_ms            (ltsm_ctrl_bfm.i_t1_ms)
   ,.stop               (ltsm_ctrl_bfm.stop)
  );

  initial begin
    // Set virtual interfaces in UVM config database
    uvm_config_db#(virtual sb_ltsm_ctrl_bfm)::set(null, "uvm_test_top", "ltsm_ctrl_vif", ltsm_ctrl_bfm);
    uvm_config_db#(virtual sb_tx_path_bfm)::set(null,   "uvm_test_top", "tx_path_vif",   tx_path_bfm);
    uvm_config_db#(virtual sb_rx_path_bfm)::set(null,   "uvm_test_top", "rx_path_vif",   rx_path_bfm);
    uvm_config_db#(virtual sb_rdi_bfm)::set(null,       "uvm_test_top", "rdi_vif",       rdi_bfm);
    uvm_config_db#(virtual sb_phy_link_bfm)::set(null,  "uvm_test_top", "phy_link_vif",  phy_link_bfm);
    
    // Run UVM test
    run_test();
  end

endmodule : tb_top
