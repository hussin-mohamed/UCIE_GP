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
    fork
        // output thread
        begin
            item_out = ITEM_T::type_id::create("item_out");
               forever begin
                // @(negedge vif.clk);
                // if (vif.i_reset) begin
                //     //@(negedge vif.clk);
                // end
                // else begin
                    @(negedge vif.clk);
                    item_out.o_tx_encoding = vif.o_tx_encoding;
                    item_out.o_tx_data = vif.o_tx_data;
                    item_out.o_tx_sb_req = vif.o_tx_sb_req;
                    item_out.o_tx_sb_rsp = vif.o_tx_sb_rsp;
                    item_out.o_tx_sb_done = vif.o_tx_sb_done;
                    item_out.o_tx_info = vif.o_tx_info;
                    ap_out.write(item_out);
                // end
                
                
            end    
            
            end
        // input thread
        begin
            item_in = ITEM_T::type_id::create("item_in");
            forever begin
               @(posedge vif.clk);
                item_in.i_tx_decoding = vif.i_tx_decoding;
                item_in.i_tx_data     = vif.i_tx_data;
                item_in.i_sb_tx_req   = vif.i_sb_tx_req;
                item_in.i_sb_tx_rsp   = vif.i_sb_tx_rsp;
                item_in.i_sb_tx_done  = vif.i_sb_tx_done;
                item_in.i_tx_info     = vif.i_tx_info;
                item_in.i_reset       = vif.i_reset;
                ap_in.write(item_in);
            end
        end
    join_any
    
    
endtask : collect_transaction