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
// The ltsm_ctrl_agent owns the sequencer and driver that stimulate the SBINIT
// control interface. This agent is specialized for the initialization-control
// path and therefore manages only the active control components needed to
// launch and restart sideband initialization.
//
//-----------------------------------------------------------------------------

class ltsm_ctrl_agent extends uvm_agent;

  virtual sb_ltsm_ctrl_bfm    bfm;
  ltsm_ctrl_sequencer seqr;
  ltsm_ctrl_driver    drvr;
  agent_config #(virtual sb_ltsm_ctrl_bfm) cfg;


  // This field determines whether an agent is active or passive.
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  // Factory registration for the concrete control agent type.
  `uvm_component_utils_begin(ltsm_ctrl_agent)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
  `uvm_component_utils_end


  // Function: new
  //
  // Creates a new agent instance with the given name.

  extern function new(string name, uvm_component parent);


  // Function: build_phase
  //
  // Retrieves the control-agent configuration and, when active, creates the
  // control driver and sequencer.

  extern function void build_phase(uvm_phase phase);


  // Function: connect_phase
  //
  // Connects the control driver to the sequencer and assigns the virtual
  // interface handle when the agent is active.

  extern function void connect_phase(uvm_phase phase);

  // Task: pre_reset_phase
  //
  // Stops any running control sequences and notifies the driver to terminate
  // its active drive thread before reset is applied.

  extern task pre_reset_phase(uvm_phase phase);

endclass : ltsm_ctrl_agent


//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: ltsm_ctrl_agent
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
