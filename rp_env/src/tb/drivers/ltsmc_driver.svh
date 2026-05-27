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
// CLASS: ltsmc_driver
//
// ...
//
//------------------------------------------------------------------------------

class ltsmc_driver extends rp_driver_base #(ltsmc_seq_item, virtual rp_ltsmc_bfm);
  `uvm_component_utils(ltsmc_driver)

  bit is_first_item;
  rand int next_state_wait_cycles;


  // Function: new
  //
  // Creates a new ltsmc_driver instance with the given name and parent.

  extern function new(string name, uvm_component parent);

  // Task: drive_item
  //
  // Drives a control transaction that starts SBINIT and races completion
  // against timeout detection.

  extern virtual task drive_item(inout ltsmc_seq_item req, output ltsmc_seq_item rsp);

endclass : ltsmc_driver


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS: ltsmc_driver
//
//------------------------------------------------------------------------------


// new
// ---

function ltsmc_driver::new(string name, uvm_component parent);
  super.new(name, parent);
  is_first_item = 1;
endfunction : new

// drive_item
// ----------

task ltsmc_driver::drive_item(inout ltsmc_seq_item req, output ltsmc_seq_item rsp);
  if (is_first_item) begin
    @(posedge bfm.clk);
    bfm.i_rx_encoding     <= req.rx_encoding;
    bfm.i_lane_map_code   <= req.lane_map_code;
    bfm.i_error_threshold <= req.error_threshold;
    bfm.i_half_rate       <= req.half_rate;
    is_first_item = 0;
  end else begin

    if ((bfm.i_rx_encoding == MBINIT_REVERSAL_RX_Per_Lane_ID_Det) || (bfm.i_rx_encoding == Data_To_Clock_test_RX_Pattern_Detection_TX_Init) 
    || (bfm.i_rx_encoding == Data_To_Clock_test_RX_Pattern_Detection_RX_Init) || (bfm.i_rx_encoding == MBINIT_REPAIRCLK_RX_Pattern_Detection)
    || (bfm.i_rx_encoding == MBINIT_REPAIRVAL_RX_Valid_Pattern_Det)) begin
    @(ev_ready_for_next_encoding);
    end
    
    if (!std::randomize(next_state_wait_cycles) with { next_state_wait_cycles inside {[5:40]}; }) begin
      `uvm_error(get_type_name(), "Failed to randomize next_state_wait_cycles")
    end
    repeat(next_state_wait_cycles) @(posedge bfm.clk);
    bfm.i_rx_encoding     <= req.rx_encoding;
    bfm.i_lane_map_code   <= req.lane_map_code;
    bfm.i_error_threshold <= req.error_threshold;
    bfm.i_half_rate       <= req.half_rate;
  end
endtask : drive_item
