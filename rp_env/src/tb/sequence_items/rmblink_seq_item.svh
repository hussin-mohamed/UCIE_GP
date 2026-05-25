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
// CLASS: rmblink_seq_item
//
// RX-Path LTSM sequence item containing transaction data exchanged between
// the TX and RX LTSM-side agents during ACTIVE-mode operation.
//
//-----------------------------------------------------------------------------

class rmblink_seq_item extends uvm_sequence_item;

  rand logic          [7:0]             val_stream   [];    // Serialized 8-bit valid stream representing the Valid signal used during link training or active phases.
  rand logic                            clk_stream_p [];    // Serialized positive clock stream used for clock training as well as data and valid sampling by the partner.
  rand logic                            clk_stream_n [];    // Serialized negative clock stream used for clock training as well as data and valid samplingby the partner.
  rand logic                            track_stream [];    // Serialized track stream.
  rand int unsigned                     idle_ui_cnt;        // Specifies the number of idle Unit Intervals (UIs) to inject before or after the active/training transmission. Used by the driver only.
  rand pattern_type_t                   pattern_type;       // Selects the specific physical training or test pattern format (CLK_PATTERN, VAL_PATTERN, or DATA_PATTERN). Used by the driver only.
  rand logic          [pDATA_WIDTH-1:0] data [pNUM_LANES];  // Two-dimensional array storing the explicit per-lane data payload to be driven across the physical link.

  `uvm_object_utils_begin(rmblink_seq_item)
    `uvm_field_array_int  (val_stream,                   UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_array_int  (clk_stream_p,                 UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_array_int  (clk_stream_n,                 UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_array_int  (track_stream,                 UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_int        (idle_ui_cnt,                  UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_enum       (pattern_type_t, pattern_type, UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_sarray_int (data,                         UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
  `uvm_object_utils_end

  // Function: new
  // ...

  extern function new(string name = "");


  // Function: do_print
  //
  // Extends the default UVM printout with raw values for invalid enums.
  
  extern virtual function void do_print(uvm_printer printer);

endclass : rmblink_seq_item

//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: rmblink_seq_item
//
//-----------------------------------------------------------------------------

// new
// ---

function rmblink_seq_item::new(string name = "");
  super.new(name);
endfunction

// do_print
// -------

function void rmblink_seq_item::do_print(uvm_printer printer);
  // ...
endfunction : do_print
