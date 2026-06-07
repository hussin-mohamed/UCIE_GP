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
// CLASS: rmblink_agent
//
// Thin typed wrapper around rp_agent_base for the sideband rmblink interface.
//
//-----------------------------------------------------------------------------

class rmblink_agent extends rp_agent_base #(
  .CFG_NAME("rmblink_cfg"),
  .INTF_T(virtual rp_rmblink_bfm),
  .ITEM_T(rmblink_seq_item),
  .SEQR_T(rmblink_sequencer),
  .DRVR_T(rmblink_driver),
  .MNTR_T(rmblink_monitor)
);
  `uvm_component_utils(rmblink_agent)

  // Function: new
  //
  // Creates the rmblink agent component.

  extern function new(string name, uvm_component parent);

endclass

//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: rmblink_agent
//
// Methods implementation for the rmblink agent wrapper.
//
//-----------------------------------------------------------------------------

// new
// ---

function rmblink_agent::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new
