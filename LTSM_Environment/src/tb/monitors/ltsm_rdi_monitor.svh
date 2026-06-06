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
// CLASS: ltsm_rdi_monitor
//
// The ltsm_rdi_monitor class extends uvm_monitor to implement complete ltsm rdi
// protocol monitoring. It captures both read and write transactions by
// detecting setup and access phases, sampling appropriate signals, and
// broadcasting transactions through the analysis port.
//

//
//------------------------------------------------------------------------------

class ltsm_rdi_monitor #(type ITEM_T, type INTF_T)  extends LTSM_monitor_base #(ITEM_T, INTF_T);
    `uvm_component_param_utils(ltsm_rdi_monitor #(ITEM_T, INTF_T))

    // Function: new
    //
    // Creates a new ltsm_rdi_monitor instance with the given name and parent.

    extern function new(string name = "ltsm_rdi_monitor", uvm_component parent = null);


    // Task: collect_transaction
    //
    // Monitors the ltsm rdi bus for setup and access phases, captures transaction
    // then broadcasts the transaction through the analysis port.

    extern virtual task collect_transaction();

endclass : ltsm_rdi_monitor


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- ltsm_rdi_monitor
//
//------------------------------------------------------------------------------


// new
// ---

function ltsm_rdi_monitor::new(string name = "ltsm_rdi_monitor", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// collect_transaction
// -------------------

task ltsm_rdi_monitor::collect_transaction();
    fork
        // output thread
        begin
            item_out=ITEM_T::type_id::create("item_out");
            forever begin
                @(negedge vif.clk);
                item_out.o_pl_state_sts = vif.o_pl_state_sts;
                item_out.o_pl_inband_pres = vif.o_pl_inband_pres;
                item_out.o_pl_phyinrecenter= vif.o_pl_phyinrecenter;
                item_out.o_pl_stallreq = vif.o_pl_stallreq;
                item_out.o_pl_clk_req = vif.o_pl_clk_req;
                item_out.o_pl_wake_ack = vif.o_pl_wake_ack;
                item_out.o_pl_lnk_cfg = vif.o_pl_lnk_cfg;
                item_out.o_pl_speedmode = vif.o_pl_speedmode;
                item_out.o_pl_max_speedmode = vif.o_pl_max_speedmode;
                item_out.o_pl_error = vif.o_pl_error;
                item_out.o_pl_trainerror = vif.o_pl_trainerror;
                item_out.o_pl_cerror = vif.o_pl_cerror;
                item_out.o_pl_nferror = vif.o_pl_nferror;
                ap_out.write(item_out);
                transaction_count_out++;
            end 
            end
        // input thread
        begin
            item_in=ITEM_T::type_id::create("item_in");
            forever begin
                @(posedge vif.clk);
                item_in.i_lp_state_req = vif.i_lp_state_req;
                item_in.i_lp_stallack = vif.i_lp_stallack;
                item_in.i_lp_clk_ack = vif.i_lp_clk_ack;
                item_in.i_lp_wake_req = vif.i_lp_wake_req;
                item_in.i_lp_linkerror = vif.i_lp_linkerror;
                ap_in.write(item_in);
                transaction_count_in++;
            end
        end
    join_any
    
endtask : collect_transaction