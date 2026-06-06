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
// CLASS: active_tx_sendall_seq
//
// ACTIVE-mode TX sequence that iterates through every supported TX-side
// encoding in the shared message table.
//
//-----------------------------------------------------------------------------

class active_tx_sendall_seq extends sb_sequence_base #(ltsm_seq_item);
  `uvm_object_utils(active_tx_sendall_seq)


  // Function: new
  //
  // Creates a new active_tx_sendall_seq instance with the given name.

  extern function new(string name = "active_tx_sendall_seq");


  // Task: body
  //
  // Sends one item for each supported TX message encoding.

  extern task body();

endclass : active_tx_sendall_seq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: active_tx_sendall_seq
//
//-----------------------------------------------------------------------------


// new
// ---

function active_tx_sendall_seq::new(string name = "active_tx_sendall_seq");
  super.new(name);
endfunction : new

// body
// ----

task active_tx_sendall_seq::body();
  foreach (tx_messages[enc]) begin
    start_item(req);
    req.data        = 0;
    req.info        = 0;
    req.msgtype     = REQ_MSG;
    req.wait_cycles = 30;
    req.set_tx_encoding(enc);
    finish_item(req);
  end
endtask : body
