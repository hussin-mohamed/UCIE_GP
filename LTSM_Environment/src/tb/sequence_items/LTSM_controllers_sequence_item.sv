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
// CLASS: LTSM_controllers_seq_item
//
// The LTSM_controllers_seq_item class represents LTSM controller transactions,
// containing both input and output fields for verification purposes.
//
//------------------------------------------------------------------------------
import uvm_pkg::*;
`include "uvm_macros.svh"

import shared_ltsm_pkg::*;
class LTSM_controllers_seq_item extends uvm_sequence_item;
  
  logic i_power;
  logic i_pll_stable;
  logic i_rx_error;
  logic i_rx_done;
  logic i_tx_done;
  logic i_val_error;
  logic o_sbinit_start;
  logic i_sb_ready;
  logic o_t1_ms;
  logic [63:0] i_lane_error;
  encoding_tx_t o_tx_encoding;
  encoding_rx_t o_rx_encoding;

    `uvm_object_utils_begin(LTSM_controllers_seq_item)
        `uvm_field_int(i_power,  UVM_NORECORD)
        `uvm_field_int(i_pll_stable, UVM_NORECORD)
        `uvm_field_int(i_rx_error, UVM_NORECORD)
        `uvm_field_int(i_rx_done, UVM_NORECORD)
        `uvm_field_int(i_tx_done, UVM_NORECORD)
        `uvm_field_int(i_val_error, UVM_NORECORD)
        `uvm_field_int(i_lane_error, UVM_NORECORD)
        `uvm_field_int(o_tx_encoding, UVM_NORECORD)
        `uvm_field_int(o_rx_encoding, UVM_NORECORD)
    `uvm_object_utils_end


    // Function: new
    //
    // Creates a new LTSM_controllers_seq_item instance with the given name.

    extern function new(string name = "LTSM_controllers_seq_item");

endclass : LTSM_controllers_seq_item


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- LTSM_controllers_seq_item
//
//------------------------------------------------------------------------------


// new
// ---

function LTSM_controllers_seq_item::new(string name = "LTSM_controllers_seq_item");
    super.new(name);
endfunction
