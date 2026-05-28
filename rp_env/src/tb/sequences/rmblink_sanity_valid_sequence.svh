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
// CLASS: rmblink_sanity_valid_sequence
//
//
//-----------------------------------------------------------------------------

typedef enum {
  TEST_PURE_RANDOM,                 // Test 1: Complete garbage data on all lines
  TEST_IDEAL_ALL_0F,                // Test 2: Perfect Valid (0F) and Perfect Clocks
  TEST_INJECT_START,                // Test 3: 16 valid patterns at the absolute start
  TEST_INJECT_MIDDLE,               // Test 4: 16 valid patterns somewhere in the middle
  TEST_INJECT_END,                  // Test 5: 16 valid patterns at the absolute end (Edge case)
  TEST_SINGLE_ERROR,                // Test 6: Ideal stream, but 1 bit flipped (Below Threshold)
  TEST_MULTI_ERR_ABOVE_THRESH,      // Test 8: Ideal stream, 5+ errors injected (Above Threshold)
  TEST_ACTIVE_IDLE,                 // Test 7: Alternating ACTIVE/IDLE patterns to test tracking logic
  TEST_ACTIVE_ERROR_INJECTION,        // Test 8: Inject errors only during ACTIVE periods to test error handling
  TEST_ACTIVE_IDLE_INJECTION,
  TEST_IDEAL_VALID_RANDOM_CLKS,     // Test 9: Perfect Valid (0F), but Clocks/Track are pure random noise
  TEST_RESET
} valid_test_mode_e;


