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

//------------------------------------------------------------------------------
//
// CLASS: ctrl_sequence_item
//
// Description: Sequence item class for ctrl sequences, containing all necessary
//              fields for controlling and monitoring the ctrl behavior.
//------------------------------------------------------------------------------
import shared_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"
class ctrl_sequence_item extends uvm_sequence_item;
  // Fields representing LTSM control and status signals
    mode_t m;
    `uvm_object_utils_begin(ctrl_sequence_item)
        `uvm_field_enum(mode_t, m, UVM_NORECORD)
    `uvm_object_utils_end

    // Function: new
    //
    // Creates a new ctrl_sequence_item instance with the given name.
    extern function new(string name = "ctrl_sequence_item");
endclass : ctrl_sequence_item

function ctrl_sequence_item::new(string name = "ctrl_sequence_item");
    super.new(name);
endfunction