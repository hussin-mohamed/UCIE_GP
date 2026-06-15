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
// CLASS: ltsmc_seq_item
//
// RX-Path LTSM sequence item containing transaction data exchanged between
// the TX and RX LTSM-side agents during ACTIVE-mode operation.
//-----------------------------------------------------------------------------

class ltsmc_seq_item extends uvm_sequence_item;

  lane_map_code_t lane_map_code;  // Selects lane mapping configuration.
  rx_encoding_t rx_encoding;  // Current state of the RX FSM.
  rand logic [15:0] error_threshold;  // Error threshold for the valid and data pattern detection.
  logic half_rate;  // Rate mode selector. Always set to 1 and used by the driver only.
  logic [pDATA_WIDTH-1:0] rx_data_results;  // One bit for each lane which indicates the successful detection of the LFSR pattern on that lane.
  logic [2:0] rx_clk_results;  // One bit for each lane which indicates the successful detection of the LFSR pattern on that lane.
  logic rx_valid_results;  // One bit for each lane which indicates the successful detection of the LFSR pattern on that lane.

  `uvm_object_utils_begin(ltsmc_seq_item)
    `uvm_field_enum(lane_map_code_t, lane_map_code, UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_enum(rx_encoding_t, rx_encoding, UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_int(error_threshold, UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_int(half_rate, UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_int(rx_data_results, UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
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

endclass : ltsmc_seq_item

//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: ltsmc_seq_item
//
//-----------------------------------------------------------------------------

// new
// ---

function ltsmc_seq_item::new(string name = "");
  super.new(name);
endfunction

// do_print
// -------

function void ltsmc_seq_item::do_print(uvm_printer printer);
  // ...
endfunction : do_print
