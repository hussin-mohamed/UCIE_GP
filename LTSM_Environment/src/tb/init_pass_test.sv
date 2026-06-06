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
// CLASS: mbinit_clk_fail_test
//
// The mbinit_clk_fail_test class provides common test infrastructure for the
// LTSM verification environment. It handles environment creation, interface
// configuration retrieval, sequence instantiation, and provides phase-based
// hooks for test execution and reporting. // it starts the sequence to mimic the initialization flow with clock failure.

//
//------------------------------------------------------------------------------

class init_pass_test extends uvm_test;
    `uvm_component_utils(init_pass_test)

    LTSM_env env;
    env_config env_cfg;
    uvm_factory factory;
    // sequence to run
    initialization_success init_seq;

    // Function: new
    //
    // Creates a new init_pass_test instance and retrieves factory singleton handle.

    extern function new(string name = "init_pass_test", uvm_component parent = null);


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

endclass : init_pass_test


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

function init_pass_test::new(string name = "init_pass_test", uvm_component parent = null);
    super.new(name, parent);
    factory = uvm_factory::get();
endfunction : new

// build_phase
// -----------

function void init_pass_test::build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Create the sequence
    init_seq = initialization_success::type_id::create("init_seq", this);

    env = LTSM_env::type_id::create("env", this);
    env_cfg = env_config::type_id::create("env_cfg", this);

    if(!uvm_config_db#(virtual TX_FSM_SB)::get(this, "",       "TX_FSM_SB",        env_cfg.tx_fsm_sb_if))
        `uvm_fatal("build_phase", "TEST - Unable to get the TX_FSM_SB from the uvm_config_db")

    if(!uvm_config_db#(virtual RX_FSM_SB)::get(this, "",       "RX_FSM_SB",        env_cfg.rx_fsm_sb_if))
        `uvm_fatal("build_phase", "TEST - Unable to get the RX_FSM_SB from the uvm_config_db")

    if(!uvm_config_db#(virtual LTSM_controllers_if)::get(this, "", "LTSM_CONTROLLERS_IF", env_cfg.vif))
        `uvm_fatal("build_phase", "TEST - Unable to get the LTSM_CONTROLLERS_IF from the uvm_config_db")

    if(!uvm_config_db#(virtual ltsm_rdi_if)::get(this, "",           "ltsm_rdi_vif",          env_cfg.ltsm_rdi_vif))
        `uvm_fatal("build_phase", "TEST - Unable to get the ltsm_rdi_vif from the uvm_config_db")

    uvm_config_db#(env_config)::set(this, "env", "ENV_CFG", env_cfg);
endfunction : build_phase

// end_of_elaboration_phase
// -------------------------

function void init_pass_test::end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    
    uvm_top.print_topology(); // Prints entire testbench hierarchy 
endfunction : end_of_elaboration_phase

// start_of_simulation_phase
// --------------------------

function void init_pass_test::start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    
    `uvm_info("start_of_simulation_phase", $sformatf("=============== Start of %s ===============", this.get_type_name()), UVM_MEDIUM)
endfunction : start_of_simulation_phase

// run_phase
// ---------

task init_pass_test::run_phase(uvm_phase phase);
    super.run_phase(phase);

    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", init_seq.get_type_name()), UVM_MEDIUM)
    init_seq.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", init_seq.get_type_name()), UVM_MEDIUM)

    phase.drop_objection(this);
endtask : run_phase

// final_phase
// -----------

function void init_pass_test::final_phase(uvm_phase phase);
    super.final_phase(phase);
    
    factory.print(0);
    `uvm_info("end_of_simulation_phase", $sformatf("=============== End of %s ===============", this.get_type_name()), UVM_MEDIUM)
endfunction : final_phase

