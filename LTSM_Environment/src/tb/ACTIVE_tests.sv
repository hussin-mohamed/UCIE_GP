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
// CLASS: ACTIVE_test
//
// The ACTIVE_test class provides common test infrastructure for the
// LTSM verification environment. It handles environment creation, interface
// configuration retrieval, sequence instantiation, and provides phase-based
// hooks for test execution and reporting.
//
//------------------------------------------------------------------------------



class ACTIVE_test extends uvm_test;
    `uvm_component_utils(ACTIVE_test)

    LTSM_env env;
    env_config env_cfg;
    uvm_factory factory;

    // sequences to end mbinit
    initialization_success init_success_seq;

    //previous sequence instances
    mbtrain_success mbtrain_success_seq;

    // linkinit virtual sequences
    linkinit_virtual_sequence linkinit_vseq;
    linkinit_reset_rdi linkinit_reset_rdi_seq;
    //active virtual sequences
    active_virtual_sequence active_vseq;

    //L1 virtual sequences
    l1_rx_vs_rsp_l1 l1_rx_seq_rsp_l1;
    l1_rx_vs_refuse_l1 l1_rx_seq_refuse_l1;
    l1_virtual_sequence_rsp_l1 l1_tx_seq_rsp_l1;
    l1_virtual_sequence_rsp_pmnak l1_tx_seq_rsp_pmnak;
    l1_tx_vs_exit_l1 l1_tx_seq_exit_l1;
    l1_rx_exit_l1_vs l1_rx_vseq_exit_l1;


    // Function: new
    //
    // Creates a new ACTIVE_test instance and retrieves factory singleton handle.
    extern function new(string name = "ACTIVE_test", uvm_component parent = null);    


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


endclass : ACTIVE_test

//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------


// new
// ---

function ACTIVE_test::new(string name = "ACTIVE_test", uvm_component parent = null);
    super.new(name, parent);
    factory = uvm_factory::get();
endfunction : new

// build_phase
// -----------
function void ACTIVE_test::build_phase(uvm_phase phase);
    super.build_phase(phase);
    // init sequences
    init_success_seq = initialization_success::type_id::create("init_success_seq");
    //mbtrain sequences
    mbtrain_success_seq = mbtrain_success::type_id::create("mbtrain_success_seq");
    
    //linkinit virtual sequence 
    linkinit_vseq = linkinit_virtual_sequence::type_id::create("linkinit_vseq");
    linkinit_reset_rdi_seq = linkinit_reset_rdi::type_id::create("linkinit_reset_rdi_seq");
    
    //active virtual sequence
    active_vseq = active_virtual_sequence::type_id::create("active_vseq");
    
    // create L1 virtual sequence 
    l1_rx_seq_rsp_l1 = l1_rx_vs_rsp_l1::type_id::create("l1_rx_seq_rsp");
    l1_rx_seq_refuse_l1 = l1_rx_vs_refuse_l1::type_id::create("l1_rx_seq_refuse");
    l1_tx_seq_rsp_l1 = l1_virtual_sequence_rsp_l1::type_id::create("l1_tx_seq_rsp");
    l1_tx_seq_rsp_pmnak = l1_virtual_sequence_rsp_pmnak::type_id::create("l1_tx_seq_rsp_pmnak");
    l1_tx_seq_exit_l1 = l1_tx_vs_exit_l1::type_id::create("l1_tx_seq_exit");
    l1_rx_vseq_exit_l1 = l1_rx_exit_l1_vs::type_id::create("l1_rx_vseq_exit_l1");

    // create environment and configuration objects
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
function void ACTIVE_test::end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    
    uvm_top.print_topology(); // Prints entire testbench hierarchy 
endfunction : end_of_elaboration_phase

// start_of_simulation_phase
// -------------------------
function void ACTIVE_test::start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    
    `uvm_info("start_of_simulation_phase", $sformatf("=============== Start of %s ===============", this.get_type_name()), UVM_MEDIUM)
endfunction : start_of_simulation_phase

// run_phase
// --------------------------

