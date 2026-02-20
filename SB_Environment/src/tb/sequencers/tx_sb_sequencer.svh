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

class tx_sb_sequencer  extends uvm_sequencer #(tx_sequence_item);
    `uvm_component_utils(tx_sb_sequencer)



  // Function: new
  //
  // Creates a new tx_sb_sequencer instance with the given name and parent.

  extern function new(string name="tx_sb_sequencer", uvm_component parent=null);

endclass : tx_sb_sequencer


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- tx_sb_sequencer
//
//------------------------------------------------------------------------------


// new
// ---

function tx_sb_sequencer::new(string name="tx_sb_sequencer", uvm_component parent=null);
  super.new(name, parent);
endfunction