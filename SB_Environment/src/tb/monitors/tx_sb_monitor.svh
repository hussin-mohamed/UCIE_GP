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

class tx_sb_monitor #(type ITEM_T, type INTF_T) extends sb_monitor_base #(ITEM_T, INTF_T);
    `uvm_component_param_utils(tx_sb_monitor #(ITEM_T, INTF_T))


    // Function: new
    //
    // Creates a new tx_sb_monitor instance with the given name and parent.

    extern function new(string name = "tx_sb_monitor", uvm_component parent = null);


    // Task: collect_transaction
    //
    // Monitors the APB bus for setup and access phases, captures transaction
    // details including address, data, strobe, and operation type (read/write),
    // then broadcasts the transaction through the analysis port.

    extern virtual task collect_transaction();

endclass : tx_sb_monitor


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- APB_monitor
//
//------------------------------------------------------------------------------


// new
// ---

function tx_sb_monitor::new(string name = "tx_sb_monitor", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// collect_transaction
// -------------------

task tx_sb_monitor::collect_transaction();
    
endtask : collect_transaction