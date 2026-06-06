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
// CLASS: reset_test
//
// SVAUnit test that exercises idle, active, soft, and clean-recovery reset
// scenarios during the SBINIT pattern-generation flow.
//
//---------------------------------------------------------------------------

class reset_test extends svaunit_test;
  `uvm_component_utils(reset_test)

  virtual sb_sva vif;

  int tx_iterations_completed = 0;
  int rx_iterations_completed = 0;

  // Function: new
  //
  // Creates the reset_test component.

  extern function new(string name = "reset_test", uvm_component parent);

  // Function: build_phase
  //
  // Retrieves the assertion interface handle and disables the UVM timeout.

  extern function void build_phase(uvm_phase phase);

  // Function: get_pattern_bit
  //
  // Returns the expected TX pattern bit for a given UI index.

  extern function logic get_pattern_bit(int idx);

  // Function: zero_outputs
  //
  // Clears the local and remote interface outputs to an idle state.

  extern function void zero_outputs();

  // Task: rx_pattern_iteration
  //
  // Drives one complete remote-die RX pattern iteration.

  extern task rx_pattern_iteration();

  // Task: run_init_attempt
  //
  // Executes one initialization attempt under the requested reset mode.

  extern task run_init_attempt(string reset_mode);

  // Task: test
  //
  // Runs the sequence of reset scenarios and a final clean recovery attempt.

  extern task test();
endclass

//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: reset_test
//
//---------------------------------------------------------------------------

// new
// ---

function reset_test::new(string name = "reset_test", uvm_component parent);
  super.new(name, parent);
endfunction

// build_phase
// -----------

function void reset_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(virtual sb_sva)::get(this, "", "VIF", vif)) begin
    `uvm_fatal("NO_VIF", "SVA IF is not set!")
  end
  uvm_top.set_timeout(0, 0); 
endfunction

// get_pattern_bit
// ---------------

function logic reset_test::get_pattern_bit(int idx);
  if (idx < 64) return (idx % 2 == 0) ? 1'b1 : 1'b0;
  else return 1'b0; 
endfunction

// zero_outputs
// ------------

function void reset_test::zero_outputs();
  vif.o_tx_decoding <= '0;
  vif.o_tx_info     <= '0;
  vif.o_tx_data     <= '0;
  vif.o_tx_valid    <= '0;
  vif.o_rx_decoding <= '0;
  vif.o_rx_info     <= '0;
  vif.o_rx_data     <= '0;
  vif.o_rx_valid    <= '0;
  vif.o_sb_tx_req   <= '0;
  vif.o_sb_tx_rsp   <= '0;
  vif.o_sb_rx_req   <= '0;
  vif.o_sb_rx_rsp   <= '0;
  vif.o_sb_tx_done  <= '0;
  vif.o_sb_rx_done  <= '0;
  vif.o_sb_ready    <= '0;
  vif.o_tx_sb_data  <= '0;
  vif.o_tx_sb_clk   <= '0;
  
  // Mimic remote lines going dead
  vif.i_rx_sb_data  <= 1'b0;
  vif.i_rx_sb_clk   <= 1'b0;
endfunction

// rx_pattern_iteration
// --------------------

task reset_test::rx_pattern_iteration();
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

