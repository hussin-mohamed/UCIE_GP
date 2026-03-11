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
// CLASS: rx_sequencer
//
// ...
//
//-----------------------------------------------------------------------------

class rx_sequencer extends uvm_sequencer #(ltsm_seq_item);
  `uvm_component_utils(rx_sequencer)


  // Function: new
  //
  // Creates a new rx_sequencer instance with the given name and parent.

  extern function new(string name, uvm_component parent);

endclass : rx_sequencer


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS- rx_sequencer
//
//-----------------------------------------------------------------------------


// new
// ---

function rx_sequencer::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new
