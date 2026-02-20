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

class tx_sb_agent extends agent_base #("TX_SB_AGENT_CFG", virtual sb_tx_path_bfm, tx_sequence_item);
    `uvm_component_utils(tx_sb_agent)

    // Function: new
    //
    // Creates a new tx_sb_agent instance with the given name and parent.

    extern function new(string name = "tx_sb_agent", uvm_component parent = null);
    // Function: build_phase
    //
// Builds the agent by creating the sequencer, driver, and monitor components,
// and connecting the analysis ports.

    extern virtual function void build_phase(uvm_phase phase);

endclass //className extends superClass

//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// CLASS- tx_sb_agent
//------------------------------------------------------------------------------    

// new
// ---
function tx_sb_agent::new(string name = "tx_sb_agent", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// build_phase
// ---

function void tx_sb_agent::build_phase(uvm_phase phase);

    // Create the sequencer, driver, and monitor components
    set_type_override_by_type ( tx_path_driver::get_type(), tx_sb_driver::get_type() );
    set_type_override_by_type ( tx_sb_sequencer::get_type(), tx_sb_sequencer::get_type() );
    set_type_override_by_type ( tx_path_monitor::get_type(), tx_sb_monitor::get_type() );
    super.build_phase(phase);
    // Connect the driver's analysis port to the agent's driver analysis port
    drvr.drvr_ap.connect(drvr_ap);

    // Connect the monitor's analysis port to the agent's monitor analysis port
    mntr.mntr_ap.connect(mntr_ap);
endfunction : build_phase