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
// CLASS: rdi_sequencer
//
// ...
//
//-----------------------------------------------------------------------------

class rdi_sequencer extends uvm_sequencer #(rdi_seq_item);
  `uvm_component_utils(rdi_sequencer)


  // Function: new
  //
  // Creates a new rdi_sequencer instance with the given name and parent.

  extern function new(string name, uvm_component parent);

endclass : rdi_sequencer


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS- rdi_sequencer
//
//-----------------------------------------------------------------------------


// new
// ---

function rdi_sequencer::new(string name, uvm_component parent);
  super.new(name, parent);
  set_report_severity_id_verbosity(UVM_INFO, "PHASESEQ", UVM_NONE);
endfunction : new