class rmblink_sanity_valid_sequence extends rp_sequence_base #(rmblink_seq_item);
  `uvm_object_utils(rmblink_sanity_valid_sequence)

  valid_test_mode_e test_mode = TEST_IDEAL_ALL_0F;

  // Function: new
  //
  // Creates a new rmblink_sanity_valid_sequence instance with the given name.

  extern function new(string name = "rmblink_sanity_valid_sequence");

  // Task: body
  //
  // Sends randomized RX items and synchronizes with the reactive FIFO.

  extern task body();

  // Task: pre_body
  //
  // Captures the typed sequencer handle before the sequence starts.

  extern task pre_body();

endclass : rmblink_sanity_valid_sequence


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: rmblink_sanity_valid_sequence
//
//-----------------------------------------------------------------------------


// new
// ---

function rmblink_sanity_valid_sequence::new(string name = "rmblink_sanity_valid_sequence");
  super.new(name);
endfunction : new


// pre_body
// --------

task rmblink_sanity_valid_sequence::pre_body();
  super.pre_body();
endtask : pre_body


// body
// ----

task rmblink_sanity_valid_sequence::body();
  int start_idx;
  start_item(req);
  
  // Allocate arrays based on your parameters
  req.val_stream     = new[VALID_CLK_PATTERN_STREAM_LEN];
  req.clk_stream_p   = new[CLK_STREAM_LEN_VALID_PAT];
  req.clk_stream_n   = new[CLK_STREAM_LEN_VALID_PAT];
  req.track_stream   = new[CLK_STREAM_LEN_VALID_PAT];

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
    
    TEST_PURE_RANDOM: begin
      if (!std::randomize(req.val_stream))   `uvm_error("SEQ", "Rand fail: val_stream")
      if (!std::randomize(req.clk_stream_p)) `uvm_error("SEQ", "Rand fail: clk_p")
      if (!std::randomize(req.clk_stream_n)) `uvm_error("SEQ", "Rand fail: clk_n")
      if (!std::randomize(req.track_stream)) `uvm_error("SEQ", "Rand fail: track")
    end

    TEST_IDEAL_ALL_0F: begin
      foreach (req.val_stream[i]) req.val_stream[i] = 8'b0000_1111;
    end

    TEST_INJECT_START: begin
      if (!std::randomize(req.val_stream)) `uvm_error("SEQ", "Rand fail")
      for (int i = 0; i < 16; i++) req.val_stream[i] = 8'b0000_1111;
    end

    TEST_INJECT_MIDDLE: begin
      if (!std::randomize(req.val_stream)) `uvm_error("SEQ", "Rand fail")
      start_idx = 32;
      `uvm_info("rmblink_sanity_valid_sequence", $sformatf("Start index: %0d", start_idx), UVM_LOW)
      
      for (int i = 0; i < 16; i++) req.val_stream[start_idx + i] = 8'b0000_1111;
    end

    TEST_INJECT_END: begin
      if (!std::randomize(req.val_stream)) `uvm_error("SEQ", "Rand fail")
      start_idx = VALID_CLK_PATTERN_STREAM_LEN - 16; 
      for (int i = 0; i < 16; i++) req.val_stream[start_idx + i] = 8'b0000_1111;
    end


    TEST_SINGLE_ERROR: begin
      foreach (req.val_stream[i]) req.val_stream[i] = 8'b0000_1111;
      start_idx = $urandom_range(VALID_CLK_PATTERN_STREAM_LEN - 1, 0);
      req.val_stream[start_idx] = 8'b0100_1011; // Inject 1 error
    end

    TEST_MULTI_ERR_ABOVE_THRESH: begin
      foreach (req.val_stream[i]) req.val_stream[i] = 8'b0000_1111;
      // Assuming threshold is at least 2
      for (int i=0; i<2; i++) begin
        start_idx = $urandom_range(VALID_CLK_PATTERN_STREAM_LEN - 1, 0);
        req.val_stream[start_idx] = 8'b0100_1011;
      end
    end

    TEST_ACTIVE_IDLE: begin
      // ACTIVE (0F)
      foreach (req.val_stream[i]) req.val_stream[i] = 8'b0000_1111;
    end

    TEST_ACTIVE_ERROR_INJECTION: begin
      foreach (req.val_stream[i]) req.val_stream[i] = 8'b0000_1111;
      start_idx = $urandom_range(VALID_CLK_PATTERN_STREAM_LEN - 1, 0);
      req.val_stream[start_idx] = 8'b0100_1011; // Inject 1 error
    end

    TEST_ACTIVE_IDLE_INJECTION: begin
      foreach (req.val_stream[i]) req.val_stream[i] = 8'b0000_1111;
      start_idx = $urandom_range(VALID_CLK_PATTERN_STREAM_LEN - 1, 0);
      req.val_stream[start_idx] = 8'b0000_0000; // Inject 1 error
      start_idx = $urandom_range(VALID_CLK_PATTERN_STREAM_LEN - 1, 0);
      req.val_stream[start_idx] = 8'b0000_0000; // Inject 1 error
      start_idx = $urandom_range(VALID_CLK_PATTERN_STREAM_LEN - 1, 0);
      req.val_stream[start_idx] = 8'b0000_0000; // Inject 1 error
    end
    
    TEST_IDEAL_VALID_RANDOM_CLKS: begin
      foreach (req.val_stream[i]) req.val_stream[i] = 8'b0000_1111;
      // Valid stream is perfect, but scramble the physical clocks
      if (!std::randomize(req.clk_stream_p)) `uvm_error("SEQ", "Rand fail: clk_p")
      if (!std::randomize(req.clk_stream_n)) `uvm_error("SEQ", "Rand fail: clk_n")
      if (!std::randomize(req.track_stream)) `uvm_error("SEQ", "Rand fail: track")
    end
    
  endcase

  // =========================================================
  // HARDCODE FINAL BITS (Overrides any randomization above)
  // =========================================================
  
  // 1. Force the last bit of the Valid stream to 0.
  // Using index [size - 1] gets the last byte. 
  req.val_stream[VALID_CLK_PATTERN_STREAM_LEN - 1][7] = 1'b0; 

  // 2. Force the last bits of the 1-bit clock and track arrays
  req.clk_stream_p[CLK_STREAM_LEN_VALID_PAT - 1] = 1'b0;
  req.clk_stream_n[CLK_STREAM_LEN_VALID_PAT - 1] = 1'b1;
  req.track_stream[CLK_STREAM_LEN_VALID_PAT - 1] = 1'b0;

  // =========================================================
  req.idle_ui_cnt = 0;
  req.rp_opmode = VAL_PATTERN;
  req.data  = {default: '0};

  finish_item(req);
endtask : body
