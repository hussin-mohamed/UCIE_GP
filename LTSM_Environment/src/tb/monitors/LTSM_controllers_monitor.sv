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
// CLASS: LTSM_controllers_monitor
//
// The LTSM_controllers_monitor class extends LTSM_monitor_base to implement complete LTSM_controllers
// protocol monitoring. It captures both read and write transactions by
// detecting setup and access phases, sampling appropriate signals, and
// broadcasting transactions through the analysis port.
//
// Type Parameters:
//   LTSM_controllers_seq_item - Transaction item type 
//   LTSM_controllers_if - Virtual interface type for the LTSM_controllers bus
//
//------------------------------------------------------------------------------

class LTSM_controllers_monitor #(type ITEM_T, type INTF_T) extends LTSM_monitor_base #(ITEM_T, INTF_T);
    `uvm_component_param_utils(LTSM_controllers_monitor #(ITEM_T, INTF_T))
    

    // Function: new
    //
    // Creates a new LTSM_controllers_monitor instance with the given name and parent.

    extern function new(string name = "LTSM_controllers_monitor", uvm_component parent = null);


    // Task: collect_transaction
    //
    // Monitors the LTSM_controllers bus for setup and access phases, captures transaction
    // details including address, data, strobe, and operation type (read/write),
    // then broadcasts the transaction through the analysis port.

    extern virtual task collect_transaction();

endclass : LTSM_controllers_monitor


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- LTSM_controllers_monitor
//
//------------------------------------------------------------------------------


// new
// ---

function LTSM_controllers_monitor::new(string name = "LTSM_controllers_monitor", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// collect_transaction
// -------------------

task LTSM_controllers_monitor::collect_transaction();
    
    fork
        // output thread
        begin
            item_out = ITEM_T::type_id::create("item_out");
                forever begin
                    @(negedge vif.clk);
                    item_out.o_tx_encoding                           = vif.o_tx_encoding;
                    item_out.o_rx_encoding                           = vif.o_rx_encoding;
                    item_out.o_sbinit_start                          = vif.o_sbinit_start;
                    item_out.o_t1_ms                                 = vif.o_t1_ms;
                    item_out.o_lane_map_tx                           = vif.o_lane_map_tx;
                    item_out.o_lane_map_rx                           = vif.o_lane_map_rx;
                    item_out.o_error_threshhold                      = vif.o_error_threshhold;
                    item_out.o_speedreg                              = vif.o_speedreg;
                    item_out.o_Runtime_Link_Test_status_register     = vif.o_Runtime_Link_Test_status_register;
                    item_out.o_Runtime_Link_Test_Control_register    = vif.o_Runtime_Link_Test_Control_register;
                    ap_out.write(item_out);
                    transaction_count_out++;
                end 
        end
        // input thread
        begin
            item_in = ITEM_T::type_id::create("item_in");
            forever begin
                @(posedge vif.clk);
                item_in.i_supply_stable                              = vif.i_supply_stable;
                item_in.i_pll_stable                         = vif.i_pll_stable;
                item_in.i_rx_error                           = vif.i_rx_error;
                item_in.i_rx_done                            = vif.i_rx_done;
                item_in.i_tx_done                            = vif.i_tx_done;
                item_in.i_rx_valid_results                          = vif.i_rx_valid_results;
                item_in.i_sb_ready                           = vif.i_sb_ready;
                item_in.i_reset                              = vif.i_reset;
                item_in.i_sb_cur_msg_done                    = vif.i_sb_cur_msg_done;
                item_in.i_speedreg                           = vif.i_speedreg;
                item_in.i_local_cap                          = vif.i_local_cap;
                item_in.i_par_check_done                     = vif.i_par_check_done;
                item_in.i_rx_data_results                    = vif.i_rx_data_results;
                item_in.i_clk_results                        = vif.i_clk_results;
                item_in.i_Runtime_Link_Test_status_register  = vif.i_Runtime_Link_Test_status_register;
                item_in.i_Runtime_Link_Test_Control_register = vif.i_Runtime_Link_Test_Control_register;
                item_in.i_sim_cycles_8                      = vif.i_sim_cycles_8;
                item_in.i_sim_cycles_4                      = vif.i_sim_cycles_4;
                item_in.i_sim_cycles_1                      = vif.i_sim_cycles_1;
                item_in.i_sim_cycles_1_us                   = vif.i_sim_cycles_1_us;
                item_in.i_sim_cycles_2_us                   = vif.i_sim_cycles_2_us;
                ap_in.write(item_in);
                transaction_count_in++;
            end
        end
    join_any
    
endtask : collect_transaction