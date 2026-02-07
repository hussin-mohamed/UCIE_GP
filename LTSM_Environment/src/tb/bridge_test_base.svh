/***********************************************************************
 * Author : Amr El Batarny
 * File   : bridge_test_base.svh
 * Brief  : Base test class providing common test infrastructure including
 *          environment setup, configuration, and sequence execution.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: bridge_test_base
//
// The bridge_test_base class provides common test infrastructure for the
// bridge verification environment. It handles environment creation, interface
// configuration retrieval, sequence instantiation, and provides phase-based
// hooks for test execution and reporting.
//
//------------------------------------------------------------------------------

class bridge_test_base extends uvm_test;
    `uvm_component_utils(bridge_test_base)

    bridge_env env;
    env_config env_cfg;
    virtual_sequence v_seq;
    uvm_factory factory;


    // Function: new
    //
    // Creates a new bridge_test_base instance and retrieves factory singleton handle.

    extern function new(string name = "bridge_test_base", uvm_component parent = null);


    // Function: build_phase
    //
    // Creates environment and configuration objects, retrieves all virtual interfaces
    // from config_db, and publishes configuration to environment.

    extern function void build_phase(uvm_phase phase);


    // Function: end_of_elaboration_phase
    //
    // Creates virtual sequence instance and prints testbench topology.

    extern function void end_of_elaboration_phase(uvm_phase phase);


    // Function: start_of_simulation_phase
    //
    // Prints test start banner message.

    extern function void start_of_simulation_phase(uvm_phase phase);


    // Task: run_phase
    //
    // Raises objection, starts virtual sequence on environment sequencer,
    // and drops objection upon completion.

    extern task run_phase(uvm_phase phase);


    // Function: final_phase
    //
    // Prints factory configuration and test completion banner.

    extern function void final_phase(uvm_phase phase);

endclass : bridge_test_base


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- bridge_test_base
//
//------------------------------------------------------------------------------


// new
// ---

function bridge_test_base::new(string name = "bridge_test_base", uvm_component parent = null);
    super.new(name, parent);
    factory = uvm_coreservice_t::get().get_factory();
endfunction : new

// build_phase
// -----------

function void bridge_test_base::build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = bridge_env::type_id::create("env", this);
    env_cfg = env_config::type_id::create("env_cfg", this);

    if(!uvm_config_db#(virtual SYSCTRL_bfm)::get(this, "",       "SYSCTRL_BFM",        env_cfg.sysctrl_bfm))
        `uvm_fatal("build_phase", "TEST - Unable to get the SYSCTRL_BFM from the uvm_config_db")

    if(!uvm_config_db#(virtual APB_bfm)::get(this, "",           "APB_BFM_1",          env_cfg.apb_bfm_1))
        `uvm_fatal("build_phase", "TEST - Unable to get the APB_BFM_1 from the uvm_config_db")

    if(!uvm_config_db#(virtual APB_bfm)::get(this, "",           "APB_BFM_2",          env_cfg.apb_bfm_2))
        `uvm_fatal("build_phase", "TEST - Unable to get the APB_BFM_2 from the uvm_config_db")

    if(!uvm_config_db#(virtual AES_if)::get(this, "",            "AES_IF",             env_cfg.aes_if))
        `uvm_fatal("build_phase", "TEST - Unable to get the AES_IF from the uvm_config_db")

    if(!uvm_config_db#(virtual APB_controller_if)::get(this, "",   "APB_CTRL_OUT_1",     env_cfg.apb_controller_if_1))
        `uvm_fatal("build_phase", "TEST - Unable to get the APB_CTRL_OUT_1 from the uvm_config_db")

    if(!uvm_config_db#(virtual APB_controller_if)::get(this, "",   "APB_CTRL_OUT_2",     env_cfg.apb_controller_if_2))
        `uvm_fatal("build_phase", "TEST - Unable to get the APB_CTRL_OUT_2 from the uvm_config_db")

    uvm_config_db#(env_config)::set(this, "env", "ENV_CFG", env_cfg);
endfunction : build_phase

// end_of_elaboration_phase
// -------------------------

function void bridge_test_base::end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    
    v_seq = virtual_sequence::type_id::create("v_seq", this);
    uvm_top.print_topology(); // Prints entire testbench hierarchy 
endfunction : end_of_elaboration_phase

// start_of_simulation_phase
// --------------------------

function void bridge_test_base::start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    
    `uvm_info("start_of_simulation_phase", $sformatf("=============== Start of %s ===============", this.get_type_name()), UVM_MEDIUM)
endfunction : start_of_simulation_phase

// run_phase
// ---------

task bridge_test_base::run_phase(uvm_phase phase);
    super.run_phase(phase);

    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", v_seq.get_type_name()), UVM_MEDIUM)
    v_seq.start(env.v_seqr); ///////////////// **************
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", v_seq.get_type_name()), UVM_MEDIUM)

    phase.drop_objection(this);
endtask : run_phase

// final_phase
// -----------

function void bridge_test_base::final_phase(uvm_phase phase);
    super.final_phase(phase);
    
    factory.print(0);
    `uvm_info("start_of_simulation_phase", $sformatf("=============== End of %s ===============", this.get_type_name()), UVM_MEDIUM)
endfunction : final_phase
