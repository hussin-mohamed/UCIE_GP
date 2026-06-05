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

// Module: sb_tb_top
// Description: Top-level testbench module for Sideband block verification
//              Instantiates DUT and all verification interfaces
//******************************************************************************

module sb_tb_top;
  import uvm_pkg::*;
  import sb_pkg::*;
  `include "uvm_macros.svh"

  //============================================================================
  // Clock and Reset Generation (Testbench Infrastructure)
  //============================================================================

  bit   clk, clk_800MHz;
  logic reset_wire;
  logic sb_ready;

  // Clock generation
  initial forever #16ns clk = ~clk;               // Logic Clock - mimics the real 100MHz clock
  initial forever #2    clk_800MHz = ~clk_800MHz; // Serialization Clock - mimics the real 800MHz clock - 8x faster than clk

  //============================================================================
  // Interface Instantiations
  //============================================================================
  // Reset interface - generates reset signal
  sb_reset_intf reset_intf(
     .clk(clk)
    ,.reset(reset_wire)
  );

  // LTSM control interface
  sb_ltsm_ctrl_bfm ltsm_ctrl_bfm(
     .clk(clk)
    ,.reset(reset_wire)
    ,.o_sb_ready(sb_ready)
  );
  
  // TX path interface
  sb_tx_bfm tx_bfm(
     .clk(clk)
    ,.reset(reset_wire)
    ,.o_sb_ready(sb_ready)
  );
  
  // RX path interface
  sb_rx_bfm    rx_bfm(
     .clk(clk)
    ,.reset(reset_wire)
    ,.o_sb_ready(sb_ready)
  );
  
  // D2D Adapter interface (RDI)
  sb_rdi_bfm        rdi_bfm(
     .clk(clk)
    ,.reset(reset_wire)
    ,.o_sb_ready(sb_ready)
  );
  
  // Physical link interface
  sb_phylink_bfm   phylink_bfm(
     .clk(clk)
    ,.clk_800MHz(clk_800MHz)
    ,.reset(reset_wire)
    ,.o_sb_ready(sb_ready)
  );

  assign phylink_bfm.tms     = ltsm_ctrl_bfm.tms;
  assign phylink_bfm.timeout = ltsm_ctrl_bfm.timeout;
  assign phylink_bfm.start   = ltsm_ctrl_bfm.i_sb_init_start;

  //============================================================================
  // DUT Instantiation
  //============================================================================
  ucie_sb_top #(
    .pFIFO_DEPTH(TX_FIFO_SIZE)
  )
  dut
  (
    // Clock and reset
     .i_clk                (clk)
    ,.i_reset              (reset_wire)
    ,.i_800MHz_clk         (clk_800MHz)

    // TX path signals
    ,.i_tx_sb_req          (tx_bfm.i_tx_sb_req)
    ,.i_tx_sb_rsp          (tx_bfm.i_tx_sb_rsp)
    ,.i_tx_sb_done         (tx_bfm.i_tx_sb_done)
    ,.i_tx_encoding        (tx_bfm.i_tx_encoding)
    ,.i_tx_data            (tx_bfm.i_tx_data)
    ,.i_tx_info            (tx_bfm.i_tx_info)
    ,.o_sb_tx_req          (tx_bfm.o_sb_tx_req)
    ,.o_sb_tx_rsp          (tx_bfm.o_sb_tx_rsp)
    ,.o_sb_tx_done         (tx_bfm.o_sb_tx_done)
    ,.o_tx_decoding        (tx_bfm.o_tx_decoding)
    ,.o_tx_data            (tx_bfm.o_tx_data)
    ,.o_tx_info            (tx_bfm.o_tx_info)
    ,.o_tx_valid           (tx_bfm.o_tx_valid)

    // RX path signals
    ,.i_rx_sb_req          (rx_bfm.i_rx_sb_req)
    ,.i_rx_sb_rsp          (rx_bfm.i_rx_sb_rsp)
    ,.i_rx_sb_done         (rx_bfm.i_rx_sb_done)
    ,.i_rx_encoding        (rx_bfm.i_rx_encoding)
    ,.i_rx_data            (rx_bfm.i_rx_data)
    ,.i_rx_info            (rx_bfm.i_rx_info)
    ,.o_sb_rx_req          (rx_bfm.o_sb_rx_req)
    ,.o_sb_rx_rsp          (rx_bfm.o_sb_rx_rsp)
    ,.o_sb_rx_done         (rx_bfm.o_sb_rx_done)
    ,.o_rx_decoding        (rx_bfm.o_rx_decoding)
    ,.o_rx_data            (rx_bfm.o_rx_data)
    ,.o_rx_info            (rx_bfm.o_rx_info)
    ,.o_rx_valid           (rx_bfm.o_rx_valid)

    // LTSM control signals
    ,.i_sb_init_start      (ltsm_ctrl_bfm.i_sb_init_start)
    ,.i_timer_1ms          (ltsm_ctrl_bfm.i_timer_1ms)
    ,.o_sb_ready           (sb_ready)

    // Physical link interface
    ,.i_rx_sb_data         (phylink_bfm.i_rx_sb_data)
    ,.i_rx_sb_clk          (phylink_bfm.i_rx_sb_clk)
    ,.o_tx_sb_data         (phylink_bfm.o_tx_sb_data)
    ,.o_tx_sb_clk          (phylink_bfm.o_tx_sb_clk)
  );

  //============================================================================
  // Binding Assertions Interface
  //============================================================================
  bind ucie_sb_top sb_sva sva_inst(
     .i_clk           (i_clk)
    ,.clk_800MHz      (i_800MHz_clk)
    ,.i_reset         (i_reset)

    ,.i_tx_sb_req     (i_tx_sb_req)
    ,.i_tx_sb_rsp     (i_tx_sb_rsp)
    ,.i_tx_sb_done    (i_tx_sb_done)
    ,.i_tx_encoding   (i_tx_encoding)
    ,.i_tx_info       (i_tx_info)
    ,.i_tx_data       (i_tx_data)

    ,.i_rx_sb_req     (i_rx_sb_req)
    ,.i_rx_sb_rsp     (i_rx_sb_rsp)
    ,.i_rx_sb_done    (i_rx_sb_done)
    ,.i_rx_encoding   (i_rx_encoding)
    ,.i_rx_info       (i_rx_info)
    ,.i_rx_data       (i_rx_data)

    ,.i_sb_init_start (i_sb_init_start)
    ,.i_timer_1ms     (i_timer_1ms)

    ,.i_rx_sb_data    (i_rx_sb_data)
    ,.i_rx_sb_clk     (i_rx_sb_clk)

    ,.o_tx_decoding   (o_tx_decoding)
    ,.o_tx_info       (o_tx_info)
    ,.o_tx_data       (o_tx_data)
    ,.o_tx_valid      (o_tx_valid)

    ,.o_rx_decoding   (o_rx_decoding)
    ,.o_rx_info       (o_rx_info)
    ,.o_rx_data       (o_rx_data)
    ,.o_rx_valid      (o_rx_valid)

    ,.o_sb_tx_req     (o_sb_tx_req)
    ,.o_sb_tx_rsp     (o_sb_tx_rsp)
    ,.o_sb_rx_req     (o_sb_rx_req)
    ,.o_sb_rx_rsp     (o_sb_rx_rsp)
    ,.o_sb_tx_done    (o_sb_tx_done)
    ,.o_sb_rx_done    (o_sb_rx_done)

    ,.o_sb_ready      (o_sb_ready)
    ,.o_tx_sb_data    (o_tx_sb_data)
    ,.o_tx_sb_clk     (o_tx_sb_clk)
  );

  initial begin
    // Set virtual interfaces in UVM config database
    uvm_config_db#(virtual sb_reset_intf)::set    (null, "uvm_test_top", "reset_intf",    reset_intf);
    uvm_config_db#(virtual sb_ltsm_ctrl_bfm)::set (null, "uvm_test_top", "ltsm_ctrl_bfm", ltsm_ctrl_bfm);
    uvm_config_db#(virtual sb_tx_bfm)::set        (null, "uvm_test_top", "tx_bfm",        tx_bfm);
    uvm_config_db#(virtual sb_rx_bfm)::set        (null, "uvm_test_top", "rx_bfm",        rx_bfm);
    uvm_config_db#(virtual sb_rdi_bfm)::set       (null, "uvm_test_top", "rdi_bfm",       rdi_bfm);
    uvm_config_db#(virtual sb_phylink_bfm)::set   (null, "uvm_test_top", "phylink_bfm",   phylink_bfm);
  
    // Run UVM test
    run_test();
  end

endmodule : sb_tb_top
