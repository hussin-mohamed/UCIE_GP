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
// CLASS: rdi_seq_item
//
// RX-Path LTSM sequence item containing transaction data exchanged between
// the TX and RX LTSM-side agents during ACTIVE-mode operation.
//
//-----------------------------------------------------------------------------

class rdi_seq_item extends uvm_sequence_item;

  logic [pNBYTES-1:0][7:0] data;

  `uvm_object_utils_begin(rdi_seq_item)
    `uvm_field_int(data, UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
  `uvm_object_utils_end

  // Function: new
  //
  // Creates a new LTSM sequence item and initializes the supported encoding
  // lists from the shared message tables when needed.
  
  extern function new(string name = "");


  // Function: do_print
  //
  // Extends the default UVM printout with raw values for invalid enums.
  
  extern virtual function void do_print(uvm_printer printer);

endclass : rdi_seq_item

//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: rdi_seq_item
//
//-----------------------------------------------------------------------------

// new
// ---

function rdi_seq_item::new(string name = "");
  super.new(name);
endfunction

// do_print
// -------

function void rdi_seq_item::do_print(uvm_printer printer);
  // ...
endfunction : do_print
