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
// CLASS: timeout_pat_gen_test
//
// SVAUnit test that exercises both timeout and successful pattern-generation
// scenarios using a reusable multi-attempt helper.
//
//---------------------------------------------------------------------------

class timeout_pat_gen_test extends svaunit_test;
  `uvm_component_utils(timeout_pat_gen_test)

  virtual sb_sva vif;

  int tx_iterations_completed = 0;
  int rx_iterations_completed = 0;

  // Function: new
  //
  // Creates the timeout_pat_gen_test component.

  extern function new(string name = "timeout_pat_gen_test", uvm_component parent);

  // Function: build_phase
  //
  // Retrieves the assertion interface handle and disables the UVM timeout.

  extern function void build_phase(uvm_phase phase);

  // Function: get_pattern_bit
  //
  // Returns the expected TX pattern bit for a given UI index.

  extern function logic get_pattern_bit(int idx);

  // Task: rx_pattern_iteration
  //
  // Drives one complete remote-die RX pattern iteration.

  extern task rx_pattern_iteration();

  // Task: run_init_attempt
  //
  // Executes either the timeout scenario or the successful initialization scenario.

  extern task run_init_attempt(bit inject_timeout);

  // Task: test
  //
  // Runs the timeout attempt followed by a successful recovery attempt.

  extern task test();
endclass

//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: timeout_pat_gen_test
//
//---------------------------------------------------------------------------

// new
// ---

function timeout_pat_gen_test::new(string name = "timeout_pat_gen_test", uvm_component parent);
  super.new(name, parent);
endfunction

// build_phase
// -----------

function void timeout_pat_gen_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(virtual sb_sva)::get(this, "", "VIF", vif)) begin
    `uvm_fatal("NO_VIF", "SVA IF is not set!")
  end
  uvm_top.set_timeout(0, 0); 
endfunction

// get_pattern_bit
// ---------------

function logic timeout_pat_gen_test::get_pattern_bit(int idx);
  if (idx < 64) return (idx % 2 == 0) ? 1'b1 : 1'b0;
  else return 1'b0; 
endfunction

// rx_pattern_iteration
// --------------------

task timeout_pat_gen_test::rx_pattern_iteration();
  for (int i = 0; i < 64; i++) begin
    @(posedge vif.clk_1x);
    vif.i_rx_sb_clk  <= 1'b1;
    vif.i_rx_sb_data <= (i % 2 == 0) ? 1'b1 : 1'b0;
    @(negedge vif.clk_1x);
    vif.i_rx_sb_clk  <= 1'b0;
  end
  
  for (int i = 0; i < 32; i++) begin
    @(posedge vif.clk_1x);
    vif.i_rx_sb_clk  <= 1'b0;
    vif.i_rx_sb_data <= 1'b0;
  end
endtask

// run_init_attempt
// ----------------

