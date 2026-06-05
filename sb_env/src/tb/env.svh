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
// CLASS: sb_env
//
// The sb_env class provides the top-level UVM environment for the Sideband
// testbench. It instantiates all agents, scoreboards, and the virtual sequencer,
// manages configuration objects, and establishes all analysis port connections
// for the verification infrastructure.
//
//-----------------------------------------------------------------------------

class sb_env extends uvm_env;
  `uvm_component_utils(sb_env)

  sb_scoreboard sb;

  sb_coverage_collector cvg;

  reset_driver rst_drvr;

  ltsm_ctrl_agent ltsm_ctrl_agt;
  tx_agent        tx_agt;
  rx_agent        rx_agt;
  // rdi_agent       rdi_agt;
  phylink_agent   phylink_agt;

  env_config env_cfg;

  ltsm_ctrl_cfg_t  ltsm_ctrl_cfg;
  tx_cfg_t         tx_cfg;
  rx_cfg_t         rx_cfg;
  // rdi_cfg_t        rdi_cfg;
  phylink_cfg_t    phylink_cfg;

  virtual_sequencer vseqr;


  // Function: new
  //
  // Creates a new sb_env instance with the given name and parent.

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


  // Function: configure_ltsm_ctrl_agent
  //
  // Configures the LTSM control agent with interface and activity settings.

  extern function void configure_ltsm_ctrl_agent();


  // Function: configure_tx_agent
  //
  // Configures the Sideband TX agent with interface and activity settings.

  extern function void configure_tx_agent();


  // Function: configure_rx_agent
  //
  // Configures the Sideband RX agent with interface and activity settings.

  extern function void configure_rx_agent();


  // Function: configure_rdi_agent
  //
  // Configures the RDI agent with interface and activity settings.

  // extern function void configure_rdi_agent();


  // Function: configure_phylink_agent
  //
  // Configures the Sideband phylink agent with interface and activity settings.

  extern function void configure_phylink_agent();

  // Function: report_phase
  //
  // Performs end-of-simulation checks to verify transaction counts across agents.

  extern virtual function void report_phase(uvm_phase phase);

endclass : sb_env


//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: sb_env
//
//---------------------------------------------------------------------------


// new
// ---

function sb_env::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void sb_env::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  sb = sb_scoreboard::type_id::create("sb", this);
  
  cvg = sb_coverage_collector::type_id::create("cvg", this);

`ifndef UCIE_SYS_LVL
  rst_drvr = reset_driver::type_id::create("rst_drvr", this);
`endif

  ltsm_ctrl_agt = ltsm_ctrl_agent::type_id::create("ltsm_ctrl_agt", this);
  tx_agt        = tx_agent::type_id::create("tx_agt", this);
  rx_agt        = rx_agent::type_id::create("rx_agt", this);
  // rdi_agt       = rdi_agent::type_id::create("rdi_agt", this);
  phylink_agt   = phylink_agent::type_id::create("phylink_agt", this);

  ltsm_ctrl_cfg = ltsm_ctrl_cfg_t::type_id::create("ltsm_ctrl_cfg");
  tx_cfg        = tx_cfg_t::type_id::create("tx_cfg");
  rx_cfg        = rx_cfg_t::type_id::create("rx_cfg");
  // rdi_cfg       = rdi_cfg_t::type_id::create("rdi_cfg");
  phylink_cfg   = phylink_cfg_t::type_id::create("phylink_cfg");

  vseqr = virtual_sequencer::type_id::create("vseqr", this);

  if(!uvm_config_db#(env_config)::get(this, "", "ENV_CFG", env_cfg))
    `uvm_fatal("build_phase", "ENV - Unable to environment configuration object from the uvm_config_db")

  configure_agents();

  uvm_config_db#(virtual sb_reset_intf)::set (this, "rst_drvr",      "reset_intf",    env_cfg.reset_intf);
  uvm_config_db#(ltsm_ctrl_cfg_t)::set       (this, "ltsm_ctrl_agt", "ltsm_ctrl_cfg", ltsm_ctrl_cfg);
  uvm_config_db#(tx_cfg_t)::set              (this, "tx_agt",        "tx_cfg",        tx_cfg);
  uvm_config_db#(rx_cfg_t)::set              (this, "rx_agt",        "rx_cfg",        rx_cfg);
  // uvm_config_db#(rdi_cfg_t)::set             (this, "rdi_agt",       "rdi_cfg",       rdi_cfg);
  uvm_config_db#(phylink_cfg_t)::set         (this, "phylink_agt",   "phylink_cfg",   phylink_cfg);
endfunction : build_phase

// connect_phase
// -------------

