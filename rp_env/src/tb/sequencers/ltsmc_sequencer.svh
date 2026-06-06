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
// CLASS: ltsmc_sequencer
//
// RX-Path RX sequencer for managing transaction flow on the RX interface.
//
//-----------------------------------------------------------------------------

class ltsmc_sequencer extends uvm_sequencer #(ltsmc_seq_item);
  `uvm_component_utils(ltsmc_sequencer)

  uvm_analysis_export #(ltsmc_seq_item) reactive_exp;
  uvm_tlm_analysis_fifo #(ltsmc_seq_item) reactive_fifo;


  // Function: new
  //
  // Creates a new ltsmc_sequencer instance with the given name and parent.

  extern function new(string name, uvm_component parent);

  // Function: connect_phase
  //
  // Connects the reactive analysis export to the backing FIFO.

  extern function void connect_phase(uvm_phase phase);
  
  // Function: build_phase
  //
  // Constructs the reactive export and FIFO used by concurrent sequences.

  extern function void build_phase(uvm_phase phase);

endclass : ltsmc_sequencer


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: ltsmc_sequencer
//
//-----------------------------------------------------------------------------


// new
// ---

function ltsmc_sequencer::new(string name, uvm_component parent);
  super.new(name, parent);
  set_report_severity_id_verbosity(UVM_INFO, "PHASESEQ", UVM_NONE);
endfunction : new

// build_phase
// -----------

function void ltsmc_sequencer::build_phase(uvm_phase phase);
  super.build_phase(phase);
  reactive_exp  = new("reactive_exp", this);
  reactive_fifo = new("reactive_fifo", this);
endfunction : build_phase

// connect_phase
// -------------

function void ltsmc_sequencer::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  reactive_exp.connect(reactive_fifo.analysis_export);
endfunction : connect_phase
