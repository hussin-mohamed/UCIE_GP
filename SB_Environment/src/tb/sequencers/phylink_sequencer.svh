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
// CLASS: phylink_sequencer
//
// ...
//
//-----------------------------------------------------------------------------

class phylink_sequencer extends uvm_sequencer #(phylink_seq_item);
  `uvm_component_utils(phylink_sequencer)


  // Function: new
  //
  // Creates a new phylink_sequencer instance with the given name and parent.

  extern function new(string name, uvm_component parent);

endclass : phylink_sequencer


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS- phylink_sequencer
//
//-----------------------------------------------------------------------------


// new
// ---

function phylink_sequencer::new(string name, uvm_component parent);
  super.new(name, parent);
  set_report_severity_id_verbosity(UVM_INFO, "PHASESEQ", UVM_NONE);
endfunction : new
