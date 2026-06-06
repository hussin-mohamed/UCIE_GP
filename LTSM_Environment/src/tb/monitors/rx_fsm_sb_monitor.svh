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
    fork
        // output thread
            begin
            item_out = ITEM_T::type_id::create("item_out");
              
            forever begin
                // @(negedge vif.clk);
                //`uvm_info("rx_fsm_sb_monitor", $sformatf("i_reset=%b", vif.i_reset), UVM_LOW);
                // if (vif.i_reset) begin
                //     @(negedge vif.clk);
                // end
                // else begin
                //     // @(negedge vif.clk);
                    @(negedge vif.clk);
                    item_out.o_rx_encoding = vif.o_rx_encoding;
                    item_out.o_rx_data = vif.o_rx_data;
                    item_out.o_rx_sb_req = vif.o_rx_sb_req;
                    item_out.o_rx_sb_rsp = vif.o_rx_sb_rsp;
                    item_out.o_rx_sb_done = vif.o_rx_sb_done;
                    item_out.o_rx_info = vif.o_rx_info;
                    ap_out.write(item_out);
                    transaction_count_out++;
                    //`uvm_info("rx_fsm_sb_monitor", $sformatf("Captured RX FSM SB transaction: o_rx_encoding=%0b, o_rx_data=%0h, o_rx_sb_req=%b, o_rx_sb_rsp=%b, o_rx_sb_done=%b, o_rx_info=%h",
                    //    item_out.o_rx_encoding, item_out.o_rx_data, item_out.o_rx_sb_req, item_out.o_rx_sb_rsp, item_out.o_rx_sb_done, item_out.o_rx_info), UVM_LOW);
                    // `uvm_info("rx_fsm_sb_monitor", $sformatf("i_reset=%b", vif.i_reset), UVM_LOW);
                end
                
                
            end   
            // end
        // input thread
        begin
            item_in = ITEM_T::type_id::create("item_in");
            forever begin
                @(posedge vif.clk);
                item_in.i_rx_decoding = vif.i_rx_decoding;
                item_in.i_rx_data     = vif.i_rx_data;
                item_in.i_sb_rx_req   = vif.i_sb_rx_req;
                item_in.i_sb_rx_rsp   = vif.i_sb_rx_rsp;
                item_in.i_sb_rx_done  = vif.i_sb_rx_done;
                item_in.i_rx_info     = vif.i_rx_info;
                item_in.i_reset       = vif.i_reset;
                ap_in.write(item_in);
                transaction_count_in++;
                //`uvm_info("rx_fsm_sb_monitor", $sformatf("Captured RX FSM SB input transaction: i_rx_decoding=%0b, i_rx_data=%0h, i_sb_rx_req=%b, i_sb_rx_rsp=%b, i_sb_rx_done=%b, i_rx_info=%h",
                    //item_in.i_rx_decoding, item_in.i_rx_data, item_in.i_sb_rx_req, item_in.i_sb_rx_rsp, item_in.i_sb_rx_done, item_in.i_rx_info), UVM_LOW);
            end
        end
    join_any
    
    
endtask : collect_transaction