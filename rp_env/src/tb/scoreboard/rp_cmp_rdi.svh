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
// CLASS: rp_cmp_rdi
//
// ...
//---------------------------------------------------------------------------

class rp_cmp_rdi extends rp_cmp_base #(rdi_seq_item, "RDI_CMP");
  `uvm_component_utils(rp_cmp_rdi)

  // Function: new
  //
  // Creates the RDI link-to-LTSM comparator.

  extern function new(string name, uvm_component parent);

  // Function: set_timeout_val
  //
  // Placeholder hook for assigning an RDI-specific timeout once the path is
  // fully modeled in the environment.

  extern virtual function void set_timeout_val(rdi_seq_item item);
endclass

//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: rp_cmp_rdi
//
//---------------------------------------------------------------------------

// new
// ---

function rp_cmp_rdi::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

// set_timeout_val
// ---------------

function void rp_cmp_rdi::set_timeout_val(rdi_seq_item item);
  
endfunction : set_timeout_val
