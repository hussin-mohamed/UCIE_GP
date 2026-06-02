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
// Sideband RX monitor for capturing transactions on the RX interface.
//
//-----------------------------------------------------------------------------

class rx_monitor extends sb_monitor_base #(ltsm_seq_item, virtual sb_rx_bfm);
  `uvm_component_utils(rx_monitor)

  rand int unsigned wait_cycles;


  // Function: new
  //
  // Creates a new rx_monitor instance with the given name and parent.

  extern function new(string name, uvm_component parent);


  // Task: collect_item_out
  //
  // Collects one RX-side item observed at the DUT output interface.

  extern virtual task collect_item_out(output ltsm_seq_item _item);

  // Task: collect_item_in
  //
  // Collects one RX-side item observed at the DUT input interface.

  extern virtual task collect_item_in(output ltsm_seq_item _item);

endclass : rx_monitor


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: rx_monitor
//
//-----------------------------------------------------------------------------


// new
// ---

function rx_monitor::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// collect_item_out
// ----------------
//
// Waits for an outgoing RX request/response, captures the item, then returns
// the randomized done handshake expected by the DUT.

task rx_monitor::collect_item_out(output ltsm_seq_item _item);
  bit is_req;

  _item = ltsm_seq_item::type_id::create("_item");

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
  _item.set_rx_encoding(rx_encoding_t'(bfm.o_rx_decoding), 1);
  _item.msgtype = (is_req)? REQ_MSG : RSP_MSG;
  _item.data    = bfm.o_rx_data;
  _item.info    = bfm.o_rx_info;
  _item.valid   = bfm.o_rx_valid;

  // Wait a randomized number of cycles before asserting the done signal
  if (!std::randomize(wait_cycles) with {wait_cycles inside {[0 : 2]};}) begin
    `uvm_error(get_type_name(), "Failed to randomize wait_cycles")
  end
`ifndef UCIE_SYS_LVL
  repeat (wait_cycles) @(negedge bfm.clk);
  bfm.i_rx_sb_done = 1;
  @(negedge bfm.clk);
  bfm.i_rx_sb_done = 0;
`endif
endtask : collect_item_out


// collect_item_in
// ----------------

task rx_monitor::collect_item_in(output ltsm_seq_item _item);
  bit is_req;

  _item = ltsm_seq_item::type_id::create("_item");

  fork
    begin
      @(posedge bfm.i_rx_sb_req);
      is_req = 1;
    end

    begin
      @(posedge bfm.i_rx_sb_rsp);
      is_req = 0;
    end
  join_any

  disable fork;

  @(negedge bfm.clk);
  _item.set_rx_encoding(rx_encoding_t'(bfm.i_rx_encoding));
  _item.msgtype = (is_req)? REQ_MSG : RSP_MSG;
  _item.data    = bfm.i_rx_data;
  _item.info    = bfm.i_rx_info;

  @(posedge bfm.o_sb_rx_done);
endtask : collect_item_in
