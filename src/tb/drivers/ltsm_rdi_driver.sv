
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
// CLASS: APB_driver_1
//
// The APB_driver_1 class extends APB_driver_base to implement APB transaction
// driving with path selection capability. It controls the sel_1 signal to
// route transactions and executes read/write operations on the APB bus.
//
// Type Parameters:
//   INTF_T - Virtual interface type for the APB bus
//
//------------------------------------------------------------------------------

class ltsm_rdi_driver extends uvm_driver #(ltsm_rdi_sequence_item);
    `uvm_component_utils(ltsm_rdi_driver)

    uvm_analysis_port #(ltsm_rdi_sequence_item) ap;

    virtual ltsm_rdi_if bfm;
    // Function: new
    //
    // Creates a new ltsm_rdi_driver instance with the given name and parent.

    extern function new(string name = "ltsm_rdi_driver", uvm_component parent = null);


    // Task: drive
    //
    // Drives ltsm rdi transactions on the bus by setting path selection signals and
    // executing read or write operations based on the transaction type.

    extern virtual task drive(ltsm_rdi_sequence_item item);

endclass : ltsm_rdi_driver


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- ltsm_rdi_driver
//
//------------------------------------------------------------------------------


// new
// ---

function ltsm_rdi_driver::new(string name = "ltsm_rdi_driver", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
endfunction : new

// drive
// -----

task ltsm_rdi_driver::drive(ltsm_rdi_sequence_item item);
    `uvm_info(get_type_name(), "Driving...", UVM_DEBUG)
    
    // item_type_name = item.get_type_name();


    `uvm_info(get_type_name(), $sformatf("DRIVED %s: \n%s", item.get_type_name(), item.sprint()), UVM_DEBUG)
endtask
