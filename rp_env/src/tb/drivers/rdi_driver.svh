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
// CLASS: rdi_driver
//
// The rdi_driver class converts RX-side sequence items into pin-level activity
// on the rp_rdi_bfm. It drives request/response handshakes toward the DUT and
// waits for the corresponding done indication before completing each item.
//
//------------------------------------------------------------------------------

class rdi_driver extends rp_driver_base #(rdi_seq_item, virtual rp_rdi_bfm);
  `uvm_component_utils(rdi_driver)


  // Function: new
  //
  // Creates a new rdi_driver instance with the given name and parent.

  extern function new(string name, uvm_component parent);


  // Task: drive_item
  //
  // Drives one RX-side sideband transaction across the BFM handshake signals.

  extern virtual task drive_item(inout rdi_seq_item req, output rdi_seq_item rsp);

endclass : rdi_driver


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS: rdi_driver
//
//------------------------------------------------------------------------------


// new
// ---

function rdi_driver::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// drive_item
// ----------

task rdi_driver::drive_item(inout rdi_seq_item req, output rdi_seq_item rsp);
  // driving logic
endtask : drive_item
