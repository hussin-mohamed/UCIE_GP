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
endfunction : new

// drive_item
// ----------

task ltsmc_driver::drive_item(inout ltsmc_seq_item req, output ltsmc_seq_item rsp);
  if (!std::randomize(next_state_wait_cycles) with { next_state_wait_cycles inside {[10:40]}; }) begin
    `uvm_error(get_type_name(), "Failed to randomize next_state_wait_cycles")
  end
  repeat(next_state_wait_cycles) @(posedge bfm.clk);
  bfm.i_rx_encoding     <= req.rx_encoding;
  bfm.i_lane_map_code   <= req.lane_map_code;
  bfm.i_error_threshold <= req.error_threshold;
  bfm.i_half_rate       <= req.half_rate;
endtask : drive_item
