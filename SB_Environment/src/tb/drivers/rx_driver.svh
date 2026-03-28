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
// CLASS: rx_driver
//
// ...
//
//------------------------------------------------------------------------------

class rx_driver extends sb_driver_base #(ltsm_seq_item, virtual sb_rx_bfm);
  `uvm_component_utils(rx_driver)


  // Function: new
  //
  // Creates a new rx_driver instance with the given name and parent.

  extern function new(string name, uvm_component parent);


  // Task: drive_item
  //
  // Drives APB transactions on the bus by setting path selection signals and
  // executing read or write operations based on the transaction type.

  extern virtual task drive_item(inout ltsm_seq_item req, output ltsm_seq_item rsp);

endclass : rx_driver


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- rx_driver
//
//------------------------------------------------------------------------------


// new
// ---

function rx_driver::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// drive_item
// -----

task rx_driver::drive_item(inout ltsm_seq_item req, output ltsm_seq_item rsp);
  // Prepare inputs
  @(negedge bfm.clk);
  bfm.i_rx_encoding = req.get_rx_encoding();
  bfm.i_rx_data     = req.data;
  bfm.i_rx_info     = req.info;

  // Trigger a request/response message to the Sideband
  @(negedge bfm.clk);
  if (req.msgtype == REQ_MSG) begin
    bfm.i_rx_sb_req = 1;
    bfm.i_rx_sb_rsp = 0;
  end else if (req.msgtype == RSP_MSG) begin
    bfm.i_rx_sb_req = 0;
    bfm.i_rx_sb_rsp = 1;
  end else begin
    `uvm_fatal(get_type_name(), $sformatf("GOT NO_TYPE msgtype in %s: \n%s", req.get_type_name(), req.sprint()))
  end

  // Deassert the req/rsp signal upon receiving the done signal
  @(negedge bfm.o_sb_rx_done);
  bfm.i_rx_sb_req = 0;
  bfm.i_rx_sb_rsp = 0;

  // Wait a randomized number of cycles before ending the trasaction
  repeat (req.wait_cycles) @(negedge bfm.clk);
endtask : drive_item
