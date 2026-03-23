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
// CLASS: regfile_sequencer
//
// The regfile_sequencer class provides a parameterized sequencer implementation
// for regfile transactions, enabling flexible sequencer instantiation with
// different transaction item types.
//
// Type Parameters:
//   ITEM_T - Transaction item type handled by the sequencer
//
//------------------------------------------------------------------------------

class regfile_sequencer #(type ITEM_T) extends uvm_sequencer #(ITEM_T);
  `uvm_component_param_utils(regfile_sequencer #(ITEM_T))


  // Function: new
  //
  // Creates a new regfile_sequencer instance with the given name and parent.

  extern function new(string name="regfile_sequencer", uvm_component parent=null);

endclass : regfile_sequencer


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- regfile_sequencer
//
//------------------------------------------------------------------------------


// new
// ---

function regfile_sequencer::new(string name="regfile_sequencer", uvm_component parent=null);
  super.new(name, parent);
endfunction