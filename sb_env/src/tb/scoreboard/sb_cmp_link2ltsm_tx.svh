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

//---------------------------------------------------------------------------
//
// CLASS: sb_cmp_link2ltsm_tx
//
// Comparator for messages predicted to land on the TX-side LTSM output after
// link-level decoding.
//---------------------------------------------------------------------------

class sb_cmp_link2ltsm_tx extends sb_cmp_base #(ltsm_seq_item, "RX_LINK2LTSM_CMP");
  `uvm_component_utils(sb_cmp_link2ltsm_tx)

  // Function: new
  //
  // Creates the TX-side link-to-LTSM comparator.

  extern function new(string name, uvm_component parent);

  // Function: set_timeout_val
  //
  // Uses the fixed link-to-LTSM RTL latency budget for TX-side items.

  extern virtual function void set_timeout_val(ltsm_seq_item item);
endclass

//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: sb_cmp_link2ltsm_tx
//
//---------------------------------------------------------------------------

// new
// ---

function sb_cmp_link2ltsm_tx::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

// set_timeout_val
// ---------------

function void sb_cmp_link2ltsm_tx::set_timeout_val(ltsm_seq_item item);
  max_allowable_latency = LINK2LTSM_RTL_LATENCY;
endfunction : set_timeout_val
