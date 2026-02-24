// ****************************************************************************
// *                                                                          *
// * Copyright (c) 2014-2015 Synopsys Inc. All rights reserved.               *
// *                                                                          *
// * Synopsys Proprietary and Confidential. This file contains confidential   *
// * information and the trade secrets of Synopsys Inc. Use, disclosure, or   *
// * reproduction is prohibited without the prior express written permission  *
// * of Synopsys, Inc.                                                        *
// *                                                                          *
// * Synopsys, Inc.                                                           *
// * 700 East Middlefield Road                                                *
// * Mountain View, California 94043                                          *
// * (800) 541-7737                                                           *
// *                                                                          *
// ****************************************************************************

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

virtual class LTSM_driver_base #(type ITEM_T, type INTF_T) extends uvm_driver #(ITEM_T);
    `uvm_component_param_utils(LTSM_driver_base#(ITEM_T, INTF_T))

    INTF_T  vif;
    ITEM_T  item;
    uvm_analysis_port #(ITEM_T) ap;
    string item_type_name;


    // Function: new
    //
    // Creates a new LTSM_driver_base instance with the given name and parent.

    extern function new(string name = "LTSM_driver_base", uvm_component parent = null);


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

endclass : LTSM_driver_base


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- LTSM_driver_base
//
//------------------------------------------------------------------------------


// new
// ---

function LTSM_driver_base::new(string name = "LTSM_driver_base", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void LTSM_driver_base::build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
endfunction : build_phase

// run_phase
// ---------

task LTSM_driver_base::run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
        drive(item);
    end
    
endtask