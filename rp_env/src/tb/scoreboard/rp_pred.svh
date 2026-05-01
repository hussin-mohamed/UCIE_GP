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


`uvm_analysis_imp_decl(_rmblink)
`uvm_analysis_imp_decl(_ltsm)

//---------------------------------------------------------------------------
//
// CLASS: rp_pred
//
// Predictor for the LTSM-to-link direction. It converts TX/RX LTSM items into
// the rmblink transactions expected from the DUT.
//
//---------------------------------------------------------------------------

class rp_pred extends uvm_component;
  `uvm_component_utils(rp_pred)

  uvm_analysis_imp_rmblink #(rmblink_seq_item,  rp_pred) axp_in_rmblink;
  uvm_analysis_imp_ltsm    #(ltsmc_seq_item,  rp_pred)    axp_in_ltsm;

  uvm_analysis_port #(rdi_seq_item)  results_ap_rdi;
  uvm_analysis_port #(ltsmc_seq_item) results_ap_ltsm;

  ltsmc_seq_item    ltsm_item;
  rmblink_seq_item rmblink_item;

  int unsigned txn_id = 0;

  // Function: new
  //
  // Creates the LTSM-to-link predictor.

  extern function new(string name, uvm_component parent);

  // Function: build_phase
  //
  // Constructs the predictor inputs and output analysis port.

  extern virtual function void build_phase(uvm_phase phase);

  // Task: pre_reset_phase
  //
  // Flushes any queued LTSM items from previous runs and resets the transaction id counter.

  extern virtual task pre_reset_phase(uvm_phase phase);

  // Function: write_rmblink
  //
  // Queues an incoming TX-side LTSM item for prediction.

  extern function void write_rmblink(rmblink_seq_item t);

  // Function: write_ltsm
  //
  // Queues an incoming RX-side LTSM item for prediction.

  extern function void write_ltsm(ltsmc_seq_item t);

  // Function: write_rdi
  //
  // Queues an incoming RDI item. The mailbox is kept for future path support.

  extern function void write_rdi(rdi_seq_item t);

  // Function: get_predicted_ltsm_item
  //
  // Builds the expected ltsm item corresponding.

  extern function ltsmc_seq_item get_predicted_ltsm_item(ltsmc_seq_item _t_ltsm_in, rmblink_seq_item _t_rmblink_in);

  // Function: get_predicted_rdi_item
  //
  // Builds the expected rdi item corresponding.

  extern function rdi_seq_item get_predicted_rdi_item(ltsmc_seq_item _t_ltsm_in, rmblink_seq_item _t_rmblink_in);
endclass : rp_pred

//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: rp_pred
//
//---------------------------------------------------------------------------

// new
// ---

function rp_pred::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void rp_pred::build_phase(uvm_phase phase);
  super.build_phase(phase);
  axp_in_rmblink  = new("axp_in_rmblink", this);
  axp_in_ltsm     = new("axp_in_ltsm", this);
  results_ap_rdi  = new("axp_in_rdi", this);
  results_ap_ltsm = new("results_ap_phy", this);
endfunction : build_phase

// pre_reset_phase
// ---------------

task rp_pred::pre_reset_phase(uvm_phase phase);
  super.pre_reset_phase(phase);
  // ...
endtask : pre_reset_phase

// write_rdi
// --------

function void rp_pred::write_rdi(rdi_seq_item t);
  // ...
endfunction : write_rdi

// write_rmblink
// --------

function void rp_pred::write_rmblink(rmblink_seq_item t);
  // ...
endfunction : write_rmblink

// write_ltsm
// --------

function void rp_pred::write_ltsm(ltsmc_seq_item t);
  // ...
endfunction : write_ltsm

// get_predicted_ltsm_item
// ------------------

function ltsmc_seq_item rp_pred::get_predicted_ltsm_item(ltsmc_seq_item _t_ltsm_in, rmblink_seq_item _t_rmblink_in);
  // ...
endfunction : get_predicted_ltsm_item

// get_predicted_rdi_item
// ------------------

function rdi_seq_item rp_pred::get_predicted_rdi_item(ltsmc_seq_item _t_ltsm_in, rmblink_seq_item _t_rmblink_in);
  // ...
endfunction : get_predicted_rdi_item
