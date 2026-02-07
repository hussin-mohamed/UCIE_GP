/***********************************************************************
 * Author : Amr El Batarny
 * File   : AES_monitor.svh
 * Brief  : Monitor for AES module output, capturing encrypted data
 *          after fixed latency period following trigger event.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: AES_monitor
//
// The AES_monitor class monitors the AES encryption module output.
// It waits for a monitoring trigger event, accounts for AES processing
// latency, then captures and broadcasts the encrypted output data.
//
//------------------------------------------------------------------------------

class AES_monitor extends uvm_monitor;
    `uvm_component_param_utils(AES_monitor)
    
    virtual AES_if bfm;
    AES_sequence_item item;
    uvm_analysis_port #(AES_sequence_item) ap;
    int unsigned transaction_count = 0;


    // Function: new
    //
    // Creates a new AES_monitor instance with the given name and parent.

    extern function new(string name = "AES_monitor", uvm_component parent = null);


    // Function: build_phase
    //
    // Creates the analysis port for broadcasting monitored AES output data.

    extern virtual function void build_phase(uvm_phase phase);


    // Task: run_phase
    //
    // Waits for start_monitoring_aes_out event trigger, delays for AES latency,
    // then captures and broadcasts the AES encrypted output.

    extern virtual task run_phase(uvm_phase phase);


    // Function: report_phase
    //
    // Reports the total number of transactions monitored during simulation.

    extern virtual function void report_phase(uvm_phase phase);

endclass : AES_monitor


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- AES_monitor
//
//------------------------------------------------------------------------------


// new
// ---

function AES_monitor::new(string name = "AES_monitor", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void AES_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
endfunction : build_phase

// run_phase
// ---------

task AES_monitor::run_phase(uvm_phase phase);
    super.run_phase(phase);

    // Wait until reset is deasserted
    @(posedge bfm.PRESETn);
    
    forever begin
        item = AES_sequence_item::type_id::create("item");

        @(posedge bfm.AES_done);
        @(negedge bfm.PCLK);
        item.data_in  = bfm.AES_in;
        item.data_out = bfm.AES_out;
        ap.write(item);
        transaction_count++;
    end
endtask : run_phase

// report_phase
// ------------

function void AES_monitor::report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("MONITORED %0d TRANSACTIONS", transaction_count), UVM_LOW)
endfunction : report_phase
