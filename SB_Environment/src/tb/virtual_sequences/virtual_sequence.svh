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
// CLASS: sbinit_sanity_vseq
//
// ...
//
//-----------------------------------------------------------------------------

class sbinit_sanity_vseq extends virtual_sequence_base;
  `uvm_object_utils(sbinit_sanity_vseq)

  sbinit_ctrl_sanity_seq    ctrl_sanity_seq;
  sbinit_phylink_sanity_seq phylink_sanity_seq;


  // Function: new
  //
  // Creates a new sbinit_sanity_vseq instance with the given name.

  extern function new(string name = "sbinit_sanity_vseq");


  // Task: pre_body
  //
  // Creates instances of child reactive sequences before body execution.

  extern task pre_body();


  // Task: body
  //
  // Retrieves sequencer handles via base class, then starts both reactive
  // sequences on their respective sequencers sequentially.

  extern task body();

endclass : sbinit_sanity_vseq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS- sbinit_sanity_vseq
//
//-----------------------------------------------------------------------------


// new
// ---

function sbinit_sanity_vseq::new(string name = "sbinit_sanity_vseq");
  super.new(name);
endfunction : new

// pre_body
// --------

task sbinit_sanity_vseq::pre_body();
  ctrl_sanity_seq    = sbinit_ctrl_sanity_seq::type_id::create("ctrl_sanity_seq");
  phylink_sanity_seq = sbinit_phylink_sanity_seq::type_id::create("phylink_sanity_seq");
endtask : pre_body

// body
// ----

task sbinit_sanity_vseq::body();
  super.body();
  fork
    begin
      ctrl_sanity_seq.start(ltsm_ctrl_seqr);
    end

    begin
      phylink_sanity_seq.start(phylink_seqr);
    end
  join

  // @(timeout_triggered);
  // disable fork;
endtask : body
