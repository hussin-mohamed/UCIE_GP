/***********************************************************************
 * Author : Amr El Batarny
 * File   : SYSCTRL_sequencer.svh
 * Brief  : System control sequencer for routing system control sequence
 *          items to the SYSCTRL driver.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: SYSCTRL_sequencer
//
// The SYSCTRL_sequencer class provides sequencer functionality for system
// control transactions, managing sequence item flow to the SYSCTRL driver.
//
//------------------------------------------------------------------------------

class SYSCTRL_sequencer extends uvm_sequencer#(SYSCTRL_sequence_item);
  `uvm_component_utils(SYSCTRL_sequencer)


  // Function: new
  //
  // Creates a new SYSCTRL_sequencer instance with the given name and parent.

  extern function new(string name="SYSCTRL_sequencer", uvm_component parent=null);

endclass : SYSCTRL_sequencer


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- SYSCTRL_sequencer
//
//------------------------------------------------------------------------------


// new
// ---

function SYSCTRL_sequencer::new(string name="SYSCTRL_sequencer", uvm_component parent=null);
  super.new(name, parent);
endfunction