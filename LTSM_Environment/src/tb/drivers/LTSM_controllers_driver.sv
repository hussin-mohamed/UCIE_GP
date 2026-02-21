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
// CLASS: LTSM_controllers_driver
//
// The LTSM_controllers_driver class extends APB_driver_base to implement APB transaction
// driving with path selection capability. It controls the sel_1 signal to
// route transactions and executes read/write operations on the APB bus.
//
// Type Parameters:
// LTSM_controllers_if - Virtual interface type for the APB bus
//
//------------------------------------------------------------------------------




class LTSM_controllers_driver #(type LTSM_controllers_if) extends LTSM_driver_base #(LTSM_controllers_seq_item, LTSM_controllers_if);
    `uvm_component_param_utils(LTSM_controllers_driver#(LTSM_controllers_if))
    virtual LTSM_controllers_if vif;
    LTSM_controllers_seq_item item;


    // Function: new
    //
    // Creates a new LTSM_controllers_driver instance with the given name and parent.

    extern function new(string name = "LTSM_controllers_driver", uvm_component parent = null);


    // Task: drive
    //
    // Drives LTSM_controllers transactions on the bus by setting path selection signals and
    // executing read or write operations based on the transaction type.

    extern virtual task drive(LTSM_controllers_seq_item item);

endclass : LTSM_controllers_driver


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- LTSM_controllers_driver
//
//------------------------------------------------------------------------------


// new
// ---

function LTSM_controllers_driver::new(string name = "LTSM_controllers_driver", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// drive
// -----

task LTSM_controllers_driver::drive(LTSM_controllers_seq_item item);
    item=ltsm_controllers_seq_item::type_id::create("item");
    seq_item_port.get_next_item(item);
    vif.i_power       = item.i_power;
    vif.i_pll_stable  = item.i_pll_stable;
    vif.i_rx_error    = item.i_rx_error;
    vif.i_rx_done     = item.i_rx_done;
    vif.i_tx_done     = item.i_tx_done;
    vif.i_val_error   = item.i_val_error;
    vif.i_lane_error  = item.i_lane_error;
    vif.i_sb_ready     = item.i_sb_ready;
    @(negedge vif.clk);
    ap.write(item);
    seq_item_port.item_done();
endtask  



