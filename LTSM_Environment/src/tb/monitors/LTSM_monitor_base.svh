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
// CLASS: LTSM_monitor_base
//
// The LTSM_monitor_base class provides a virtual base implementation for APB
// protocol monitors. It includes common infrastructure such as analysis port,
// transaction counting, and reset handling. Derived classes must implement
// the collect_transaction() method for protocol-specific monitoring behavior.
//
// Type Parameters:
//   ITEM_T - Transaction item type to be monitored
//   INTF_T - Virtual interface type for the APB bus
//
//------------------------------------------------------------------------------

virtual class LTSM_monitor_base #(type ITEM_T, type INTF_T) extends uvm_monitor;
    `uvm_component_param_utils(LTSM_monitor_base #(ITEM_T, INTF_T))
    
    INTF_T vif;
    ITEM_T item_in,item_out;
    uvm_analysis_port #(ITEM_T) ap_in,ap_out;
    int unsigned transaction_count_in = 0;
    int unsigned transaction_count_out = 0;


    // Function: new
    //
    // Creates a new LTSM_monitor_base instance with the given name and parent.

    extern function new(string name = "LTSM_monitor_base", uvm_component parent = null);


    // Function: build_phase
    //
    // Creates the analysis port for broadcasting monitored transactions.

    extern virtual function void build_phase(uvm_phase phase);


    // Task: run_phase
    //
    // Waits for reset deassertion then continuously collects transactions by
    // calling the virtual collect_transaction() method.

    extern virtual task run_phase(uvm_phase phase);


    // Task: collect_transaction
    //
    // Pure virtual method that must be implemented by derived classes to define
    // protocol-specific transaction collection behavior.

    pure virtual task collect_transaction();


    // Function: report_phase
    //
    // Reports the total number of transactions monitored during simulation.

    extern virtual function void report_phase(uvm_phase phase);

endclass : LTSM_monitor_base


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- LTSM_monitor_base
//
//------------------------------------------------------------------------------


// new
// ---

function LTSM_monitor_base::new(string name = "LTSM_monitor_base", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void LTSM_monitor_base::build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap_in = new("ap_in", this);
    ap_out = new("ap_out", this);
endfunction

// run_phase
// ---------

task LTSM_monitor_base::run_phase(uvm_phase phase);
    super.run_phase(phase);
        collect_transaction();  // Call virtual method
endtask

// report_phase
// ------------

function void LTSM_monitor_base::report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("MONITORED %0d input TRANSACTIONS", transaction_count_in), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("MONITORED %0d output TRANSACTIONS", transaction_count_out), UVM_LOW)
endfunction
