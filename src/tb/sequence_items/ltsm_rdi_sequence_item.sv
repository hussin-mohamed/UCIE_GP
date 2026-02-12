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
// CLASS: ltsm_rdi_sequence_item
//
// The ltsm_rdi_sequence_item class represents the output transaction
//
//------------------------------------------------------------------------------

class ltsm_rdi_sequence_item extends uvm_sequence_item;


    // `uvm_object_utils_begin(ltsm_rdi_sequence_item)
    //     `uvm_field_int(data, UVM_NORECORD)
    // `uvm_object_utils_end


    // Function: new
    //
    // Creates a new ltsm_rdi_sequence_item instance with the given name.

    extern function new(string name = "ltsm_rdi_sequence_item");

endclass : ltsm_rdi_sequence_item


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- ltsm_rdi_sequence_item
//
//------------------------------------------------------------------------------


// new
// ---

function ltsm_rdi_sequence_item::new(string name = "ltsm_rdi_sequence_item");
    super.new(name);
endfunction