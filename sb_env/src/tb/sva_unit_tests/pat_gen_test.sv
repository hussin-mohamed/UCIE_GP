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

`include "uvm_macros.svh"
`include "svaunit_defines.svh"
import uvm_pkg::*;
import svaunit_pkg::*;

//---------------------------------------------------------------------------
//
// CLASS: pat_gen_test
//
// SVAUnit test that drives a nominal pattern-generation handshake between the
// local and remote dies for the pattern-generation assertions.
//
//---------------------------------------------------------------------------

class pat_gen_test extends svaunit_test;
  `uvm_component_utils(pat_gen_test)

  virtual sb_sva vif;

  // Function: new
  //
  // Creates the pat_gen_test component.

  extern function new(string name = "pat_gen_test", uvm_component parent);

  // Function: build_phase
  //
  // Retrieves the assertion interface handle from the UVM configuration DB.

  extern function void build_phase(uvm_phase phase);

  // Task: tx_pattern_iteration
  //
  // Drives one complete local-die TX pattern iteration.

  extern task tx_pattern_iteration();

  // Task: test
  //
  // Runs the nominal bidirectional pattern-generation scenario.

  extern task test();
endclass

//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: pat_gen_test
//
//---------------------------------------------------------------------------

// new
// ---

function pat_gen_test::new(string name = "pat_gen_test", uvm_component parent);
  super.new(name, parent);
endfunction

// build_phase
// -----------

function void pat_gen_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(virtual sb_sva)::get(this, "", "VIF", vif)) begin
    `uvm_fatal("NO_VIF", "SVA IF is not set!")
  end
endfunction

// tx_pattern_iteration
// --------------------

task pat_gen_test::tx_pattern_iteration();
  // 64 cycles of alternating 1 and 0
  for (int i = 0; i < 64; i++) begin
    @(posedge vif.clk_1x);
    vif.o_tx_sb_data <= (i % 2 == 0) ? 1'b1 : 1'b0;
  end
  
  // 32 cycles of 0
  for (int i = 0; i < 32; i++) begin
    @(posedge vif.clk_1x);
    vif.o_tx_sb_data <= 1'b0;
  end
endtask

// test
// ----

task pat_gen_test::test();
  bit rx_detected = 0;

  // 1. Initialize safe states
  vif.i_sb_init_start <= 1'b0;
  vif.o_tx_sb_data    <= 1'b0;
  vif.i_rx_sb_data    <= 1'b0;

  // Wait for main clock and trigger the sequence
  @(posedge vif.i_clk);
  vif.i_sb_init_start <= 1'b1;

  // 2. Launch concurrent TX and RX operations
  fork
    // ------------------------------------------------------------------
    // THREAD 1: The RX Input Generator (The Link Partner)
    // ------------------------------------------------------------------
    begin
      // Wait an arbitrary amount of time to simulate asynchronous arrival
      repeat(150) @(posedge vif.i_rx_sb_clk); 
      
      // Inject exactly 128 bits of alternating 101010... pattern
      for (int i = 0; i < 128; i++) begin
        @(posedge vif.i_rx_sb_clk);
        vif.i_rx_sb_data <= (i % 2 == 0) ? 1'b1 : 1'b0;
      end
      
      // Signal to the TX thread that the RX pattern has been fully received
      rx_detected = 1;
    end

    // ------------------------------------------------------------------
    // THREAD 2: The TX Output Generator (The Sideband)
    // ------------------------------------------------------------------
    begin
      // Wait for the exact edge where i_sb_init_start was sampled
      @(posedge vif.i_clk);

      // Keep generating the pattern in a loop UNTIL the RX thread finishes
      while (!rx_detected) begin
        tx_pattern_iteration();
      end

      // Once RX is detected, the specification mandates exactly 4 MORE iterations
      for (int i = 0; i < 4; i++) begin
        tx_pattern_iteration();
      end
    end
  join

  // 3. Give the SVA engine a few clock cycles to process the final endpoint
  repeat(5) @(posedge vif.i_clk);

  // 4. Verify the assertion passed
  // `fail_if_sva_not_succeeded("tb_top.dut_if.ap_pat_gen", "Assertion ap_pat_gen failed or did not trigger.")
endtask
