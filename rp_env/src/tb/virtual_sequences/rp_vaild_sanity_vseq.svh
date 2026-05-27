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
// CLASS: rp_vaild_sanity_vseq
//
//
//-----------------------------------------------------------------------------

class rp_vaild_sanity_vseq extends virtual_sequence_base;
  `uvm_object_utils(rp_vaild_sanity_vseq)

  ltsmc_sequence     ltsmc_seq;
  rmblink_sanity_valid_sequence  rmblink_valid_sequence;


  // Function: new
  //
  // Creates a new rp_vaild_sanity_vseq instance with the given name.

  extern function new(string name = "rp_vaild_sanity_vseq");


  // Task: pre_body
  //
  // Creates instances of child reactive sequences before body execution.

  extern task pre_body();


  // Task: body
  //
  // Runs SBINIT to completion and then launches the directed ACTIVE-phase
  // sequences on the child sequencers.

  extern task body();

endclass : rp_vaild_sanity_vseq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: rp_vaild_sanity_vseq
//
//-----------------------------------------------------------------------------


// new
// ---

function rp_vaild_sanity_vseq::new(string name = "rp_vaild_sanity_vseq");
  super.new(name);
endfunction : new

// pre_body
// --------

task rp_vaild_sanity_vseq::pre_body();
  super.pre_body();
  ltsmc_seq = ltsmc_sequence::type_id::create("ltsmc_seq");
  rmblink_valid_sequence = rmblink_sanity_valid_sequence::type_id::create("rmblink_valid_sequence");
endtask : pre_body

// body
// ----
  
task rp_vaild_sanity_vseq::body();
  valid_test_mode_e current_test;
  current_test = current_test.first();

  // Loop through all states in the enum
  do begin
    `uvm_info("VSEQ", $sformatf("======================================="), UVM_LOW)
    `uvm_info("VSEQ", $sformatf(" STARTING TEST: %s", current_test.name()), UVM_LOW)
    `uvm_info("VSEQ", $sformatf("======================================="), UVM_LOW)

    // 1. Setup LTSMC 
    ltsmc_seq.configure (._next_state_type(CUSTOM),
                         ._lane_map_code(lane_map_code_t'(0)),
                         ._error_threshold(2), // Set threshold to 2 for the error tests
                         ._half_rate(1'b1),
                         ._target_rx_enc(MBINIT_REPAIRVAL_RX_Init_Handshake));
    ltsmc_seq.start(ltsmc_seqr); 
    
    ltsmc_seq.configure (._next_state_type(NEXT),
                         ._lane_map_code(lane_map_code_t'(0)),
                         ._error_threshold(2),
                         ._half_rate(1'b1),
                         ._target_rx_enc(RESET_Reset));
    ltsmc_seq.start(ltsmc_seqr);

    // 2. Pass the current test mode to the valid sequence and execute
    rmblink_valid_sequence.test_mode = current_test;
    rmblink_valid_sequence.start(rmblink_seqr);

    // 3. Reset phases (Looping to reset state between tests)
    repeat (3) begin
      ltsmc_seq.configure (._next_state_type(NEXT),
                           ._lane_map_code(lane_map_code_t'(0)),
                           ._error_threshold(2),
                           ._half_rate(1'b1),
                           ._target_rx_enc(RESET_Reset));
      ltsmc_seq.start(ltsmc_seqr);
    end
    ltsmc_seq.configure (._next_state_type(CUSTOM),
                         ._lane_map_code(lane_map_code_t'(0)),
                         ._error_threshold(2), // Set threshold to 2 for the error tests
                         ._half_rate(1'b1),
                         ._target_rx_enc(RESET_Reset));
    ltsmc_seq.start(ltsmc_seqr); 

    // Move to the next enum test case
    current_test = current_test.next();

  end while (current_test != current_test.first()); // Stop when it loops back to the beginning

  #100;
  `uvm_info("VSEQ", "ALL 10 VALID PATTERN TESTS COMPLETED.", UVM_LOW)
endtask : body
