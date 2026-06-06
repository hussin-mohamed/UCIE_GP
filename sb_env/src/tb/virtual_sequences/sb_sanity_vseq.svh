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
// CLASS: sb_sanity_vseq
//
// The sb_sanity_vseq class coordinates the basic directed sideband flow. It
// first launches the SBINIT control and phylink initialization sequences in
// parallel, then starts a short directed ACTIVE-phase sequence on the TX, RX,
// and phylink agents.
//
//-----------------------------------------------------------------------------

class sb_sanity_vseq extends virtual_sequence_base;
  `uvm_object_utils(sb_sanity_vseq)

  sbinit_ctrl_sanity_seq     sbinit_ctrl_seq;
  sbinit_phylink_sanity_seq  sbinit_phylink_seq;
  active_tx_sanity_seq       active_tx_seq;
  active_rx_sanity_seq       active_rx_seq;
  active_phylink_sanity_seq  active_phylink_seq;


  // Function: new
  //
  // Creates a new sb_sanity_vseq instance with the given name.

  extern function new(string name = "sb_sanity_vseq");


  // Task: pre_body
  //
  // Creates instances of child reactive sequences before body execution.

  extern task pre_body();


  // Task: body
  //
  // Runs SBINIT to completion and then launches the directed ACTIVE-phase
  // sequences on the child sequencers.

  extern task body();

endclass : sb_sanity_vseq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: sb_sanity_vseq
//
//-----------------------------------------------------------------------------


// new
// ---

function sb_sanity_vseq::new(string name = "sb_sanity_vseq");
  super.new(name);
endfunction : new

// pre_body
// --------

task sb_sanity_vseq::pre_body();
  super.pre_body();
  sbinit_ctrl_seq    = sbinit_ctrl_sanity_seq::type_id::create("sbinit_ctrl_seq");
  sbinit_phylink_seq = sbinit_phylink_sanity_seq::type_id::create("sbinit_phylink_seq");
  active_tx_seq      = active_tx_sanity_seq::type_id::create("active_tx_seq");
  active_rx_seq      = active_rx_sanity_seq::type_id::create("active_rx_seq");
  active_phylink_seq = active_phylink_sanity_seq::type_id::create("active_phylink_seq");
endtask : pre_body

// body
// ----

task sb_sanity_vseq::body();
  fork
    begin
      sbinit_ctrl_seq.start(ltsm_ctrl_seqr);
    end

    begin
      sbinit_phylink_seq.start(phylink_seqr);
    end
  join
  #100;

  active_tx_seq.start(tx_seqr);
  active_phylink_seq.start(phylink_seqr);
  active_rx_seq.start(rx_seqr);
endtask : body
