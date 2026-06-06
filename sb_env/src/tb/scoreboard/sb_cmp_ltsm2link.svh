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
// CLASS: sb_cmp_ltsm2link
//
// Comparator for the LTSM-to-link path. It checks the predicted phylink item
// against the monitored DUT phylink output.
//---------------------------------------------------------------------------

class sb_cmp_ltsm2link extends sb_cmp_base #(phylink_seq_item, "LTSM2LINK_CMP");
  `uvm_component_utils(sb_cmp_ltsm2link)

  // Function: new
  //
  // Creates the LTSM-to-link comparator.

  extern function new(string name, uvm_component parent);

  // Function: set_timeout_val
  //
  // Derives the allowed latency from the phylink message format.

  extern virtual function void set_timeout_val(phylink_seq_item item);
endclass

//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: sb_cmp_ltsm2link
//
//---------------------------------------------------------------------------

// new
// ---

function sb_cmp_ltsm2link::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

// set_timeout_val
// ---------------

function void sb_cmp_ltsm2link::set_timeout_val(phylink_seq_item item);
  if (item.opcode == MSG_WO_DATA) begin
    max_allowable_latency = LTSM2LINK_RTL_LATENCY + HEADER_SER_LATENCY;
  end else if (item.opcode == MSG_W_64B_DATA) begin
    max_allowable_latency = LTSM2LINK_RTL_LATENCY + HEADER_SER_LATENCY + IDLE_LATENCY + DATA_SER_LATENCY;
  end
endfunction : set_timeout_val
