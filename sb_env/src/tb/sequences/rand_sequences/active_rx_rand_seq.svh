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
// CLASS: active_rx_rand_seq
//
// Random ACTIVE-mode RX sequence that generates a stream of constrained-random
// RX LTSM items.
//
//-----------------------------------------------------------------------------

class active_rx_rand_seq extends sb_sequence_base #(ltsm_seq_item);
  `uvm_object_utils(active_rx_rand_seq)


  // Function: new
  //
  // Creates a new active_rx_rand_seq instance with the given name.

  extern function new(string name = "active_rx_rand_seq");


  // Task: body
  //
  // Randomizes and sends multiple RX-side ACTIVE items.

  extern task body();

endclass : active_rx_rand_seq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: active_rx_rand_seq
//
// Implements randomized RX ACTIVE stimulus generation.
//
//-----------------------------------------------------------------------------


// new
// ---

function active_rx_rand_seq::new(string name = "active_rx_rand_seq");
  super.new(name);
endfunction : new

// body
// ----
//
// Generates 500 randomized RX items using the shared ltsm_seq_item constraints.

task active_rx_rand_seq::body();
  repeat(1000) begin
    start_item(req);
    req.set_dir(MSG_FROM_RX);
    assert(req.randomize());
    finish_item(req);
  end
endtask : body
