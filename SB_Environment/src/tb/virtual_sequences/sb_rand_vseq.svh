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
// CLASS: sb_rand_vseq
//
// The sb_rand_vseq class extends the sanity flow with randomized SBINIT
// phylink behavior and high-volume randomized ACTIVE traffic on all active
// interfaces.
//
//-----------------------------------------------------------------------------

class sb_rand_vseq extends sb_sanity_vseq;
  `uvm_object_utils(sb_rand_vseq)

  sbinit_phylink_rand_seq    sbinit_rand_seq;
  active_tx_rand_seq         tx_rand_seq;
  active_rx_rand_seq         rx_rand_seq;
  active_phylink_rand_seq    phylink_rand_seq;
  // active_phylink_conc_seq phylink_conc_seq;

  // Function: new
  //
  // Creates a new sb_rand_vseq instance with the given name.

  extern function new(string name = "sb_rand_vseq");


  // Task: pre_body
  //
  // Creates instances of child reactive sequences before body execution.

  extern task pre_body();


  // Task: body
  //
  // Runs randomized SBINIT link activity and then starts the randomized
  // ACTIVE-phase sequences.

  extern task body();

endclass : sb_rand_vseq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: sb_rand_vseq
//
//-----------------------------------------------------------------------------


// new
// ---

function sb_rand_vseq::new(string name = "sb_rand_vseq");
  super.new(name);
endfunction : new

// pre_body
// --------

task sb_rand_vseq::pre_body();
  super.pre_body();
  sbinit_rand_seq  = sbinit_phylink_rand_seq::type_id::create("sbinit_rand_seq");
  tx_rand_seq      = active_tx_rand_seq::type_id::create("tx_rand_seq");
  rx_rand_seq      = active_rx_rand_seq::type_id::create("rx_rand_seq");
  phylink_rand_seq = active_phylink_rand_seq::type_id::create("phylink_rand_seq");
endtask : pre_body

// body
// ----

task sb_rand_vseq::body();
  fork
    begin
      sbinit_ctrl_seq.start(ltsm_ctrl_seqr);
    end

    begin
      sbinit_rand_seq.start(phylink_seqr);
    end
  join
  #100;

  tx_rand_seq.start(tx_seqr);
  rx_rand_seq.start(rx_seqr);
  phylink_rand_seq.start(phylink_seqr);

  // active_phylink_seq.start(phylink_seqr);
  // fork
  //   begin
  //   end

  //   begin
  //     rx_conc_seq.start(rx_seqr);
  //   end

  //   begin
  //     phylink_conc_seq.start(phylink_seqr);
  //   end
  // join

endtask : body
