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
// CLASS: rp_test_base
//
// The rp_test_base class provides common test infrastructure for the
// RX-Path verification environment. It handles environment creation, interface
// configuration retrieval, sequence instantiation, and provides phase-based
// hooks for test execution and reporting. It also provides phase jumping
// mechanism to perform idle and active reset testing.
//
//---------------------------------------------------------------------------

virtual class rp_test_base extends uvm_test;
  `uvm_component_utils(rp_test_base)

  rp_env                env;
  env_config            env_cfg;
  virtual_sequence_base vseq;
  uvm_factory           factory = uvm_factory::get();
  int unsigned          run_count = 3;
  bit                   hit_reset = 0;
  rand bit              hit_reset_during_init;
  rand int              reset_delay_ns;


  // Function: new
  //
  // Creates a new rp_test_base instance and retrieves factory singleton handle.

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

  // Task: main_phase
  //
  // Raises objection, starts virtual sequence on environment sequencer,
  // and drops objection upon completion.

  extern task main_phase(uvm_phase phase);


  // Function: phase_ready_to_end
  //
  // Base test class for the RX-Path testbench, handling environment setup and common test configuration.

  extern virtual function void phase_ready_to_end(uvm_phase phase);


  // Function: final_phase
  //
  // Prints factory configuration and test completion banner.

  extern function void final_phase(uvm_phase phase);

endclass : rp_test_base


//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: rp_test_base
//
//---------------------------------------------------------------------------


// new
// ---

function rp_test_base::new(string name, uvm_component parent);
  super.new(name, parent);
  env_cfg = env_config::type_id::create("env_cfg", this);
endfunction : new

// build_phase
// -----------

function void rp_test_base::build_phase(uvm_phase phase);
  super.build_phase(phase);

  env = rp_env::type_id::create("env", this);

  if(!uvm_config_db#(virtual rp_reset_intf)::get  (this, "", "reset_intf",  env_cfg.reset_intf))
    `uvm_fatal("build_phase", "TEST - Unable to get the reset_intf from the uvm_config_db")
  
  if(!uvm_config_db#(virtual rp_rdi_bfm)::get     (this, "", "rdi_bfm",     env_cfg.rdi_bfm))
    `uvm_fatal("build_phase", "TEST - Unable to get the rdi_vbfm from the uvm_config_db")

  if(!uvm_config_db#(virtual rp_ltsmc_bfm)::get    (this, "", "ltsmc_bfm",    env_cfg.ltsmc_bfm))
    `uvm_fatal("build_phase", "TEST - Unable to get the ltsmc_vbfm from the uvm_config_db")

  if(!uvm_config_db#(virtual rp_rmblink_bfm)::get (this, "", "rmblink_bfm", env_cfg.rmblink_bfm))
    `uvm_fatal("build_phase", "TEST - Unable to get the tx_vbfm from the uvm_config_db")

  uvm_config_db#(env_config)::set(this, "env", "ENV_CFG", env_cfg);
endfunction : build_phase

// end_of_elaboration_phase
// ------------------------

function void rp_test_base::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);

  vseq = virtual_sequence_base::type_id::create("vseq", this);
  uvm_top.print_topology(); // Prints entire testbench hierarchy 
endfunction : end_of_elaboration_phase

// start_of_simulation_phase
// -------------------------

function void rp_test_base::start_of_simulation_phase(uvm_phase phase);
  super.start_of_simulation_phase(phase);
  
  `uvm_info("start_of_simulation_phase", $sformatf("=============== Start of %s ===============", this.get_type_name()), UVM_MEDIUM)
endfunction : start_of_simulation_phase

// main_phase
// ----------

task rp_test_base::main_phase(uvm_phase phase);
  fork
    begin
      // Get the objection object for the current phase
      uvm_objection objection = phase.get_objection();
      
      super.main_phase(phase);
  
      
      // Set the drain time
      if (objection != null) begin
        objection.set_drain_time(this, 4000ns);
      end
  
      phase.raise_objection(this);
      
       `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vseq.get_type_name()), UVM_MEDIUM)
        vseq.start(env.vseqr);
       `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vseq.get_type_name()), UVM_MEDIUM)
  
      phase.drop_objection(this); 
    end
  join_none

  if(hit_reset) begin
    `uvm_info(get_type_name(), "Starting ACTIVE RESETBase test class for the RX-Path testbench, handling environment setup and common test configuration.", UVM_MEDIUM)
    phase.raise_objection(this);
    std::randomize(reset_delay_ns) with { reset_delay_ns dist {[400:1000]:=3, [1001:10000]:=4, [10001:200000]:=3}; };
    `uvm_info(get_type_name(), $sformatf("Jumping backward to the uvm_pre_reset_phase after %0dns delayBase test class for the RX-Path testbench, handling environment setup and common test configuration.", reset_delay_ns), UVM_LOW)
    #(reset_delay_ns);
    phase.drop_objection(this);
    phase.get_objection().set_report_severity_id_override(UVM_WARNING, "OBJTN_CLEAR", UVM_INFO);
    phase.jump(uvm_pre_reset_phase::get());
    hit_reset = 0;
  end
endtask : main_phase

// phase_ready_to_end
// ------------------

function void rp_test_base::phase_ready_to_end(uvm_phase phase);
  super.phase_ready_to_end(phase);
  if(phase.get_imp() == uvm_shutdown_phase::get()) begin
    if(run_count < 2) begin
      phase.jump(uvm_pre_reset_phase::get());
      run_count++;
    end
  end
endfunction : phase_ready_to_end

// final_phase
// -----------

function void rp_test_base::final_phase(uvm_phase phase);
  super.final_phase(phase);
  
  factory.print(0);
  `uvm_info("start_of_simulation_phase", $sformatf("=============== End of %s ===============", this.get_type_name()), UVM_MEDIUM)
endfunction : final_phase
