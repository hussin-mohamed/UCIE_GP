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

`include "../shared_pkg.sv"
import shared_pkg::*;
import uvm_pkg::*;
import svunit_uvm_mock_pkg::*;

`include "svunit_defines.svh"
`include "uvm_macros.svh"
`include "../sb_utils.svh"
`include "../sequence_items/ltsm_seq_item.svh"
`include "../sequence_items/phylink_seq_item.svh"
`include "../sequence_items/rdi_seq_item.svh"
`include "../scoreboard/sb_pred_link2ltsm.svh"

//=============================================================================
// UUT Wrapper
//=============================================================================

//---------------------------------------------------------------------------
//
// CLASS: sb_pred_link2ltsm_uvm_wrapper
//
// Lightweight UVM wrapper around sb_pred_link2ltsm that captures the TX and
// RX predictor outputs in local FIFOs for unit-test checking.
//
//---------------------------------------------------------------------------

class sb_pred_link2ltsm_uvm_wrapper extends sb_pred_link2ltsm;

  `uvm_component_utils(sb_pred_link2ltsm_uvm_wrapper)
  
  uvm_tlm_analysis_fifo #(ltsm_seq_item) out_fifo_tx;
  uvm_tlm_analysis_fifo #(ltsm_seq_item) out_fifo_rx;

  // Function: new
  //
  // Creates the predictor wrapper component.

  extern function new(string name = "sb_pred_link2ltsm_uvm_wrapper", uvm_component parent);

  // Function: build_phase
  //
  // Constructs the local FIFOs used to observe predicted TX and RX items.

  extern function void build_phase(uvm_phase phase);

  // Function: connect_phase
  //
  // Connects the predictor output ports to the local observation FIFOs.

  extern function void connect_phase(uvm_phase phase);
endclass

//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: sb_pred_link2ltsm_uvm_wrapper
//
//---------------------------------------------------------------------------

// new
// ---

function sb_pred_link2ltsm_uvm_wrapper::new(string name = "sb_pred_link2ltsm_uvm_wrapper", uvm_component parent);
  super.new(name, parent);
endfunction

// build_phase
// -----------

function void sb_pred_link2ltsm_uvm_wrapper::build_phase(uvm_phase phase);
   super.build_phase(phase);
   out_fifo_tx = new("out_fifo_tx", this);
   out_fifo_rx = new("out_fifo_rx", this);
endfunction

// connect_phase
// -------------

function void sb_pred_link2ltsm_uvm_wrapper::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  results_ap_tx.connect(out_fifo_tx.analysis_export);
  results_ap_rx.connect(out_fifo_rx.analysis_export);
endfunction

//=============================================================================
// Unit Test Module
//=============================================================================
module sb_pred_link2ltsm_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "sb_pred_link2ltsm_ut";
  svunit_testcase svunit_ut;

  sb_pred_link2ltsm_uvm_wrapper my_sb_pred_link2ltsm;

  // Test Variables
  phylink_seq_item phy_item;
  ltsm_seq_item    out_item;

  //---------------------------------------------------------
  // Helper: Populate explicit fields and calculate parity
  //---------------------------------------------------------
  function void populate_phy_item(
    opcode_t     op, 
    srcid_t      src, 
    dstid_t      dst, 
    fullcode_t   fc, 
    logic [15:0] inf, 
    logic [63:0] dat,
    bit          force_bad_cp = 1'b0,
    bit          force_bad_dp = 1'b0
  );
    phy_item.opcode   = op;
    phy_item.srcid    = src;
    phy_item.dstid    = dst;
    phy_item.fullcode = fc;
    phy_item.info     = inf;
    phy_item.data     = dat;

    // Calculate correct parity (XOR of all non-reserved bits)
    phy_item.cp = ^{dst, inf, fc, src, op};
    phy_item.dp = ^dat;

    // Inject parity errors if requested for negative testing
    if (force_bad_cp) phy_item.cp = ~phy_item.cp;
    if (force_bad_dp) phy_item.dp = ~phy_item.dp;
  endfunction

  //===================================
  // Build
  //===================================
  function void build();
    svunit_ut = new(name);
    my_sb_pred_link2ltsm = sb_pred_link2ltsm_uvm_wrapper::type_id::create("my_sb_pred_link2ltsm", null);
    svunit_deactivate_uvm_component(my_sb_pred_link2ltsm);
  endfunction

  //===================================
  // Setup
  //===================================
  task setup();
    svunit_ut.setup();
    
    // Instantiate the unpacked item
    phy_item = phylink_seq_item::type_id::create("phy_item");

    svunit_activate_uvm_component(my_sb_pred_link2ltsm);
    svunit_uvm_test_start();
  endtask

  //===================================
  // Teardown
  //===================================
  task teardown();
    svunit_ut.teardown();
    svunit_uvm_test_finish();
    svunit_deactivate_uvm_component(my_sb_pred_link2ltsm);
  endtask

  //===================================
  // SVUNIT TESTS
  //===================================
  `SVUNIT_TESTS_BEGIN

    //=========================================================================
    // TX MESSAGE TESTS
    //=========================================================================

    `SVTEST(tx_sbinit_out_of_reset_test)
      populate_phy_item(MSG_WO_DATA, SRC_PHY, DST_PHY, SBINIT_out_of_Reset, 16'h1111, 64'h0);
      my_sb_pred_link2ltsm.write(phy_item);
      
      `FAIL_IF(my_sb_pred_link2ltsm.out_fifo_tx.used() != 1)
      my_sb_pred_link2ltsm.out_fifo_tx.get(out_item);
      
      `FAIL_UNLESS_EQUAL(out_item.get_dir(), MSG_FROM_TX)
      `FAIL_UNLESS_EQUAL(out_item.get_tx_encoding(), SBINIT_TX_Out_Of_Reset_MSG)
      `FAIL_UNLESS_EQUAL(out_item.valid, 1'b1)
    `SVTEST_END

    `SVTEST(tx_sbinit_done_handshake_test)
      populate_phy_item(MSG_WO_DATA, SRC_PHY, DST_PHY, SBINIT_done_req, 16'h2222, 64'h0);
      my_sb_pred_link2ltsm.write(phy_item);
      
      `FAIL_IF(my_sb_pred_link2ltsm.out_fifo_tx.used() != 1)
      my_sb_pred_link2ltsm.out_fifo_tx.get(out_item);
      
      `FAIL_UNLESS_EQUAL(out_item.get_dir(), MSG_FROM_TX)
      `FAIL_UNLESS_EQUAL(out_item.get_tx_encoding(), SBINIT_TX_Done_Handshake)
      `FAIL_UNLESS_EQUAL(out_item.valid, 1'b1)
    `SVTEST_END

    `SVTEST(tx_mbinit_param_config_handshake_test)
      populate_phy_item(MSG_W_64B_DATA, SRC_PHY, DST_PHY, MBINIT_PARAM_configuration_req, 16'h3333, 64'hDEADBEEF_00001111);
      my_sb_pred_link2ltsm.write(phy_item);
      
      `FAIL_IF(my_sb_pred_link2ltsm.out_fifo_tx.used() != 1)
      my_sb_pred_link2ltsm.out_fifo_tx.get(out_item);
      
      `FAIL_UNLESS_EQUAL(out_item.get_dir(), MSG_FROM_TX)
      `FAIL_UNLESS_EQUAL(out_item.get_tx_encoding(), MBINIT_PARAM_TX_Config_Handshake)
      `FAIL_UNLESS_EQUAL(out_item.valid, 1'b1)
    `SVTEST_END

    `SVTEST(tx_start_rx_init_d2c_eye_sweep_resp_test)
      populate_phy_item(MSG_WO_DATA, SRC_PHY, DST_PHY, Start_Rx_Init_D_to_C_eye_sweep_resp, 16'h4444, 64'h0);
      my_sb_pred_link2ltsm.write(phy_item);
      
      `FAIL_IF(my_sb_pred_link2ltsm.out_fifo_tx.used() != 1)
      my_sb_pred_link2ltsm.out_fifo_tx.get(out_item);
      
      `FAIL_UNLESS_EQUAL(out_item.get_dir(), MSG_FROM_TX)
      `FAIL_UNLESS_EQUAL(out_item.get_tx_encoding(), Send_Start_Rx_Init_D_to_C_eye_sweep_resp)
      `FAIL_UNLESS_EQUAL(out_item.valid, 1'b1)
    `SVTEST_END

    `SVTEST(tx_rx_init_d2c_sweep_done_with_results_test)
      populate_phy_item(MSG_W_64B_DATA, SRC_PHY, DST_PHY, Rx_Init_D_to_C_sweep_done_with_results, 16'h5555, 64'hFEEDFACE_CAFEBABE);
      my_sb_pred_link2ltsm.write(phy_item);
      
      `FAIL_IF(my_sb_pred_link2ltsm.out_fifo_tx.used() != 1)
      my_sb_pred_link2ltsm.out_fifo_tx.get(out_item);
      
      `FAIL_UNLESS_EQUAL(out_item.get_dir(), MSG_FROM_TX)
      `FAIL_UNLESS_EQUAL(out_item.get_tx_encoding(), Send_Rx_Init_D_to_C_sweep_done_with_results)
      `FAIL_UNLESS_EQUAL(out_item.valid, 1'b1)
    `SVTEST_END

    //=========================================================================
    // RX MESSAGE TESTS
    //=========================================================================

    `SVTEST(rx_sbinit_done_handshake_test)
      populate_phy_item(MSG_WO_DATA, SRC_PHY, DST_PHY, SBINIT_done_resp, 16'h6666, 64'h0);
      my_sb_pred_link2ltsm.write(phy_item);
      
      `FAIL_IF(my_sb_pred_link2ltsm.out_fifo_rx.used() != 1)
      my_sb_pred_link2ltsm.out_fifo_rx.get(out_item);
      
      `FAIL_UNLESS_EQUAL(out_item.get_dir(), MSG_FROM_RX)
      `FAIL_UNLESS_EQUAL(out_item.get_rx_encoding(), SBINIT_RX_Done_Handshake)
      `FAIL_UNLESS_EQUAL(out_item.valid, 1'b1)
    `SVTEST_END

    `SVTEST(rx_mbinit_param_send_resp_test)
      populate_phy_item(MSG_W_64B_DATA, SRC_PHY, DST_PHY, MBINIT_PARAM_configuration_resp, 16'h7777, 64'h11223344_55667788);
      my_sb_pred_link2ltsm.write(phy_item);
      
      `FAIL_IF(my_sb_pred_link2ltsm.out_fifo_rx.used() != 1)
      my_sb_pred_link2ltsm.out_fifo_rx.get(out_item);
      
      `FAIL_UNLESS_EQUAL(out_item.get_dir(), MSG_FROM_RX)
      `FAIL_UNLESS_EQUAL(out_item.get_rx_encoding(), MBINIT_PARAM_RX_Send_RESP)
      `FAIL_UNLESS_EQUAL(out_item.valid, 1'b1)
    `SVTEST_END

    `SVTEST(rx_start_rx_init_d2c_eye_sweep_req_test)
      populate_phy_item(MSG_W_64B_DATA, SRC_PHY, DST_PHY, Start_Rx_Init_D_to_C_eye_sweep_req, 16'h8888, 64'hCAFE_F00D_BEEF_0000);
      my_sb_pred_link2ltsm.write(phy_item);
      
      `FAIL_IF(my_sb_pred_link2ltsm.out_fifo_rx.used() != 1)
      my_sb_pred_link2ltsm.out_fifo_rx.get(out_item);
      
      `FAIL_UNLESS_EQUAL(out_item.get_dir(), MSG_FROM_RX)
      `FAIL_UNLESS_EQUAL(out_item.get_rx_encoding(), Send_Start_Rx_Init_D_to_C_eye_sweep_req)
      `FAIL_UNLESS_EQUAL(out_item.valid, 1'b1)
    `SVTEST_END

    //=========================================================================
    // PARITY ERROR NEGATIVE TESTS
    //=========================================================================

    `SVTEST(tx_invalid_cp_drops_valid_bit_test)
      // Pass force_bad_cp = 1 to intentionally corrupt the control parity bit
      populate_phy_item(MSG_WO_DATA, SRC_PHY, DST_PHY, SBINIT_out_of_Reset, 16'h1111, 64'h0, 1'b1, 1'b0);
      my_sb_pred_link2ltsm.write(phy_item);
      
      `FAIL_IF(my_sb_pred_link2ltsm.out_fifo_tx.used() != 1)
      my_sb_pred_link2ltsm.out_fifo_tx.get(out_item);
      
      // Because CP is corrupted, is_valid() should fail, meaning valid = 0
      `FAIL_UNLESS_EQUAL(out_item.valid, 1'b0)
    `SVTEST_END

    `SVTEST(rx_invalid_dp_drops_valid_bit_test)
      // Pass force_bad_dp = 1 to intentionally corrupt the data parity bit
      populate_phy_item(MSG_W_64B_DATA, SRC_PHY, DST_PHY, MBINIT_PARAM_configuration_resp, 16'h7777, 64'h11223344_55667788, 1'b0, 1'b1);
      my_sb_pred_link2ltsm.write(phy_item);
      
      `FAIL_IF(my_sb_pred_link2ltsm.out_fifo_rx.used() != 1)
      my_sb_pred_link2ltsm.out_fifo_rx.get(out_item);
      
      // Because DP is corrupted, is_valid() should fail, meaning valid = 0
      `FAIL_UNLESS_EQUAL(out_item.valid, 1'b0)
    `SVTEST_END

    //=========================================================================
    // UNSUPPORTED MESSAGE FILTERING TESTS (is_supported_msg)
    //=========================================================================

    //---------------------------------------------------------
    // Test: Unsupported Opcode (Predictor should drop message)
    //---------------------------------------------------------
    `SVTEST(unsupported_opcode_is_ignored_test)
      // Cast an invalid 5-bit opcode (e.g., 'h1F) to the enum
      populate_phy_item(opcode_t'(5'b11111), SRC_PHY, DST_PHY, SBINIT_out_of_Reset, 16'h0, 64'h0);
      my_sb_pred_link2ltsm.write(phy_item);
      
      // Verify no items were routed to either FIFO
      `FAIL_UNLESS_EQUAL(my_sb_pred_link2ltsm.out_fifo_tx.used(), 0)
      `FAIL_UNLESS_EQUAL(my_sb_pred_link2ltsm.out_fifo_rx.used(), 0)
    `SVTEST_END

    //---------------------------------------------------------
    // Test: Unsupported Source ID (Predictor should drop message)
    //---------------------------------------------------------
    `SVTEST(unsupported_srcid_is_ignored_test)
      // Cast an invalid srcid (e.g., 3'b000) instead of SRC_PHY
      populate_phy_item(MSG_WO_DATA, srcid_t'(3'b000), DST_PHY, SBINIT_out_of_Reset, 16'h0, 64'h0);
      my_sb_pred_link2ltsm.write(phy_item);
      
      `FAIL_UNLESS_EQUAL(my_sb_pred_link2ltsm.out_fifo_tx.used(), 0)
      `FAIL_UNLESS_EQUAL(my_sb_pred_link2ltsm.out_fifo_rx.used(), 0)
    `SVTEST_END

    //---------------------------------------------------------
    // Test: Unsupported Destination ID (Predictor should drop message)
    //---------------------------------------------------------
    `SVTEST(unsupported_dstid_is_ignored_test)
      // Cast an invalid dstid (e.g., 3'b000) instead of DST_PHY
      populate_phy_item(MSG_WO_DATA, SRC_PHY, dstid_t'(3'b000), SBINIT_out_of_Reset, 16'h0, 64'h0);
      my_sb_pred_link2ltsm.write(phy_item);
      
      `FAIL_UNLESS_EQUAL(my_sb_pred_link2ltsm.out_fifo_tx.used(), 0)
      `FAIL_UNLESS_EQUAL(my_sb_pred_link2ltsm.out_fifo_rx.used(), 0)
    `SVTEST_END

    //---------------------------------------------------------
    // Test: Unsupported Fullcode (Predictor should drop message)
    //---------------------------------------------------------
    `SVTEST(unsupported_fullcode_is_ignored_test)
      // Create a fullcode where msgcode[3:0] is NOT 'h5 or 'hA
      // e.g., 16'h1111 -> msgcode is 8'h11 -> least significant 4 bits is 'h1
      populate_phy_item(MSG_WO_DATA, SRC_PHY, DST_PHY, fullcode_t'(16'h1111), 16'h0, 64'h0);
      my_sb_pred_link2ltsm.write(phy_item);
      
      `FAIL_UNLESS_EQUAL(my_sb_pred_link2ltsm.out_fifo_tx.used(), 0)
      `FAIL_UNLESS_EQUAL(my_sb_pred_link2ltsm.out_fifo_rx.used(), 0)
    `SVTEST_END

  `SVUNIT_TESTS_END

endmodule
