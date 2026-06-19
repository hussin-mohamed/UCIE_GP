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
// CLASS: active_rx_conc_seq
//
// Concurrent ACTIVE-mode RX sequence that sends randomized RX traffic while
// waiting for the reactive side of the agent to acknowledge each item.
//
//-----------------------------------------------------------------------------

class active_rx_conc_seq extends sb_sequence_base #(ltsm_seq_item);
  `uvm_object_utils(active_rx_conc_seq)

  rx_sequencer seqr;


  // Function: new
  //
  // Creates a new active_rx_conc_seq instance with the given name.

  extern function new(string name = "active_rx_conc_seq");


  // Task: body
  //
  // Sends randomized RX items and synchronizes with the reactive FIFO.

  extern task body();

  // Task: pre_body
  //
  // Captures the typed sequencer handle before the sequence starts.

  extern task pre_body();

endclass : active_rx_conc_seq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: active_rx_conc_seq
//
// Implements concurrent RX ACTIVE stimulus with reactive handshaking.
//
//-----------------------------------------------------------------------------


// new
// ---

function active_rx_conc_seq::new(string name = "active_rx_conc_seq");
  super.new(name);
endfunction : new


// pre_body
// --------
//
// Casts the base sequencer handle so the sequence can access the reactive FIFO.

task active_rx_conc_seq::pre_body();
  super.pre_body();
  $cast(seqr, get_sequencer());
endtask : pre_body


// body
// ----
//
// Issues a randomized RX item, then waits for the paired reactive response.

task active_rx_conc_seq::body();
  ltsm_seq_item dummy;
  while(seqr.reactive_fifo.try_get(dummy)); // Flush any stale responses
  repeat (900) begin
    start_item(req);
    req.set_dir(MSG_FROM_RX);
    assert(req.randomize());
    finish_item(req);
    seqr.reactive_fifo.get(rsp);
  end
endtask : body
