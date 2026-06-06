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
// CLASS: negative_corner_cases_test
//
// SVAUnit negative test that injects several protocol violations into the
// SBINIT flow to verify the assertions catch premature ready, extra toggles,
// and odd-millisecond glitches.
//
//---------------------------------------------------------------------------

class negative_corner_cases_test extends svaunit_test;
  `uvm_component_utils(negative_corner_cases_test)

  virtual sb_sva vif;

  int tx_iterations_completed = 0;
  int rx_iterations_completed = 0;

  // Function: new
  //
  // Creates the negative_corner_cases_test component.

  extern function new(string name = "negative_corner_cases_test", uvm_component parent);

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

  // Task: run_evil_attempt
  //
  // Executes one SBINIT attempt while injecting the selected protocol violation.

  extern task run_evil_attempt(string error_type);

  // Task: test
  //
  // Runs the sequence of negative-corner-case attempts.

  extern task test();
endclass

//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: negative_corner_cases_test
//
//---------------------------------------------------------------------------

// new
// ---

function negative_corner_cases_test::new(string name = "negative_corner_cases_test", uvm_component parent);
  super.new(name, parent);
endfunction

// build_phase
// -----------

function void negative_corner_cases_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(virtual sb_sva)::get(this, "", "VIF", vif)) begin
    `uvm_fatal("NO_VIF", "SVA IF is not set!")
  end
  uvm_top.set_timeout(0, 0); 
endfunction

// get_pattern_bit
// ---------------

function logic negative_corner_cases_test::get_pattern_bit(int idx);
  if (idx < 64) return (idx % 2 == 0) ? 1'b1 : 1'b0;
  else return 1'b0; 
endfunction

// zero_outputs
// ------------

function void negative_corner_cases_test::zero_outputs();
  vif.o_tx_decoding <= '0; vif.o_tx_info <= '0; vif.o_tx_data <= '0; vif.o_tx_valid <= '0;
  vif.o_rx_decoding <= '0; vif.o_rx_info <= '0; vif.o_rx_data <= '0; vif.o_rx_valid <= '0;
  vif.o_sb_tx_req   <= '0; vif.o_sb_tx_rsp <= '0; vif.o_sb_rx_req <= '0; vif.o_sb_rx_rsp <= '0;
  vif.o_sb_tx_done  <= '0; vif.o_sb_rx_done <= '0; vif.o_sb_ready <= '0;
  vif.o_tx_sb_data  <= '0; vif.o_tx_sb_clk <= '0;
  vif.i_rx_sb_data  <= 1'b0; vif.i_rx_sb_clk <= 1'b0;
endfunction

// rx_pattern_iteration
// --------------------

task negative_corner_cases_test::rx_pattern_iteration();
  for (int i = 0; i < 64; i++) begin
    @(posedge vif.clk_1x);
    vif.i_rx_sb_clk <= 1'b1; vif.i_rx_sb_data <= (i % 2 == 0) ? 1'b1 : 1'b0;
    @(negedge vif.clk_1x);
    vif.i_rx_sb_clk <= 1'b0;
  end
  for (int i = 0; i < 32; i++) begin
    @(posedge vif.clk_1x);
    vif.i_rx_sb_clk <= 1'b0; vif.i_rx_sb_data <= 1'b0;
  end
endtask

// run_evil_attempt
// ----------------

