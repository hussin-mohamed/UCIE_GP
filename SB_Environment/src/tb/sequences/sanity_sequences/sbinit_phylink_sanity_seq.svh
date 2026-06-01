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
// CLASS: sbinit_phylink_sanity_seq
//
// Directed SBINIT phylink sequence that sends the training pattern until the
// remote side reports pattern detection or a timeout.
//
//-----------------------------------------------------------------------------

class sbinit_phylink_sanity_seq extends sb_sequence_base #(phylink_seq_item);
  `uvm_object_utils(sbinit_phylink_sanity_seq)


  // Function: new
  //
  // Creates a new sbinit_phylink_sanity_seq instance with the given name.

  extern function new(string name = "sbinit_phylink_sanity_seq");


  // Task: body
  //
  // Drives deterministic SBINIT pattern iterations and reacts to driver status.

  extern task body();

endclass : sbinit_phylink_sanity_seq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: sbinit_phylink_sanity_seq
//
// Implements the directed SBINIT phylink handshake.
//
//-----------------------------------------------------------------------------


// new
// ---

function sbinit_phylink_sanity_seq::new(string name = "sbinit_phylink_sanity_seq");
  super.new(name);
endfunction : new

// body
// ----
//
// Sends the first out-of-reset iteration, then continues with steady-state
// SBINIT patterns until pattern detection or timeout is reported.

task sbinit_phylink_sanity_seq::body();
  start_item(req);
  req.op_mode           = SBINIT;
  req.pattern           = `SBINIT_PATTERN;
  req.idle_ui_cnt       = 32;
  req.out_of_rst_ui_cnt = 1000;
  finish_item(req);
  forever begin
    start_item(req);
    req.op_mode           = SBINIT;
    req.pattern           = `SBINIT_PATTERN;
    req.idle_ui_cnt       = 32;
    req.out_of_rst_ui_cnt = 0;
    finish_item(req);

    // Get the driver response that reports pattern detection or timeout.
    get_response(rsp);

    if (rsp.pat_detected) begin
      `uvm_info(get_type_name(), "Pattern is DETECTED, Sending 4 more pattern iterations...", UVM_DEBUG)
      for (int i = 0; i < 1; i++) begin
        start_item(req);
        `uvm_info(get_type_name(), $sformatf("ITERATION%0d...", i), UVM_DEBUG)
        req.op_mode           = SBINIT;
        req.pattern           = `SBINIT_PATTERN;
        req.idle_ui_cnt       = 32;
        req.out_of_rst_ui_cnt = 0;
        finish_item(req);
      end
      break;
    end else if (rsp.timeout_detected) begin
      `uvm_info(get_type_name(), "Timeout is DETECTED", UVM_DEBUG)
      break;
    end
  end

endtask : body
