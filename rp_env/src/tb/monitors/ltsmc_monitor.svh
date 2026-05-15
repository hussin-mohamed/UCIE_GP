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
// CLASS: ltsmc_monitor
//
// RX-Path TX monitor for capturing transactions on the TX interface.
//
//-----------------------------------------------------------------------------

class ltsmc_monitor extends rp_monitor_base #(ltsmc_seq_item, virtual rp_ltsmc_bfm);
  `uvm_component_utils(ltsmc_monitor)


  // Function: new
  //
  // Creates a new ltsmc_monitor instance with the given name and parent.

  extern function new(string name, uvm_component parent);


  // Task: collect_item_out
  //
  // Collects one TX-side item observed at the DUT output interface.

  extern virtual task collect_item_out(output ltsmc_seq_item _item);

  // Task: collect_item_in
  //
  // Collects one TX-side item observed at the DUT input interface.

  extern virtual task collect_item_in(output ltsmc_seq_item _item);

endclass : ltsmc_monitor


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: ltsmc_monitor
//
//-----------------------------------------------------------------------------


// new
// ---

function ltsmc_monitor::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// collect_item_out
// ----------------

task ltsmc_monitor::collect_item_out(output ltsmc_seq_item _item);
  _item = new();
  lane_map_code_t         lane_map_code;    // Selects lane mapping configuration.
  rx_encoding_t           rx_encoding;      // Current state of the RX FSM.
  rand logic [15:0]       error_threshold;  // Error threshold for the valid and data pattern detection.
  logic                   half_rate;        // Rate mode selector.
  logic [pDATA_WIDTH-1:0] rx_data_results,  // One bit for each lane which indicates the successful detection of the LFSR pattern on that lane.

  while (!bfm.o_rx_done) begin
    @(negedge bfm.clk);
  end

  _item.rx_data_results = bfm.o_rx_data_results;
endtask : collect_item_out


// collect_item_in
// ----------------

task ltsmc_monitor::collect_item_in(output ltsmc_seq_item _item);
  _item = new();
  @(bfm.rx_encoding);
  if (is_monitored_state(bfm.rx_encoding)) begin
    @(posedge clk);
    _item.lane_map_code   = bfm.i_lane_map_code;
    _item.rx_encoding     = bfm.i_rx_encoding;
    _item.error_threshold = bfm.i_error_threshold;
    _item.half_rate       = bfm.i_half_rate;
  end
endtask : collect_item_in
