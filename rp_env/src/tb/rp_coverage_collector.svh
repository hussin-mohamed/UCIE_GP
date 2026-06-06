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

`uvm_analysis_imp_decl(_rmblink_cg)
`uvm_analysis_imp_decl(_ltsm_cg)

//---------------------------------------------------------------------------
//
// CLASS: rp_coverage_collector
//
// Coverage collector for RX-Path verification traffic.
//
//---------------------------------------------------------------------------

class rp_coverage_collector extends uvm_component;
  `uvm_component_utils(rp_coverage_collector)

  uvm_analysis_imp_rmblink_cg #(rmblink_seq_item, rp_coverage_collector) rmblink_exp;
  uvm_analysis_imp_ltsm_cg    #(ltsmc_seq_item, rp_coverage_collector)   ltsm_exp;

  rmblink_seq_item rmblink_item;
  ltsmc_seq_item   ltsm_item;


  //---------------------------------------------------------------------------
  //
  // COVERGROUP: cg_rmblink
  //
  //---------------------------------------------------------------------------

  covergroup cg_rmblink;
    // ...
  endgroup : cg_rmblink

  covergroup cg_ltsm;
    // ...
  endgroup : cg_ltsm


  // Function: new
  //
  // Creates the coverage collector and constructs its analysis implementations
  // and covergroups.

  extern function new(string name, uvm_component parent);

  // Function: write_rmblink_cg
  //
  // Receives one monitored rmblink transaction, clones it into the collector's
  // local storage, and samples the rmblink covergroup.

  extern virtual function void write_rmblink_cg(rmblink_seq_item t);

  // Function: write_ltsm_cg
  //
  // Receives one monitored LTSM transaction.

  extern virtual function void write_ltsm_cg(ltsmc_seq_item t);
endclass

//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: rp_coverage_collector
//
//---------------------------------------------------------------------------

// new
// ---

function rp_coverage_collector::new(string name, uvm_component parent);
  super.new(name, parent);
  rmblink_exp = new("rmblink_exp", this);
  ltsm_exp    = new("ltsm_exp", this);

  cg_rmblink = new();
  cg_ltsm    = new();
endfunction : new

// write_rmblink_cg
// -------------

function void rp_coverage_collector::write_rmblink_cg(rmblink_seq_item t);
  // if (t == null) begin
  //   `uvm_error("COV", "Null rmblink_seq_item received")
  //   return;
  // end
  // $cast(rmblink_item, t.clone());
  // cg_rmblink.sample();
endfunction : write_rmblink_cg

// write_ltsm_cg
// ----------

function void rp_coverage_collector::write_ltsm_cg(ltsmc_seq_item t);
  // if (t == null) begin
  //   `uvm_error("COV", "Null ltsmc_seq_item received")
  //   return;
  // end
  // $cast(ltsm_item, t.clone());
  // cg_ltsm.sample();
endfunction : write_ltsm_cg
