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

class rmblink_sanity_valid_sequence extends rp_sequence_base #(rmblink_seq_item);
  `uvm_object_utils(rmblink_sanity_valid_sequence)

  
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
  start_item(req);
  req.val_stream     = new[VALID_CLK_PATTERN_STREAM_LEN];
  req.clk_stream_p   = new[CLK_STREAM_LEN_VALID_PAT];
  req.clk_stream_n   = new[CLK_STREAM_LEN_VALID_PAT];
  req.track_stream   = new[CLK_STREAM_LEN_VALID_PAT];

  foreach (req.val_stream[i]) begin
      req.val_stream[i] = 8'b0000_1111; // You can also write 8'hF0
    end

    foreach (req.clk_stream_p[i]) begin
      // Using the modulo operator (%) to check if the index is even
      if (i % 2 == 0) begin
        req.clk_stream_p[i] = 1'b1; // Even index -> 1
      end else begin
        req.clk_stream_p[i] = 1'b0; // Odd index -> 0
      end
    end
    
    foreach (req.clk_stream_n[i]) begin
      // Using the modulo operator (%) to check if the index is even
      if (i % 2 == 0) begin
        req.clk_stream_n[i] = 1'b0; // Even index -> 0
      end else begin
        req.clk_stream_n[i] = 1'b1; // Odd index -> 1
      end
    end

    foreach (req.track_stream[i]) begin
      // Using the modulo operator (%) to check if the index is even
      if (i % 2 == 0) begin
        req.track_stream[i] = 1'b1; // Even index -> 1
      end else begin
        req.track_stream[i] = 1'b0; // Odd index -> 0
      end
    end

  
    req.idle_ui_cnt = 0;
    req.rp_opmode = VAL_PATTERN;
    req.data  = {default: '0}; // Initialize all data lanes to 0 for the valid pattern

  finish_item(req);
endtask : body
