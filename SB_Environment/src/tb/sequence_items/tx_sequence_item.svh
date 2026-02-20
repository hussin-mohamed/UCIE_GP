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
// CLASS: tx_sequence_item
//
// Description: Sequence item class for tx sequences, containing all necessary
//              fields for controlling and monitoring the tx behavior.
//------------------------------------------------------------------------------
import shared_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"
class tx_sequence_item extends LTSM_sequence_item_base;
    encoding_tx_t encoding;
    `uvm_object_utils_begin(tx_sequence_item)
        `uvm_field_enum(encoding, encoding_tx_t, UVM_NORECORD)
    `uvm_object_utils_end
    // Function: new
    //
    // Creates a new tx_sequence_item instance with the given name.
    extern function new(string name = "tx_sequence_item");
endclass : tx_sequence_item

function tx_sequence_item::new(string name = "tx_sequence_item");
    super.new(name);
endfunction
