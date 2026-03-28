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
// CLASS: tx_sanity_seq
//
// ...
//
//-----------------------------------------------------------------------------

class tx_sanity_seq extends sb_sequence_base #(ltsm_seq_item);
  `uvm_object_utils(tx_sanity_seq)


  // Function: new
  //
  // Creates a new tx_sanity_seq instance with the given name.

  extern function new(string name = "tx_sanity_seq");


  // Task: body
  //
  // ...

  extern task body();

endclass : tx_sanity_seq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS- tx_sanity_seq
//
//-----------------------------------------------------------------------------


// new
// ---

function tx_sanity_seq::new(string name = "tx_sanity_seq");
  super.new(name);
endfunction : new

// body
// ----

task tx_sanity_seq::body();
  start_item(req);
  req.data        = 0;
  req.info        = 0;
  req.msgtype     = REQ_MSG;
  req.wait_cycles = 30;
  req.set_tx_encoding(SBINIT_TX_Out_Of_Reset_MSG);
  finish_item(req);
endtask : body
