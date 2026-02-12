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
// CLASS: rx_fsm_sb_monitor
//
// The rx_fsm_sb_monitor class extends LTSM_monitor_base to provide monitoring
// capabilities for the RX FSM sideband signals. It captures relevant signals and transactions
// then broadcasts them through an analysis port for further processing.
// Type Parameters:
//   ITEM_T - Transaction item type (typically APB_sequence_item)
//   INTF_T - Virtual interface type for the APB bus
//
//------------------------------------------------------------------------------

class rx_fsm_sb_monitor #(type ITEM_T, type INTF_T) extends LTSM_monitor_base #(ITEM_T, INTF_T);
    `uvm_component_param_utils(rx_fsm_sb_monitor #(ITEM_T, INTF_T))


    // Function: new
    //
    // Creates a new rx_fsm_sb_monitor instance with the given name and parent.

    extern function new(string name = "rx_fsm_sb_monitor", uvm_component parent = null);


    

    extern virtual task collect_transaction();

endclass : rx_fsm_sb_monitor


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- rx_fsm_sb_monitor
//
//------------------------------------------------------------------------------


// new
// ---

function rx_fsm_sb_monitor::new(string name = "rx_fsm_sb_monitor", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// collect_transaction
// -------------------

task rx_fsm_sb_monitor::collect_transaction();
    item = ITEM_T::type_id::create("item");

    
endtask : collect_transaction