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

class rdi_monitor extends rp_monitor_base #(rdi_seq_item, virtual rp_rdi_bfm);
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

  do begin
     @(negedge bfm.clk);
  end while (bfm.pl_valid == 1'b0);
  _item.data = bfm.pl_data;
endtask : collect_item_out


// collect_item_in
// ---------------

task rdi_monitor::collect_item_in(output rdi_seq_item _item);
  _item = new();
  #100;
endtask : collect_item_in
