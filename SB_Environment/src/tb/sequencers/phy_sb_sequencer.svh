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

class phy_sb_sequencer  extends uvm_sequencer #(phy_sequence_item);
    `uvm_component_utils(phy_sb_sequencer)



  // Function: new
  //
  // Creates a new phy_sb_sequencer instance with the given name and parent.

  extern function new(string name="phy_sb_sequencer", uvm_component parent=null);

endclass : phy_sb_sequencer


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- phy_sb_sequencer
//
//------------------------------------------------------------------------------


// new
// ---

function phy_sb_sequencer::new(string name="phy_sb_sequencer", uvm_component parent=null);
  super.new(name, parent);
endfunction