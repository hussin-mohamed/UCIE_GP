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
// CLASS: sb_conc_vseq
//
// The sb_conc_vseq class extends the sanity flow with concurrent ACTIVE-phase
// traffic. After SBINIT completes, it starts the TX, RX, and phylink
// concurrent sequences in parallel.
//
//-----------------------------------------------------------------------------

class sb_conc_vseq extends sb_sanity_vseq;
  `uvm_object_utils(sb_conc_vseq)

  active_tx_conc_seq      tx_conc_seq;
  active_rx_conc_seq      rx_conc_seq;
  active_phylink_conc_seq phylink_conc_seq;

  // Function: new
  //
  // Creates a new sb_conc_vseq instance with the given name.

  extern function new(string name = "sb_conc_vseq");


  // Task: pre_body
  //
  // Creates instances of child reactive sequences before body execution.

  extern task pre_body();


  // Task: body
  //
  // Runs SBINIT and then launches the concurrent ACTIVE-phase sequences
  // together on their respective child sequencers.

  extern task body();

endclass : sb_conc_vseq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: sb_conc_vseq
//
//-----------------------------------------------------------------------------


// new
// ---

function sb_conc_vseq::new(string name = "sb_conc_vseq");
  super.new(name);
endfunction : new

// pre_body
// --------

task sb_conc_vseq::pre_body();
  super.pre_body();
  tx_conc_seq      = active_tx_conc_seq::type_id::create("tx_conc_seq");
  rx_conc_seq      = active_rx_conc_seq::type_id::create("rx_conc_seq");
  phylink_conc_seq = active_phylink_conc_seq::type_id::create("phylink_conc_seq");
endtask : pre_body

// body
// ----

task sb_conc_vseq::body();
  fork
    begin
      sbinit_ctrl_seq.start(ltsm_ctrl_seqr);
    end

    begin
      sbinit_phylink_seq.start(phylink_seqr);
    end
  join
  #100;

  fork
    begin
      tx_conc_seq.start(tx_seqr);
    end

    begin
      rx_conc_seq.start(rx_seqr);
    end

    begin
      phylink_conc_seq.start(phylink_seqr);
    end
  join

endtask : body
