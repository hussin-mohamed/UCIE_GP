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
// CLASS: sb_sanity_test
//
// The sb_sanity_test class runs the baseline directed sideband scenario.
// It keeps the default virtual-sequence selection from sb_test_base and uses
// a short timeout to act as a quick smoke test for the environment.
//
//-----------------------------------------------------------------------------

class sb_sanity_test extends sb_test_base;
  `uvm_component_utils(sb_sanity_test)

  // Function: new
  //
  // Creates a new sb_sanity_test instance and retrieves factory singleton handle.

  extern function new(string name, uvm_component parent);


  // Function: end_of_elaboration_phase
  //
  // Applies the timeout used by the sanity scenario.

  extern function void end_of_elaboration_phase(uvm_phase phase);
endclass : sb_sanity_test


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: sb_sanity_test
//
//-----------------------------------------------------------------------------


// new
// ---

function sb_sanity_test::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// end_of_elaboration_phase
// ---------

function void sb_sanity_test::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  uvm_top.set_timeout(50us, 0);
endfunction

