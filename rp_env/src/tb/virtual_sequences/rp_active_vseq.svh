// ****************************************************************************
// * *
// * Copyright (c) 2014-2015 Synopsys Inc. All rights reserved.               *
// * *
// * Synopsys Proprietary and Confidential. This file contains confidential   *
// * information and the trade secrets of Synopsys Inc. Use, disclosure, or   *
// * reproduction is prohibited without the prior express written permission  *
// * of Synopsys, Inc.                                                        *
// * *
// * Synopsys, Inc.                                                           *
// * 700 East Middlefield Road                                                *
// * Mountain View, California 94043                                          *
// * (800) 541-7737                                                           *
// * *
// ****************************************************************************


//-----------------------------------------------------------------------------
//
// CLASS: rp_active_vseq
//
// Virtual sequence to test direct jumps into the ACTIVE state and execute 
// standard data transactions on the rmblink interface.
//
//-----------------------------------------------------------------------------

class rp_active_vseq extends virtual_sequence_base;
  `uvm_object_utils(rp_active_vseq)

  ltsmc_sequence          ltsmc_seq;
  rmblink_active_sequence rmblink_seq;

  extern function new(string name = "rp_active_vseq");
  extern task pre_body();
  extern task body();
  
  // Helper task to jump to active and send data
  extern task execute_active_scenario(lane_map_code_t map_code, string scen_name);

endclass : rp_active_vseq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

function rp_active_vseq::new(string name = "rp_active_vseq");
  super.new(name);
endfunction : new

task rp_active_vseq::pre_body();
  super.pre_body();
  ltsmc_seq   = ltsmc_sequence::type_id::create("ltsmc_seq");
  rmblink_seq = rmblink_active_sequence::type_id::create("rmblink_seq");
endtask : pre_body


task rp_active_vseq::execute_active_scenario(lane_map_code_t map_code, string scen_name);
  `uvm_info("VSEQ_ACTIVE", $sformatf("========================================"), UVM_LOW)
  `uvm_info("VSEQ_ACTIVE", $sformatf(" RUNNING: %s", scen_name), UVM_LOW)
  `uvm_info("VSEQ_ACTIVE", $sformatf(" MODE:    %0s", map_code.name()), UVM_LOW)
  `uvm_info("VSEQ_ACTIVE", $sformatf("========================================"), UVM_LOW)

  // 1. Force a clean RESET
  ltsmc_seq.configure(
     ._next_state_type(CUSTOM)
    ,._lane_map_code(map_code)
    ,._error_threshold(0)
    ,._half_rate(1'b1)
    ,._target_rx_enc(RESET_Reset)
  );
  ltsmc_seq.start(ltsmc_seqr);

  // 2. Jump directly to the start of the Active Phase Initialization
  ltsmc_seq.configure(
     ._next_state_type(CUSTOM)
    ,._lane_map_code(map_code)
    ,._error_threshold(0)
    ,._half_rate(1'b1)
    ,._target_rx_enc(LINKINIT_RX_PL_Clk_Req_Handshake)
  );
  ltsmc_seq.start(ltsmc_seqr);

  // 3. Traverse through the LINKINIT handshakes until locked in ACTIVE_RX_Active
  ltsmc_seq.configure(
     ._next_state_type(TRAVERSE)
    ,._lane_map_code(map_code)
    ,._error_threshold(0)
    ,._half_rate(1'b1)
    ,._target_rx_enc(ACTIVE_RX_Active)
  );
  ltsmc_seq.start(ltsmc_seqr);

  // 4. Fire the RMBLINK physical stimulus burst (Directed Data)
  rmblink_seq.num_iterations = 1000;               // Send 20 cycles of data
  rmblink_seq.directed_data  = $urandom();         // Alternating 0/1 directed payload
  rmblink_seq.start(rmblink_seqr);

  #50ns;
endtask


task rp_active_vseq::body();

  // Test standard X16 mode ACTIVE data transfer
  execute_active_scenario(X8_LOWER_MODE, "Simple Directed Data Transfer in ACTIVE State");

  `uvm_info("VSEQ_ACTIVE", "ACTIVE state data transfer completed successfully.", UVM_LOW)

endtask : body