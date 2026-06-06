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
// Minimal Sideband RDI sequence item used to keep the environment interfaces
// and scoreboard hooks in place while the RDI path is completed.
//-----------------------------------------------------------------------------

class rdi_seq_item extends uvm_sequence_item;
  // Enum specifying the type of the current operation of the Sideband (SBINIT/ACTIVE)
  operation_t op_mode;
  opcode_t      opcode;

  `uvm_object_utils(rdi_seq_item)

  // Function: new
  //
  // Creates a new RDI sequence item instance with the given name.
  extern function new(string name = "");
endclass : rdi_seq_item

//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: rdi_seq_item
//
// Methods implementation for the RDI sequence item.
//
//-----------------------------------------------------------------------------

// new
// ---
//
// Initializes the item to ACTIVE mode.

function rdi_seq_item::new(string name = "");
  super.new(name);
  op_mode = ACTIVE;
endfunction
