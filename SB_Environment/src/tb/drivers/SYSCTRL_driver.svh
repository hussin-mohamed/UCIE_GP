/***********************************************************************
 * Author : Amr El Batarny
 * File   : SYSCTRL_driver.svh
 * Brief  : System control driver for managing reset and system-level
 *          control signals.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: SYSCTRL_driver
//
// The SYSCTRL_driver class manages system control signals including reset
// generation and system-level configuration. Currently implements basic
// reset functionality with infrastructure for future control expansion.
//
//------------------------------------------------------------------------------

class SYSCTRL_driver extends uvm_driver #(SYSCTRL_sequence_item);
    `uvm_component_utils(SYSCTRL_driver)

    virtual SYSCTRL_bfm bfm;
    SYSCTRL_sequence_item   item;
    uvm_analysis_port #(SYSCTRL_sequence_item) ap;


    // Function: new
    //
    // Creates a new SYSCTRL_driver instance with the given name and parent.

    extern function new(string name = "SYSCTRL_driver", uvm_component parent = null);


    // Function: build_phase
    //
    // Creates the analysis port for broadcasting system control transactions.

    extern virtual function void build_phase(uvm_phase phase);


    // Task: run_phase
    //
    // Executes system reset sequence via the BFM interface.

    extern virtual task run_phase(uvm_phase phase);

endclass : SYSCTRL_driver


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- SYSCTRL_driver
//
//------------------------------------------------------------------------------


// new
// ---

function SYSCTRL_driver::new(string name = "SYSCTRL_driver", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void SYSCTRL_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
endfunction : build_phase

// run_phase
// ---------

task SYSCTRL_driver::run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    `uvm_info(get_type_name(), "Entered SYSCTRL_driver", UVM_LOW)

    bfm.reset();
endtask