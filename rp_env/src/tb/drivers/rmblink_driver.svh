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
// CLASS: rmblink_driver
//
// ...
//
//-----------------------------------------------------------------------------

class rmblink_driver extends rp_driver_base #(rmblink_seq_item, virtual rp_rmblink_bfm);
  `uvm_component_utils(rmblink_driver)


  // Function: new
  //
  // Creates a new rmblink_driver instance with the given name and parent.

  extern function new(string name, uvm_component parent);


  // Task: drive_item
  //
  // Drives a rmblink item either as an SBINIT pattern exchange or as an
  // ACTIVE serialized sideband message.

  extern virtual task drive_item(inout rmblink_seq_item req, output rmblink_seq_item rsp);

endclass : rmblink_driver


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: rmblink_driver
//
//-----------------------------------------------------------------------------


// new
// ---

function rmblink_driver::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// drive_item
// -----

task rmblink_driver::drive_item(inout rmblink_seq_item req, output rmblink_seq_item rsp);
  // driving logic
endtask : drive_item
