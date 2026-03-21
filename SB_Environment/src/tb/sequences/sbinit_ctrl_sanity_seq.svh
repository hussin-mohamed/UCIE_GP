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
// The sbinit_ctrl_sanity_seq class implements a two-phase sequence: first
// writing to all register file locations with full strobe, then switching
// to AES path and polling for the request signal to indicate readiness.
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
  // ...

  extern task body();

endclass : sbinit_ctrl_sanity_seq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS- sbinit_ctrl_sanity_seq
//
//-----------------------------------------------------------------------------


// new
// ---

function sbinit_ctrl_sanity_seq::new(string name = "sbinit_ctrl_sanity_seq");
  super.new(name);
endfunction : new

// body
// ----

task sbinit_ctrl_sanity_seq::body();
  start_item(req);
  req.sbinit_mode = START;
  finish_item(req);
endtask : body
