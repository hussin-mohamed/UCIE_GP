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
// CLASS: rmblink_active_sequence
//
// Drives a simple directed payload on the rmblink interface during the ACTIVE state.
//
//-----------------------------------------------------------------------------

class rmblink_active_sequence extends rp_sequence_base #(rmblink_seq_item);
  `uvm_object_utils(rmblink_active_sequence)

  rmblink_sequencer seqr;

  // --- Configuration Knobs ---
  int          num_iterations = 10;
  logic [15:0] directed_data  = 16'hABCD;

  extern function new(string name = "rmblink_active_sequence");
  extern task pre_body();
  extern task body();

endclass : rmblink_active_sequence

//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

function rmblink_active_sequence::new(string name = "rmblink_active_sequence");
  super.new(name);
endfunction : new

task rmblink_active_sequence::pre_body();
  super.pre_body();
  $cast(seqr, get_sequencer());
endtask : pre_body

task rmblink_active_sequence::body();
  for (int cycle = 0; cycle < num_iterations; cycle++) begin
    start_item(req);
    assert(req.randomize());

    // Standard generic streams for ACTIVE operation
    req.val_stream   = get_ideal_valid_stream(pDATA_WIDTH/8);
    req.clk_stream_p = get_ideal_clkp_stream(pDATA_WIDTH);
    req.clk_stream_n = get_ideal_clkn_stream(pDATA_WIDTH);
    req.track_stream = get_ideal_clkp_stream(pDATA_WIDTH);
    req.rp_opmode    = DATA_PATTERN;
    if ((((cycle + 1) % 4) == 0) && cycle != 0) begin
      req.idle_ui_cnt  = 64;
    end else begin
      req.idle_ui_cnt  = 0;
    end

    if (cycle == 0) begin
      req.is_first_data_pat = 1;
    end else begin
      req.is_first_data_pat = 0;
    end

    // Fill all lane chunks with the simple directed data value
    for (int lane = 0; lane < pNUM_LANES; lane++) begin
      for (int word = 0; word < pDATA_WIDTH/16; word++) begin
        req.data[lane][word*16 +: 16] = $random();
      end
    end
    
    finish_item(req);
  end
endtask : body