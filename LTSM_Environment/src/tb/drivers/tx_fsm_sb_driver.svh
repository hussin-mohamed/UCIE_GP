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
    item=tx_fsm_sb_sequence_item::type_id::create("item");
    seq_item_port.get_next_item(item);
    vif.i_tx_decoding <= item.i_tx_decoding;
    vif.i_tx_data     <= item.i_tx_data;
    vif.i_sb_tx_req   <= item.i_sb_tx_req;
    vif.i_sb_tx_rsp   <= item.i_sb_tx_rsp;
    vif.i_sb_tx_done  <= item.i_sb_tx_done;
    vif.i_tx_info     <= item.i_tx_info;

   repeat(2)
        @(posedge vif.clk);
        
     vif.i_sb_tx_req   = 0;
     vif.i_sb_tx_rsp   = 0;
     vif.i_sb_tx_done  = 0;
    seq_item_port.item_done();
    // item=tx_fsm_sb_sequence_item::type_id::create("item");
    // seq_item_port.try_next_item(item);
    
    // if (item != null) begin
    //     vif.i_tx_decoding = item.i_tx_decoding;
    //     vif.i_tx_data     = item.i_tx_data;
    //     vif.i_sb_tx_req   = item.i_sb_tx_req;
    //     vif.i_sb_tx_rsp   = item.i_sb_tx_rsp;
    //     vif.i_sb_tx_done  = item.i_sb_tx_done;
    //     vif.i_tx_info     = item.i_tx_info;

    //     repeat(2)
    //         @(negedge vif.clk);
        
    //     ap.write(item);
    //     vif.i_sb_tx_req   = 0;
    //     vif.i_sb_tx_rsp   = 0;
    //     vif.i_sb_tx_done  = 0;
    //     seq_item_port.item_done();
    // end
    // else begin
    //     item=tx_fsm_sb_sequence_item::type_id::create("item");
    //     item.i_tx_decoding = 0;
    //     item.i_tx_data     = 0;
    //     item.i_sb_tx_req   = 0;
    //     item.i_sb_tx_rsp   = 0;
    //     item.i_sb_tx_done  = 0;
    //     item.i_tx_info     = 0;

    //     repeat(2)
    //         @(negedge vif.clk);
            
    //     ap.write(item);

    // end
    
    // fork
    //     begin
    //         item=tx_fsm_sb_sequence_item::type_id::create("item");
    //         seq_item_port.get_next_item(item);
    //         vif.i_tx_decoding = item.i_tx_decoding;
    //         vif.i_tx_data     = item.i_tx_data;
    //         vif.i_sb_tx_req   = item.i_sb_tx_req;
    //         vif.i_sb_tx_rsp   = item.i_sb_tx_rsp;
    //         vif.i_sb_tx_done  = item.i_sb_tx_done;
    //         vif.i_tx_info     = item.i_tx_info;
    //         repeat(2)
    //             @(negedge vif.clk);
    //         seq_item_port.item_done();
    //     end
    //     begin
    //         repeat(2)
    //             @(negedge vif.clk);
    //         ap.write(item);
    //     end
    // join_any
endtask