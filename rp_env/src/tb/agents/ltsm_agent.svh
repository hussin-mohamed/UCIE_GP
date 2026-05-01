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
// CLASS: ltsm_agent
//
// Thin typed wrapper around rp_agent_base for the sideband RX LTSM interface.
//
//-----------------------------------------------------------------------------

class ltsm_agent extends rp_agent_base #(
  .CFG_NAME("ltsm_cfg"),
  .INTF_T(virtual rp_ltsm_bfm),
  .ITEM_T(ltsmc_seq_item),
  .SEQR_T(ltsmc_sequencer),
  .DRVR_T(ltsm_driver),
  .MNTR_T(ltsm_monitor)
);
  `uvm_component_utils(ltsm_agent)

  // Function: new
  //
  // Creates the RX agent component.

  extern function new(string name, uvm_component parent);

endclass

//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: ltsm_agent
//
// Methods implementation for the RX agent wrapper.
//
//-----------------------------------------------------------------------------

// new
// ---

function ltsm_agent::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new
