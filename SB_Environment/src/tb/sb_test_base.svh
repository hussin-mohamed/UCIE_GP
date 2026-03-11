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

//---------------------------------------------------------------------------
//
// CLASS: sb_test_base
//
// The sb_test_base class provides common test infrastructure for the
// sideband verification environment. It handles environment creation, interface
// configuration retrieval, sequence instantiation, and provides phase-based
// hooks for test execution and reporting.
//
//---------------------------------------------------------------------------

class sb_test_base extends uvm_test;
  `uvm_component_utils(sb_test_base)

  sb_env           env;
  env_config       env_cfg;
  // virtual_sequence v_seq;
  uvm_factory      factory = uvm_factory::get();


  // Function: new
  //
  // Creates a new sb_test_base instance and retrieves factory singleton handle.

  extern function new(string name, uvm_component parent);


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

endclass : sb_test_base


//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS- sb_test_base
//
//---------------------------------------------------------------------------


// new
// ---

function sb_test_base::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void sb_test_base::build_phase(uvm_phase phase);
  super.build_phase(phase);

  env = sb_env::type_id::create("env", this);
  env_cfg = env_config::type_id::create("env_cfg", this);

  if(!uvm_config_db#(virtual sb_reset_intf)::get     (this, "", "reset_intf",   env_cfg.reset_intf))
    `uvm_fatal("build_phase", "TEST - Unable to get the reset_intf from the uvm_config_db")

  if(!uvm_config_db#(virtual sb_ltsm_ctrl_bfm)::get (this, "", "ltsm_ctrl_bfm", env_cfg.ltsm_ctrl_bfm))
    `uvm_fatal("build_phase", "TEST - Unable to get the ltsm_ctrl_vbfm from the uvm_config_db")

  if(!uvm_config_db#(virtual sb_tx_bfm)::get        (this, "", "tx_bfm",        env_cfg.tx_bfm))
    `uvm_fatal("build_phase", "TEST - Unable to get the tx_vbfm from the uvm_config_db")

  if(!uvm_config_db#(virtual sb_rx_bfm)::get        (this, "", "rx_bfm",        env_cfg.rx_bfm))
    `uvm_fatal("build_phase", "TEST - Unable to get the rx_vbfm from the uvm_config_db")

  if(!uvm_config_db#(virtual sb_rdi_bfm)::get       (this, "", "rdi_bfm",       env_cfg.rdi_bfm))
    `uvm_fatal("build_phase", "TEST - Unable to get the rdi_vbfm from the uvm_config_db")

  if(!uvm_config_db#(virtual sb_phylink_bfm)::get   (this, "", "phylink_bfm",   env_cfg.phylink_bfm))
    `uvm_fatal("build_phase", "TEST - Unable to get the phylink_vbfm from the uvm_config_db")

  uvm_config_db#(env_config)::set(this, "env", "ENV_CFG", env_cfg);
endfunction : build_phase

// end_of_elaboration_phase
// -------------------------

function void sb_test_base::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  
  // v_seq = virtual_sequence::type_id::create("v_seq", this);
  uvm_top.print_topology(); // Prints entire testbench hierarchy 
endfunction : end_of_elaboration_phase

// start_of_simulation_phase
// --------------------------

function void sb_test_base::start_of_simulation_phase(uvm_phase phase);
  super.start_of_simulation_phase(phase);
  
  `uvm_info("start_of_simulation_phase", $sformatf("=============== Start of %s ===============", this.get_type_name()), UVM_MEDIUM)
endfunction : start_of_simulation_phase

// run_phase
// ---------

task sb_test_base::run_phase(uvm_phase phase);
  super.run_phase(phase);

  phase.raise_objection(this);
  
  // `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", v_seq.get_type_name()), UVM_MEDIUM)
  // v_seq.start(env.v_seqr); ///////////////// **************
  // `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", v_seq.get_type_name()), UVM_MEDIUM)

  phase.drop_objection(this);
endtask : run_phase

// final_phase
// -----------

function void sb_test_base::final_phase(uvm_phase phase);
  super.final_phase(phase);
  
  factory.print(0);
  `uvm_info("start_of_simulation_phase", $sformatf("=============== End of %s ===============", this.get_type_name()), UVM_MEDIUM)
endfunction : final_phase
