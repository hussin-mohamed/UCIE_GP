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

`include "uvm_macros.svh"
`include "svunit_defines.svh"
`include "../sequence_items/ltsm_seq_item.svh"
`include "../sequence_items/phylink_seq_item.svh"
`include "../sequence_items/rdi_seq_item.svh"
`include "../sb_utils.svh"

// Note: Ensure all predictor and comparator classes are included/compiled 
// before sb_scoreboard.svh, or that they are included inside sb_scoreboard.svh
`include "../scoreboard/sb_pred_ltsm2link.svh"
`include "../scoreboard/sb_pred_link2ltsm.svh"
`include "../scoreboard/sb_cmp_base.svh"
`include "../scoreboard/sb_cmp_ltsm2link.svh"
`include "../scoreboard/sb_cmp_link2ltsm_tx.svh"
`include "../scoreboard/sb_cmp_link2ltsm_rx.svh"
`include "../scoreboard/sb_cmp_link2ltsm_rdi.svh"
`include "../scoreboard/sb_scoreboard.svh"

import svunit_uvm_mock_pkg::*;

//---------------------------------------------------------------------------
//
// CLASS: sb_scoreboard_uvm_wrapper
//
// Lightweight UVM wrapper around sb_scoreboard used to instantiate the full
// scoreboard in SVUnit without additional environment infrastructure.
//
//---------------------------------------------------------------------------

