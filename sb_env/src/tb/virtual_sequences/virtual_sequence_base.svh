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
// CLASS: virtual_sequence_base
//
// The virtual_sequence_base class provides a virtual base for virtual sequences
// that coordinate multiple child sequences across different sequencers. It
// maintains handles to child sequencers and their associated sequences.
//
//-----------------------------------------------------------------------------

typedef class sbinit_ctrl_sanity_seq;
typedef class sbinit_phylink_sanity_seq;

class virtual_sequence_base extends uvm_sequence;
  `uvm_object_utils(virtual_sequence_base)

  virtual_sequencer   vseqr;
  
  ltsm_ctrl_sequencer ltsm_ctrl_seqr;
  phylink_sequencer   phylink_seqr;
  tx_sequencer        tx_seqr;
  rx_sequencer        rx_seqr;


  // Function: new
  //
  // Creates a new virtual_sequence_base instance with the given name.

  extern function new(string name = "virtual_sequence_base");


  // Task: pre_body
  //
  // Retrieves virtual sequencer handle and extracts child sequencer references
  // for use by derived sequence implementations.

  extern task pre_body();

endclass : virtual_sequence_base


//-------------------------------------------------------------------------------
// IMPLEMENTATION
//-------------------------------------------------------------------------------

//-------------------------------------------------------------------------------
//
// CLASS: virtual_sequence_base
//
//-------------------------------------------------------------------------------


// new
// ---

function virtual_sequence_base::new(string name = "virtual_sequence_base");
  super.new(name);
endfunction : new

// pre_body
// ----

task virtual_sequence_base::pre_body();
  if (!$cast(vseqr, m_sequencer)) begin
    `uvm_fatal(get_type_name(), "Couldn't cast the virtual sequencer")
  end
  ltsm_ctrl_seqr = vseqr.ltsm_ctrl_seqr;
  phylink_seqr   = vseqr.phylink_seqr;
  tx_seqr        = vseqr.tx_seqr;
  rx_seqr        = vseqr.rx_seqr;
endtask : pre_body
