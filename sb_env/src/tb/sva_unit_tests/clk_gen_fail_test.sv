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

import uvm_pkg::*;
import svaunit_pkg::*;
`include "uvm_macros.svh"

//---------------------------------------------------------------------------
//
// CLASS: clk_gen_fail_test
//
// SVAUnit negative test that injects malformed TX sideband clock-generation
// sequences to confirm the clock-generation assertions fail.
//
//---------------------------------------------------------------------------

class clk_gen_fail_test extends svaunit_test;
  `uvm_component_utils(clk_gen_fail_test)

  virtual sb_sva vif;

  // Function: new
  //
  // Creates the clk_gen_fail_test component.

  extern function new(string name = "clk_gen_fail_test", uvm_component parent);

  // Function: build_phase
  //
  // Retrieves the assertion interface handle from the UVM configuration DB.

  extern function void build_phase(uvm_phase phase);

  // Task: test
  //
  // Drives several malformed clock-generation corner cases.

  extern task test();
endclass

//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: clk_gen_fail_test
//
//---------------------------------------------------------------------------

// new
// ---

function clk_gen_fail_test::new(string name = "clk_gen_fail_test", uvm_component parent);
  super.new(name, parent);
endfunction

// build_phase
// -----------

function void clk_gen_fail_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(virtual sb_sva)::get(this, "", "VIF", vif)) begin
    `uvm_fatal("NO_VIF", "SVA IF is not set!")
  end
endfunction

// test
// ----

task clk_gen_fail_test::test();
  // Initialize to safe states
  vif.i_sb_init_start <= 1'b0;
  vif.o_tx_sb_clk     <= 1'b0;
  @(posedge vif.i_clk);

  // =========================================================
  // CORNER CASE 1: The Late Start (Shifted by 1 clk_800MHz)
  // =========================================================
  `uvm_info("FAIL_TEST", "Injecting Corner Case 1: Late Start...", UVM_LOW)
  vif.i_sb_init_start <= 1'b1;
  @(posedge vif.i_clk);
  vif.i_sb_init_start <= 1'b0; // Drop trigger so we can reuse it later

  // INTENTIONAL BUG: Delay 1 extra clk_800MHz cycle before starting toggles
  @(posedge vif.clk_800MHz);
  
  for (int i = 0; i < 64; i++) begin
    @(posedge vif.clk_800MHz)  vif.o_tx_sb_clk <= 1'b1;
    @(negedge vif.clk_800MHz)  vif.o_tx_sb_clk <= 1'b0;
  end
  for (int i = 0; i < 32; i++) begin
    @(posedge vif.clk_800MHz);
    vif.o_tx_sb_clk <= 1'b0;
  end
  @(posedge vif.i_clk);


  // =========================================================
  // CORNER CASE 2: The Early Stop (63 toggles instead of 64)
  // =========================================================
  `uvm_info("FAIL_TEST", "Injecting Corner Case 2: Early Stop...", UVM_LOW)
  vif.i_sb_init_start <= 1'b1;
  @(posedge vif.i_clk);
  vif.i_sb_init_start <= 1'b0;

  // INTENTIONAL BUG: Only 63 toggles!
  for (int i = 0; i < 63; i++) begin
    @(posedge vif.clk_800MHz)  vif.o_tx_sb_clk <= 1'b1;
    @(negedge vif.clk_800MHz)  vif.o_tx_sb_clk <= 1'b0;
  end
  // 33 low cycles to pad the remaining time
  for (int i = 0; i < 33; i++) begin
    @(posedge vif.clk_800MHz);
    vif.o_tx_sb_clk <= 1'b0;
  end
  @(posedge vif.i_clk);


  // =========================================================
  // CORNER CASE 3: Glitch in the Low Interval
  // =========================================================
  `uvm_info("FAIL_TEST", "Injecting Corner Case 3: Glitch in Low Interval...", UVM_LOW)
  vif.i_sb_init_start <= 1'b1;
  @(posedge vif.i_clk);
  vif.i_sb_init_start <= 1'b0;

  // 64 Correct toggles
  for (int i = 0; i < 64; i++) begin
    @(posedge vif.clk_800MHz)  vif.o_tx_sb_clk <= 1'b1;
    @(negedge vif.clk_800MHz)  vif.o_tx_sb_clk <= 1'b0;
  end
  
  // 15 low cycles...
  for (int i = 0; i < 15; i++) begin
    @(posedge vif.clk_800MHz);
    vif.o_tx_sb_clk <= 1'b0;
  end
  
  // INTENTIONAL BUG: 1 rogue toggle in the middle of the low period!
  @(posedge vif.clk_800MHz)  vif.o_tx_sb_clk <= 1'b1;
  @(negedge vif.clk_800MHz)  vif.o_tx_sb_clk <= 1'b0;
  
  // Remaining 16 low cycles...
  for (int i = 0; i < 16; i++) begin
    @(posedge vif.clk_800MHz);
    vif.o_tx_sb_clk <= 1'b0;
  end
  
  @(posedge vif.clk_800MHz);
endtask