task ACTIVE_test::run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
  
    ////////////test(1) - linkinit to active ,local die request L1 & remote die respond L1  ////////////
    
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", init_success_seq.get_type_name()), UVM_MEDIUM)
    // Start initialization sequence to end mbinit
    init_success_seq.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", init_success_seq.get_type_name()), UVM_MEDIUM)
    
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", linkinit_reset_rdi_seq.get_type_name()), UVM_MEDIUM)
    linkinit_reset_rdi_seq.start(env.v_seqr);
    
    // Start mbtrain sequence to end mbtrain
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", mbtrain_success_seq.get_type_name()), UVM_MEDIUM)
    mbtrain_success_seq.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", mbtrain_success_seq.get_type_name()), UVM_MEDIUM)
    
    
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", linkinit_vseq.get_type_name()), UVM_MEDIUM)
    // Start link initialization virtual sequence
    linkinit_vseq.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", linkinit_vseq.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", active_vseq.get_type_name()), UVM_MEDIUM)
    // Start active virtual sequence
    active_vseq.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", active_vseq.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", l1_tx_seq_rsp_l1.get_type_name()), UVM_MEDIUM)
    //Start L1 virtual sequence
    l1_tx_seq_rsp_l1.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", l1_tx_seq_rsp_l1.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", l1_tx_seq_exit_l1.get_type_name()), UVM_MEDIUM)
    //exit L1 virtual sequence
    l1_tx_seq_exit_l1.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", l1_tx_seq_exit_l1.get_type_name()), UVM_MEDIUM)


  //-------------------------------------------------------------  
   ////////////test(2) - linkinit to active ,local die request L1 & remote die refuse L1  ////////////   
    
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", init_success_seq.get_type_name()), UVM_MEDIUM)
    // Start initialization sequence to end mbinit
    init_success_seq.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", init_success_seq.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", mbtrain_success_seq.get_type_name()), UVM_MEDIUM)
    mbtrain_success_seq.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", mbtrain_success_seq.get_type_name()), UVM_MEDIUM)
    

   `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", linkinit_vseq.get_type_name()), UVM_MEDIUM)
    // Start link initialization virtual sequence
    linkinit_vseq.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", linkinit_vseq.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", active_vseq.get_type_name()), UVM_MEDIUM)
    // Start active virtual sequence
    active_vseq.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", active_vseq.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", l1_tx_seq_rsp_pmnak.get_type_name()), UVM_MEDIUM)
    //start L1 virtual sequence
    l1_tx_seq_rsp_pmnak.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", l1_tx_seq_rsp_pmnak.get_type_name()), UVM_MEDIUM)
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", l1_tx_seq_exit_l1.get_type_name()), UVM_MEDIUM)
    
    l1_tx_seq_rsp_l1.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", l1_tx_seq_exit_l1.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", l1_tx_seq_exit_l1.get_type_name()), UVM_MEDIUM)
    //exit L1 virtual sequence
    l1_tx_seq_exit_l1.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", l1_tx_seq_exit_l1.get_type_name()), UVM_MEDIUM)




 // -------------------------------------------------------------
       ////////////test(3) - linkinit to active ,remote die request L1 & local die respond L1  ////////////

  
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", init_success_seq.get_type_name()), UVM_MEDIUM)
    // Start initialization sequence to end mbinit
    init_success_seq.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", init_success_seq.get_type_name()), UVM_MEDIUM)
    
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", linkinit_reset_rdi_seq.get_type_name()), UVM_MEDIUM)
    linkinit_reset_rdi_seq.start(env.v_seqr);
    
    // Start mbtrain sequence to end mbtrain
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", mbtrain_success_seq.get_type_name()), UVM_MEDIUM)
    mbtrain_success_seq.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", mbtrain_success_seq.get_type_name()), UVM_MEDIUM)
    

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", linkinit_vseq.get_type_name()), UVM_MEDIUM)
    // Start link initialization virtual sequence
    linkinit_vseq.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", linkinit_vseq.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", active_vseq.get_type_name()), UVM_MEDIUM)
    // Start active virtual sequence
    active_vseq.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", active_vseq.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", l1_rx_seq_rsp_l1.get_type_name()), UVM_MEDIUM)
    //start L1 virtual sequence   
    l1_rx_seq_rsp_l1.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", l1_rx_seq_rsp_l1.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", l1_tx_seq_exit_l1.get_type_name()), UVM_MEDIUM)
    //exit L1 virtual sequence
    l1_tx_seq_exit_l1.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", l1_tx_seq_exit_l1.get_type_name()), UVM_MEDIUM)



 // -------------------------------------------------------------
    ////////////test(4) - linkinit to active ,remote die request L1 & local die refuse L1  ////////////

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", init_success_seq.get_type_name()), UVM_MEDIUM)
    // Start initialization sequence to end mbinit
    init_success_seq.start(env.v_seqr);
  //  `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", init_success_seq.get_type_name()), UVM_MEDIUM)
  
  `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", linkinit_reset_rdi_seq.get_type_name()), UVM_MEDIUM)
  linkinit_reset_rdi_seq.start(env.v_seqr);
  
    // Start mbtrain sequence to end mbtrain
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", mbtrain_success_seq.get_type_name()), UVM_MEDIUM)
    mbtrain_success_seq.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", mbtrain_success_seq.get_type_name()), UVM_MEDIUM)
    

   `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", linkinit_vseq.get_type_name()), UVM_MEDIUM)
    // Start link initialization virtual sequence
    linkinit_vseq.start(env.v_seqr);
  //  `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", linkinit_vseq.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", active_vseq.get_type_name()), UVM_MEDIUM)
    // Start active virtual sequence
    active_vseq.start(env.v_seqr);
  //  `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", active_vseq.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", l1_rx_seq_refuse_l1.get_type_name()), UVM_MEDIUM)
    //start L1 virtual sequence
    l1_rx_seq_refuse_l1.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", l1_rx_seq_refuse_l1.get_type_name()), UVM_MEDIUM)


    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", l1_tx_seq_exit_l1.get_type_name()), UVM_MEDIUM)
    //exit L1 virtual sequence
    l1_tx_seq_exit_l1.start(env.v_seqr);
 //   `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", l1_tx_seq_exit_l1.get_type_name()), UVM_MEDIUM)

    //-------------------------------------------------------------
   ////////////test(5) - remote die request exit L1  ////////////
    
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", init_success_seq.get_type_name()), UVM_MEDIUM)
    // Start initialization sequence to end mbinit
    init_success_seq.start(env.v_seqr);
  //  `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", init_success_seq.get_type_name()), UVM_MEDIUM)
  
  `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", linkinit_reset_rdi_seq.get_type_name()), UVM_MEDIUM)
  linkinit_reset_rdi_seq.start(env.v_seqr);
  
    // Start mbtrain sequence to end mbtrain
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", mbtrain_success_seq.get_type_name()), UVM_MEDIUM)
    mbtrain_success_seq.start(env.v_seqr);
  //  `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", mbtrain_success_seq.get_type_name()), UVM_MEDIUM)
    
    
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", linkinit_vseq.get_type_name()), UVM_MEDIUM)
    // Start link initialization virtual sequence
    linkinit_vseq.start(env.v_seqr);
 //   `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", linkinit_vseq.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", active_vseq.get_type_name()), UVM_MEDIUM)
    // Start active virtual sequence
    active_vseq.start(env.v_seqr);
 //   `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", active_vseq.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", l1_tx_seq_rsp_l1.get_type_name()), UVM_MEDIUM)
    //Start L1 virtual sequence
    l1_tx_seq_rsp_l1.start(env.v_seqr);
 //   `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", l1_tx_seq_rsp_l1.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", l1_rx_vseq_exit_l1.get_type_name()), UVM_MEDIUM)
    //exit L1 virtual sequence
    l1_rx_vseq_exit_l1.start(env.v_seqr);
 //   `uvm_info(get_type_name(), $sformatf("Finishing sequence: %s", l1_rx_vseq_exit_l1.get_type_name()), UVM_MEDIUM)

    phase.drop_objection(this);
endtask : run_phase

// final_phase
// -----------

function void ACTIVE_test::final_phase(uvm_phase phase);
    super.final_phase(phase);
    
    factory.print(0);
    `uvm_info("end_of_simulation_phase", $sformatf("=============== End of %s ===============", this.get_type_name()), UVM_MEDIUM)
endfunction : final_phase