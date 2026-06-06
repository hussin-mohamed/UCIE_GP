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
// CLASS: active_rx_sanity_seq
//
// Directed ACTIVE-mode RX sequence that sends a small representative set of
// messages toward the DUT RX-side LTSM path.
//
//-----------------------------------------------------------------------------

class active_rx_sanity_seq extends sb_sequence_base #(ltsm_seq_item);
  `uvm_object_utils(active_rx_sanity_seq)


  // Function: new
  //
  // Creates a new active_rx_sanity_seq instance with the given name.

  extern function new(string name = "active_rx_sanity_seq");


  // Task: body
  //
  // Drives a short directed set of RX messages used by the sanity scenario.

  extern task body();

endclass : active_rx_sanity_seq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: active_rx_sanity_seq
//
// Implements the directed RX ACTIVE sanity stimulus.
//
//-----------------------------------------------------------------------------


// new
// ---

function active_rx_sanity_seq::new(string name = "active_rx_sanity_seq");
  super.new(name);
endfunction : new

// body
// ----
//
// Sends a deterministic RX response item to validate the basic reverse path.

task active_rx_sanity_seq::body();
  start_item(req);
  req.data        = 0;
  req.info        = 0;
  req.msgtype     = RSP_MSG;
  req.wait_cycles = 30;
  req.set_rx_encoding(MBINIT_CAL_RX_Done_Handshake);
  finish_item(req);

  // Additional directed RX items can be enabled here when extending the sanity
  // scenario coverage.
endtask : body
