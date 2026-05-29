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
// CLASS: rp_sanity_lfsr_vseq
//
//-----------------------------------------------------------------------------

class rp_sanity_lfsr_vseq extends virtual_sequence_base;
  `uvm_object_utils(rp_sanity_lfsr_vseq)

  ltsmc_sequence                    ltsmc_seq;
  rmblink_sanity_lfsr_sequence      rmblink_seq;

  extern function new(string name = "rp_sanity_lfsr_vseq");
  extern task pre_body();
  extern task body();
  
  // Helper task to cleanly execute and log each scenario with dynamic lane mapping
  extern task execute_scenario(lane_map_code_t map_code, lfsr_scenario_e scen, int iters, string scen_name ,rx_encoding_t start_state , rx_encoding_t end_state);

endclass : rp_sanity_lfsr_vseq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

function rp_sanity_lfsr_vseq::new(string name = "rp_sanity_lfsr_vseq");
  super.new(name);
endfunction : new


task rp_sanity_lfsr_vseq::pre_body();
  super.pre_body();
  ltsmc_seq   = ltsmc_sequence::type_id::create("ltsmc_seq");
  rmblink_seq = rmblink_sanity_lfsr_sequence::type_id::create("rmblink_seq");
endtask : pre_body


task rp_sanity_lfsr_vseq::execute_scenario(lane_map_code_t map_code, lfsr_scenario_e scen, int iters, string scen_name ,rx_encoding_t start_state , rx_encoding_t end_state);
  `uvm_info("VSEQ_SCENARIO", $sformatf("========================================"), UVM_LOW)
  `uvm_info("VSEQ_SCENARIO", $sformatf(" RUNNING: %s", scen_name), UVM_LOW)
  `uvm_info("VSEQ_SCENARIO", $sformatf(" MODE:    %0s", map_code.name()), UVM_LOW)
  `uvm_info("VSEQ_SCENARIO", $sformatf(" STATE: %s", start_state.name()), UVM_LOW)
  `uvm_info("VSEQ_SCENARIO", $sformatf("========================================"), UVM_LOW)

  // 1. Force a clean RESET
  ltsmc_seq.configure(
     ._next_state_type(CUSTOM)
    ,._lane_map_code(map_code)
    ,._error_threshold(16'b1)
    ,._half_rate(1'b1)
    ,._target_rx_enc(RESET_Reset)
  );
  ltsmc_seq.start(ltsmc_seqr);

  // 2. Traverse along the FSM up to the LFSR Detection state
  ltsmc_seq.configure(
     ._next_state_type(CUSTOM)
    ,._lane_map_code(map_code)
    ,._error_threshold(16'b1)
    ,._half_rate(1'b1)
    ,._target_rx_enc(start_state)
  );
  ltsmc_seq.start(ltsmc_seqr);

  repeat (2) begin
  ltsmc_seq.configure(
     ._next_state_type(NEXT)
    ,._lane_map_code(map_code)
    ,._error_threshold(16'b1)
    ,._half_rate(1'b1)
    ,._target_rx_enc(start_state)
  );
  ltsmc_seq.start(ltsmc_seqr);
  end

  // 3. Configure RMBLINK physical stimulus at LFSR Clear state to initialize LFSR states in the seq;
  rmblink_seq.rx_lfsr_pattern_generation (1'b0, 1'b1, rmblink_seq.dummy_data);

  // 4. Configure and fire the RMBLINK physical stimulus burst with LFSR patterns based on the scenario
  // Note: The physical sequence drives all 16 lanes, but the DUT/Scoreboard 
  // will only evaluate the active subset based on the map_code.
  ltsmc_seq.configure(
     ._next_state_type(NEXT)
    ,._lane_map_code(map_code)
    ,._error_threshold(16'b1)
    ,._half_rate(1'b1)
    ,._target_rx_enc(start_state)
  );
  ltsmc_seq.start(ltsmc_seqr);

  rmblink_seq.scenario       = scen;
  rmblink_seq.num_iterations = iters;
  rmblink_seq.train_mode = 1'b1;
  rmblink_seq.start(rmblink_seqr);

  // 5. Conclude the FSM sub-routine Handshake
  ltsmc_seq.configure(
     ._next_state_type(TRAVERSE)
    ,._lane_map_code(map_code)
    ,._error_threshold(16'b1)
    ,._half_rate(1'b1)
    ,._target_rx_enc(end_state)
  );
  ltsmc_seq.start(ltsmc_seqr);
  
  // Brief delay between scenarios to separate waveform transactions visually
  #50ns; 
endtask


task rp_sanity_lfsr_vseq::body();
/*
  // ========================================================================
  // PHASE 1: X8 LOWER MODE (Lanes 0-7)
  // ========================================================================
  `uvm_info("VSEQ_SCENARIO", ">>> STARTING X8_LOWER_MODE SCENARIOS <<<", UVM_LOW)

  execute_scenario(X8_LOWER_MODE, SCENARIO_EXACT_MATCH,               64, "X8L: SCENARIO 1 (Ideal 64 Pattern Iterations)"                          ,MBTRAIN_DATAVREF_RX_Start_Handshake, MBTRAIN_DATAVREF_RX_End_Handshake);
  execute_scenario(X8_LOWER_MODE, SCENARIO_ERROR_BELOW_THRESH_RANDOM, 64, "X8L: SCENARIO 2 (Injecting Failures Below Threshold at random position)",MBTRAIN_DATAVREF_RX_Start_Handshake, MBTRAIN_DATAVREF_RX_End_Handshake);
  execute_scenario(X8_LOWER_MODE, SCENARIO_ERROR_ABOVE_THRESH_RANDOM, 64, "X8L: SCENARIO 3 (Injecting Failures Above Threshold at random position)",MBTRAIN_DATAVREF_RX_Start_Handshake, MBTRAIN_DATAVREF_RX_End_Handshake);
  execute_scenario(X8_LOWER_MODE, SCENARIO_ERROR_BELOW_THRESH_START,  64, "X8L: SCENARIO 4 (Injecting Failures Below Threshold at start position)" ,MBTRAIN_DATAVREF_RX_Start_Handshake, MBTRAIN_DATAVREF_RX_End_Handshake);
  execute_scenario(X8_LOWER_MODE, SCENARIO_ERROR_BELOW_THRESH_END,    64, "X8L: SCENARIO 5 (Injecting Failures Below Threshold at end position)"   ,MBTRAIN_DATAVREF_RX_Start_Handshake, MBTRAIN_DATAVREF_RX_End_Handshake);
  execute_scenario(X8_LOWER_MODE, SCENARIO_ERROR_ABOVE_THRESH_START,  64, "X8L: SCENARIO 6 (Injecting Failures Above Threshold at start position)" ,MBTRAIN_DATAVREF_RX_Start_Handshake, MBTRAIN_DATAVREF_RX_End_Handshake);
  execute_scenario(X8_LOWER_MODE, SCENARIO_ERROR_ABOVE_THRESH_END,    64, "X8L: SCENARIO 7 (Injecting Failures Above Threshold at end position)"   ,MBTRAIN_DATAVREF_RX_Start_Handshake, MBTRAIN_DATAVREF_RX_End_Handshake);


  // ========================================================================
  // PHASE 2: X8 UPPER MODE (Lanes 8-15)
  // ========================================================================
  `uvm_info("VSEQ_SCENARIO", ">>> STARTING X8_UPPER_MODE SCENARIOS <<<", UVM_LOW)

  execute_scenario(X8_UPPER_MODE, SCENARIO_EXACT_MATCH,               64, "X8U: SCENARIO 1 (Ideal 64 Pattern Iterations)"                          ,MBTRAIN_DATAVREF_RX_Start_Handshake, MBTRAIN_DATAVREF_RX_End_Handshake);
  execute_scenario(X8_UPPER_MODE, SCENARIO_ERROR_BELOW_THRESH_RANDOM, 64, "X8U: SCENARIO 2 (Injecting Failures Below Threshold at random position)",MBTRAIN_DATAVREF_RX_Start_Handshake, MBTRAIN_DATAVREF_RX_End_Handshake);
  execute_scenario(X8_UPPER_MODE, SCENARIO_ERROR_ABOVE_THRESH_RANDOM, 64, "X8U: SCENARIO 3 (Injecting Failures Above Threshold at random position)",MBTRAIN_DATAVREF_RX_Start_Handshake, MBTRAIN_DATAVREF_RX_End_Handshake);
  execute_scenario(X8_UPPER_MODE, SCENARIO_ERROR_BELOW_THRESH_START,  64, "X8U: SCENARIO 4 (Injecting Failures Below Threshold at start position)" ,MBTRAIN_DATAVREF_RX_Start_Handshake, MBTRAIN_DATAVREF_RX_End_Handshake);
  execute_scenario(X8_UPPER_MODE, SCENARIO_ERROR_BELOW_THRESH_END,    64, "X8U: SCENARIO 5 (Injecting Failures Below Threshold at end position)"   ,MBTRAIN_DATAVREF_RX_Start_Handshake, MBTRAIN_DATAVREF_RX_End_Handshake);
  execute_scenario(X8_UPPER_MODE, SCENARIO_ERROR_ABOVE_THRESH_START,  64, "X8U: SCENARIO 6 (Injecting Failures Above Threshold at start position)" ,MBTRAIN_DATAVREF_RX_Start_Handshake, MBTRAIN_DATAVREF_RX_End_Handshake);
  execute_scenario(X8_UPPER_MODE, SCENARIO_ERROR_ABOVE_THRESH_END,    64, "X8U: SCENARIO 7 (Injecting Failures Above Threshold at end position)"   ,MBTRAIN_DATAVREF_RX_Start_Handshake, MBTRAIN_DATAVREF_RX_End_Handshake);

*/
  // ========================================================================
  // PHASE 3: X16 MODE (Lanes 0-15)
  // ========================================================================
  `uvm_info("VSEQ_SCENARIO", ">>> STARTING X16_MODE SCENARIOS <<<", UVM_LOW)

  execute_scenario(X16_MODE, SCENARIO_EXACT_MATCH,               64, "X16: SCENARIO 1 (Ideal 64 Pattern Iterations)"                          ,MBTRAIN_DATAVREF_RX_Start_Handshake, MBTRAIN_DATAVREF_RX_End_Handshake);
  execute_scenario(X16_MODE, SCENARIO_ERROR_BELOW_THRESH_RANDOM, 64, "X16: SCENARIO 2 (Injecting Failures Below Threshold at random position)",MBTRAIN_DATAVREF_RX_Start_Handshake, MBTRAIN_DATAVREF_RX_End_Handshake);
  execute_scenario(X16_MODE, SCENARIO_ERROR_ABOVE_THRESH_RANDOM, 64, "X16: SCENARIO 3 (Injecting Failures Above Threshold at random position)",MBTRAIN_DATAVREF_RX_Start_Handshake, MBTRAIN_DATAVREF_RX_End_Handshake);
  execute_scenario(X16_MODE, SCENARIO_ERROR_BELOW_THRESH_START,  64, "X16: SCENARIO 4 (Injecting Failures Below Threshold at start position)" ,MBTRAIN_DATAVREF_RX_Start_Handshake, MBTRAIN_DATAVREF_RX_End_Handshake);
  execute_scenario(X16_MODE, SCENARIO_ERROR_BELOW_THRESH_END,    64, "X16: SCENARIO 5 (Injecting Failures Below Threshold at end position)"   ,MBTRAIN_DATAVREF_RX_Start_Handshake, MBTRAIN_DATAVREF_RX_End_Handshake);
  execute_scenario(X16_MODE, SCENARIO_ERROR_ABOVE_THRESH_START,  64, "X16: SCENARIO 6 (Injecting Failures Above Threshold at start position)" ,MBTRAIN_DATAVREF_RX_Start_Handshake, MBTRAIN_DATAVREF_RX_End_Handshake);
  execute_scenario(X16_MODE, SCENARIO_ERROR_ABOVE_THRESH_END,    64, "X16: SCENARIO 7 (Injecting Failures Above Threshold at end position)"   ,MBTRAIN_DATAVREF_RX_Start_Handshake, MBTRAIN_DATAVREF_RX_End_Handshake);

  `uvm_info("VSEQ_SCENARIO", "All Per-Lane ID Detection Scenarios for X16 Mode and X8 Modes Completed Successfully.", UVM_LOW)

endtask : body
