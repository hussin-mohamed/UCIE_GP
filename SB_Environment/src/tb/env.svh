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
// CLASS: sb_env
//
// The sb_env class provides the top-level UVM environment for the sb
// testbench. It instantiates all agents, scoreboards, and the virtual sequencer,
// manages configuration objects, and establishes all analysis port connections
// for the verification infrastructure.
//
//------------------------------------------------------------------------------

class sb_env extends uvm_env;
    `uvm_component_utils(sb_env)

    sb_scoreboard sb;

    ctrl_sb_agent  ltsm_ctrl_agt;
    tx_sb_agent    tx_path_agt;
    rx_sb_agent    rx_path_agt;
    //rdi_agent        rdi_agt;
    phy_sb_agent   phy_link_agt;

    env_config env_cfg;

    ltsm_ctrl_cfg_t  ltsm_ctrl_cfg;
    tx_path_cfg_t    tx_path_cfg;
    rx_path_cfg_t    rx_path_cfg;
    //rdi_cfg_t        rdi_cfg;
    phy_link_cfg_t   phy_link_cfg;

    virtual_sequencer v_seqr;


    // Function: new
    //
    // Creates a new sb_env instance with the given name and parent.

    extern function new(string name = "sb_env", uvm_component parent = null);


    // Function: build_phase
    //
    // Creates all scoreboards, agents, configuration objects, and virtual sequencer.
    // Retrieves environment configuration and distributes agent configurations.

    extern function void build_phase(uvm_phase phase);


    // Function: connect_phase
    //
    // Connects all analysis ports between agents and scoreboards, and assigns
    // child sequencer handles to the virtual sequencer.

    extern function void connect_phase(uvm_phase phase);


    // Function: configure_agents
    //
    // Calls individual agent configuration functions to set up all agent
    // configuration objects with appropriate settings.

    extern function void configure_agents();


    // Function: configure_ltsm_ctrl_agent
    //
    // Configures the system control agent with interface and activity settings.

    extern function void configure_ltsm_ctrl_agent();


    // Function: configure_tx_path_agent
    //
    // Configures the first APB agent with interface and activity settings.

    extern function void configure_tx_path_agent();


    // Function: configure_rx_path_agent
    //
    // Configures the second APB agent with interface and activity settings.

    extern function void configure_rx_path_agent();


    // Function: configure_apb_controller_agent_1
    //
    // Configures the first APB controller agent with interface and activity settings.

    extern function void configure_apb_controller_agent_1();


    // Function: configure_apb_controller_agent_2
    //
    // Configures the second APB controller agent with interface and activity settings.

    extern function void configure_apb_controller_agent_2();


    // Function: configure_aes_agent
    //
    // Configures the AES agent with interface and activity settings.

    extern function void configure_aes_agent();

endclass : sb_env


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- sb_env
//
//------------------------------------------------------------------------------


// new
// ---

function sb_env::new(string name = "sb_env", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void sb_env::build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    sb = sb_scoreboard::type_id::create("sb", this);

    ctrl_sb_agent = ctrl_sb_agent::type_id::create("ctrl_sb_agent", this);
    tx_sb_agent   = tx_sb_agent::type_id::create("tx_sb_agent", this);
    rx_sb_agent   = rx_sb_agent::type_id::create("rx_sb_agent", this);
    //rdi_agt       = rdi_agent::type_id::create("rdi_agt", this);
    phy_sb_agent  = phy_sb_agent::type_id::create("phy_sb_agent", this);

    ltsm_ctrl_cfg = ltsm_ctrl_cfg_t::type_id::create("ltsm_ctrl_cfg");
    tx_path_cfg   = tx_path_cfg_t::type_id::create("tx_path_cfg");
    rx_path_cfg   = rx_path_cfg_t::type_id::create("rx_path_cfg");
    //rdi_cfg       = rdi_cfg_t::type_id::create("rdi_cfg");
    phy_link_cfg  = phy_link_cfg_t::type_id::create("phy_link_cfg");

    v_seqr = virtual_sequencer::type_id::create("v_seqr", this);

    if(!uvm_config_db#(env_config)::get(this, "", "ENV_CFG", env_cfg))
        `uvm_fatal("build_phase", "ENV - Unable to environment configuration object from the uvm_config_db")

    configure_agents();

    uvm_config_db#(ltsm_ctrl_cfg_t)::set(this, "ltsm_ctrl_agt", "ltsm_ctrl_cfg", ltsm_ctrl_cfg);
    uvm_config_db#(tx_path_cfg_t)::set(this,   "tx_path_agt",   "tx_path_cfg",   tx_path_cfg);
    uvm_config_db#(rx_path_cfg_t)::set(this,   "rx_path_agt",   "rx_path_cfg",   rx_path_cfg);
    //uvm_config_db#(rdi_cfg_t)::set(this,       "rdi_agt",       "rdi_cfg",       rdi_cfg);
    uvm_config_db#(phy_link_cfg_t)::set(this,  "phy_link_agt",  "phy_link_cfg",  phy_link_cfg);
endfunction : build_phase

// connect_phase
// -------------

function void sb_env::connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    v_seqr.ltsm_ctrl_seqr = ltsm_ctrl_agt.seqr;
    v_seqr.tx_path_seqr   = tx_path_agt.seqr;
    v_seqr.rx_path_seqr   = rx_path_agt.seqr;
   // v_seqr.rdi_seqr       = rdi_agt.seqr;
    v_seqr.phy_link_seqr  = phy_link_agt.seqr;
endfunction : connect_phase

// configure_agents
// ----------------

function void sb_env::configure_agents();
    configure_ltsm_ctrl_agent();
    configure_tx_path_agent();
    configure_rx_path_agent();
    //configure_rdi_agent();
    configure_phy_link_agent();
endfunction : configure_agents

// configure_ltsm_ctrl_agent
// -----------------------

function void sb_env::configure_ltsm_ctrl_agent();
    ltsm_ctrl_cfg.bfm       = env_cfg.ltsm_ctrl_if;
    ltsm_ctrl_cfg.is_active = env_cfg.is_active_ltsm_ctrl;
endfunction : configure_ltsm_ctrl_agent

// configure_tx_path_agent
// ---------------------

function void sb_env::configure_tx_path_agent();
    tx_path_cfg.bfm         = env_cfg.tx_path_if;
    tx_path_cfg.is_active   = env_cfg.is_active_tx_path;
endfunction : configure_tx_path_agent

// configure_rx_path_agent
// ---------------------

function void sb_env::configure_rx_path_agent();
    rx_path_cfg.bfm         = env_cfg.rx_path_if;
    rx_path_cfg.is_active   = env_cfg.is_active_rx_path;
endfunction : configure_rx_path_agent

// configure_phy_link_agent
// --------------------------------

function void sb_env::configure_phy_link_agent();
    phy_link_cfg.bfm        =   env_cfg.phy_link_if;
    phy_link_cfg.is_active  =   env_cfg.is_active_phy_link;
endfunction : configure_phy_link_agent

// // configure_rdi_agent
// // -------------------

// function void sb_env::configure_rdi_agent();
//     rdi_cfg.bfm        =   env_cfg.rdi_if;
//     rdi_cfg.is_active  =   env_cfg.is_active_rdi;
// endfunction : configure_rdi_agent
// // --------------------------------
