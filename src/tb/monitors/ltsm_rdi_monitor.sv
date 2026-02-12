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

class ltsm_rdi_monitor  extends uvm_monitor;
    `uvm_component_utils(ltsm_rdi_monitor)
    virtual ltsm_rdi_if vif;
    uvm_analysis_port #(ltsm_rdi_sequence_item) ap;
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
    ap = new("ap", this);
endfunction : new

// collect_transaction
// -------------------

task ltsm_rdi_monitor::collect_transaction();
    // `uvm_info(get_type_name(), $sformatf("MONITORED %s: \n%s", item.get_type_name(), item.sprint()), UVM_DEBUG)
endtask : collect_transaction