task negative_corner_cases_test::run_evil_attempt(string error_type);
  int ms_count = 0;
  int tx_bit_idx = 0;
  bit pattern_detected = 0;
  bit start_final_countdown = 0;
  int post_detect_iters = 0;

  tx_iterations_completed = 0; rx_iterations_completed = 0;
  zero_outputs();

  @(posedge vif.i_clk);
  vif.i_sb_init_start <= 1'b1;

  fork
    begin : attempt_container
      event attempt_complete;

      fork
        begin
          @(posedge vif.i_clk);
          vif.i_sb_init_start <= 1'b0;
        end

        begin
          forever @(posedge vif.i_clk) begin
            if (vif.i_timer_1ms) ms_count++;
          end
        end

        begin : rx_thread
          repeat(500) @(posedge vif.clk_1x); 
          while (tx_iterations_completed < 2) begin
            rx_pattern_iteration(); rx_iterations_completed++;
          end
          for (int i = 0; i < 4; i++) begin
            rx_pattern_iteration(); rx_iterations_completed++;
          end
        end

        // THE EVIL TX GENERATOR
        begin : tx_thread
          while (post_detect_iters < 4) begin
            @(posedge vif.clk_1x);
            if (ms_count >= 8) break; 
            if (!pattern_detected && rx_iterations_completed >= 2) pattern_detected = 1;

            // -------------------------------------------------------------
            // CORNER CASE 1: The Premature Ready
            // Hardware asserts ready after 3 iterations instead of 4.
            // -------------------------------------------------------------
            if (error_type == "PREMATURE_READY" && post_detect_iters == 3) begin
              `uvm_warning("EVIL_TEST", "Injecting PREMATURE_READY violation!")
              @(posedge vif.i_clk);
              vif.o_sb_ready <= 1'b1;
              -> attempt_complete;
              break;
            end

            if (ms_count % 2 == 0) begin
              vif.o_tx_sb_data <= get_pattern_bit(tx_bit_idx);
              
              if (tx_bit_idx < 64) begin
                vif.o_tx_sb_clk <= 1'b1;
                @(negedge vif.clk_1x); 
                vif.o_tx_sb_clk <= 1'b0;
              end else begin
                // -------------------------------------------------------------
                // CORNER CASE 2: The Bleed-Over Toggle
                // Clock toggles exactly ONE extra time during the 32-UI low phase
                // -------------------------------------------------------------
                if (error_type == "EXTRA_TOGGLE" && tx_bit_idx == 64) begin
                  `uvm_warning("EVIL_TEST", "Injecting EXTRA_TOGGLE violation!")
                  vif.o_tx_sb_clk <= 1'b1;
                  @(negedge vif.clk_1x); 
                  vif.o_tx_sb_clk <= 1'b0;
                end else begin
                  vif.o_tx_sb_clk <= 1'b0;
                end
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
              
              // -------------------------------------------------------------
              // CORNER CASE 3: The Odd-Millisecond Glitch
              // A 1-cycle spike occurs deep inside the supposedly paused state
              // -------------------------------------------------------------
              if (error_type == "ODD_MS_GLITCH" && ms_count == 1 && tx_bit_idx == 40) begin
                `uvm_warning("EVIL_TEST", "Injecting ODD_MS_GLITCH violation!")
                vif.o_tx_sb_data <= 1'b1; // Force a spike!
              end
            end
          end

          if (error_type != "PREMATURE_READY") begin
            vif.o_tx_sb_data <= 1'b0;
            vif.o_tx_sb_clk  <= 1'b0; 
            if (ms_count < 8) begin
              @(posedge vif.i_clk);
              vif.o_sb_ready <= 1'b1;
            end
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

task negative_corner_cases_test::test();
  vif.i_reset <= 1'b1; // Start with reset
  repeat(10) @(posedge vif.i_clk);
  vif.i_reset <= 1'b0;
  vif.i_sb_init_start <= 1'b0;

  // Reset loop
  fork
    begin
      forever begin
        @(posedge vif.i_clk);
        if (vif.o_sb_ready && vif.i_sb_init_start) vif.i_sb_init_start <= 1'b0;
      end
    end
  join_none

  `uvm_info("SVA_TEST", "--- NEGATIVE TEST 1: PREMATURE READY ---", UVM_LOW)
  run_evil_attempt("PREMATURE_READY");
  repeat(50) @(posedge vif.i_clk); vif.i_reset <= 1'b1; repeat(50) @(posedge vif.i_clk); vif.i_reset <= 1'b0;

  `uvm_info("SVA_TEST", "--- NEGATIVE TEST 2: EXTRA CLOCK TOGGLE ---", UVM_LOW)
  run_evil_attempt("EXTRA_TOGGLE");
  repeat(50) @(posedge vif.i_clk); vif.i_reset <= 1'b1; repeat(50) @(posedge vif.i_clk); vif.i_reset <= 1'b0;

  `uvm_info("SVA_TEST", "--- NEGATIVE TEST 3: ODD MS GLITCH ---", UVM_LOW)
  run_evil_attempt("ODD_MS_GLITCH");
  repeat(200) @(posedge vif.i_clk);
endtask
