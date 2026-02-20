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

class ctrl_sb_sequencer  extends uvm_sequencer #(ctrl_sequence_item);
    `uvm_component_utils(ctrl_sb_sequencer)



  // Function: new
  //
  // Creates a new ctrl_sb_sequencer instance with the given name and parent.

  extern function new(string name="ctrl_sb_sequencer", uvm_component parent=null);

endclass : ctrl_sb_sequencer


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- ctrl_sb_sequencer
//
//------------------------------------------------------------------------------


// new
// ---

function ctrl_sb_sequencer::new(string name="ctrl_sb_sequencer", uvm_component parent=null);
  super.new(name, parent);
endfunction