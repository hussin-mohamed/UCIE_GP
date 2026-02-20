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
// CLASS: ltsm_sequence_item_base
//
// Description: Sequence item class for LTSM sequences, containing all necessary
//              fields for controlling and monitoring the LTSM behavior.
//------------------------------------------------------------------------------
import shared_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"
class ltsm_sequence_item_base extends uvm_sequence_item;
  // Fields representing LTSM control and status signals
        logic [63:0] data;
        logic [15:0] info;
        msgtype_t t;
        int size;
    `uvm_object_utils_begin(ltsm_sequence_item_base)
        `uvm_field_int(data,  UVM_NORECORD)
        `uvm_field_int(info, UVM_NORECORD)
        `uvm_field_enum(msgtype_t, t, UVM_NORECORD)
        `uvm_field_int(size, UVM_NORECORD)
    `uvm_object_utils_end

    // Function: new
    //
    // Creates a new ltsm_sequence_item_base instance with the given name.
    extern function new(string name = "ltsm_sequence_item_base");
endclass : ltsm_sequence_item_base

function ltsm_sequence_item_base::new(string name = "ltsm_sequence_item_base");
    super.new(name);
endfunction