class sb_scoreboard_uvm_wrapper extends sb_scoreboard;

  `uvm_component_utils(sb_scoreboard_uvm_wrapper)

  // Function: new
  //
  // Creates the scoreboard wrapper component.

  extern function new(string name = "sb_scoreboard_uvm_wrapper", uvm_component parent);

  //===================================
  // Build
  //===================================

  // Function: build_phase
  //
  // Delegates scoreboard construction to the base class.

  extern function void build_phase(uvm_phase phase);

  //==================================
  // Connect
  //=================================

  // Function: connect_phase
  //
  // Delegates scoreboard connectivity to the base class.

  extern function void connect_phase(uvm_phase phase);
endclass

//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: sb_scoreboard_uvm_wrapper
//
//---------------------------------------------------------------------------

// new
// ---

function sb_scoreboard_uvm_wrapper::new(string name = "sb_scoreboard_uvm_wrapper", uvm_component parent);
  super.new(name, parent);
endfunction

// build_phase
// -----------

function void sb_scoreboard_uvm_wrapper::build_phase(uvm_phase phase);
   super.build_phase(phase);
endfunction

// connect_phase
// -------------

function void sb_scoreboard_uvm_wrapper::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
endfunction

module sb_scoreboard_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "sb_scoreboard_ut";
  svunit_testcase svunit_ut;

  //===================================
  // UUT
  //===================================
  sb_scoreboard_uvm_wrapper my_sb_scoreboard;

  // Test Variables
  ltsm_seq_item    ltsm_tx_item;
  ltsm_seq_item    ltsm_rx_item;
  phylink_seq_item phy_item;

  //---------------------------------------------------------
  // Helper: Populate explicit fields and calculate parity
  //---------------------------------------------------------
  function void populate_phy_item(
    phylink_seq_item item,
    opcode_t     op, 
    srcid_t      src, 
    dstid_t      dst, 
    fullcode_t   fc, 
    logic [15:0] inf, 
    logic [63:0] dat
  );
    item.opcode   = op;
    item.srcid    = src;
    item.dstid    = dst;
    item.fullcode = fc;
    item.info     = inf;
    item.data     = dat;

    // Calculate correct parity
    item.cp = ^{dst, inf, fc, src, op};
    item.dp = ^dat;
  endfunction

  //===================================
  // Build
  //===================================
  function void build();
    svunit_ut = new(name);

    my_sb_scoreboard = sb_scoreboard_uvm_wrapper::type_id::create("my_sb_scoreboard", null);

    svunit_deactivate_uvm_component(my_sb_scoreboard);
  endfunction

  //===================================
  // Setup for running the Unit Tests
  //===================================
  task setup();
    svunit_ut.setup();
    
    // Instantiate test items
    ltsm_tx_item = ltsm_seq_item::type_id::create("ltsm_tx_item");
    ltsm_rx_item = ltsm_seq_item::type_id::create("ltsm_rx_item");
    phy_item     = phylink_seq_item::type_id::create("phy_item");

    svunit_activate_uvm_component(my_sb_scoreboard);

    // start the testing phase
    svunit_uvm_test_start();
  endtask

  //===================================
  // Teardown
  //===================================
  task teardown();
    svunit_ut.teardown();
    // terminate the testing phase 
    svunit_uvm_test_finish();

    svunit_deactivate_uvm_component(my_sb_scoreboard);
  endtask

  //===================================
  // SVUNIT TESTS
  //===================================
  `SVUNIT_TESTS_BEGIN

    //=========================================================================
    // INTEGRATION MATCH TESTS
    //=========================================================================

    //---------------------------------------------------------
    // Test 1: LTSM -> Link (Perfect Match)
    //---------------------------------------------------------
    `SVTEST(ltsm2link_path_match_test)
      // 1. Setup Stimulus (Driven by LTSM TX Monitor)
      ltsm_tx_item.set_tx_encoding(SBINIT_TX_Out_Of_Reset_MSG);
      ltsm_tx_item.info = 16'hAAAA;
      ltsm_tx_item.data = 64'h0;

      // 2. Setup Expected Actual (Driven by PHY Link Monitor)
      populate_phy_item(phy_item, MSG_WO_DATA, SRC_PHY, DST_PHY, SBINIT_out_of_Reset, 16'hAAAA, 64'h0);

      // 3. Inject stimulus and actual into wrapper
      my_sb_scoreboard.axp_in_tx.write(ltsm_tx_item);
      my_sb_scoreboard.axp_out_phy.write(phy_item);

      // 4. Yield to let comparator threads execute. 
      // If the UUT works, no uvm_error will be logged.
      #10;
    `SVTEST_END

    //---------------------------------------------------------
    // Test 2: Link -> LTSM RX Path (Perfect Match)
    //---------------------------------------------------------
    `SVTEST(link2ltsm_rx_path_match_test)
      // 1. Setup Stimulus (Driven by PHY Link Monitor)
      populate_phy_item(phy_item, MSG_WO_DATA, SRC_PHY, DST_PHY, SBINIT_done_resp, 16'h6666, 64'h0);

      // 2. Setup Expected Actual (Driven by LTSM RX Monitor)
      ltsm_rx_item.set_rx_encoding(SBINIT_RX_Done_Handshake);
      ltsm_rx_item.info = 16'h6666;
      ltsm_rx_item.data = 64'h0;
      ltsm_rx_item.valid = 1'b1; // Mark as valid parity

      // 3. Inject
      my_sb_scoreboard.axp_in_phy.write(phy_item);
      my_sb_scoreboard.axp_out_rx.write(ltsm_rx_item);

      #10;
    `SVTEST_END

    //=========================================================================
    // INTEGRATION MISMATCH TESTS (Testing Error Catching)
    //=========================================================================

    //---------------------------------------------------------
    // Test 3: LTSM -> Link (Data Field Mismatch)
    //---------------------------------------------------------
    `SVTEST(ltsm2link_path_mismatch_test)
      // Tell SVUnit to expect a UVM error from the cmp_ltsm2link component. 
      // Using "Mismatch" handles both your old and new logging strings.
      uvm_report_mock::expect_error("cmp_ltsm2link", "Mismatch");

      // Stimulus
      ltsm_tx_item.set_tx_encoding(MBINIT_PARAM_TX_Config_Handshake);
      ltsm_tx_item.info = 16'h1234;
      ltsm_tx_item.data = 64'h1111_2222;

      // Actual (Intentionally corrupt the data field to force a mismatch)
      populate_phy_item(phy_item, MSG_W_64B_DATA, SRC_PHY, DST_PHY, MBINIT_PARAM_configuration_req, 16'h1234, 64'hDEAD_BEEF);

      my_sb_scoreboard.axp_in_tx.write(ltsm_tx_item);
      my_sb_scoreboard.axp_out_phy.write(phy_item);

      #10;
    `SVTEST_END

    //---------------------------------------------------------
    // Test 4: Link -> LTSM TX Path (Info Field Mismatch)
    //---------------------------------------------------------
    `SVTEST(link2ltsm_tx_path_mismatch_test)
      uvm_report_mock::expect_error("cmp_link2ltsm_tx", "Mismatch");

      // Stimulus (SBINIT_done_req is evaluated as a TX msg inside link2ltsm predictor)
      populate_phy_item(phy_item, MSG_WO_DATA, SRC_PHY, DST_PHY, SBINIT_done_req, 16'h1111, 64'h0);

      // Actual (Intentionally corrupt the info field to force a mismatch)
      ltsm_tx_item.set_tx_encoding(SBINIT_TX_Done_Handshake);
      ltsm_tx_item.info = 16'h9999;
      ltsm_tx_item.data = 64'h0;
      ltsm_tx_item.valid = 1'b1;

      my_sb_scoreboard.axp_in_phy.write(phy_item);
      my_sb_scoreboard.axp_out_tx.write(ltsm_tx_item);

      #10;
    `SVTEST_END

  `SVUNIT_TESTS_END

endmodule
