/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_monitor_base.svh
 * Brief  : Virtual base class for APB protocol monitors providing
 *          common monitoring infrastructure and transaction collection.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: APB_monitor_base
//
// The APB_monitor_base class provides a virtual base implementation for APB
// protocol monitors. It includes common infrastructure such as analysis port,
// transaction counting, and reset handling. Derived classes must implement
// the collect_transaction() method for protocol-specific monitoring behavior.
//
// Type Parameters:
//   ITEM_T - Transaction item type to be monitored
//   INTF_T - Virtual interface type for the APB bus
//
//------------------------------------------------------------------------------

virtual class APB_monitor_base #(type ITEM_T, type INTF_T) extends uvm_monitor;
    `uvm_component_param_utils(APB_monitor_base #(ITEM_T, INTF_T))
    
    INTF_T bfm;
    ITEM_T item;
    uvm_analysis_port #(ITEM_T) ap;
    int unsigned transaction_count = 0;


    // Function: new
    //
    // Creates a new APB_monitor_base instance with the given name and parent.

    extern function new(string name = "APB_monitor_base", uvm_component parent = null);


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

endclass : APB_monitor_base


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- APB_monitor_base
//
//------------------------------------------------------------------------------


// new
// ---

function APB_monitor_base::new(string name = "APB_monitor_base", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void APB_monitor_base::build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
endfunction

// run_phase
// ---------

task APB_monitor_base::run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    // Wait until reset is deasserted
    @(posedge bfm.PRESETn);
    
    forever begin
        collect_transaction();  // Call virtual method
    end
endtask

// report_phase
// ------------

function void APB_monitor_base::report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("MONITORED %0d TRANSACTIONS", transaction_count), UVM_LOW)
endfunction
