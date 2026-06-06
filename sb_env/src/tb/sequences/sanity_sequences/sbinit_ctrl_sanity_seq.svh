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
// CLASS: sbinit_ctrl_sanity_seq
//
// Directed SBINIT control sequence that starts the Sideband initialization
// flow through the control agent.
//
//-----------------------------------------------------------------------------

class sbinit_ctrl_sanity_seq extends sb_sequence_base #(ltsm_ctrl_seq_item);
  `uvm_object_utils(sbinit_ctrl_sanity_seq)

  bit       timeout;
  bit [2:0] ms_cnt;


  // Function: new
  //
  // Creates a new sbinit_ctrl_sanity_seq instance with the given name.

  extern function new(string name = "sbinit_ctrl_sanity_seq");


  // Task: body
  //
  // Sends the START command that kicks off the SBINIT control flow.

  extern task body();

endclass : sbinit_ctrl_sanity_seq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: sbinit_ctrl_sanity_seq
//
// Implements the directed SBINIT control start sequence.
//
//-----------------------------------------------------------------------------


// new
// ---

function sbinit_ctrl_sanity_seq::new(string name = "sbinit_ctrl_sanity_seq");
  super.new(name);
endfunction : new

// body
// ----
//
// Drives a single control transaction that requests SBINIT start.

task sbinit_ctrl_sanity_seq::body();
  start_item(req);
  req.sbinit_mode = START;
  finish_item(req);
endtask : body
