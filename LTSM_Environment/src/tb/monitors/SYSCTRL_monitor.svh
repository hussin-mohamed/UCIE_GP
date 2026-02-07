/***********************************************************************
 * Author : Amr El Batarny
 * File   : SYSCTRL_monitor.svh
 * Brief  : System control monitor for capturing system-level control
 *          signals and transactions (currently minimal implementation).
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: SYSCTRL_monitor
//
// The SYSCTRL_monitor class provides monitoring capabilities for system control
// signals. This is a minimal implementation with infrastructure for future
// expansion of system-level control transaction monitoring.
//
//------------------------------------------------------------------------------

class SYSCTRL_monitor extends uvm_monitor;
    `uvm_component_utils(SYSCTRL_monitor)
    
    virtual SYSCTRL_bfm bfm;
    APB_sequence_item_1 item;
    uvm_analysis_port #(SYSCTRL_sequence_item) ap;


    // Function: new
    //
    // Creates a new SYSCTRL_monitor instance with the given name and parent.

    extern function new(string name = "SYSCTRL_monitor", uvm_component parent = null);


    // Function: build_phase
    //
    // Creates the analysis port for broadcasting system control transactions.

    extern virtual function void build_phase(uvm_phase phase);

endclass : SYSCTRL_monitor


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- SYSCTRL_monitor
//
//------------------------------------------------------------------------------


// new
// ---

function SYSCTRL_monitor::new(string name = "SYSCTRL_monitor", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void SYSCTRL_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
endfunction : build_phase
