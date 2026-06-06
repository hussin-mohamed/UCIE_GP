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
// CLASS: ltsmc_agent
//
// Thin typed wrapper around rp_agent_base for the sideband RX LTSM interface.
//
//-----------------------------------------------------------------------------

class ltsmc_agent extends rp_agent_base #(
  .CFG_NAME("ltsmc_cfg"),
  .INTF_T(virtual rp_ltsmc_bfm),
  .ITEM_T(ltsmc_seq_item),
  .SEQR_T(ltsmc_sequencer),
  .DRVR_T(ltsmc_driver),
  .MNTR_T(ltsmc_monitor)
);
  `uvm_component_utils(ltsmc_agent)

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
// CLASS: ltsmc_agent
//
// Methods implementation for the RX agent wrapper.
//
//-----------------------------------------------------------------------------

// new
// ---

function ltsmc_agent::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new
