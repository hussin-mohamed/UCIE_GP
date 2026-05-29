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
// CLASS: rp_sanity_PerLaneID_vseq
//
//-----------------------------------------------------------------------------

class rp_sanity_PerLaneID_vseq extends virtual_sequence_base;
  `uvm_object_utils(rp_sanity_PerLaneID_vseq)

  ltsmc_sequence                    ltsmc_seq;
  rmblink_sanity_PerLaneID_sequence rmblink_seq;

  extern function new(string name = "rp_sanity_PerLaneID_vseq");
  extern task pre_body();
  extern task body();
  
  // Helper task to cleanly execute and log each scenario with dynamic lane mapping
  extern task execute_scenario(lane_map_code_t map_code, per_lane_scenario_e scen, int iters, string scen_name);

endclass : rp_sanity_PerLaneID_vseq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

function rp_sanity_PerLaneID_vseq::new(string name = "rp_sanity_PerLaneID_vseq");
  super.new(name);
endfunction : new


task rp_sanity_PerLaneID_vseq::pre_body();
  super.pre_body();
  ltsmc_seq   = ltsmc_sequence::type_id::create("ltsmc_seq");
  rmblink_seq = rmblink_sanity_PerLaneID_sequence::type_id::create("rmblink_seq");
endtask : pre_body


task rp_sanity_PerLaneID_vseq::execute_scenario(lane_map_code_t map_code, per_lane_scenario_e scen, int iters, string scen_name);
  `uvm_info("VSEQ_SCENARIO", $sformatf("========================================"), UVM_LOW)
  `uvm_info("VSEQ_SCENARIO", $sformatf(" RUNNING: %s", scen_name), UVM_LOW)
  `uvm_info("VSEQ_SCENARIO", $sformatf(" MODE:    %0s", map_code.name()), UVM_LOW)
  `uvm_info("VSEQ_SCENARIO", $sformatf("========================================"), UVM_LOW)

  // 1. Force a clean RESET
  ltsmc_seq.configure(
     ._next_state_type(CUSTOM)
    ,._lane_map_code(map_code)
    ,._error_threshold(0)
    ,._half_rate(1'b1)
    ,._target_rx_enc(RESET_Reset)
  );
  ltsmc_seq.start(ltsmc_seqr);

  // 2. Traverse along the FSM up to the MBINIT.REPAIRMB Start Handshake state
  ltsmc_seq.configure(
     ._next_state_type(CUSTOM)
    ,._lane_map_code(map_code)
    ,._error_threshold(0)
    ,._half_rate(1'b1)
    ,._target_rx_enc(MBINIT_REPAIRMB_RX_Init_Handshake)
  );
  ltsmc_seq.start(ltsmc_seqr);

  // 3. Traverse along the FSM up to the Per-Lane ID Detection state
  ltsmc_seq.configure(
     ._next_state_type(TRAVERSE)
    ,._lane_map_code(map_code)
    ,._error_threshold(0)
    ,._half_rate(1'b1)
    ,._target_rx_enc(Data_To_Clock_test_RX_Pattern_Detection_TX_Init)
  );
  ltsmc_seq.start(ltsmc_seqr);

  // 4. Configure and fire the RMBLINK physical stimulus burst
  // Note: The physical sequence drives all 16 lanes, but the DUT/Scoreboard 
  // will only evaluate the active subset based on the map_code.
  rmblink_seq.configure(
     ._scenario(scen)
    ,._num_iterations(iters)
    ,._lane_map_code(map_code)
    ,._mixed_mode(MIXED_ALTERNATING)
  );
  rmblink_seq.start(rmblink_seqr);

  // 4. Conclude the FSM sub-routine Handshake
  ltsmc_seq.configure(
     ._next_state_type(TRAVERSE)
    ,._lane_map_code(map_code)
    ,._error_threshold(0)
    ,._half_rate(1'b1)
    ,._target_rx_enc(MBINIT_REPAIRMB_RX_Done_Handshake)
  );
  ltsmc_seq.start(ltsmc_seqr);

  // Brief delay between scenarios to separate waveform transactions visually
  #50ns; 
endtask


task rp_sanity_PerLaneID_vseq::body();

  // ========================================================================
  // PHASE 1: X8 LOWER MODE (Lanes 0-7)
  // ========================================================================
  `uvm_info("VSEQ_SCENARIO", ">>> STARTING X8_LOWER_MODE SCENARIOS <<<", UVM_LOW)
  
  execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, 32, "X8_LOWER: SCENARIO 1 (Ideal 32 Pattern Iterations)");
  execute_scenario(X8_LOWER_MODE, SCENARIO_FAIL_MIDWAY, 32, "X8_LOWER: SCENARIO 2 (Injecting Failures Midway)");
  execute_scenario(X8_LOWER_MODE, SCENARIO_NOISE_THEN_IDEAL, 47, "X8_LOWER: SCENARIO 3 (Random Noise Then Ideal)");
  execute_scenario(X8_LOWER_MODE, SCENARIO_WRONG_LANE_ID, 32, "X8_LOWER: SCENARIO 4 (Valid Framing but Wrong Lane IDs)");
  execute_scenario(X8_LOWER_MODE, SCENARIO_RANDOM_INTERLEAVED, 100, "X8_LOWER: SCENARIO 5 (Highly Randomized Interleaved)");
  execute_scenario(X8_LOWER_MODE, SCENARIO_MIXED_SUCCESS, 32, "X8_LOWER: SCENARIO 6 (Mixed Success - Even Lanes Pass, Odd Fail)");
  execute_scenario(X8_LOWER_MODE, SCENARIO_LATE_SUCCESS, 32, "X8_LOWER: SCENARIO 7 (Late Success - Last 16 patterns valid for Even Lanes)");
  execute_scenario(X8_LOWER_MODE, SCENARIO_THRESHOLD_TEASER, 32, "X8_LOWER: SCENARIO 8 (Threshold Teaser - Sends exactly 15 valid words, then 1 garbage word, then repeats.)");


  // ========================================================================
  // PHASE 2: X8 UPPER MODE (Lanes 8-15)
  // ========================================================================
  `uvm_info("VSEQ_SCENARIO", ">>> STARTING X8_UPPER_MODE SCENARIOS <<<", UVM_LOW)
  
  execute_scenario(X8_UPPER_MODE, SCENARIO_IDEAL, 32, "X8_UPPER: SCENARIO 1 (Ideal 32 Pattern Iterations)");
  execute_scenario(X8_UPPER_MODE, SCENARIO_FAIL_MIDWAY, 32, "X8_UPPER: SCENARIO 2 (Injecting Failures Midway)");
  execute_scenario(X8_UPPER_MODE, SCENARIO_NOISE_THEN_IDEAL, 47, "X8_UPPER: SCENARIO 3 (Random Noise Then Ideal)");
  execute_scenario(X8_UPPER_MODE, SCENARIO_WRONG_LANE_ID, 32, "X8_UPPER: SCENARIO 4 (Valid Framing but Wrong Lane IDs)");
  execute_scenario(X8_UPPER_MODE, SCENARIO_RANDOM_INTERLEAVED, 100, "X8_UPPER: SCENARIO 5 (Highly Randomized Interleaved)");
  execute_scenario(X8_UPPER_MODE, SCENARIO_MIXED_SUCCESS, 32, "X8_UPPER: SCENARIO 6 (Mixed Success - Even Lanes Pass, Odd Fail)");
  execute_scenario(X8_UPPER_MODE, SCENARIO_LATE_SUCCESS, 32, "X8_UPPER: SCENARIO 7 (Late Success - Last 16 patterns valid for Even Lanes)");
  execute_scenario(X8_UPPER_MODE, SCENARIO_THRESHOLD_TEASER, 32, "X8_UPPER: SCENARIO 8 (Threshold Teaser - Sends exactly 15 valid words, then 1 garbage word, then repeats.)");


  // ========================================================================
  // PHASE 3: X16 MODE (Lanes 0-15)
  // ========================================================================
  `uvm_info("VSEQ_SCENARIO", ">>> STARTING X16_MODE SCENARIOS <<<", UVM_LOW)
  execute_scenario(X16_MODE, SCENARIO_IDEAL, 32, "X16: SCENARIO 1 (Ideal 32 Pattern Iterations)");
  execute_scenario(X16_MODE, SCENARIO_FAIL_MIDWAY, 32, "X16: SCENARIO 2 (Injecting Failures Midway)");
  execute_scenario(X16_MODE, SCENARIO_NOISE_THEN_IDEAL, 47, "X16: SCENARIO 3 (Random Noise Then Ideal)");
  execute_scenario(X16_MODE, SCENARIO_WRONG_LANE_ID, 32, "X16: SCENARIO 4 (Valid Framing but Wrong Lane IDs)");
  execute_scenario(X16_MODE, SCENARIO_RANDOM_INTERLEAVED, 100, "X16: SCENARIO 5 (Highly Randomized Interleaved)");
  execute_scenario(X16_MODE, SCENARIO_MIXED_SUCCESS, 32, "X16: SCENARIO 6 (Mixed Success - Even Lanes Pass, Odd Fail)");
  execute_scenario(X16_MODE, SCENARIO_LATE_SUCCESS, 32, "X16: SCENARIO 7 (Late Success - Last 16 patterns valid for Even Lanes)");
  execute_scenario(X16_MODE, SCENARIO_THRESHOLD_TEASER, 32, "X16: SCENARIO 8 (Threshold Teaser - Sends exactly 15 valid words, then 1 garbage word, then repeats.)");

  `uvm_info("VSEQ_SCENARIO", "All Per-Lane ID Detection Scenarios for X16 Mode and X8 Modes Completed Successfully.", UVM_LOW)

endtask : body


// // 1. Force a clean RESET
//   ltsmc_seq.configure(
//      ._next_state_type(CUSTOM)
//     ,._lane_map_code(map_code)
//     ,._error_threshold(0)
//     ,._half_rate(1'b1)
//     ,._target_rx_enc(RESET_Reset)
//   );
//   ltsmc_seq.start(ltsmc_seqr);

//   // 2. Traverse along the FSM up to the Per-Lane ID Detection state
//   ltsmc_seq.configure(
//      ._next_state_type(CUSTOM)
//     ,._lane_map_code(map_code)
//     ,._error_threshold(0)
//     ,._half_rate(1'b1)
//     ,._target_rx_enc(MBINIT_REPAIRMB_RX_Init_Handshake)
//   );
//   ltsmc_seq.start(ltsmc_seqr);
//   ltsmc_seq.configure(
//      ._next_state_type(TRAVERSE)
//     ,._lane_map_code(map_code)
//     ,._error_threshold(0)
//     ,._half_rate(1'b1)
//     ,._target_rx_enc(Data_To_Clock_test_RX_Pattern_Detection_TX_Init)
//   );
//   ltsmc_seq.start(ltsmc_seqr);

//   // 3. Configure and fire the RMBLINK physical stimulus burst
//   // Note: The physical sequence drives all 16 lanes, but the DUT/Scoreboard 
//   // will only evaluate the active subset based on the map_code.
//   rmblink_seq.scenario       = scen;
//   rmblink_seq.num_iterations = iters;
//   rmblink_seq.start(rmblink_seqr);

//   // 4. Conclude the FSM sub-routine Handshake
//   ltsmc_seq.configure(
//      ._next_state_type(TRAVERSE)
//     ,._lane_map_code(map_code)
//     ,._error_threshold(0)
//     ,._half_rate(1'b1)
//     ,._target_rx_enc(MBINIT_REPAIRMB_RX_Done_Handshake)
//   );
//   ltsmc_seq.start(ltsmc_seqr);












  // // 1. Force a clean RESET
  // ltsmc_seq.configure(
  //    ._next_state_type(CUSTOM)
  //   ,._lane_map_code(map_code)
  //   ,._error_threshold(0)
  //   ,._half_rate(1'b1)
  //   ,._target_rx_enc(RESET_Reset)
  // );
  // ltsmc_seq.start(ltsmc_seqr);

  // // 2. Traverse along the FSM up to the Per-Lane ID Detection state
  // ltsmc_seq.configure(
  //    ._next_state_type(TRAVERSE)
  //   ,._lane_map_code(map_code)
  //   ,._error_threshold(0)
  //   ,._half_rate(1'b1)
  //   ,._target_rx_enc(MBINIT_REVERSAL_RX_Per_Lane_ID_Det)
  // );
  // ltsmc_seq.start(ltsmc_seqr);

  // // 3. Configure and fire the RMBLINK physical stimulus burst
  // // Note: The physical sequence drives all 16 lanes, but the DUT/Scoreboard 
  // // will only evaluate the active subset based on the map_code.
  // rmblink_seq.scenario       = scen;
  // rmblink_seq.num_iterations = iters;
  // rmblink_seq.start(rmblink_seqr);

  // // 4. Conclude the FSM sub-routine Handshake
  // ltsmc_seq.configure(
  //    ._next_state_type(TRAVERSE)
  //   ,._lane_map_code(map_code)
  //   ,._error_threshold(0)
  //   ,._half_rate(1'b1)
  //   ,._target_rx_enc(MBINIT_REVERSAL_RX_Done_Handshake)
  // );
  // ltsmc_seq.start(ltsmc_seqr);