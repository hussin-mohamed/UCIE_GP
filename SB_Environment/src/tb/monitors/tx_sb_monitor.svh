/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_monitor.svh
 * Brief  : APB protocol monitor for capturing read and write transactions
 *          from the APB bus including address, data, and strobe signals.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: APB_monitor
//
// The APB_monitor class extends APB_monitor_base to implement complete APB
// protocol monitoring. It captures both read and write transactions by
// detecting setup and access phases, sampling appropriate signals, and
// broadcasting transactions through the analysis port.
//
// Type Parameters:
//   ITEM_T - Transaction item type (typically APB_sequence_item)
//   INTF_T - Virtual interface type for the APB bus
//
//------------------------------------------------------------------------------

class tx_sb_monitor extends uvm_monitor;
    `uvm_component_utils(tx_sb_monitor)
    tx_sequence_item item;

    virtual sb_ltsm_tx_bfm vif;
    uvm_analysis_port #(tx_sequence_item) ap;

   // Function: new
    //
    // Creates a new tx_sb_monitor instance with the given name and parent.

    extern function new(string name = "tx_sb_monitor", uvm_component parent = null);

    // Function: build_phase
    //
    // Builds the monitor component 

    extern function void build_phase(uvm_phase phase);
    // Task: run_phase
    //
    // Monitors tx transactions on the bus by sampling signals and
    // broadcasting captured transactions through the analysis port.

    extern task run_phase(tx_sequence_item item);

endclass : tx_sb_monitor


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- tx_sb_monitor
//
//------------------------------------------------------------------------------


// new
// ---

function tx_sb_monitor::new(string name = "tx_sb_monitor", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// build_phase
// -------------------

function tx_sb_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    
endfunction : build_phase

// run_phase
// ---------

task tx_sb_monitor::run_phase(tx_sequence_item item);
    super.run_phase(phase);
    forever begin
        @(negedge vif.clk);
        item = tx_sequence_item::type_id::create("item");
        item.data=vif.o_tx_data;
        item.encoding=vif.o_tx_encoding;
        item.info=vif.o_tx_info;
        ap.write(item); 
    end
endtask


