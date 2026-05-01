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
// CLASS: rmblink_sequencer
//
// RX-Path rmblink sequencer for managing transaction flow on the rmblink
// interface.
//
//-----------------------------------------------------------------------------

class rmblink_sequencer extends uvm_sequencer #(rmblink_seq_item);
  `uvm_component_utils(rmblink_sequencer)

  uvm_analysis_export #(rmblink_seq_item) reactive_exp;
  uvm_tlm_analysis_fifo #(rmblink_seq_item) reactive_fifo;


  // Function: new
  //
  // Creates a new rmblink_sequencer instance with the given name and parent.

  extern function new(string name, uvm_component parent);

  // Function: connect_phase
  //
  // Connects the reactive analysis export to the backing FIFO.

  extern function void connect_phase(uvm_phase phase);

  // Function: build_phase
  //
  // Constructs the reactive export and FIFO used by the rmblink driver flow.

  extern function void build_phase(uvm_phase phase);

endclass : rmblink_sequencer


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: rmblink_sequencer
//
//-----------------------------------------------------------------------------


// new
// ---

function rmblink_sequencer::new(string name, uvm_component parent);
  super.new(name, parent);
  set_report_severity_id_verbosity(UVM_INFO, "PHASESEQ", UVM_NONE);
endfunction : new

// build_phase
// -----------

function void rmblink_sequencer::build_phase(uvm_phase phase);
  super.build_phase(phase);
  reactive_exp  = new("reactive_exp", this);
  reactive_fifo = new("reactive_fifo", this);
endfunction : build_phase

// connect_phase
// -------------

function void rmblink_sequencer::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  reactive_exp.connect(reactive_fifo.analysis_export);
endfunction : connect_phase
