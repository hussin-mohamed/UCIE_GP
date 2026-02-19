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
// CLASS: virtual_sequencer
//
// The virtual_sequencer class provides a central sequencer that maintains
// handles to multiple child sequencers, enabling parent sequences to
// coordinate execution across multiple agents.
//
//------------------------------------------------------------------------------

class virtual_sequencer extends uvm_sequencer;
  `uvm_component_utils(virtual_sequencer)


  // Function: new
  //
  // Creates a new virtual_sequencer instance with the given name and parent.

  extern function new(string name="virtual_sequencer", uvm_component parent=null);

  APB_sequencer #(APB_sequence_item_1) apb_seqr_1;
  APB_sequencer #(APB_sequence_item_2) apb_seqr_2;

endclass : virtual_sequencer


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- virtual_sequencer
//
//------------------------------------------------------------------------------


// new
// ---

function virtual_sequencer::new(string name="virtual_sequencer", uvm_component parent=null);
  super.new(name, parent);
endfunction : new