task reset_test::run_init_attempt(string reset_mode);
  int ms_count = 0;
  int tx_bit_idx = 0;
  bit pattern_detected = 0;
  bit start_final_countdown = 0;
  int post_detect_iters = 0;

  tx_iterations_completed = 0;
  rx_iterations_completed = 0;

  zero_outputs();

  // Only assert start if we aren't doing an IDLE reset
  if (reset_mode != "IDLE") begin
    @(posedge vif.i_clk);
    vif.i_sb_init_start <= 1'b1;
  end

  fork
    begin : attempt_container
      event attempt_complete;

      fork
        // THREAD 0: The Pulse Dropper
        begin
          if (reset_mode != "IDLE") begin
            @(posedge vif.i_clk);
            vif.i_sb_init_start <= 1'b0;
          end
        end

        // THREAD 1: Background Timer 
        begin
          forever @(posedge vif.i_clk) begin
            if (vif.i_timer_1ms) ms_count++;
          end
        end

        // THREAD 2: Remote Die RX Generation
        begin : rx_thread
          repeat(500) @(posedge vif.clk_1x); 
          while (tx_iterations_completed < 2) begin
            rx_pattern_iteration();
            rx_iterations_completed++;
          end
          for (int i = 0; i < 4; i++) begin
            rx_pattern_iteration();
            rx_iterations_completed++;
          end
        end

        // THREAD 3: Unified TX Generator
        begin : tx_thread
          while (post_detect_iters < 4) begin
            @(posedge vif.clk_1x);

            if (ms_count >= 8) break; 

            if (!pattern_detected && rx_iterations_completed >= 2) pattern_detected = 1;

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

          if (ms_count < 8) begin
            `uvm_info("SVA_TEST", "Handshake successful. Asserting ready.", UVM_LOW)
            @(posedge vif.i_clk);
            vif.o_sb_ready <= 1'b1;
            if (reset_mode == "NONE") -> attempt_complete; 
          end else begin
            `uvm_info("SVA_TEST", "Timeout reached.", UVM_LOW)
            if (reset_mode == "NONE") -> attempt_complete;
          end
        end

        // THREAD 4: The Intelligent Reset Controller
        begin : reset_thread
          if (reset_mode == "IDLE") begin
            repeat(50) @(posedge vif.i_clk);
            `uvm_info("SVA_TEST", ">>> DROPPING IDLE RESET <<<", UVM_LOW)
            vif.i_reset <= 1'b1;
            disable tx_thread; disable rx_thread;
            zero_outputs();
            repeat(100) @(posedge vif.i_clk);
            vif.i_reset <= 1'b0;
            -> attempt_complete;
          end
          
          else if (reset_mode == "ACTIVE") begin
            repeat(400) @(posedge vif.clk_1x);
            `uvm_info("SVA_TEST", ">>> DROPPING ACTIVE RESET BOMB <<<", UVM_LOW)
            vif.i_reset <= 1'b1;
            disable tx_thread; disable rx_thread;
            zero_outputs();
            repeat(100) @(posedge vif.i_clk);
            vif.i_reset <= 1'b0;
            -> attempt_complete;
          end
          
          else if (reset_mode == "SOFT") begin
            // Wait for the TX thread to successfully finish the handshake first!
            wait(vif.o_sb_ready == 1'b1);
            repeat(50) @(posedge vif.i_clk); 
            `uvm_info("SVA_TEST", ">>> DROPPING SOFT RESET (POST-SUCCESS) <<<", UVM_LOW)
            vif.i_reset <= 1'b1;
            disable tx_thread; disable rx_thread;
            zero_outputs();
            repeat(100) @(posedge vif.i_clk);
            vif.i_reset <= 1'b0;
            -> attempt_complete;
          end
        end
        
      join_none

      wait(attempt_complete.triggered);
      disable fork;
    end : attempt_container
  join
endtask

// test
// ----

task reset_test::test();
  vif.i_reset <= 1'b0;
  vif.i_sb_init_start <= 1'b0;

  fork
    begin
      forever begin
        @(posedge vif.i_clk);
        // Only pull start low automatically if it wasn't already handled
        if (vif.o_sb_ready && vif.i_sb_init_start) vif.i_sb_init_start <= 1'b0;
      end
    end
  join_none

  `uvm_info("SVA_TEST", "--- SCENARIO 1: IDLE RESET ---", UVM_LOW)
  run_init_attempt("IDLE");
  repeat(200) @(posedge vif.i_clk);

  `uvm_info("SVA_TEST", "--- SCENARIO 2: ACTIVE RESET (MID-FLIGHT) ---", UVM_LOW)
  run_init_attempt("ACTIVE");
  repeat(200) @(posedge vif.i_clk);

  `uvm_info("SVA_TEST", "--- SCENARIO 3: SOFT RESET (POST-SUCCESS) ---", UVM_LOW)
  run_init_attempt("SOFT");
  repeat(200) @(posedge vif.i_clk);

  `uvm_info("SVA_TEST", "--- SCENARIO 4: CLEAN RECOVERY ---", UVM_LOW)
  run_init_attempt("NONE");
  repeat(500) @(posedge vif.i_clk);
endtask
