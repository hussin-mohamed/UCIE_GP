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
// CLASS: clk_gen_test
//
// SVAUnit test that drives a legal TX sideband clock generation sequence for
// the pattern-generation assertions.
//
//---------------------------------------------------------------------------

class clk_gen_test extends svaunit_test;
  `uvm_component_utils(clk_gen_test)

  // Virtual interface handle to access the assertion signals.
  virtual sb_sva vif;

  // Function: new
  //
  // Creates the clk_gen_test component.

  extern function new(string name = "clk_gen_test", uvm_component parent);

  // Function: build_phase
  //
  // Retrieves the assertion interface handle from the UVM configuration DB.

  extern function void build_phase(uvm_phase phase);

  // Task: test
  //
  // Drives the nominal TX clock-generation pattern expected by the assertion.

  extern task test();
endclass

//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: clk_gen_test
//
//---------------------------------------------------------------------------

// new
// ---

function clk_gen_test::new(string name = "clk_gen_test", uvm_component parent);
  super.new(name, parent);
endfunction

// build_phase
// -----------

function void clk_gen_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(virtual sb_sva)::get(this, "", "VIF", vif)) begin
    `uvm_fatal("NO_VIF", "SVA IF is not set!")
  end
endfunction

// test
// ----

task clk_gen_test::test();
  // 1. Initialize to safe states
  vif.i_sb_init_start <= 1'b0;
  vif.o_tx_sb_clk     <= 1'b0;

  // 2. Align to the main logic clock and trigger the sequence
  @(posedge vif.i_clk);
  vif.i_sb_init_start <= 1'b1;

  // Wait for the next active clock edge
  @(posedge vif.i_clk);

  // 3. Drive o_tx_sb_clk to match clk_800MHz for 64 cycles
  for (int i = 0; i < 64; i++) begin
    @(posedge vif.clk_800MHz)  vif.o_tx_sb_clk <= 1'b1;
    @(negedge vif.clk_800MHz)  vif.o_tx_sb_clk <= 1'b0;
  end

  // 4. Keep o_tx_sb_clk low for 32 cycles
  for (int i = 0; i < 32; i++) begin
    @(posedge vif.clk_800MHz);
    vif.o_tx_sb_clk <= 1'b0;
  end

  // Wait exactly 1 more clk_800MHz cycle for the final clk_2x SVA sequence step to evaluate and register SUCCESS
  @(posedge vif.clk_800MHz);
endtask
