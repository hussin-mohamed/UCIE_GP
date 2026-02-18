/***********************************************************************
 * Author : Amr El Batarny
 * File   : dummy_driver.svh
 * Brief  : Placeholder driver for testing and infrastructure validation
 *          without actual driving functionality.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: dummy_driver
//
// The dummy_driver class provides a minimal driver implementation for testing
// purposes. It includes the standard driver infrastructure (analysis port,
// BFM handle) but implements no driving functionality.
//
// Type Parameters:
//   ITEM_T - Transaction item type
//   INTF_T - Virtual interface type
//
//------------------------------------------------------------------------------

class dummy_driver #(type ITEM_T, type INTF_T) extends uvm_driver #(ITEM_T);
    `uvm_component_param_utils(dummy_driver#(ITEM_T, INTF_T))

    INTF_T  bfm;
    ITEM_T  req, rsp;
    uvm_analysis_port #(ITEM_T) ap;
    string item_type_name;


    // Function: new
    //
    // Creates a new dummy_driver instance with the given name and parent.

    extern function new(string name = "dummy_driver", uvm_component parent = null);


    // Function: build_phase
    //
    // Creates the analysis port infrastructure.

    extern virtual function void build_phase(uvm_phase phase);

endclass : dummy_driver


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- dummy_driver
//
//------------------------------------------------------------------------------


// new
// ---

function dummy_driver::new(string name = "dummy_driver", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void dummy_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
endfunction : build_phase