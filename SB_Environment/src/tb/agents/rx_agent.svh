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
// CLASS: rx_agent
//
// Thin typed wrapper around agent_base for the sideband RX LTSM interface.
//
//-----------------------------------------------------------------------------

class rx_agent extends agent_base #(
  .CFG_NAME("rx_cfg"),
  .INTF_T(virtual sb_rx_bfm),
  .ITEM_T(ltsm_seq_item),
  .SEQR_T(rx_sequencer),
  .DRVR_T(rx_driver),
  .MNTR_T(rx_monitor)
);
  `uvm_component_utils(rx_agent)

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
// CLASS: rx_agent
//
// Methods implementation for the RX agent wrapper.
//
//-----------------------------------------------------------------------------

// new
// ---

function rx_agent::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new
