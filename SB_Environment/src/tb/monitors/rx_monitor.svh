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
// CLASS: rx_monitor
//
// ...
//
//-----------------------------------------------------------------------------

class rx_monitor extends sb_monitor_base #(ltsm_seq_item, virtual sb_rx_bfm);
  `uvm_component_utils(rx_monitor)

  rand int unsigned wait_cycles;


  // Function: new
  //
  // Creates a new rx_monitor instance with the given name and parent.

  extern function new(string name, uvm_component parent);


  // Task: collect_item
  //
  // ...

  extern virtual task collect_item(output ltsm_seq_item _item);

endclass : rx_monitor


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS- rx_monitor
//
//-----------------------------------------------------------------------------


// new
// ---

function rx_monitor::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// collect_item
// ------------

task rx_monitor::collect_item(output ltsm_seq_item _item);
  bit is_req;

  fork
    begin
      @(posedge bfm.o_sb_rx_req);
      is_req = 1;
    end

    begin
      @(posedge bfm.o_sb_rx_rsp);
      is_req = 0;
    end
  join_any

  disable fork;

  @(negedge bfm.clk);
  _item.set_rx_encoding(rx_encoding_t'(bfm.o_rx_decoding));
  _item.msgtype = (is_req)? REQ_MSG : RSP_MSG;
  _item.data    = bfm.o_rx_data;
  _item.info    = bfm.o_rx_info;
  _item.valid   = bfm.o_rx_valid;

  // Wait a randomized number of cycles before asserting the done signal
  if (!std::randomize(wait_cycles) with { wait_cycles inside {[1:10]}; }) begin
    `uvm_error(get_type_name(), "Failed to randomize wait_cycles")
  end
  repeat (wait_cycles) @(negedge bfm.clk);
  bfm.i_rx_sb_done = 1;
  @(negedge bfm.clk);
  bfm.i_rx_sb_done = 0;
  return;
endtask : collect_item
