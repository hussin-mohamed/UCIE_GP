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
// CLASS: rx_fsm_sb_sequence_item
//
// The rx_fsm_sb_sequence_item class provides the base transaction item for rx_fsm_sb operations
//
//------------------------------------------------------------------------------
import shared_ltsm_pkg::*;
class rx_fsm_sb_sequence_item extends uvm_sequence_item;
  
        logic [8:0] i_rx_decoding,o_rx_encoding;
        logic [63:0] i_rx_data,o_rx_data;
        logic [15:0] i_rx_info,o_rx_info;
        logic i_reset;
        logic i_sb_rx_req, i_sb_rx_rsp, i_sb_rx_done;
        logic o_rx_sb_req, o_rx_sb_rsp, o_rx_sb_done;
        

    `uvm_object_utils_begin(rx_fsm_sb_sequence_item)
        `uvm_field_int(i_rx_decoding, UVM_NORECORD)
        `uvm_field_int(o_rx_encoding, UVM_NORECORD)
        `uvm_field_int(i_rx_data,            UVM_NORECORD)
        `uvm_field_int(o_rx_data,            UVM_NORECORD)
        `uvm_field_int(i_rx_info,            UVM_NORECORD)
        `uvm_field_int(o_rx_info,            UVM_NORECORD)
    `uvm_object_utils_end
        

    // Function: new
    //
    // Creates a new rx_fsm_sb_sequence_item instance with the given name.

    extern function new(string name = "rx_fsm_sb_sequence_item_base");

endclass : rx_fsm_sb_sequence_item


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- rx_fsm_sb_sequence_item_base
//
//------------------------------------------------------------------------------


// new
// ---

function rx_fsm_sb_sequence_item::new(string name = "rx_fsm_sb_sequence_item_base");
    super.new(name);
endfunction