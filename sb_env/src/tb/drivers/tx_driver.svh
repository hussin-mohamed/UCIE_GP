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
// CLASS: tx_driver
//
// The tx_driver class converts TX-side sequence items into pin-level activity
// on the sb_tx_bfm. It drives request/response handshakes toward the DUT and
// waits for the corresponding done indication before completing each item.
//
//------------------------------------------------------------------------------

class tx_driver extends sb_driver_base #(ltsm_seq_item, virtual sb_tx_bfm);
  `uvm_component_utils(tx_driver)


  // Function: new
  //
  // Creates a new tx_driver instance with the given name and parent.

  extern function new(string name, uvm_component parent);


  // Task: drive_item
  //
  // Drives one TX-side sideband transaction across the BFM handshake signals.

  extern virtual task drive_item(inout ltsm_seq_item req, output ltsm_seq_item rsp);

endclass : tx_driver


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS: tx_driver
//
//------------------------------------------------------------------------------


// new
// ---

function tx_driver::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// drive_item
// -----

task tx_driver::drive_item(inout ltsm_seq_item req, output ltsm_seq_item rsp);
  // Prepare inputs
  @(posedge bfm.clk);
  bfm.i_tx_encoding <= req.get_tx_encoding();
  bfm.i_tx_data     <= req.data;
  bfm.i_tx_info     <= req.info;

  // Trigger a request/response message to the Sideband
  @(posedge bfm.clk);
  if (req.msgtype == REQ_MSG) begin
    bfm.i_tx_sb_req <= 1;
    bfm.i_tx_sb_rsp <= 0;
  end else if (req.msgtype == RSP_MSG) begin
    bfm.i_tx_sb_req <= 0;
    bfm.i_tx_sb_rsp <= 1;
  end else begin
    `uvm_fatal(get_type_name(), $sformatf("GOT NO_TYPE msgtype in %s: \n%s", req.get_type_name(), req.sprint()))
  end

  // Deassert the req/rsp signal upon receiving the done signal
  while(!bfm.o_sb_tx_done) begin
    @(posedge bfm.clk);
  end
  bfm.i_tx_sb_req <= 0;
  bfm.i_tx_sb_rsp <= 0;

  record_driven_item();

  // Wait a randomized number of cycles before ending the trasaction
  repeat (req.wait_cycles) @(posedge bfm.clk);
endtask : drive_item
