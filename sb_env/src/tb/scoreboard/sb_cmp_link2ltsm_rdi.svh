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
// CLASS: sb_cmp_link2ltsm_rdi
//
// Comparator placeholder for the link-to-LTSM RDI path. The class is present
// so the scoreboard can be wired consistently while RDI checking is completed.
//---------------------------------------------------------------------------

class sb_cmp_link2ltsm_rdi extends sb_cmp_base #(rdi_seq_item, "RDI_LINK2LTSM_CMP");
  `uvm_component_utils(sb_cmp_link2ltsm_rdi)

  // Function: new
  //
  // Creates the RDI link-to-LTSM comparator.

  extern function new(string name, uvm_component parent);

  // Function: set_timeout_val
  //
  // Placeholder hook for assigning an RDI-specific timeout once the path is
  // fully modeled in the environment.

  extern virtual function void set_timeout_val(rdi_seq_item item);

  extern virtual task main_phase(uvm_phase phase);
  extern virtual function void report_phase(uvm_phase phase); 
endclass

//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: sb_cmp_link2ltsm_rdi
//
//---------------------------------------------------------------------------

// new
// ---

function sb_cmp_link2ltsm_rdi::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

// set_timeout_val
// ---------------

function void sb_cmp_link2ltsm_rdi::set_timeout_val(rdi_seq_item item);
  
endfunction : set_timeout_val

// main_phase
// ----------

task sb_cmp_link2ltsm_rdi::main_phase(uvm_phase phase);

endtask : main_phase

// report_phase
// ------------

function void sb_cmp_link2ltsm_rdi::report_phase(uvm_phase phase);
  
endfunction : report_phase
