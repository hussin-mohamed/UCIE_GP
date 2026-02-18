/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_controller_monitor.svh
 * Brief  : Monitor for APB controller output, capturing concatenated
 *          data when concat_done signal is asserted.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: APB_controller_monitor
//
// The APB_controller_monitor class monitors the APB controller's concatenated
// output data. It detects the concat_done signal, captures the concatenated
// output, and triggers an event for downstream monitoring synchronization.
//
//------------------------------------------------------------------------------

class APB_controller_monitor extends uvm_monitor;
    `uvm_component_param_utils(APB_controller_monitor)
    
    virtual APB_controller_if bfm;
    APB_controller_sequence_item item;
    uvm_analysis_port #(APB_controller_sequence_item) ap;
    int unsigned transaction_count = 0;


    // Function: new
    //
    // Creates a new APB_controller_monitor instance with the given name and parent.

    extern function new(string name = "APB_controller_monitor", uvm_component parent = null);


    // Function: build_phase
    //
    // Creates the analysis port for broadcasting monitored concatenated output.

    extern virtual function void build_phase(uvm_phase phase);


    // Task: run_phase
    //
    // Waits for reset deassertion then monitors concat_done signal to capture
    // concatenated output data and trigger AES output monitoring event.

    extern virtual task run_phase(uvm_phase phase);


    // Function: report_phase
    //
    // Reports the total number of transactions monitored during simulation.

    extern virtual function void report_phase(uvm_phase phase);

endclass : APB_controller_monitor


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- APB_controller_monitor
//
//------------------------------------------------------------------------------


// new
// ---

function APB_controller_monitor::new(string name = "APB_controller_monitor", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void APB_controller_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
endfunction : build_phase

// run_phase
// ---------

task APB_controller_monitor::run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    // Wait until reset is deasserted
    @(posedge bfm.PRESETn);
    
    forever begin
        item = APB_controller_sequence_item::type_id::create("item");

        @(posedge bfm.concat_done);
        @(negedge bfm.PCLK);
        item.data = bfm.concat_out;
        ap.write(item);
        transaction_count++;
        -> start_monitoring_aes_out;
    end
endtask : run_phase

// report_phase
// ------------

function void APB_controller_monitor::report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("MONITORED %0d TRANSACTIONS", transaction_count), UVM_DEBUG)
endfunction : report_phase
