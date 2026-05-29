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
// CLASS: agent
//
// The agent class provides a highly parameterized UVM agent implementation
// that can be configured with different sequencers, drivers, and monitors.
// Supports both active and passive operation modes based on configuration.
//
//------------------------------------------------------------------------------

class ltsm_rdi_agent extends uvm_agent;

    uvm_analysis_port #(ltsm_rdi_sequence_item) ap_in, ap_out;
    ltsm_rdi_driver #(virtual ltsm_rdi_if) drvr;
    ltsm_rdi_monitor #(ltsm_rdi_sequence_item, virtual ltsm_rdi_if) mntr;
    ltsm_rdi_sequencer seqr ;


    rdi_agent_cfg_type#(virtual ltsm_rdi_if) rdi_cfg;
    // This field determines whether an agent is active or passive.
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_param_utils_begin(ltsm_rdi_agent)
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
    `uvm_component_utils_end


    // Function: new
    //
    // Creates a new agent instance with the given name (defaults to AGT_NAME parameter).

    extern function new(string name = "ltsm_rdi_agent", uvm_component parent = null);


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

endclass : ltsm_rdi_agent


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

function ltsm_rdi_agent::new(string name = "ltsm_rdi_agent", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void ltsm_rdi_agent::build_phase(uvm_phase phase);
    super.build_phase(phase);

    if(!uvm_config_db#(rdi_agent_cfg_type #(virtual ltsm_rdi_if))::get(this, "", "rdi_cfg", rdi_cfg))
         `uvm_fatal("build_phase", $sformatf("AGENT - Unable to get the agent configuration object from the uvm_config_db, CFG_NAME: %s, agent name: %s", "rdi_cfg", this.get_full_name()))
        

    mntr = ltsm_rdi_monitor #(ltsm_rdi_sequence_item, virtual ltsm_rdi_if)::type_id::create("mntr", this);

    if (rdi_cfg != null) is_active = rdi_cfg.is_active;

    if(is_active == UVM_ACTIVE) begin
        drvr = ltsm_rdi_driver #(virtual ltsm_rdi_if)::type_id::create("drvr", this);
        seqr = ltsm_rdi_sequencer #(ltsm_rdi_sequence_item)::type_id::create("seqr", this);
    end

    ap_out = new("ap_out", this);
    ap_in = new("ap_in", this);
endfunction : build_phase

// connect_phase
// -------------

function void ltsm_rdi_agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
        `uvm_info("connect_phase", "Connecting LTSM_env components and virtual sequencer", UVM_LOW)

    mntr.ap_in.connect(ap_in);
    mntr.ap_out.connect(ap_out);
    mntr.vif = rdi_cfg.vif;

    if(is_active == UVM_ACTIVE) begin
        drvr.seq_item_port.connect(seqr.seq_item_export);
        drvr.vif = rdi_cfg.vif;
    end
endfunction : connect_phase
