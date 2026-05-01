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
// CLASS: rp_rand_test
//
// The rp_rand_test class runs randomized sideband traffic after initialization.
// It overrides the default virtual sequence with rp_rand_vseq and assigns a
// longer timeout than the sanity test to allow the randomized stimulus to
// complete.
//
//-----------------------------------------------------------------------------

class rp_rand_test extends rp_test_base;
  `uvm_component_utils(rp_rand_test)

  // Function: new
  //
  // Creates a new rp_rand_test instance and retrieves factory singleton handle.

  extern function new(string name, uvm_component parent);


  // Function: build_phase
  //
  // Registers the factory override for the virtual sequence

  extern function void build_phase(uvm_phase phase);


  // Function: end_of_elaboration_phase
  //
  // Applies the timeout used by the randomized scenario.

  extern function void end_of_elaboration_phase(uvm_phase phase);
endclass : rp_rand_test


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: rp_rand_test
//
//-----------------------------------------------------------------------------


// new
// ---

function rp_rand_test::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void rp_rand_test::build_phase(uvm_phase phase);
  rp_sanity_vseq::type_id::set_type_override(rp_rand_vseq::get_type());

  super.build_phase(phase);
endfunction : build_phase

// end_of_elaboration_phase
// ---------

function void rp_rand_test::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  uvm_top.set_timeout(50000us, 0);
endfunction
