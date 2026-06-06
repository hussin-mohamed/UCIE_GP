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
// CLASS: sb_sendall_vseq
//
// The sb_sendall_vseq class extends the sanity flow with a complete sweep of
// the supported message lookup tables. After SBINIT, it drives exhaustive TX,
// RX, and phylink ACTIVE-phase sequences.
//
//-----------------------------------------------------------------------------

class sb_sendall_vseq extends sb_sanity_vseq;
  `uvm_object_utils(sb_sendall_vseq)

  active_tx_sendall_seq      tx_sendall_seq;
  active_rx_sendall_seq      rx_sendall_seq;
  active_phylink_sendall_seq phylink_sendall_seq;

  // Function: new
  //
  // Creates a new sb_sendall_vseq instance with the given name.

  extern function new(string name = "sb_sendall_vseq");


  // Task: pre_body
  //
  // Creates instances of child reactive sequences before body execution.

  extern task pre_body();


  // Task: body
  //
  // Runs SBINIT and then starts the exhaustive ACTIVE-phase sweep sequences.

  extern task body();

endclass : sb_sendall_vseq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: sb_sendall_vseq
//
//-----------------------------------------------------------------------------


// new
// ---

function sb_sendall_vseq::new(string name = "sb_sendall_vseq");
  super.new(name);
endfunction : new

// pre_body
// --------

task sb_sendall_vseq::pre_body();
  super.pre_body();
  tx_sendall_seq      = active_tx_sendall_seq::type_id::create("tx_sendall_seq");
  rx_sendall_seq      = active_rx_sendall_seq::type_id::create("rx_sendall_seq");
  phylink_sendall_seq = active_phylink_sendall_seq::type_id::create("phylink_sendall_seq");
endtask : pre_body

// body
// ----

task sb_sendall_vseq::body();
  fork
    begin
      sbinit_ctrl_seq.start(ltsm_ctrl_seqr);
    end

    begin
      sbinit_phylink_seq.start(phylink_seqr);
    end
  join
  #100;

  tx_sendall_seq.start(tx_seqr);
  rx_sendall_seq.start(rx_seqr);
  phylink_sendall_seq.start(phylink_seqr);
endtask : body
