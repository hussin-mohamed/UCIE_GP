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

//-----------------------------------------------------------------------------
//
// CLASS: agent_base
//
// The agent class provides a highly parameterized UVM agent implementation.
// Supports both active and passive operation modes based on configuration.
//
// Type Parameters:
//   CFG_NAME - Configuration object name for config_db lookup
//   INTF_T   - Virtual interface type
//
//-----------------------------------------------------------------------------

virtual class agent_base #(
    string CFG_NAME = "GENERIC_CFG_NAME",
    type   INTF_T   = virtual sb_tx_path_bfm,
    type   ITEM_T   = tx_path_seq_item
    ) extends uvm_agent;

    INTF_T                 bfm;
    tx_path_sequencer      seqr;
    tx_path_driver         drvr;
    tx_path_monitor        mntr;
    agent_config #(INTF_T) cfg;

    uvm_analysis_port #(ITEM_T) drvr_ap, mntr_ap;

    // This field determines whether an agent is active or passive.
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_param_utils_begin(agent_base #(CFG_NAME, INTF_T))
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
    `uvm_component_utils_end


    // Function: new
    //
    // Creates a new agent instance with the given name.

    extern function new(string name, uvm_component parent);


    // Function: build_phase
    //
    // Retrieves agent configuration from config_db and creates monitor. If configured
    // as active agent, also creates driver and sequencer and their analysis ports.

    extern function void build_phase(uvm_phase phase);


    // Function: connect_phase
    //
    // Connects monitor to its interface and analysis port. For active agents,
    // connects driver to sequencer, assigns interface, and connects driver analysis port.

    extern function void connect_phase(uvm_phase phase);

endclass : agent_base


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- agent
//
//------------------------------------------------------------------------------


// new
// ---

function agent::new(string name, uvm_component parent);
    super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void agent::build_phase(uvm_phase phase);
    super.build_phase(phase);

    if(!uvm_config_db#(agent_config #(INTF_T))::get(this, "", CFG_NAME, cfg))
        `uvm_fatal("build_phase", $sformatf("AGENT - Unable to get the agent configuration object from the uvm_config_db, CFG_NAME: %s, agent name: %s", CFG_NAME, this.get_full_name()))

    mntr = MNTR_T::type_id::create("mntr", this);

    if (cfg != null) is_active = cfg.is_active;

    if(is_active == UVM_ACTIVE) begin
        drvr = DRVR_T::type_id::create("drvr", this);
        seqr = SEQR_T::type_id::create("seqr", this);
        drvr_ap = new("drvr_ap", this);
    end

    mntr_ap = new("mntr_ap", this);
endfunction : build_phase

// connect_phase
// -------------

function void agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    mntr.ap.connect(mntr_ap);
    mntr.bfm = cfg.bfm;

    if(is_active == UVM_ACTIVE) begin
        drvr.seq_item_port.connect(seqr.seq_item_export);
        drvr.bfm = cfg.bfm;
        drvr.ap.connect(drvr_ap);
    end
endfunction : connect_phase
