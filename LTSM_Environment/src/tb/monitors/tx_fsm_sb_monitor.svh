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
// CLASS: tx_fsm_sb_monitor
//
// The tx_fsm_sb_monitor class extends LTSM_monitor_base to provide monitoring
// capabilities for the tx FSM sideband signals. It captures relevant signals and transactions
// then broadcasts them through an analysis port for further processing.
// Type Parameters:
//   ITEM_T - Transaction item type (typically APB_sequence_item)
//   INTF_T - Virtual interface type for the APB bus
//
//------------------------------------------------------------------------------

class tx_fsm_sb_monitor #(type ITEM_T, type INTF_T) extends LTSM_monitor_base #(ITEM_T, INTF_T);
    `uvm_component_param_utils(tx_fsm_sb_monitor #(ITEM_T, INTF_T))


    // Function: new
    //
    // Creates a new tx_fsm_sb_monitor instance with the given name and parent.

    extern function new(string name = "tx_fsm_sb_monitor", uvm_component parent = null);


    

    extern virtual task collect_transaction();

endclass : tx_fsm_sb_monitor


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- tx_fsm_sb_monitor
//
//------------------------------------------------------------------------------


// new
// ---

function tx_fsm_sb_monitor::new(string name = "tx_fsm_sb_monitor", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// collect_transaction
// -------------------

task tx_fsm_sb_monitor::collect_transaction();
    item = ITEM_T::type_id::create("item");
    @(negedge vif.clk);
    forever begin
        @(negedge vif.clk);
        item.o_tx_encoding = vif.o_tx_encoding;
        item.o_tx_data = vif.o_tx_data;
        item.o_sb_tx_req = vif.o_sb_tx_req;
        item.o_sb_tx_rsp = vif.o_sb_tx_rsp;
        item.o_sb_tx_done = vif.o_sb_tx_done;
        item.o_tx_info = vif.o_tx_info;
        ap.write(item);
    end
endtask : collect_transaction