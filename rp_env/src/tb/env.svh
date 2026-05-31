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
// CLASS: rp_env
//
// The rp_env class provides the top-level UVM environment for the RX-Path
// testbench. It instantiates all agents, scoreboards, and the virtual sequencer,
// manages configuration objects, and establishes all analysis port connections
// for the verification infrastructure.
//
//-----------------------------------------------------------------------------

class rp_env extends uvm_env;
  `uvm_component_utils(rp_env)

  rp_scoreboard sb;

  // rp_coverage_collector cvg;

  reset_driver    rst_drvr;

  rdi_agent       rdi_agt;
  ltsmc_agent      ltsmc_agt;
  rmblink_agent   rmblink_agt;

  env_config      env_cfg;

  rdi_cfg_t       rdi_cfg;
  ltsmc_cfg_t      ltsmc_cfg;
  rmblink_cfg_t   rmblink_cfg;

  virtual_sequencer vseqr;


  // Function: new
  //
  // Creates a new rp_env instance with the given name and parent.

  extern function new(string name, uvm_component parent);


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

  // Task: pre_reset_phase
  //
  // Handles cleanup and sequence stopping prior to reset.

  extern task pre_reset_phase(uvm_phase phase);


  // Function: configure_agents
  //
  // Calls individual agent configuration functions to set up all agent
  // configuration objects with appropriate settings.

  extern function void configure_agents();


  // Function: configure_rdi_agent
  //
  // Configures the RDI agent with interface and activity settings.

  extern function void configure_rdi_agent();
  

  // Function: configure_ltsmc_agent
  //
  // Configures the LTSM control agent with interface and activity settings.

  extern function void configure_ltsmc_agent();


  // Function: configure_rmblink_agent
  //
  // Configures the RX-Path rmblink agent with interface and activity settings.

  extern function void configure_rmblink_agent();

  // Function: report_phase
  //
  // Performs end-of-simulation checks to verify transaction counts across agents.

  extern virtual function void report_phase(uvm_phase phase);

endclass : rp_env


//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: rp_env
//
//---------------------------------------------------------------------------


// new
// ---

function rp_env::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void rp_env::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  sb = rp_scoreboard::type_id::create("sb", this);
  
  // cvg = rp_coverage_collector::type_id::create("cvg", this);

  `ifndef UCIE_SYS_LVL
    rst_drvr = reset_driver::type_id::create("rst_drvr", this);
  `endif

  rdi_agt       = rdi_agent::type_id::create("rdi_agt", this);
  ltsmc_agt      = ltsmc_agent::type_id::create("ltsmc_agt", this);
  rmblink_agt   = rmblink_agent::type_id::create("rmblink_agt", this);

  rdi_cfg       = rdi_cfg_t::type_id::create("rdi_cfg");
  ltsmc_cfg      = ltsmc_cfg_t::type_id::create("ltsmc_cfg");
  rmblink_cfg   = rmblink_cfg_t::type_id::create("rmblink_cfg");

  vseqr = virtual_sequencer::type_id::create("vseqr", this);

  if(!uvm_config_db#(env_config)::get(this, "", "ENV_CFG", env_cfg))
    `uvm_fatal("build_phase", "ENV - Unable to environment configuration object from the uvm_config_db")

  configure_agents();

  uvm_config_db#(virtual rp_reset_intf)::set (this, "rst_drvr",      "reset_intf",    env_cfg.reset_intf);
  uvm_config_db#(rdi_cfg_t)::set             (this, "rdi_agt",       "rdi_cfg",       rdi_cfg);
  uvm_config_db#(ltsmc_cfg_t)::set            (this, "ltsmc_agt",      "ltsmc_cfg",      ltsmc_cfg);
  uvm_config_db#(rmblink_cfg_t)::set         (this, "rmblink_agt",   "rmblink_cfg",   rmblink_cfg);
endfunction : build_phase

// connect_phase
// -------------

function void rp_env::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  // rmblink_agt.in_ap.connect(cvg.rmblink_exp);

  rmblink_agt.in_ap.connect(sb.axp_in_rmblink);
  ltsmc_agt.in_ap.connect(sb.axp_in_ltsmc);

  rdi_agt.out_ap.connect(sb.axp_out_rdi);
  ltsmc_agt.out_ap.connect(sb.axp_out_ltsmc);

  vseqr.rdi_seqr     = rdi_agt.seqr;
  vseqr.ltsmc_seqr    = ltsmc_agt.seqr;
  vseqr.rmblink_seqr = rmblink_agt.seqr;
endfunction : connect_phase


// pre_reset_phase
// ---------------

task rp_env::pre_reset_phase(uvm_phase phase);
  super.pre_reset_phase(phase);
  vseqr.stop_sequences();
endtask : pre_reset_phase


// configure_agents
// ----------------

function void rp_env::configure_agents();
  configure_rdi_agent();
  configure_ltsmc_agent();
  configure_rmblink_agent();
endfunction : configure_agents

// configure_ltsmc_agent
// -------------------------

function void rp_env::configure_ltsmc_agent();
  ltsmc_cfg.bfm         = env_cfg.ltsmc_bfm;
  ltsmc_cfg.is_active   = env_cfg.is_active_ltsmc;
  ltsmc_cfg.is_reactive = env_cfg.is_reactive_ltsmc;
endfunction : configure_ltsmc_agent

// configure_rdi_agent
// -------------------

function void rp_env::configure_rdi_agent();
  rdi_cfg.bfm         =   env_cfg.rdi_bfm;
  rdi_cfg.is_active   =   env_cfg.is_active_rdi;
  rdi_cfg.is_reactive =   env_cfg.is_reactive_rdi;
endfunction : configure_rdi_agent

// configure_rmblink_agent
// -----------------------

function void rp_env::configure_rmblink_agent();
  rmblink_cfg.bfm         =   env_cfg.rmblink_bfm;
  rmblink_cfg.bfm_drive         =   env_cfg.rmblink_bfm_drive;
  rmblink_cfg.is_active   =   env_cfg.is_active_rmblink;
  rmblink_cfg.is_reactive =   env_cfg.is_reactive_rmblink;
endfunction : configure_rmblink_agent

// report_phase
// ------------

function void rp_env::report_phase(uvm_phase phase);
  super.report_phase(phase);

  // assert ((tx_agt.mntr.txn_in_cnt + rx_agt.mntr.txn_in_cnt) == rmblink_agt.mntr.txn_out_cnt) else
  //   `uvm_warning(get_type_name(), $sformatf(
  //     "Sum of TX driven (%0d) and RX driven (%0d) transactions does not equal the total transactions captured by the Phylink monitor (%0d)",
  //     tx_agt.mntr.txn_in_cnt, rx_agt.mntr.txn_in_cnt, rmblink_agt.mntr.txn_out_cnt));

  // assert ((rmblink_agt.mntr.txn_in_cnt - sb.prd_link2ltsm.invalid_msg_cnt) == (tx_agt.mntr.txn_out_cnt + rx_agt.mntr.txn_out_cnt)) else
  //   `uvm_warning(get_type_name(), $sformatf(
  //     "Total valid transactions driven by the Phylink driver (%0d) does not equal the sum of transactions captured by the TX monitor (%0d) and RX monitor (%0d)",
  //     (rmblink_agt.mntr.txn_in_cnt - sb.prd_link2ltsm.invalid_msg_cnt), tx_agt.mntr.txn_out_cnt, rx_agt.mntr.txn_out_cnt));
endfunction : report_phase
