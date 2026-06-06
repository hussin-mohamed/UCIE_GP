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
// CLASS: active_phylink_sequence
//
//-----------------------------------------------------------------------------

class active_phylink_sequence extends sb_sequence_base #(phylink_seq_item);
  `uvm_object_utils(active_phylink_sequence)


  // Function: new
  //
  // Creates a new active_phylink_sequence instance with the given name.

  extern function new(string name = "active_phylink_sequence");


  // Task: pre_body
  //
  // Overrides the base sequence's pre_body to avoid overwriting the pre-assigned req.
  extern task pre_body();

  // Task: body
  //
  // Generates a bounded batch of ACTIVE phylink items for basic checking.
  extern task body();

endclass : active_phylink_sequence


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: active_phylink_sequence
//
// Implements the ACTIVE phylink sanity stimulus.
//
//-----------------------------------------------------------------------------


// new
// ---

function active_phylink_sequence::new(string name = "active_phylink_sequence");
  super.new(name);
endfunction : new

// pre_body
// --------

task active_phylink_sequence::pre_body();
  seq_print("Entered active_phylink_sequence pre_body (custom override)");
endtask : pre_body

// body
// ----

task active_phylink_sequence::body();
  if (req.idle_ui_cnt < 32) begin
    req.idle_ui_cnt = 100;
  end
  `uvm_info(get_type_name(), $sformatf("Driving phylink item: op_mode=%s, fullcode=%s, idle_ui_cnt=%0d", req.op_mode.name(), req.fullcode.name(), req.idle_ui_cnt), UVM_LOW)
  start_item(req);
  finish_item(req);
endtask : body
