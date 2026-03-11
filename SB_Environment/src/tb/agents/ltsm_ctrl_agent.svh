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
// CLASS: ltsm_ctrl_agent
//
// ...
//
//-----------------------------------------------------------------------------

class ltsm_ctrl_agent extends uvm_agent;

  virtual sb_ltsm_ctrl_bfm    bfm;
  ltsm_ctrl_sequencer seqr;
  ltsm_ctrl_driver    drvr;
  agent_config #(virtual sb_ltsm_ctrl_bfm) cfg;


  // This field determines whether an agent is active or passive.
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  // Provide implementations of virtual methods such as get_type_name and create
  `uvm_component_utils_begin(ltsm_ctrl_agent)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
  `uvm_component_utils_end


  // Function: new
  //
  // Creates a new agent instance with the given name.

  extern function new(string name, uvm_component parent);


  // Function: build_phase
  //
  // Retrieves agent configuration from config_db and creates monitor. If configured
  // as active agent, also creates driver and sequencer and their analysis ports.

  extern function void build_phase(uvm_phase phase);


  // Function: connect_phase
  //
  // Connects monitor to its interface and analysis port. For active agents,
  // connects driver to sequencer, assigns interface, and connects driver analysis port.

  extern function void connect_phase(uvm_phase phase);

  extern task pre_reset_phase(uvm_phase phase);

endclass : ltsm_ctrl_agent


//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS- agent
//
//---------------------------------------------------------------------------


// new
// ---

function ltsm_ctrl_agent::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void ltsm_ctrl_agent::build_phase(uvm_phase phase);
  super.build_phase(phase);

  if(!uvm_config_db#(agent_config #(virtual sb_ltsm_ctrl_bfm))::get(this, "", "ltsm_ctrl_cfg", cfg))
    `uvm_fatal("build_phase", $sformatf("AGENT - Unable to get the agent configuration object from the uvm_config_db, CFG_NAME: ltsm_ctrl_cfg, agent name: %s", this.get_full_name()))

  if (cfg != null) is_active = cfg.is_active;

  if(is_active == UVM_ACTIVE) begin
    drvr = ltsm_ctrl_driver::type_id::create("drvr", this);
    seqr = ltsm_ctrl_sequencer::type_id::create("seqr", this);
  end

endfunction : build_phase

// connect_phase
// -------------

function void ltsm_ctrl_agent::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  if(is_active == UVM_ACTIVE) begin
    drvr.seq_item_port.connect(seqr.seq_item_export);
    drvr.bfm = cfg.bfm;
  end
endfunction : connect_phase

// pre_reset_phase
// ---------------

task ltsm_ctrl_agent::pre_reset_phase(uvm_phase phase);
  super.pre_reset_phase(phase);

  if((is_active == UVM_ACTIVE) && seqr && drvr) begin
    seqr.stop_sequences();
    ->drvr.reset_driver;
  end
endtask : pre_reset_phase
