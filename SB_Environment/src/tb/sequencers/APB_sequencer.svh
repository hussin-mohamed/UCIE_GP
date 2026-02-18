/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_sequencer.svh
 * Brief  : Parameterized APB sequencer for routing sequence items to
 *          APB drivers.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: APB_sequencer
//
// The APB_sequencer class provides a parameterized sequencer implementation
// for APB transactions, enabling flexible sequencer instantiation with
// different transaction item types.
//
// Type Parameters:
//   ITEM_T - Transaction item type handled by the sequencer
//
//------------------------------------------------------------------------------

class APB_sequencer #(type ITEM_T) extends uvm_sequencer #(ITEM_T);
  `uvm_component_param_utils(APB_sequencer #(ITEM_T))


  // Function: new
  //
  // Creates a new APB_sequencer instance with the given name and parent.

  extern function new(string name="APB_sequencer", uvm_component parent=null);

endclass : APB_sequencer


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- APB_sequencer
//
//------------------------------------------------------------------------------


// new
// ---

function APB_sequencer::new(string name="APB_sequencer", uvm_component parent=null);
  super.new(name, parent);
endfunction