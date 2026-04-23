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
// CLASS: phylink_sequencer
//
// Sideband phylink sequencer for managing transaction flow on the phylink
// interface.
//
//-----------------------------------------------------------------------------

class phylink_sequencer extends uvm_sequencer #(phylink_seq_item);
  `uvm_component_utils(phylink_sequencer)

  uvm_analysis_export #(phylink_seq_item) reactive_exp;
  uvm_tlm_analysis_fifo #(phylink_seq_item) reactive_fifo;


  // Function: new
  //
  // Creates a new phylink_sequencer instance with the given name and parent.

  extern function new(string name, uvm_component parent);

  // Function: connect_phase
  //
  // Connects the reactive analysis export to the backing FIFO.

  extern function void connect_phase(uvm_phase phase);

  // Function: build_phase
  //
  // Constructs the reactive export and FIFO used by the phylink driver flow.

  extern function void build_phase(uvm_phase phase);

endclass : phylink_sequencer


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: phylink_sequencer
//
//-----------------------------------------------------------------------------


// new
// ---

function phylink_sequencer::new(string name, uvm_component parent);
  super.new(name, parent);
  set_report_severity_id_verbosity(UVM_INFO, "PHASESEQ", UVM_NONE);
endfunction : new

// build_phase
// -----------

function void phylink_sequencer::build_phase(uvm_phase phase);
  super.build_phase(phase);
  reactive_exp  = new("reactive_exp", this);
  reactive_fifo = new("reactive_fifo", this);
endfunction : build_phase

// connect_phase
// -------------

function void phylink_sequencer::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  reactive_exp.connect(reactive_fifo.analysis_export);
endfunction : connect_phase
