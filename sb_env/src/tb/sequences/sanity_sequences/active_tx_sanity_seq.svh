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
// CLASS: active_tx_sanity_seq
//
// Directed ACTIVE-mode TX sequence that sends a small representative set of
// messages toward the DUT TX-side LTSM path.
//
//-----------------------------------------------------------------------------

class active_tx_sanity_seq extends sb_sequence_base #(ltsm_seq_item);
  `uvm_object_utils(active_tx_sanity_seq)


  // Function: new
  //
  // Creates a new active_tx_sanity_seq instance with the given name.

  extern function new(string name = "active_tx_sanity_seq");


  // Task: body
  //
  // Drives a short directed set of TX messages used by the sanity scenario.

  extern task body();

endclass : active_tx_sanity_seq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: active_tx_sanity_seq
//
// Implements the directed TX ACTIVE sanity stimulus.
//
//-----------------------------------------------------------------------------


// new
// ---

function active_tx_sanity_seq::new(string name = "active_tx_sanity_seq");
  super.new(name);
endfunction : new

// body
// ----
//
// Sends two deterministic TX items to exercise no-data and data-carrying flows.

task active_tx_sanity_seq::body();
  start_item(req);
  req.data        = 0;
  req.info        = 0;
  req.msgtype     = REQ_MSG;
  req.wait_cycles = 30;
  req.set_tx_encoding(SBINIT_TX_Out_Of_Reset_MSG);
  finish_item(req);

  start_item(req);
  req.data        = 64'habcd1234abcd1234;
  req.info        = 16'h5678;
  req.msgtype     = REQ_MSG;
  req.wait_cycles = 30;
  req.set_tx_encoding(MBINIT_PARAM_TX_Config_Handshake);
  finish_item(req);
endtask : body
