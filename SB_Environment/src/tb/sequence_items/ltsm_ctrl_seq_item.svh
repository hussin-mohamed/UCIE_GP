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
// CLASS: ltsm_ctrl_seq_item
//
// Description: ...
//-----------------------------------------------------------------------------

class ltsm_ctrl_seq_item extends uvm_sequence_item;

  // Enum specifying the type of mode of the SBINIT (START/T1MS)
  sbinit_mode_t sbinit_mode;

  `uvm_object_utils_begin(ltsm_ctrl_seq_item)
    `uvm_field_enum (sbinit_mode_t,  sbinit_mode, UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
  `uvm_object_utils_end

  // Function: new
  //
  // Creates a new ltsm_ctrl_seq_item instance with the given name.
  extern function new(string name = "");
endclass : ltsm_ctrl_seq_item

//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS- ltsm_ctrl_seq_item
//
//-----------------------------------------------------------------------------

// new
// ---

function ltsm_ctrl_seq_item::new(string name = "");
  super.new(name);
endfunction
