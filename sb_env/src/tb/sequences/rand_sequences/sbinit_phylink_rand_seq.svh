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

typedef enum {
   RAND_TILL_DETECTION
  ,RAND_TILL_TIMEOUT
} sbinit_seq_mode_e;

//-----------------------------------------------------------------------------
//
// CLASS: sbinit_phylink_rand_seq
//
// Randomized SBINIT phylink sequence that varies the early training pattern
// timing while still waiting for pattern detection or timeout.
//
//-----------------------------------------------------------------------------

class sbinit_phylink_rand_seq extends sb_sequence_base #(phylink_seq_item);
  `uvm_object_utils(sbinit_phylink_rand_seq)

  sbinit_seq_mode_e m_sbinit_seq_mode = RAND_TILL_DETECTION;
  bit timeout_detected = 0;

  // Function: new
  //
  // Creates a new sbinit_phylink_rand_seq instance with the given name.

  extern function new(string name = "sbinit_phylink_rand_seq");

  // Function: configure
  //

  extern function void configure(sbinit_seq_mode_e _sbinit_seq_mode);


  // Task: body
  //
  // Randomizes the initial and follow-up SBINIT items until the driver reports
  // pattern detection or timeout.

  extern task body();

endclass : sbinit_phylink_rand_seq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: sbinit_phylink_rand_seq
//
//-----------------------------------------------------------------------------


// new
// ---

function sbinit_phylink_rand_seq::new(string name = "sbinit_phylink_rand_seq");
  super.new(name);
endfunction : new

// configure
// ---------

function void sbinit_phylink_rand_seq::configure(sbinit_seq_mode_e _sbinit_seq_mode);
  m_sbinit_seq_mode = _sbinit_seq_mode;
endfunction : configure

// body
// ----

task sbinit_phylink_rand_seq::body();
  bit force_pattern_error = (m_sbinit_seq_mode == RAND_TILL_DETECTION)? 0 : 1;
  timeout_detected = 0;

  start_item(req);
  req.configure_randomization(._mode(SBINIT), ._is_first_iteration(1), ._force_pattern_error(force_pattern_error));
  assert(req.randomize());
  finish_item(req);
  get_response(rsp);

  if (rsp.in_pat_detected) begin
    // Pattern detected on the first item
  end else if (rsp.timeout_detected) begin
    `uvm_info(get_type_name(), "Timeout is DETECTED", UVM_DEBUG)
    timeout_detected = 1;
  end else begin
    forever begin
      start_item(req);
      req.configure_randomization(._mode(SBINIT), ._force_pattern_error(force_pattern_error));
      assert(req.randomize());
      finish_item(req);

      // Get the driver response that reports pattern detection or timeout.
      get_response(rsp);

      if (rsp.in_pat_detected) begin
        break;
      end else if (rsp.timeout_detected) begin
        `uvm_info(get_type_name(), "Timeout is DETECTED", UVM_DEBUG)
        timeout_detected = 1;
        break;
      end
    end
  end

  `uvm_info("SBINIT_RAND_SEQ", "End of sequence", UVM_LOW)

endtask : body
