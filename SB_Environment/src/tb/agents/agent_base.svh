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
// CLASS: agent_base
//
//-----------------------------------------------------------------------------

virtual class agent_base #(
  string CFG_NAME = "tx_cfg",
  type   INTF_T   = virtual sb_tx_bfm,
  type   ITEM_T   = ltsm_seq_item,
  type   SEQR_T   = tx_sequencer, // Parameterized Sequencer
  type   DRVR_T   = tx_driver,    // Parameterized Driver
  type   MNTR_T   = tx_monitor    // Parameterized Monitor
) extends uvm_agent;

  INTF_T            bfm;
  SEQR_T            seqr;
  DRVR_T            drvr;
  MNTR_T            mntr;
  agent_config #(INTF_T) cfg;

  uvm_analysis_port #(ITEM_T) drvr_ap, mntr_ap;
  
  // This field determines whether an agent is active or passive.
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  
  // Provide implementations of virtual methods such as get_type_name and create
  // `uvm_component_param_utils_begin(agent_base #(CFG_NAME, INTF_T, ITEM_T, SEQR_T, DRVR_T, MNTR_T))
  //   `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
  // `uvm_component_utils_end

  extern function new(string name, uvm_component parent);
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
  extern task pre_reset_phase(uvm_phase phase);

endclass : agent_base

//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

function agent_base::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

function void agent_base::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  if(!uvm_config_db#(agent_config #(INTF_T))::get(this, "", CFG_NAME, cfg))
    `uvm_fatal("build_phase", $sformatf("AGENT - Unable to get the agent configuration object from the uvm_config_db, CFG_NAME: %s, agent name: %s", CFG_NAME, this.get_full_name()))

  // Use the parameterized type for creation!
  mntr = MNTR_T::type_id::create("mntr", this);
  
  if (cfg != null) is_active = cfg.is_active;

  if(is_active == UVM_ACTIVE) begin
    // Use the parameterized types for creation!
    drvr    = DRVR_T::type_id::create("drvr", this);
    seqr    = SEQR_T::type_id::create("seqr", this);
    drvr_ap = new("drvr_ap", this);
  end

  mntr_ap = new("mntr_ap", this);
endfunction : build_phase

function void agent_base::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  mntr.ap.connect(mntr_ap);
  mntr.bfm = cfg.bfm;
  
  if(is_active == UVM_ACTIVE) begin
    drvr.seq_item_port.connect(seqr.seq_item_export);
    drvr.bfm = cfg.bfm;
    drvr.ap.connect(drvr_ap);
  end
endfunction : connect_phase

task agent_base::pre_reset_phase(uvm_phase phase);
  super.pre_reset_phase(phase);
  if((is_active == UVM_ACTIVE) && seqr && drvr) begin
    seqr.stop_sequences();
    ->drvr.reset_driver;
  end
endtask : pre_reset_phase