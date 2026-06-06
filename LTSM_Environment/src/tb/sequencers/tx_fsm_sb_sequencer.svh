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
// CLASS: tx_fsm_sequencer
//
// The tx_fsm_sequencer class provides a parameterized sequencer implementation
// for tx_fsm transactions, enabling flexible sequencer instantiation with
// different transaction item types.
//
// Type Parameters:
//   ITEM_T - Transaction item type handled by the sequencer
//
//------------------------------------------------------------------------------

class tx_fsm_sb_sequencer #(type ITEM_T) extends uvm_sequencer #(ITEM_T);
  `uvm_component_param_utils(tx_fsm_sb_sequencer #(ITEM_T))


  // Function: new
  //
  // Creates a new tx_fsm_sb_sequencer instance with the given name and parent.

  extern function new(string name="tx_fsm_sb_sequencer", uvm_component parent=null);

endclass : tx_fsm_sb_sequencer


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- tx_fsm_sequencer
//
//------------------------------------------------------------------------------


// new
// ---

function tx_fsm_sb_sequencer::new(string name="tx_fsm_sb_sequencer", uvm_component parent=null);
  super.new(name, parent);
endfunction