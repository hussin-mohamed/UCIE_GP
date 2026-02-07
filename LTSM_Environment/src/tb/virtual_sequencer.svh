/***********************************************************************
 * Author : Amr El Batarny
 * File   : virtual_sequencer.svh
 * Brief  : Parent sequencer maintaining handles to child sequencers for
 *          coordinated multi-agent sequence execution.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

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
