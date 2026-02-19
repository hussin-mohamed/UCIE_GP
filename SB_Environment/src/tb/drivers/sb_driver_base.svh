/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_driver_base.svh
 * Brief  : Virtual base class for APB protocol drivers providing
 *          common driving infrastructure and transaction handling.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: APB_driver_base
//
// The APB_driver_base class provides a virtual base implementation for APB
// protocol drivers. It handles sequence item fetching, response handling,
// and transaction broadcasting through an analysis port. Derived classes
// must implement the drive() method for protocol-specific driving behavior.
//
// Type Parameters:
//   ITEM_T - Transaction item type to be driven
//   INTF_T - Virtual interface type for the APB bus
//
//------------------------------------------------------------------------------

virtual class sb_driver_base #(type ITEM_T, type INTF_T) extends uvm_driver #(ITEM_T);
    `uvm_component_param_utils(sb_driver_base#(ITEM_T, INTF_T))

    INTF_T  bfm;
    ITEM_T  req;
    uvm_analysis_port #(ITEM_T) ap;
    string item_type_name;


    // Function: new
    //
    // Creates a new APB_driver_base instance with the given name and parent.

    extern function new(string name = "APB_driver_base", uvm_component parent = null);


    // Function: build_phase
    //
    // Creates the analysis port for broadcasting driven transactions.

    extern virtual function void build_phase(uvm_phase phase);


    // Task: run_phase
    //
    // Main driver loop that fetches sequence items, drives them via the virtual
    // drive() method, broadcasts transactions, and sends responses back to sequencer.

    extern virtual task run_phase(uvm_phase phase);


    // Task: drive
    //
    // Pure virtual method that must be implemented by derived classes to define
    // protocol-specific transaction driving behavior on the APB bus.

    pure virtual task drive(ITEM_T item);

endclass : sb_driver_base


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- sb_driver_base
//
//------------------------------------------------------------------------------


// new
// ---

function sb_driver_base::new(string name = "sb_driver_base", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void sb_driver_base::build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
endfunction : build_phase

// run_phase
// ---------

task sb_driver_base::run_phase(uvm_phase phase);
    super.run_phase(phase);

   
endtask