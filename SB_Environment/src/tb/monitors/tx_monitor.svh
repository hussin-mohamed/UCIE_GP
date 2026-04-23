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
// CLASS: tx_monitor
//
// Sideband TX monitor for capturing transactions on the TX interface.
//
//-----------------------------------------------------------------------------

class tx_monitor extends sb_monitor_base #(ltsm_seq_item, virtual sb_tx_bfm);
  `uvm_component_utils(tx_monitor)

  rand int unsigned wait_cycles;

  // Function: new
  //
  // Creates a new tx_monitor instance with the given name and parent.

  extern function new(string name, uvm_component parent);


  // Task: collect_item_out
  //
  // Collects one TX-side item observed at the DUT output interface.

  extern virtual task collect_item_out(output ltsm_seq_item _item);

  // Task: collect_item_in
  //
  // Collects one TX-side item observed at the DUT input interface.

  extern virtual task collect_item_in(output ltsm_seq_item _item);

endclass : tx_monitor


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: tx_monitor
//
//-----------------------------------------------------------------------------


// new
// ---

function tx_monitor::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// collect_item_out
// ----------------
//
// Waits for an outgoing TX request/response, captures the item, then returns
// the randomized done handshake expected by the DUT.

task tx_monitor::collect_item_out(output ltsm_seq_item _item);
  bit is_req;

  _item = ltsm_seq_item::type_id::create("_item");

  fork
    begin
      @(posedge bfm.o_sb_tx_req);
      is_req = 1;
    end

    begin
      @(posedge bfm.o_sb_tx_rsp);
      is_req = 0;
    end
  join_any

  disable fork;

  @(negedge bfm.clk);
  _item.set_tx_encoding(tx_encoding_t'(bfm.o_tx_decoding), 1);
  _item.msgtype = (is_req)? REQ_MSG : RSP_MSG;
  _item.data    = bfm.o_tx_data;
  _item.info    = bfm.o_tx_info;
  _item.valid   = bfm.o_tx_valid;

  // Wait a randomized number of cycles before asserting the done signal
  if (!std::randomize(wait_cycles) with { wait_cycles inside {[0:2]}; }) begin
    `uvm_error(get_type_name(), "Failed to randomize wait_cycles")
  end
  repeat (wait_cycles) @(negedge bfm.clk);
  bfm.i_tx_sb_done = 1;
  @(negedge bfm.clk);
  bfm.i_tx_sb_done = 0;
endtask : collect_item_out


// collect_item_in
// ----------------
//
// Waits for an incoming TX request/response and captures the associated item.

task tx_monitor::collect_item_in(output ltsm_seq_item _item);
  bit is_req;

  _item = ltsm_seq_item::type_id::create("_item");

  fork
    begin
      @(posedge bfm.i_tx_sb_req);
      is_req = 1;
    end

    begin
      @(posedge bfm.i_tx_sb_rsp);
      is_req = 0;
    end
  join_any

  disable fork;

  @(negedge bfm.clk);
  _item.set_tx_encoding(tx_encoding_t'(bfm.i_tx_encoding));
  _item.msgtype = (is_req)? REQ_MSG : RSP_MSG;
  _item.data    = bfm.i_tx_data;
  _item.info    = bfm.i_tx_info;

  while (!bfm.o_sb_tx_done) begin
    @(posedge bfm.clk);
  end
endtask : collect_item_in
