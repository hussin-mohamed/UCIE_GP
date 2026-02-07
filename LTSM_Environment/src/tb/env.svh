/***********************************************************************
 * Author : Amr El Batarny
 * File   : env.svh
 * Brief  : Top-level verification environment containing agents, scoreboards,
 *          and configuration infrastructure for the bridge testbench.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: bridge_env
//
// The bridge_env class provides the top-level UVM environment for the bridge
// testbench. It instantiates all agents, scoreboards, and the virtual sequencer,
// manages configuration objects, and establishes all analysis port connections
// for the verification infrastructure.
//
//------------------------------------------------------------------------------

class bridge_env extends uvm_env;
    `uvm_component_utils(bridge_env)

    APB_scoreboard            #(APB_sequence_item_1, APB_sequence_item_1)          apb_sb_1;
    APB_scoreboard            #(APB_sequence_item_2, APB_sequence_item_2)          apb_sb_2;
    APB_controller_scoreboard #(APB_sequence_item_1, APB_controller_sequence_item) apb_ctrl_sb_1;
    APB_controller_scoreboard #(APB_sequence_item_2, APB_controller_sequence_item) apb_ctrl_sb_2;
    AES_scoreboard                                                                 aes_sb;

    sysctrl_agt_type          sysctrl_agt;
    apb_agt_1_type            apb_agt_1;
    apb_agt_2_type            apb_agt_2;
    apb_controller_agt_1_type apb_controller_agt_1;
    apb_controller_agt_2_type apb_controller_agt_2;
    aes_agt_type              aes_agt;

    env_config env_cfg;

    sysctrl_cfg_type        sysctrl_cfg;
    apb_cfg_1_type          apb_cfg_1;
    apb_cfg_2_type          apb_cfg_2;
    apb_controller_cfg_type apb_controller_cfg_1;
    apb_controller_cfg_type apb_controller_cfg_2;
    aes_cfg_type            aes_cfg;

    virtual_sequencer v_seqr;


    // Function: new
    //
    // Creates a new bridge_env instance with the given name and parent.

    extern function new(string name = "bridge_env", uvm_component parent = null);


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

    extern function void configure_sysctrl_agent();


    // Function: configure_apb_agent_1
    //
    // Configures the first APB agent with interface and activity settings.

    extern function void configure_apb_agent_1();


    // Function: configure_apb_agent_2
    //
    // Configures the second APB agent with interface and activity settings.

    extern function void configure_apb_agent_2();


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

endclass : bridge_env


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

function bridge_env::new(string name = "bridge_env", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void bridge_env::build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    apb_sb_1      = APB_scoreboard#(APB_sequence_item_1, APB_sequence_item_1)::type_id::create("apb_sb_1", this);
    apb_sb_2      = APB_scoreboard#(APB_sequence_item_2, APB_sequence_item_2)::type_id::create("apb_sb_2", this);
    apb_ctrl_sb_1 = APB_controller_scoreboard#(APB_sequence_item_1, APB_controller_sequence_item)::type_id::create("apb_ctrl_sb_1", this);
    apb_ctrl_sb_2 = APB_controller_scoreboard#(APB_sequence_item_2, APB_controller_sequence_item)::type_id::create("apb_ctrl_sb_2", this);
    aes_sb        = AES_scoreboard::type_id::create("aes_sb", this);

    sysctrl_agt           = sysctrl_agt_type::type_id::create("sysctrl_agt", this);
    apb_agt_1             = apb_agt_1_type::type_id::create("apb_agt_1", this);
    apb_agt_2             = apb_agt_2_type::type_id::create("apb_agt_2", this);
    apb_controller_agt_1  = apb_controller_agt_1_type::type_id::create("apb_controller_agt_1", this);
    apb_controller_agt_2  = apb_controller_agt_2_type::type_id::create("apb_controller_agt_2", this);
    aes_agt               = aes_agt_type::type_id::create("aes_agt", this);

    sysctrl_cfg           = sysctrl_cfg_type::type_id::create("sysctrl_cfg");
    apb_cfg_1             = apb_cfg_1_type::type_id::create("apb_cfg_1");
    apb_cfg_2             = apb_cfg_2_type::type_id::create("apb_cfg_2");
    apb_controller_cfg_1  = apb_controller_cfg_type::type_id::create("apb_controller_cfg_1");
    apb_controller_cfg_2  = apb_controller_cfg_type::type_id::create("apb_controller_cfg_2");
    aes_cfg           = aes_cfg_type::type_id::create("aes_cfg");

    v_seqr = virtual_sequencer::type_id::create("v_seqr", this);

    if(!uvm_config_db#(env_config)::get(this, "", "ENV_CFG", env_cfg))
        `uvm_fatal("build_phase", "ENV - Unable to environment configuration object from the uvm_config_db")

    configure_agents();

    uvm_config_db#(sysctrl_cfg_type)::set(this, "sysctrl_agt", "SYSCTRL_AGT_CFG", sysctrl_cfg);
    uvm_config_db#(apb_cfg_1_type)::set(this, "apb_agt_1", "APB_AGT_CFG_1", apb_cfg_1);
    uvm_config_db#(apb_cfg_2_type)::set(this, "apb_agt_2", "APB_AGT_CFG_2", apb_cfg_2);
    uvm_config_db#(apb_controller_cfg_type)::set(this, "apb_controller_agt_1", "APB_CTRL_OUT_AGT_CFG_1", apb_controller_cfg_1);
    uvm_config_db#(apb_controller_cfg_type)::set(this, "apb_controller_agt_2", "APB_CTRL_OUT_AGT_CFG_2", apb_controller_cfg_2);
    uvm_config_db#(aes_cfg_type)::set(this, "aes_agt", "AES_OUT_AGT_CFG", aes_cfg);
endfunction : build_phase

// connect_phase
// -------------

function void bridge_env::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    apb_agt_1.drvr_ap.connect(apb_sb_1.expt_in);
    apb_agt_2.drvr_ap.connect(apb_sb_2.expt_in);

    apb_agt_1.mntr_ap.connect(apb_ctrl_sb_1.expt_in);
    apb_controller_agt_1.mntr_ap.connect(apb_ctrl_sb_1.expt_out);
    
    apb_controller_agt_2.mntr_ap.connect(apb_ctrl_sb_2.expt_out);
    apb_agt_2.mntr_ap.connect(apb_ctrl_sb_2.expt_in);

    apb_agt_1.mntr_ap.connect(apb_sb_1.expt_out);
    apb_agt_2.mntr_ap.connect(apb_sb_2.expt_out);

    apb_controller_agt_1.mntr_ap.connect(aes_sb.expt_in);
    aes_agt.mntr_ap.connect(aes_sb.expt_out);

    v_seqr.apb_seqr_1 = apb_agt_1.seqr;
    v_seqr.apb_seqr_2 = apb_agt_2.seqr;
endfunction : connect_phase

// configure_agents
// ----------------

function void bridge_env::configure_agents();
    configure_sysctrl_agent();
    configure_apb_agent_1();
    configure_apb_agent_2();
    configure_apb_controller_agent_1();
    configure_apb_controller_agent_2();
    configure_aes_agent();
endfunction : configure_agents

// configure_sysctrl_agent
// -----------------------

function void bridge_env::configure_sysctrl_agent();
    sysctrl_cfg.bfm                 =   env_cfg.sysctrl_bfm;
    sysctrl_cfg.is_active           =   env_cfg.is_active_sysctrl;
endfunction : configure_sysctrl_agent

// configure_apb_agent_1
// ---------------------

function void bridge_env::configure_apb_agent_1();
    apb_cfg_1.bfm                   =   env_cfg.apb_bfm_1;
    apb_cfg_1.is_active             =   env_cfg.is_active_apb_1;
endfunction : configure_apb_agent_1

// configure_apb_agent_2
// ---------------------

function void bridge_env::configure_apb_agent_2();
    apb_cfg_2.bfm                   =   env_cfg.apb_bfm_2;
    apb_cfg_2.is_active             =   env_cfg.is_active_apb_2;
endfunction : configure_apb_agent_2

// configure_apb_controller_agent_1
// --------------------------------

function void bridge_env::configure_apb_controller_agent_1();
    apb_controller_cfg_1.bfm        =   env_cfg.apb_controller_if_1;
    apb_controller_cfg_1.is_active  =   env_cfg.is_active_apb_controller_1;
endfunction : configure_apb_controller_agent_1

// configure_apb_controller_agent_2
// --------------------------------

function void bridge_env::configure_apb_controller_agent_2();
    apb_controller_cfg_2.bfm        =   env_cfg.apb_controller_if_2;
    apb_controller_cfg_2.is_active  =   env_cfg.is_active_apb_controller_2;
endfunction : configure_apb_controller_agent_2

// configure_aes_agent
// -------------------

function void bridge_env::configure_aes_agent();
    aes_cfg.bfm                     =   env_cfg.aes_if;
    aes_cfg.is_active               =   env_cfg.is_active_aes;
endfunction : configure_aes_agent
