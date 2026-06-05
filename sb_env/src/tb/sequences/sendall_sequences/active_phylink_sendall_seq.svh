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
// CLASS: active_phylink_sendall_seq
//
// ACTIVE-mode phylink sequence that sends one instance of every supported
// message defined in the TX and RX lookup tables.
//
//-----------------------------------------------------------------------------

class active_phylink_sendall_seq extends sb_sequence_base #(phylink_seq_item);
  `uvm_object_utils(active_phylink_sendall_seq)


  // Function: new
  //
  // Creates a new active_phylink_sendall_seq instance with the given name.

  extern function new(string name = "active_phylink_sendall_seq");


  // Task: body
  //
  // Iterates over both TX and RX message tables, reconstructing the phylink
  // fields and parity for each supported message.

  extern task body();

endclass : active_phylink_sendall_seq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: active_phylink_sendall_seq
//
//-----------------------------------------------------------------------------


// new
// ---

function active_phylink_sendall_seq::new(string name = "active_phylink_sendall_seq");
  super.new(name);
endfunction : new

// body
// ----

task active_phylink_sendall_seq::body();
  logic [127:0] msg_raw;
  // First cover all messages that originate from the TX-side table.
  foreach (tx_messages[enc]) begin
    start_item(req);
    req.op_mode  = ACTIVE;
    req.fullcode = tx_messages[enc].fullcode;
    req.opcode   = tx_messages[enc].opcode;
    req.srcid    = tx_messages[enc].srcid;
    req.dstid    = tx_messages[enc].dstid;
    req.info     = '0;
    req.data     = '0;
    req.rsvd1    = '0;
    req.rsvd2    = '0;
    req.rsvd3    = '0;
    req.rsvd4    = '0;

    msg_raw = struct2raw(tx_messages[enc]);
    
    req.cp       = ^{msg_raw[61:0]};
    req.dp       = ^{msg_raw[127:64]};

    req.idle_ui_cnt = 100;
    finish_item(req);
  end

  // Then cover all messages that originate from the RX-side table.
  foreach (rx_messages[enc]) begin
    start_item(req);
    req.op_mode  = ACTIVE;
    req.fullcode = rx_messages[enc].fullcode;
    req.opcode   = rx_messages[enc].opcode;
    req.srcid    = rx_messages[enc].srcid;
    req.dstid    = rx_messages[enc].dstid;
    req.info     = '0;
    req.data     = '0;
    req.rsvd1    = '0;
    req.rsvd2    = '0;
    req.rsvd3    = '0;
    req.rsvd4    = '0;

    msg_raw = struct2raw(rx_messages[enc]);
    
    req.cp       = ^{msg_raw[61:0]};
    req.dp       = ^{msg_raw[127:64]};

    req.idle_ui_cnt = 100;
    finish_item(req);
  end
endtask : body
