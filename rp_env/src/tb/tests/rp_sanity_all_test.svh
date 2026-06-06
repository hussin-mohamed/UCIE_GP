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
// CLASS: rp_sanity_all_test
//
//
//-----------------------------------------------------------------------------

class rp_sanity_all_test extends rp_test_base;
  `uvm_component_utils(rp_sanity_all_test)

  // Function: new
  //
  // Creates a new rp_sanity_all_test instance and retrieves factory singleton handle.

  extern function new(string name, uvm_component parent);


  // Function: build_phase
  //
  // Registers the factory override for the virtual sequence

  extern function void build_phase(uvm_phase phase);


  // Function: end_of_elaboration_phase
  //
  // Applies the timeout used by the concurrent scenario.

  extern function void end_of_elaboration_phase(uvm_phase phase);
endclass : rp_sanity_all_test


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: rp_sanity_all_test
//
//-----------------------------------------------------------------------------


// new
// ---

function rp_sanity_all_test::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void rp_sanity_all_test::build_phase(uvm_phase phase);
  virtual_sequence_base::type_id::set_type_override(rp_sanity_all_vseq::get_type());
  
  // env_cfg.is_reactive_tx = 1;
  // env_cfg.is_reactive_rx = 1;

  super.build_phase(phase);
endfunction : build_phase

// end_of_elaboration_phase
// ---------

function void rp_sanity_all_test::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  uvm_top.set_timeout(100s, 0);
endfunction
