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
// CLASS: sanity_test
//
// The sanity_test ...
//
//-----------------------------------------------------------------------------

class sanity_test extends sb_test_base;
  `uvm_component_utils(sanity_test)

  // Function: new
  //
  // Creates a new sanity_test instance and retrieves factory singleton handle.

  extern function new(string name, uvm_component parent);


  // Task: main_phase
  //
  // Raises objection, starts virtual sequence on environment sequencer,
  // and drops objection upon completion.

  extern task main_phase(uvm_phase phase);


  // Function: end_of_elaboration_phase
  //
  // ...

  extern function void end_of_elaboration_phase(uvm_phase phase);
endclass : sanity_test


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS- sanity_test
//
//-----------------------------------------------------------------------------


// new
// ---

function sanity_test::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// end_of_elaboration_phase
// ---------

function void sanity_test::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  uvm_top.set_timeout(50us, 0);
endfunction

// main_phase
// ---------

task sanity_test::main_phase(uvm_phase phase);
  super.main_phase(phase);

  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vseq.get_type_name()), UVM_MEDIUM)
  vseq.start(env.vseqr);
  `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vseq.get_type_name()), UVM_MEDIUM)

  phase.drop_objection(this);
endtask : main_phase
