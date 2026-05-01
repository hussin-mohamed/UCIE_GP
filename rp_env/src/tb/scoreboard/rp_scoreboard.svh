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
// CLASS: rp_scoreboard
//
// Top-level scoreboard wrapper that connects the sideband predictors and
// comparators for both LTSM-to-link and link-to-LTSM checking paths.
//
//---------------------------------------------------------------------------

class rp_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(rp_scoreboard)

  // --- Inputs from Drivers (Stimulus) ---
  uvm_analysis_export #(rmblink_seq_item)  axp_in_rmblink;
  uvm_analysis_export #(ltsmc_seq_item)    axp_in_ltsm;

  // --- Outputs from Monitors (Actuals) ---
  uvm_analysis_export #(rdi_seq_item)      axp_out_rdi;
  uvm_analysis_export #(ltsmc_seq_item)    axp_out_ltsm;

  // --- Components ---
  rp_pred prd;
  
  rp_cmp_rdi  cmp_rdi;
  rp_cmp_ltsm cmp_ltsm;

  // Function: new
  //
  // Creates the scoreboard component.

  extern function new(string name, uvm_component parent);

  // Function: build_phase
  //
  // Constructs the analysis exports, predictors, and comparator instances.

  extern function void build_phase(uvm_phase phase);

  // Function: connect_phase
  //
  // Connects the wrapper exports to the predictor/comparator pipelines.

  extern function void connect_phase(uvm_phase phase);
endclass : rp_scoreboard

//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: rp_scoreboard
//
//---------------------------------------------------------------------------

// new
// ---

function rp_scoreboard::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void rp_scoreboard::build_phase(uvm_phase phase);
  super.build_phase(phase);

  // Construct exports
  axp_in_rmblink = new("axp_in_rmblink", this);
  axp_in_ltsm    = new("axp_in_ltsm",    this);
  axp_out_rdi    = new("axp_out_rdi",    this);
  axp_out_ltsm   = new("axp_out_ltsm",   this);

  // Factory create components
  prd      = rp_pred::type_id::create("prd", this);
  cmp_rdi  = rp_cmp_rdi::type_id::create("cmp_rdi", this);
  cmp_ltsm = rp_cmp_ltsm::type_id::create("cmp_ltsm", this);
endfunction : build_phase

// connect_phase
// -------------

function void rp_scoreboard::connect_phase(uvm_phase phase);
  // Connect wrapper inputs to predictor inputs
  axp_in_rmblink.connect(prd.axp_in_rmblink);
  axp_in_ltsm.connect(prd.axp_in_ltsm);
  
  // Connect predictor output to comparator expected input
  prd.results_ap_rdi.connect(cmp_rdi.axp_in_exp);
  prd.results_ap_ltsm.connect(cmp_ltsm.axp_in_exp);
  
  // Connect wrapper actual output to comparator actual input
  axp_out_rdi.connect(cmp_rdi.axp_out_actual);
  axp_out_ltsm.connect(cmp_ltsm.axp_out_actual);
endfunction : connect_phase
