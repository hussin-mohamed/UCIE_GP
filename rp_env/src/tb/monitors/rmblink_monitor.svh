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
// CLASS: rmblink_monitor
//
// RX-Path rmblink monitor for capturing transactions on the rmblink interface.
//
//-----------------------------------------------------------------------------

class rmblink_monitor extends rp_monitor_base #(
   .ITEM_T(rmblink_seq_item)
  ,.INTF_T(virtual rp_rmblink_bfm)
  ,.is_reactive(0)
  ,.collect_out(0)
  ,.collect_in(1)
);
  `uvm_component_utils(rmblink_monitor)


  // Function: new
  //
  // Creates a new rmblink_monitor instance with the given name and parent.

  extern function new(string name, uvm_component parent);


  // Task: collect_item_out
  //
  // Collects one rmblink item observed at the DUT output interface.

  extern virtual task collect_item_out(output rmblink_seq_item _item);

  // Task: collect_item_in
  //
  // Collects one rmblink item observed at the DUT input interface.

  extern virtual task collect_item_in(output rmblink_seq_item _item);

endclass : rmblink_monitor


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: rmblink_monitor
//
//-----------------------------------------------------------------------------


// new
// ---

function rmblink_monitor::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// collect_item_out
// ----------------

task rmblink_monitor::collect_item_out(output rmblink_seq_item _item);
  _item = new();
endtask : collect_item_out


// collect_item_in
// ----------------

task rmblink_monitor::collect_item_in(output rmblink_seq_item _item);
  _item = new();

  while (
    bfm.i_rx_encoding != MBINIT_REVERSAL_RX_Per_Lane_ID_Det               &&  // Per Lane ID pattern
    bfm.i_rx_encoding != Data_To_Clock_test_RX_Pattern_Detection_TX_Init  &&  // LFSR pattern or Per Lane ID pattern
    bfm.i_rx_encoding != Data_To_Clock_test_RX_Pattern_Detection_RX_Init  &&  // LFSR pattern
    bfm.i_rx_encoding != ACTIVE_RX_Active                                     // Active data transmission
  ) begin
    @(posedge bfm.clk);
  end

  bfm.deserialize_data(
     ._data(_item.data)
    ,._val_stream(_item.val_stream)
  );
endtask : collect_item_in
