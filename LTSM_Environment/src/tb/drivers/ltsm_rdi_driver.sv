
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

class ltsm_rdi_driver #(type INTF_T) extends LTSM_driver_base #(ltsm_rdi_sequence_item, INTF_T);
    `uvm_component_param_utils(ltsm_rdi_driver#(INTF_T))

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

endfunction : new

// drive
// -----

task ltsm_rdi_driver::drive(ltsm_rdi_sequence_item item);
    item=ltsm_rdi_sequence_item::type_id::create("item");
    seq_item_port.get_next_item(item);
    vif.i_lp_state_req <= item.i_lp_state_req;
    vif.i_lp_stallack <= item.i_lp_stallack;
    vif.i_lp_clk_ack <= item.i_lp_clk_ack;
    vif.i_lp_wake_req <= item.i_lp_wake_req;
    vif.i_lp_linkerror <= item.i_lp_linkerror;
    vif.i_reset <= item.i_reset;
    repeat(2)
        @(posedge vif.clk);
        
    seq_item_port.item_done();
    // item=ltsm_rdi_sequence_item::type_id::create("item");
    // seq_item_port.try_next_item(item);
    
    // if (item != null) begin
    //     vif.i_lp_state_req = item.i_lp_state_req;
    //     vif.i_lp_stallack = item.i_lp_stallack;
    //     vif.i_lp_clk_ack = item.i_lp_clk_ack;
    //     vif.i_lp_wake_req = item.i_lp_wake_req;
    //     vif.i_lp_linkerror = item.i_lp_linkerror;
    //     @(negedge vif.clk);
    //     ap.write(item);
    //     seq_item_port.item_done();
    // end
    // else begin
    //     item=ltsm_rdi_sequence_item::type_id::create("item");
    //     item.i_lp_state_req = 0;
    //     item.i_lp_stallack = 0;
    //     item.i_lp_clk_ack = 0;
    //     item.i_lp_wake_req = 0;
    //     item.i_lp_linkerror = 0;
    //     ap.write(item);
    // end
    
    // fork
    //     begin
    //         item=ltsm_rdi_sequence_item::type_id::create("item");
    //         seq_item_port.get_next_item(item);
    //         vif.i_lp_state_req = item.i_lp_state_req;
    //         vif.i_lp_stallack = item.i_lp_stallack;
    //         vif.i_lp_clk_ack = item.i_lp_clk_ack;
    //         vif.i_lp_wake_req = item.i_lp_wake_req;
    //         vif.i_lp_linkerror = item.i_lp_linkerror;
    //         @(negedge vif.clk);
    //         seq_item_port.item_done();
    //     end
    //     begin
    //         @(negedge vif.clk);
    //         ap.write(item);
    //     end
    // join_any
endtask
