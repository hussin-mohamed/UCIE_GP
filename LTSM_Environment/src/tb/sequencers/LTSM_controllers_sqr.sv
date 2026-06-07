
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
// CLASS: LTSM_controllers_sequencer
//
// The LTSM_controllers_sequencer class provides a parameterized sequencer implementation
// for LTSM controllers transactions, enabling flexible sequencer instantiation with
// different transaction item types.
//
// Type Parameters:
//   ITEM_T - Transaction item type handled by the sequencer
//
//------------------------------------------------------------------------------

class LTSM_controllers_sqr #(type LTSM_controllers_seq_item) extends uvm_sequencer #(LTSM_controllers_seq_item);
  `uvm_component_utils(LTSM_controllers_sqr #(LTSM_controllers_seq_item))


  // Function: new
  //
  // Creates a new LTSM_controllers_sqr instance with the given name and parent.

  extern function new(string name="LTSM_controllers_sqr", uvm_component parent=null);

endclass : LTSM_controllers_sqr

//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- LTSM_controllers_sqr
//
//------------------------------------------------------------------------------


// new
// ---

function LTSM_controllers_sqr::new(string name="LTSM_controllers_sqr", uvm_component parent=null);
  super.new(name, parent);
endfunction

