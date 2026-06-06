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
// CLASS: tx_fsm_sb_sequence_item
//
// The tx_fsm_sb_sequence_item class provides the base transaction item for tx_fsm_sb operations
//
//------------------------------------------------------------------------------
import shared_ltsm_pkg::*;
class tx_fsm_sb_sequence_item extends uvm_sequence_item;
  
        logic [8:0] i_tx_decoding,o_tx_encoding;
        logic [63:0] i_tx_data,o_tx_data;
        logic [15:0] i_tx_info,o_tx_info;
        logic i_reset;
        logic i_sb_tx_req, i_sb_tx_rsp, i_sb_tx_done;
        logic o_tx_sb_req, o_tx_sb_rsp, o_tx_sb_done;
        

    `uvm_object_utils_begin(tx_fsm_sb_sequence_item)
        `uvm_field_int(i_tx_decoding, UVM_NORECORD)
        `uvm_field_int(o_tx_encoding, UVM_NORECORD)
        `uvm_field_int(i_tx_data,            UVM_NORECORD)
        `uvm_field_int(o_tx_data,            UVM_NORECORD)
        `uvm_field_int(i_tx_info,            UVM_NORECORD)
        `uvm_field_int(o_tx_info,            UVM_NORECORD)
    `uvm_object_utils_end
        

    // Function: new
    //
    // Creates a new tx_fsm_sb_sequence_item instance with the given name.

    extern function new(string name = "tx_fsm_sb_sequence_item_base");

endclass : tx_fsm_sb_sequence_item


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- tx_fsm_sb_sequence_item_base
//
//------------------------------------------------------------------------------


// new
// ---

function tx_fsm_sb_sequence_item::new(string name = "tx_fsm_sb_sequence_item_base");
    super.new(name);
endfunction