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

  rand logic          [7:0]             val_pattern;        // Serialized 8-bit pattern representing the Valid signal used during link training or active phases.
  rand logic                            clk_stream_p [];    // Serialized 32-bit pattern representing the positive Clock signal used for clock training.
  rand logic                            clk_stream_n [];    // Serialized 32-bit pattern representing the negative Clock signal used for clock training.
  rand int unsigned                     idle_ui_cnt_dat;    // Specifies the number of idle Unit Intervals (UIs) to inject before or after the active/training Data transmission.
  rand int unsigned                     idle_ui_cnt_val;    // Specifies the number of idle Unit Intervals (UIs) to inject before or after the active/training Valid transmission.
  rand int unsigned                     idle_ui_cnt_clk;    // Specifies the number of idle Unit Intervals (UIs) to inject before or after the active/training Clok transmission.
  rand int unsigned                     clk_iter_cnt;       // Defines the number of times the clock pattern is repeated during the training sequence.
  rand int unsigned                     val_iter_cnt;       // Defines the number of times the valid pattern is repeated during the training sequence.
  rand int unsigned                     dat_iter_cnt;       // Defines the number of times the main payload data pattern is repeated during the training sequence.
  rand pattern_type_t                   pattern_type;       // Selects the specific physical training or test pattern format (CLK_PATTERN, VAL_PATTERN, or DATA_PATTERN).
  rand rate_mode_t                      rate_mode;          // Configures the operational data transfer rate mode for the current transaction (Half Rate (HR) or Quadrature Rate (QR)).
  rand logic          [pDATA_WIDTH-1:0] data [pNUM_LANES];  // Two-dimensional array storing the explicit per-lane data payload to be driven across the physical link.

  `uvm_object_utils_begin(rmblink_seq_item)
    `uvm_field_int        (val_pattern,                  UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_array_int  (clk_stream_p,                 UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_array_int  (clk_stream_n,                 UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_int        (idle_ui_cnt_dat,              UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_int        (idle_ui_cnt_val,              UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_int        (idle_ui_cnt_clk,              UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_int        (clk_iter_cnt,                 UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_int        (val_iter_cnt,                 UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_int        (dat_iter_cnt,                 UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_enum       (rate_mode_t, rate_mode,       UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_enum       (pattern_type_t, pattern_type, UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_sarray_int (data,                         UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
  `uvm_object_utils_end

  // Function: new
  
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
