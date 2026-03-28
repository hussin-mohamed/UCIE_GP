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
// CLASS: sb_scoreboard
//
// Description: ...
//---------------------------------------------------------------------------

class sb_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(sb_scoreboard)

  // --- Inputs from Drivers (Stimulus) ---
  uvm_analysis_export #(ltsm_seq_item)    axp_in_tx;
  uvm_analysis_export #(ltsm_seq_item)    axp_in_rx;
  uvm_analysis_export #(rdi_seq_item)     axp_in_rdi;
  uvm_analysis_export #(phylink_seq_item) axp_in_phy;

  // --- Outputs from Monitors (Actuals) ---
  uvm_analysis_export #(ltsm_seq_item)     axp_out_tx;
  uvm_analysis_export #(ltsm_seq_item)     axp_out_rx;
  uvm_analysis_export #(rdi_seq_item)      axp_out_rdi;
  uvm_analysis_export #(phylink_seq_item)  axp_out_phy;

  // --- Components ---
  sb_pred_ltsm2link     prd_ltsm2link;
  sb_cmp_ltsm2link      cmp_ltsm2link;
  
  sb_pred_link2ltsm     prd_link2ltsm;
  sb_cmp_link2ltsm_tx   cmp_link2ltsm_tx;
  sb_cmp_link2ltsm_rx   cmp_link2ltsm_rx;
  sb_cmp_link2ltsm_rdi  cmp_link2ltsm_rdi;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Construct exports
    axp_in_tx   = new("axp_in_tx", this);
    axp_in_rx   = new("axp_in_rx", this);
    axp_in_rdi  = new("axp_in_rdi", this);
    axp_in_phy  = new("axp_in_phy", this);

    axp_out_tx  = new("axp_out_tx", this);
    axp_out_rx  = new("axp_out_rx", this);
    axp_out_rdi = new("axp_out_rdi", this);
    axp_out_phy = new("axp_out_phy", this);

    // Factory create components
    prd_ltsm2link     = sb_pred_ltsm2link::type_id::create("prd_ltsm2link", this);
    cmp_ltsm2link     = sb_cmp_ltsm2link::type_id::create("cmp_ltsm2link", this);
    
    prd_link2ltsm     = sb_pred_link2ltsm::type_id::create("prd_link2ltsm", this);
    cmp_link2ltsm_tx  = sb_cmp_link2ltsm_tx::type_id::create("cmp_link2ltsm_tx", this);
    cmp_link2ltsm_rx  = sb_cmp_link2ltsm_rx::type_id::create("cmp_link2ltsm_rx", this);
    cmp_link2ltsm_rdi = sb_cmp_link2ltsm_rdi::type_id::create("cmp_link2ltsm_rdi", this);
  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
    // --- Connect LTSM -> Link Pipeline ---
    // 1. Connect wrapper inputs to predictor inputs
    axp_in_tx.connect(prd_ltsm2link.axp_in_tx);
    axp_in_rx.connect(prd_ltsm2link.axp_in_rx);
    axp_in_rdi.connect(prd_ltsm2link.axp_in_rdi);
    
    // 2. Connect predictor output to comparator expected input
    prd_ltsm2link.results_ap_phy.connect(cmp_ltsm2link.axp_in_exp);
    
    // 3. Connect wrapper actual output to comparator actual input
    axp_out_phy.connect(cmp_ltsm2link.axp_out_actual);


    // --- Connect Link -> LTSM Pipeline ---
    // 1. Connect wrapper input to predictor
    axp_in_phy.connect(prd_link2ltsm.analysis_export);
    
    // 2. Connect predictor outputs to respective comparators' expected inputs
    prd_link2ltsm.results_ap_tx.connect(cmp_link2ltsm_tx.axp_in_exp);
    prd_link2ltsm.results_ap_rx.connect(cmp_link2ltsm_rx.axp_in_exp);
    prd_link2ltsm.results_ap_rdi.connect(cmp_link2ltsm_rdi.axp_in_exp);

    // 3. Connect wrapper actual outputs to respective comparators' actual inputs
    axp_out_tx.connect(cmp_link2ltsm_tx.axp_out_actual);
    axp_out_rx.connect(cmp_link2ltsm_rx.axp_out_actual);
    axp_out_rdi.connect(cmp_link2ltsm_rdi.axp_out_actual);
  endfunction : connect_phase
endclass
