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
// CLASS: tx_fsm_sb_driver
//
// The tx_fsm_sb_driver class extends LTSM_driver_base to implement APB transaction
// driving with path selection capability. It controls the sel_1 signal to
// route transactions and executes read/write operations on the APB bus.
//
// Type Parameters:
//   INTF_T - Virtual interface type for the APB bus
//
//------------------------------------------------------------------------------

class tx_fsm_sb_driver #(type INTF_T) extends LTSM_driver_base #(tx_fsm_sb_sequence_item, INTF_T);
    `uvm_component_param_utils(tx_fsm_sb_driver#(INTF_T))

    // Function: new
    //
    // Creates a new tx_fsm_sb_driver instance with the given name and parent.

    extern function new(string name = "tx_fsm_sb_driver", uvm_component parent = null);


    // Task: drive
    //
    // Drives APB transactions on the bus by setting path selection signals and
    // executing read or write operations based on the transaction type.

    extern virtual task drive(tx_fsm_sb_sequence_item item);

endclass : tx_fsm_sb_driver


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- tx_fsm_sb_driver
//
//------------------------------------------------------------------------------


// new
// ---

function tx_fsm_sb_driver::new(string name = "tx_fsm_sb_driver", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// drive
// -----

task tx_fsm_sb_driver::drive(tx_fsm_sb_sequence_item item);
    `uvm_info(get_type_name(), "Driving...", UVM_DEBUG)

    
    `uvm_info(get_type_name(), $sformatf("DRIVED %s: \n%s", item.get_type_name(), item.sprint()), UVM_DEBUG)
endtask