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

  rand logic          [7:0]             val_pattern;
  rand logic          [31:0]            clk_pattern;
  rand logic          [pDATA_WIDTH-1:0] clk_fwd_p;
  rand logic          [pDATA_WIDTH-1:0] clk_fwd_n;
  rand int unsigned                     idle_ui_cnt;
  rand int unsigned                     clk_iter_cnt;
  rand int unsigned                     val_iter_cnt;
  rand int unsigned                     dat_iter_cnt;
  rand pattern_type_t                   pattern_type;
  rand rate_mode_t                      rate_mode;           // HR/QR
  rand logic          [pDATA_WIDTH-1:0] data [pNUM_LANES];   // pNUM_LANES lanes, each is a pDATA_WIDTH width bus

  `uvm_object_utils_begin(rmblink_seq_item)
    `uvm_field_int        (valid_pattern,                UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_int        (clk_pattern,                  UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_int        (idle_ui_cnt,                  UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_int        (clk_iter_cnt,                 UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_int        (val_iter_cnt,                 UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_int        (dat_iter_cnt,                 UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_enum       (rate_mode_t, rate_mode,       UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_enum       (pattern_type_t, pattern_type, UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_sarray_int (data,                         UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
  `uvm_object_utils_end

  // Function: new
  //
  // Creates a new LTSM sequence item and initializes the supported encoding
  // lists from the shared message tables when needed.
  
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
