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
// CLASS: ltsm_monitor
//
// RX-Path TX monitor for capturing transactions on the TX interface.
//
//-----------------------------------------------------------------------------

class ltsm_monitor extends rp_monitor_base #(ltsmc_seq_item, virtual rp_ltsm_bfm);
  `uvm_component_utils(ltsm_monitor)


  // Function: new
  //
  // Creates a new ltsm_monitor instance with the given name and parent.

  extern function new(string name, uvm_component parent);


  // Task: collect_item_out
  //
  // Collects one TX-side item observed at the DUT output interface.

  extern virtual task collect_item_out(output ltsmc_seq_item _item);

  // Task: collect_item_in
  //
  // Collects one TX-side item observed at the DUT input interface.

  extern virtual task collect_item_in(output ltsmc_seq_item _item);

endclass : ltsm_monitor


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: ltsm_monitor
//
//-----------------------------------------------------------------------------


// new
// ---

function ltsm_monitor::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// collect_item_out
// ----------------

task ltsm_monitor::collect_item_out(output ltsmc_seq_item _item);
  _item = new();
endtask : collect_item_out


// collect_item_in
// ----------------

task ltsm_monitor::collect_item_in(output ltsmc_seq_item _item);
  _item = new();
endtask : collect_item_in
