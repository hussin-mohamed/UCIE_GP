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

//-----------------------------------------------------------------------------
//
// CLASS: rmblink_sanity_clk_sequence
//
//
//-----------------------------------------------------------------------------

typedef enum {
  TEST_CLK_PURE_RANDOM,                 // Test 1: Complete garbage data on all lines
  TEST_CLK_IDEAL_ALL,                // Test 2: Perfect Valid (0F) and Perfect Clocks
  TEST_CLK_INJECT_START,                // Test 3: 16 valid patterns at the absolute start
  TEST_CLK_INJECT_MIDDLE,               // Test 4: 16 valid patterns somewhere in the middle
  TEST_CLK_INJECT_END,                  // Test 5: 16 valid patterns at the absolute end (Edge case)
  TEST_CLK_RESET
    
} clk_test_mode_e;


class rmblink_sanity_clk_sequence extends rp_sequence_base #(rmblink_seq_item);
  `uvm_object_utils(rmblink_sanity_clk_sequence)

  clk_test_mode_e test_mode = TEST_CLK_IDEAL_ALL;

  // Function: new
  //
  // Creates a new rmblink_sanity_clk_sequence instance with the given name.

  extern function new(string name = "rmblink_sanity_clk_sequence");

  // Task: body
  //
  // Sends randomized RX items and synchronizes with the reactive FIFO.

  extern task body();

  // Task: pre_body
  //
  // Captures the typed sequencer handle before the sequence starts.

  extern task pre_body();

endclass : rmblink_sanity_clk_sequence


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: rmblink_sanity_clk_sequence
//
//-----------------------------------------------------------------------------


// new
// ---

function rmblink_sanity_clk_sequence::new(string name = "rmblink_sanity_clk_sequence");
  super.new(name);
endfunction : new


// pre_body
// --------

task rmblink_sanity_clk_sequence::pre_body();
  super.pre_body();
endtask : pre_body


// body
// ----

task rmblink_sanity_clk_sequence::body();
  int start_idx;
  int block_num;
  start_item(req);
  
  // Allocate arrays based on your parameters
  req.val_stream     = new[VALID_CLK_PATTERN_STREAM_LEN];
  req.clk_stream_p   = new[CLK_STREAM_LEN_CLK_PAT];
  req.clk_stream_n   = new[CLK_STREAM_LEN_CLK_PAT];
  req.track_stream   = new[CLK_STREAM_LEN_CLK_PAT];
  

  // ---------------------------------------------------------
  // BASELINE: Set to Ideal/Zeros to prevent uninitialized data
  // ---------------------------------------------------------
  foreach (req.val_stream[i])   req.val_stream[i] = 8'h00;
  foreach (req.clk_stream_p[i]) req.clk_stream_p[i] = (i % 2 == 0) ? 1'b1 : 1'b0;
  foreach (req.clk_stream_n[i]) req.clk_stream_n[i] = (i % 2 == 0) ? 1'b0 : 1'b1;
  foreach (req.track_stream[i]) req.track_stream[i] = (i % 2 == 0) ? 1'b1 : 1'b0;

  // ---------------------------------------------------------
  // TEST SCENARIOS: Overwrite baseline based on test_mode
  // ---------------------------------------------------------
  case (test_mode)
    
    TEST_CLK_PURE_RANDOM: begin
      if (!std::randomize(req.clk_stream_p)) `uvm_error("SEQ", "Rand fail: clk_p")
      if (!std::randomize(req.clk_stream_n)) `uvm_error("SEQ", "Rand fail: clk_n")
      if (!std::randomize(req.track_stream)) `uvm_error("SEQ", "Rand fail: track")
    end

    TEST_CLK_IDEAL_ALL: begin
      foreach (req.clk_stream_p[i]) req.clk_stream_p[i] = (i % 2 == 0) ? 1'b1 : 1'b0;
      foreach (req.clk_stream_n[i]) req.clk_stream_n[i] = (i % 2 == 0) ? 1'b0 : 1'b1;
      foreach (req.track_stream[i]) req.track_stream[i] = (i % 2 == 0) ? 1'b1 : 1'b0;
    end

    TEST_CLK_INJECT_START: begin
      if (!std::randomize(req.clk_stream_p)) `uvm_error("SEQ", "Rand fail: clk_p")
      if (!std::randomize(req.clk_stream_n)) `uvm_error("SEQ", "Rand fail: clk_n")
      if (!std::randomize(req.track_stream)) `uvm_error("SEQ", "Rand fail: track")
      block_num = 0; 
      start_idx = block_num * CLK_STROBE_CLK_PAT;
      for (int i = 0; i < 512; i++)  req.clk_stream_p[start_idx + i] = ((start_idx + i) % 2 == 0) ? 1'b1 : 1'b0;
      for (int i = 0; i < 512; i++)  req.clk_stream_n[start_idx + i] = ((start_idx + i) % 2 == 0) ? 1'b0 : 1'b1;
      for (int i = 0; i < 512; i++)  req.track_stream[start_idx + i] = ((start_idx + i) % 2 == 0) ? 1'b1 : 1'b0;
    end

    TEST_CLK_INJECT_MIDDLE: begin
      if (!std::randomize(req.clk_stream_p)) `uvm_error("SEQ", "Rand fail: clk_p")
      if (!std::randomize(req.clk_stream_n)) `uvm_error("SEQ", "Rand fail: clk_n")
      if (!std::randomize(req.track_stream)) `uvm_error("SEQ", "Rand fail: track")
      block_num = $urandom_range(0, VALID_CLK_PATTERN_STREAM_LEN - 16); 
      start_idx = block_num * CLK_STROBE_CLK_PAT;
      for (int i = 0; i < 512; i++)  req.clk_stream_p[start_idx + i] = ((start_idx + i) % 2 == 0) ? 1'b1 : 1'b0;
      block_num = $urandom_range(0, VALID_CLK_PATTERN_STREAM_LEN - 16); 
      start_idx = block_num * CLK_STROBE_CLK_PAT;
      for (int i = 0; i < 512; i++)  req.clk_stream_n[start_idx + i] = ((start_idx + i) % 2 == 0) ? 1'b0 : 1'b1;
      block_num = $urandom_range(0, VALID_CLK_PATTERN_STREAM_LEN - 16); 
      start_idx = block_num * CLK_STROBE_CLK_PAT;
      for (int i = 0; i < 512; i++)  req.track_stream[start_idx + i] = ((start_idx + i) % 2 == 0) ? 1'b1 : 1'b0;
    end

    TEST_CLK_INJECT_END: begin
      if (!std::randomize(req.clk_stream_p)) `uvm_error("SEQ", "Rand fail: clk_p")
      if (!std::randomize(req.clk_stream_n)) `uvm_error("SEQ", "Rand fail: clk_n")
      if (!std::randomize(req.track_stream)) `uvm_error("SEQ", "Rand fail: track")
      block_num = VALID_CLK_PATTERN_STREAM_LEN - 16; 
      start_idx = block_num * CLK_STROBE_CLK_PAT;
      for (int i = 0; i < 512; i++)  req.clk_stream_p[start_idx + i] = ((start_idx + i) % 2 == 0) ? 1'b1 : 1'b0;
      for (int i = 0; i < 512; i++)  req.clk_stream_n[start_idx + i] = ((start_idx + i) % 2 == 0) ? 1'b0 : 1'b1;
      for (int i = 0; i < 512; i++)  req.track_stream[start_idx + i] = ((start_idx + i) % 2 == 0) ? 1'b1 : 1'b0;
    end

    TEST_CLK_RESET: begin
      foreach (req.clk_stream_p[i]) req.clk_stream_p[i] = 1'b0;
      foreach (req.clk_stream_n[i]) req.clk_stream_n[i] = 1'b0;
      foreach (req.track_stream[i]) req.track_stream[i] = 1'b0;
    end
    
  endcase

  // =========================================================
  // HARDCODE START BITS (Overrides any randomization above)
  // =========================================================
  
  // Force the last bits of the 1-bit clock and track arrays
  req.clk_stream_p[0] = 1'b1;
  req.clk_stream_n[0] = 1'b0;
  req.track_stream[0] = 1'b1;
  
  // =========================================================
  // HARDCODE FINAL BITS (Overrides any randomization above)
  // =========================================================
  
  // Force the last bits of the 1-bit clock and track arrays
  req.clk_stream_p[CLK_STREAM_LEN_CLK_PAT - 1] = 1'b0;
  req.clk_stream_n[CLK_STREAM_LEN_CLK_PAT - 1] = 1'b1;
  req.track_stream[CLK_STREAM_LEN_CLK_PAT - 1] = 1'b0;

  // =========================================================
  req.idle_ui_cnt = 16;
  req.rp_opmode = CLK_PATTERN;
  req.data  = {default: '0}; 

  finish_item(req);
endtask : body
