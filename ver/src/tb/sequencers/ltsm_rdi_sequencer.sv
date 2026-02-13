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

//------------------------------------------------------------------------------
//
// CLASS: APB_sequencer
//
// The APB_sequencer class provides a parameterized sequencer implementation
// for APB transactions, enabling flexible sequencer instantiation with
// different transaction item types.
//
//
//
//------------------------------------------------------------------------------

class ltsm_rdi_sequencer#(type rdi_sequence_item) extends uvm_sequencer #(rdi_sequence_item);
  `uvm_component_utils(ltsm_rdi_sequencer#(rdi_sequence_item))


  // Function: new
  //
  // Creates a new ltsm_rdi_sequencer instance with the given name and parent.

  extern function new(string name="ltsm_rdi_sequencer", uvm_component parent=null);

endclass : ltsm_rdi_sequencer


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- ltsm_rdi_sequencer
//
//------------------------------------------------------------------------------


// new
// ---

function ltsm_rdi_sequencer::new(string name="ltsm_rdi_sequencer", uvm_component parent=null);
  super.new(name, parent);
endfunction