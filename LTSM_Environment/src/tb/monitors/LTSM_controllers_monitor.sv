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
// CLASS: LTSM_controllers_monitor
//
// The LTSM_controllers_monitor class extends LTSM_monitor_base to implement complete LTSM_controllers
// protocol monitoring. It captures both read and write transactions by
// detecting setup and access phases, sampling appropriate signals, and
// broadcasting transactions through the analysis port.
//
// Type Parameters:
//   LTSM_controllers_seq_item - Transaction item type 
//   LTSM_controllers_if - Virtual interface type for the LTSM_controllers bus
//
//------------------------------------------------------------------------------

class LTSM_controllers_monitor #(type ITEM_T, type INTF_T) extends LTSM_monitor_base #(ITEM_T, INTF_T);
    `uvm_component_param_utils(LTSM_controllers_monitor #(ITEM_T, INTF_T))
    

    // Function: new
    //
    // Creates a new LTSM_controllers_monitor instance with the given name and parent.

    extern function new(string name = "LTSM_controllers_monitor", uvm_component parent = null);


    // Task: collect_transaction
    //
    // Monitors the LTSM_controllers bus for setup and access phases, captures transaction
    // details including address, data, strobe, and operation type (read/write),
    // then broadcasts the transaction through the analysis port.

    extern virtual task collect_transaction();

endclass : LTSM_controllers_monitor


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- LTSM_controllers_monitor
//
//------------------------------------------------------------------------------


// new
// ---

function LTSM_controllers_monitor::new(string name = "LTSM_controllers_monitor", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// collect_transaction
// -------------------

task LTSM_controllers_monitor::collect_transaction();
    item = ITEM_T::type_id::create("item");
    @(negedge vif.clk);
    forever begin
        @(negedge vif.clk);
        item.o_tx_encoding  = vif.o_tx_encoding;
        item.o_rx_encoding     = vif.o_rx_encoding;
        item.o_sbinit_start = vif.o_sbinit_start;
        item.o_t1_ms        = vif.o_t1_ms;
        ap.write(item);
    end
endtask : collect_transaction