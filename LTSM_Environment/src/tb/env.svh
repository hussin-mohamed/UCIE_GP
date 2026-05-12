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
// CLASS: LTSM_env
//
// The LTSM_env class provides the top-level UVM environment for the LTSM
// testbench. It instantiates all agents, scoreboards, and the virtual sequencer,
// manages configuration objects, and establishes all analysis port connections
// for the verification infrastructure.
//
//------------------------------------------------------------------------------

class LTSM_env extends uvm_env;
    `uvm_component_utils(LTSM_env)

    tx_fsm_sb_agent               tx_agent;
    rx_fsm_sb_agent               rx_agent;
    LTSM_controllers_agent        LTSM_ctrl_agt;
    ltsm_rdi_agent          rdi_agt;

    agent_config #(virtual RX_FSM_SB) rx_cfg;
    agent_config #(virtual TX_FSM_SB) tx_cfg;
    LTSM_controllers_agent_cfg #(virtual LTSM_controllers_if) LTSM_ctrl_cfg;
    rdi_agent_cfg_type #(virtual ltsm_rdi_if) rdi_cfg;
    env_config env_cfg;

    scoreboard score;

    virtual_sequencer v_seqr;


    // Function: new
    //
    // Creates a new LTSM_env instance with the given name and parent.

    extern function new(string name = "LTSM_env", uvm_component parent = null);


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


    // Function: configure_sysctrl_agent
    //
    // Configures the system control agent with interface and activity settings.

    
    extern function void configure_tx_agent();


    // Function: configure_rx_agent
    //
    // Configures the RX FSM SB agent with interface and activity settings.

    extern function void configure_rx_agent();

    // Function: configure_LTSM_controller_agent
    //
    // Configures the LTSM controllers agent with interface and activity settings.
    extern function void configure_LTSM_controller_agent();

    // Function: configure_rdi_agent
    //
    // Configures the RDI agent with interface and activity settings.
    extern function void configure_rdi_agent();

endclass : LTSM_env


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- bridge_env
//
//------------------------------------------------------------------------------


// new
// ---

function LTSM_env::new(string name = "LTSM_env", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void LTSM_env::build_phase(uvm_phase phase);
    super.build_phase(phase);

    tx_agent = tx_fsm_sb_agent::type_id::create("tx_agent", this);
    rx_agent = rx_fsm_sb_agent::type_id::create("rx_agent", this);
    LTSM_ctrl_agt         = LTSM_controllers_agent ::type_id::create("LTSM_ctrl_agt", this);
    rdi_agt           = ltsm_rdi_agent::type_id::create("rdi_agt", this);

    rx_cfg           = agent_config #(virtual RX_FSM_SB)::type_id::create("rx_cfg");
    tx_cfg           = agent_config #(virtual TX_FSM_SB)::type_id::create("tx_cfg");
    LTSM_ctrl_cfg     = LTSM_controllers_agent_cfg #(virtual LTSM_controllers_if)::type_id::create("LTSM_ctrl_cfg");
    rdi_cfg            = rdi_agent_cfg_type #(virtual ltsm_rdi_if)::type_id::create("rdi_cfg");
    score              = scoreboard::type_id::create("score", this);
    rdi_cfg            = new("rdi_cfg");


    v_seqr = virtual_sequencer::type_id::create("v_seqr", this);

    if(!uvm_config_db#(env_config)::get(this, "", "ENV_CFG", env_cfg))
        `uvm_fatal("build_phase", "ENV - Unable to environment configuration object from the uvm_config_db")

    configure_agents();

    uvm_config_db#(agent_config#(virtual TX_FSM_SB))::set(this, "tx_agent", "tx_config", tx_cfg);
    uvm_config_db#(agent_config#(virtual RX_FSM_SB))::set(this, "rx_agent", "rx_config", rx_cfg);
    uvm_config_db#(LTSM_controllers_agent_cfg #(virtual LTSM_controllers_if))::set(this, "LTSM_ctrl_agt", "LTSM_CTRL_AGT_CFG", LTSM_ctrl_cfg);
    uvm_config_db#(rdi_agent_cfg_type #(virtual ltsm_rdi_if))::set(this, "rdi_agt", "rdi_cfg", rdi_cfg);

endfunction : build_phase

// connect_phase
// -------------

function void LTSM_env::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info("connect_phase", "Connecting LTSM_env components and virtual sequencer", UVM_LOW)
    v_seqr.tx_seqr = tx_agent.seqr;
    v_seqr.rx_seqr = rx_agent.seqr;
    v_seqr.LTSM_ctrl_seqr = LTSM_ctrl_agt.seqr;
    v_seqr.ltsm_rdi_seqr = rdi_agt.seqr;

    rx_agent.ap_in.connect(score.ap_rx_fsm_sb_in);
    rx_agent.ap_out.connect(score.ap_rx_fsm_sb_out);

    tx_agent.ap_in.connect(score.ap_tx_fsm_sb_in);
    tx_agent.ap_out.connect(score.ap_tx_fsm_sb_out);

    LTSM_ctrl_agt.ap_in.connect(score.ap_controllers_in);
    LTSM_ctrl_agt.ap_out.connect(score.ap_controllers_out);

    rdi_agt.ap_in.connect(score.ap_rdi_in);
    rdi_agt.ap_out.connect(score.ap_rdi_out);
    `uvm_info("connect_phase", "Connecting LTSM_env components and virtual sequencer has finished", UVM_LOW)
endfunction : connect_phase

// configure_agents
// ----------------

function void LTSM_env::configure_agents();
    configure_tx_agent();
    configure_rx_agent();
    configure_LTSM_controller_agent();
    configure_rdi_agent();
endfunction : configure_agents

// configure_tx_agent
// ------------------

function void LTSM_env::configure_tx_agent();
    tx_cfg.vif                 =   env_cfg.tx_fsm_sb_if;
    tx_cfg.is_active           =   env_cfg.is_active_tx_fsm_sb;
endfunction : configure_tx_agent

// configure_rx_agent
// ------------------

function void LTSM_env::configure_rx_agent();
    rx_cfg.vif                 =   env_cfg.rx_fsm_sb_if;
    rx_cfg.is_active           =   env_cfg.is_active_rx_fsm_sb;
endfunction : configure_rx_agent

function void LTSM_env::configure_LTSM_controller_agent();
    LTSM_ctrl_cfg.vif               =   env_cfg.vif;
    LTSM_ctrl_cfg.is_active         =   env_cfg.is_active_LTSM_controllers;
endfunction : configure_LTSM_controller_agent

function void LTSM_env::configure_rdi_agent();
    rdi_cfg.vif                     =   env_cfg.ltsm_rdi_vif;
    rdi_cfg.is_active               =   env_cfg.is_active_rdi;
endfunction : configure_rdi_agent
