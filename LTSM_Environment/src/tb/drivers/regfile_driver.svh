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
// CLASS: regfile_driver
//
// The regfile_driver class extends LTSM_driver_base to implement regfile transaction
// driving with path selection capability. It controls the sel_1 signal to
// route transactions and executes read/write operations on the regfile bus.
//

//
//------------------------------------------------------------------------------

class regfile_driver #(type INTF_T) extends LTSM_driver_base #(regfile_sequence_item, INTF_T);
    `uvm_component_param_utils(regfile_driver#(INTF_T))

    // Function: new
    //
    // Creates a new regfile_driver instance with the given name and parent.

    extern function new(string name = "regfile_driver", uvm_component parent = null);


    // Task: drive
    //
    // Drives APB transactions on the bus by setting path selection signals and
    // executing read or write operations based on the transaction type.

    extern virtual task drive(regfile_sequence_item item);

endclass : regfile_driver


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- regfile_driver
//
//------------------------------------------------------------------------------


// new
// ---

function regfile_driver::new(string name = "regfile_driver", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// drive
// -----

task regfile_driver::drive(regfile_sequence_item item);
    item=regfile_sequence_item::type_id::create("item");
    seq_item_port.get_next_item(item);
    vif.i_tx_decoding = item.i_speedreg;
    vif.i_local_cap    = item.i_local_cap;
    vif.i_Runtime_Link_Test_status_register   = item.i_Runtime_Link_Test_status_register;
    vif.i_Runtime_Link_Test_Control_register  = item.i_Runtime_Link_Test_Control_register;
    @(negedge vif.clk);
    ap.write(item);
    seq_item_port.item_done();
endtask