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
// CLASS: rp_cmp_ltsmc
//
// Comparator for the LTSM-to-link path. It checks the predicted ltsmc item
// against the monitored DUT ltsmc output.
//---------------------------------------------------------------------------

class rp_cmp_ltsmc extends rp_cmp_base #(ltsmc_seq_item, "LTSM_CMP");
  `uvm_component_utils(rp_cmp_ltsmc)

  // Function: new
  //
  // Creates the LTSM-to-link comparator.

  extern function new(string name, uvm_component parent);

  // Function: set_timeout_val
  //
  // Derives the allowed latency from the ltsmc message format.

  extern virtual function void set_timeout_val(ltsmc_seq_item item);
endclass

//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: rp_cmp_ltsmc
//
//---------------------------------------------------------------------------

// new
// ---

function rp_cmp_ltsmc::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

// set_timeout_val
// ---------------

function void rp_cmp_ltsmc::set_timeout_val(ltsmc_seq_item item);
  
endfunction : set_timeout_val
