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
// CLASS: rdi_monitor
//
// RX-Path RX monitor for capturing transactions on the RX interface.
//
//-----------------------------------------------------------------------------

class rdi_monitor extends rp_monitor_base #(
  .ITEM_T(rdi_seq_item)
  ,.INTF_T(virtual rp_rdi_bfm)
  ,.is_reactive(0)
  ,.collect_out(1)
  ,.collect_in(0)
);
  `uvm_component_utils(rdi_monitor)


  // Function: new
  //
  // ...

  extern function new(string name, uvm_component parent);


  // Task: collect_item_out
  //
  // ...

  extern virtual task collect_item_out(output rdi_seq_item _item);

  // Task: collect_item_in
  //
  // ...

  extern virtual task collect_item_in(output rdi_seq_item _item);

endclass : rdi_monitor


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: rdi_monitor
//
//-----------------------------------------------------------------------------


// new
// ---

function rdi_monitor::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new


// collect_item_out
// ----------------

task rdi_monitor::collect_item_out(output rdi_seq_item _item);
  _item = rdi_seq_item::type_id::create("_item");

  @(posedge bfm.pl_valid);
  @(negedge bfm.clk);
  _item.data = bfm.pl_data;
endtask : collect_item_out


// collect_item_in
// ---------------

task rdi_monitor::collect_item_in(output rdi_seq_item _item);
  _item = new();
endtask : collect_item_in