function void sb_env::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  phylink_agt.in_ap.connect(cvg.phylink_exp);

  tx_agt.in_ap.connect(sb.axp_in_tx);
  rx_agt.in_ap.connect(sb.axp_in_rx);
  // rdi_agt.in_ap.connect(sb.axp_in_rdi);
  phylink_agt.in_ap.connect(sb.axp_in_phy);

  tx_agt.out_ap.connect(sb.axp_out_rx);
  rx_agt.out_ap.connect(sb.axp_out_tx);
  // rdi_agt.out_ap.connect(sb.axp_out_rdi);
  phylink_agt.out_ap.connect(sb.axp_out_phy);

  vseqr.ltsm_ctrl_seqr = ltsm_ctrl_agt.seqr;
  vseqr.tx_seqr        = tx_agt.seqr;
  vseqr.rx_seqr        = rx_agt.seqr;
  // vseqr.rdi_seqr       = rdi_agt.seqr;
  vseqr.phylink_seqr   = phylink_agt.seqr;
endfunction : connect_phase


// pre_reset_phase
// ---------------

task sb_env::pre_reset_phase(uvm_phase phase);
  super.pre_reset_phase(phase);
  vseqr.stop_sequences();
endtask : pre_reset_phase


// configure_agents
// ----------------

function void sb_env::configure_agents();
  configure_ltsm_ctrl_agent();
  configure_tx_agent();
  configure_rx_agent();
  // configure_rdi_agent();
  configure_phylink_agent();
endfunction : configure_agents

// configure_ltsm_ctrl_agent
// -------------------------

function void sb_env::configure_ltsm_ctrl_agent();
  ltsm_ctrl_cfg.bfm        = env_cfg.ltsm_ctrl_bfm;
  ltsm_ctrl_cfg.is_active  = env_cfg.is_active_ltsm_ctrl;
  ltsm_ctrl_cfg.is_reactive = env_cfg.is_reactive_ltsm_ctrl;
endfunction : configure_ltsm_ctrl_agent

// configure_tx_agent
// ------------------

function void sb_env::configure_tx_agent();
  tx_cfg.bfm          = env_cfg.tx_bfm;
  tx_cfg.is_active    = env_cfg.is_active_tx;
  tx_cfg.is_reactive  = env_cfg.is_reactive_tx;
endfunction : configure_tx_agent

// configure_rx_agent
// ------------------

function void sb_env::configure_rx_agent();
  rx_cfg.bfm          = env_cfg.rx_bfm;
  rx_cfg.is_active    = env_cfg.is_active_rx;
  rx_cfg.is_reactive  = env_cfg.is_reactive_rx;
endfunction : configure_rx_agent

// configure_rdi_agent
// -------------------

// function void sb_env::configure_rdi_agent();
//   rdi_cfg.bfm         =   env_cfg.rdi_bfm;
//   rdi_cfg.is_active   =   env_cfg.is_active_rdi;
//   rdi_cfg.is_reactive =   env_cfg.is_reactive_rdi;
// endfunction : configure_rdi_agent

// configure_phylink_agent
// -----------------------

function void sb_env::configure_phylink_agent();
  phylink_cfg.bfm         =   env_cfg.phylink_bfm;
  phylink_cfg.bfm_drive         =   env_cfg.phylink_bfm_drive;
  phylink_cfg.is_active   =   env_cfg.is_active_phylink;
  phylink_cfg.is_reactive =   env_cfg.is_reactive_phylink;
endfunction : configure_phylink_agent

// report_phase
// ------------

function void sb_env::report_phase(uvm_phase phase);
  super.report_phase(phase);

  assert ((tx_agt.mntr.txn_in_cnt + rx_agt.mntr.txn_in_cnt) == phylink_agt.mntr.txn_out_cnt) else
    `uvm_warning(get_type_name(), $sformatf(
      "Sum of TX driven (%0d) and RX driven (%0d) transactions does not equal the total transactions captured by the Phylink monitor (%0d)",
      tx_agt.mntr.txn_in_cnt, rx_agt.mntr.txn_in_cnt, phylink_agt.mntr.txn_out_cnt));

  assert ((phylink_agt.mntr.txn_in_cnt - sb.prd_link2ltsm.invalid_msg_cnt) == (tx_agt.mntr.txn_out_cnt + rx_agt.mntr.txn_out_cnt)) else
    `uvm_warning(get_type_name(), $sformatf(
      "Total valid transactions driven by the Phylink driver (%0d) does not equal the sum of transactions captured by the TX monitor (%0d) and RX monitor (%0d)",
      (phylink_agt.mntr.txn_in_cnt - sb.prd_link2ltsm.invalid_msg_cnt), tx_agt.mntr.txn_out_cnt, rx_agt.mntr.txn_out_cnt));
endfunction : report_phase
