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
// CLASS: active_phylink_rand_seq
//
// Random ACTIVE-mode phylink sequence that generates a long constrained-random
// stream of link-level transactions.
//
//-----------------------------------------------------------------------------

class active_phylink_rand_seq extends sb_sequence_base #(phylink_seq_item);
  `uvm_object_utils(active_phylink_rand_seq)


  // Function: new
  //
  // Creates a new active_phylink_rand_seq instance with the given name.

  extern function new(string name = "active_phylink_rand_seq");


  // Task: body
  //
  // Randomizes and sends multiple ACTIVE phylink items.

  extern task body();

endclass : active_phylink_rand_seq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: active_phylink_rand_seq
//
// Implements randomized ACTIVE phylink stress stimulus.
//
//-----------------------------------------------------------------------------


// new
// ---

function active_phylink_rand_seq::new(string name = "active_phylink_rand_seq");
  super.new(name);
endfunction : new

// body
// ----
//
// Generates 1000 randomized ACTIVE phylink items for stress testing.

task active_phylink_rand_seq::body();
  repeat(4000) begin
    start_item(req);
    req.configure_randomization(ACTIVE);
    assert(req.randomize());
    finish_item(req);
  end
endtask : body
