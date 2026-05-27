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
// CLASS: rmblink_sanity_PerLaneID_sequence
//
//
//-----------------------------------------------------------------------------

class rmblink_sanity_PerLaneID_sequence extends rp_sequence_base #(rmblink_seq_item);
  `uvm_object_utils(rmblink_sanity_PerLaneID_sequence)

  ltsmc_sequencer seqr;
  rx_encoding_t   current_state_enc;
  rx_encoding_t   previous_state_enc;
  rx_encoding_t   resume_state_enc;

  // Local Configuration Storage
  lane_map_code_t m_lane_map_code;
  logic [15:0]    m_error_threshold;
  logic           m_half_rate;

  bit is_first_data_pat;


  // Function: new
  //
  // Creates a new rmblink_sanity_PerLaneID_sequence instance with the given name.

  extern function new(string name = "rmblink_sanity_PerLaneID_sequence");


  // Task: body
  //
  // Sends randomized RX items and synchronizes with the reactive FIFO.

  extern task body();

  // Task: pre_body
  //
  // Captures the typed sequencer handle before the sequence starts.

  extern task pre_body();

endclass : rmblink_sanity_PerLaneID_sequence


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: rmblink_sanity_PerLaneID_sequence
//
//-----------------------------------------------------------------------------


// new
// ---

function rmblink_sanity_PerLaneID_sequence::new(string name = "rmblink_sanity_PerLaneID_sequence");
  super.new(name);
  current_state_enc = RESET_Reset;
  resume_state_enc  = RESET_Reset;
  is_first_data_pat = 1;
endfunction : new


// pre_body
// --------

task rmblink_sanity_PerLaneID_sequence::pre_body();
  super.pre_body();
  $cast(seqr, get_sequencer());
endtask : pre_body


// body
// ----

task rmblink_sanity_PerLaneID_sequence::body();
  start_item(req);

  // req.data         = get_ideal_PerLaneID_pattern();
  assert(req.randomize());
  req.val_stream   = get_ideal_valid_stream(pDATA_WIDTH/8);
  req.clk_stream_p = get_ideal_clkp_stream(pDATA_WIDTH);
  req.clk_stream_n = get_ideal_clkn_stream(pDATA_WIDTH);
  req.track_stream = get_ideal_clkp_stream(pDATA_WIDTH);
  req.idle_ui_cnt  = 0;
  req.rp_opmode    = DATA_PATTERN;
  req.is_first_data_pat = is_first_data_pat;
  is_first_data_pat = 0;
  finish_item(req);
endtask : body
