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

class rmblink_sanity_PerLaneID_sequence extends rp_sequence_base #(ltsmc_seq_item);
  `uvm_object_utils(rmblink_sanity_PerLaneID_sequence)

  rmblink_sequencer seqr;

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
  
  finish_item(req);
endtask : body