task timeout_pat_gen_test::run_init_attempt(bit inject_timeout);
  int ms_count = 0;
  int tx_bit_idx = 0;
  bit pattern_detected = 0;
  bit start_final_countdown = 0;
  int post_detect_iters = 0;

  // Reset iteration trackers for the new attempt
  tx_iterations_completed = 0;
  rx_iterations_completed = 0;

  vif.o_tx_sb_data    <= 1'b0;
  vif.o_tx_sb_clk     <= 1'b0;
  vif.i_rx_sb_data    <= 1'b0;
  vif.i_rx_sb_clk     <= 1'b0;
  vif.o_sb_ready      <= 1'b0;

  // Assert start command
  @(posedge vif.i_clk);
  vif.i_sb_init_start <= 1'b1;

  fork
    begin : execution_threads
      fork
        // THREAD 1: Local Timer Tracker
        begin
          forever @(posedge vif.i_clk) begin
            if (vif.i_timer_1ms) ms_count++;
          end
        end

        // THREAD 2: Remote Die RX Generation
        begin
          repeat(500) @(posedge vif.clk_1x); 
          
          if (inject_timeout) begin
            // -- INCOMPLETE RX (Forces Timeout) --
            rx_pattern_iteration();
            rx_iterations_completed++;
            for (int i = 0; i < 32; i++) begin
              @(posedge vif.clk_1x);
              vif.i_rx_sb_clk  <= 1'b1;
              vif.i_rx_sb_data <= (i % 2 == 0) ? 1'b1 : 1'b0;
              @(negedge vif.clk_1x);
              vif.i_rx_sb_clk  <= 1'b0;
            end
            vif.i_rx_sb_clk  <= 1'b0;
            vif.i_rx_sb_data <= 1'b0;
            forever @(posedge vif.i_clk); // Sleep until cleanly killed
          end else begin
            // -- COMPLETE RX (Forces Detection & Success) --
            while (tx_iterations_completed < 2) begin
              rx_pattern_iteration();
              rx_iterations_completed++;
            end
            for (int i = 0; i < 4; i++) begin
              rx_pattern_iteration();
              rx_iterations_completed++;
            end
            forever @(posedge vif.i_clk); // Sleep until cleanly killed
          end
        end

        // THREAD 3: The Unified TX Generator
        begin
          while (post_detect_iters < 4) begin
            @(posedge vif.clk_1x);

            if (ms_count >= 8) break; 

            if (!pattern_detected && rx_iterations_completed >= 2) begin
              pattern_detected = 1;
            end

            if (ms_count % 2 == 0) begin
              vif.o_tx_sb_data <= get_pattern_bit(tx_bit_idx);
              if (tx_bit_idx < 64) begin
                vif.o_tx_sb_clk <= 1'b1;
                @(negedge vif.clk_1x); 
                vif.o_tx_sb_clk <= 1'b0;
              end else begin
                vif.o_tx_sb_clk <= 1'b0;
              end

              tx_bit_idx++;
              if (tx_bit_idx == 96) begin
                tx_bit_idx = 0; 
                tx_iterations_completed++;
                
                if (start_final_countdown) post_detect_iters++;
                if (pattern_detected && !start_final_countdown) start_final_countdown = 1;
              end
            end else begin
              vif.o_tx_sb_data <= 1'b0;
              vif.o_tx_sb_clk  <= 1'b0; 
            end
          end

          vif.o_tx_sb_data <= 1'b0;
          vif.o_tx_sb_clk  <= 1'b0; 

          if (ms_count >= 8) begin
            `uvm_info("SVA_TEST", "8ms timeout reached. Initialization failed.", UVM_LOW)
          end else begin
            `uvm_info("SVA_TEST", "Handshake successful. Asserting ready.", UVM_LOW)
            @(posedge vif.i_clk);
            vif.o_sb_ready <= 1'b1;
          end
        end
      join_any
      
      // This instantly destroys the local Timer and RX threads the moment 
      // the TX thread (Thread 3) finishes its job. 
      disable fork; 
    end : execution_threads
  join
endtask

// test
// ----

task timeout_pat_gen_test::test();
  vif.i_sb_init_start <= 1'b0;

  // 1. Spawn the Background Signal Monitors 
  // These run forever and evaluate continuously across all attempts
  fork
    begin
      forever begin
        @(posedge vif.i_clk);
        if (vif.o_sb_ready) vif.i_sb_init_start <= 1'b0;
      end
    end
    begin
      forever begin
        @(posedge vif.timeout);
        @(posedge vif.i_clk);
        vif.i_sb_init_start <= 1'b0;
      end
    end
  join_none

  // 2. ATTEMPT 1: The Intentional Timeout
  `uvm_info("SVA_TEST", "--- STARTING ATTEMPT 1: TIMEOUT SCENARIO ---", UVM_LOW)
  run_init_attempt(.inject_timeout(1));

  // Wait for the hardware state machine to fully reset after timeout
  repeat(1000) @(posedge vif.i_clk);

  // 3. ATTEMPT 2: Successful Protocol Handshake
  `uvm_info("SVA_TEST", "--- STARTING ATTEMPT 2: SUCCESS SCENARIO ---", UVM_LOW)
  run_init_attempt(.inject_timeout(0));

  // Wait a bit to ensure assertions evaluate properly before the test ends
  repeat(500) @(posedge vif.i_clk);
endtask
