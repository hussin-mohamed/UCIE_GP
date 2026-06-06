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
// CLASS: active_phylink_conc_seq
//
// Concurrent ACTIVE-mode phylink sequence that generates a shorter burst of
// randomized link-level traffic for the concurrent scenario.
//
//-----------------------------------------------------------------------------

class active_phylink_conc_seq extends sb_sequence_base #(phylink_seq_item);
  `uvm_object_utils(active_phylink_conc_seq)


  // Function: new
  //
  // Creates a new active_phylink_conc_seq instance with the given name.

  extern function new(string name = "active_phylink_conc_seq");


  // Task: body
  //
  // Randomizes and sends a bounded number of ACTIVE phylink items.

  extern task body();

endclass : active_phylink_conc_seq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: active_phylink_conc_seq
//
// Implements concurrent-scenario ACTIVE phylink stimulus.
//
//-----------------------------------------------------------------------------


// new
// ---

function active_phylink_conc_seq::new(string name = "active_phylink_conc_seq");
  super.new(name);
endfunction : new

// body
// ----
//
// Generates 10 randomized ACTIVE phylink items to pair with concurrent TX/RX
// agent activity.

task active_phylink_conc_seq::body();
  repeat(4000) begin
    start_item(req);
    req.configure_randomization(ACTIVE);
    assert(req.randomize());
    finish_item(req);
  end
endtask : body
