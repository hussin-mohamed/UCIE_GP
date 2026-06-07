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
// CLASS: rp_agent_base
//
// The rp_agent_base class is a parameterized base class for all RX-Path agents.
// It handles common tasks like configuration retrieval, monitor and driver
// instantiation, and analysis port connections.
//
//-----------------------------------------------------------------------------

virtual class rp_agent_base #(
   string CFG_NAME
  ,type   INTF_T
  ,type   ITEM_T
  ,type   SEQR_T
  ,type   DRVR_T
  ,type   MNTR_T
) extends uvm_agent;

  INTF_T                 bfm;
  SEQR_T                 seqr;
  DRVR_T                 drvr;
  MNTR_T                 mntr;
  agent_config #(INTF_T) cfg;

  uvm_analysis_port #(ITEM_T) in_ap, out_ap;
  
  // This field determines whether an agent is active or passive.
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  // Function: new
  //
  // Creates a new parameterized rp_agent_base instance.
  
  extern function new(string name, uvm_component parent);

  // Function: build_phase
  //
  // Retrieves configuration, instantiates monitor, and conditionally
  // instantiates driver and sequencer if the agent is active.
  
  extern function void build_phase(uvm_phase phase);

  // Function: connect_phase
  //
  // Connects the monitor analysis ports and, if active, connects the
  // driver to the sequencer and assigns the BFM handle.
  
  extern function void connect_phase(uvm_phase phase);

  // Task: pre_reset_phase
  //
  // Stops any running sequences and triggers a driver reset if active.
  
  extern task pre_reset_phase(uvm_phase phase);
endclass : rp_agent_base


//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

// new
// ---

function rp_agent_base::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new


// build_phase
// -----------

function void rp_agent_base::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  if(!uvm_config_db#(agent_config #(INTF_T))::get(this, "", CFG_NAME, cfg))
    `uvm_fatal("build_phase", $sformatf("AGENT - Unable to get the agent configuration object from the uvm_config_db, CFG_NAME: %s, agent name: %s", CFG_NAME, this.get_full_name()))

  mntr = MNTR_T::type_id::create("mntr", this);
  
  if (cfg != null) is_active = cfg.is_active;

  if(is_active == UVM_ACTIVE) begin
    // Create driver and sequencer for active agents
    drvr = DRVR_T::type_id::create("drvr", this);
    seqr = SEQR_T::type_id::create("seqr", this);
  end

  // Initialize analysis ports
  in_ap = new("in_ap", this);
  out_ap = new("out_ap", this);
endfunction : build_phase


// connect_phase
// -------------

function void rp_agent_base::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  mntr.out_ap.connect(out_ap);
  mntr.in_ap.connect(in_ap);
  mntr.bfm = cfg.bfm;

  if(is_active == UVM_ACTIVE) begin
    drvr.seq_item_port.connect(seqr.seq_item_export);
    mntr.reactive_ap.connect(seqr.reactive_exp);
    `ifdef UCIE_SYS_LVL
    drvr.bfm = cfg.bfm_drive;
    `else
    drvr.bfm = cfg.bfm;
    `endif
  end
endfunction : connect_phase


// pre_reset_phase
// ---------------

task rp_agent_base::pre_reset_phase(uvm_phase phase);
  super.pre_reset_phase(phase);
  if((is_active == UVM_ACTIVE) && seqr && drvr) begin
    seqr.stop_sequences();
    ->drvr.reset_driver;
  end
endtask : pre_reset_phase
