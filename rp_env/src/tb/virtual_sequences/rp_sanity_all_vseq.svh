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
// CLASS: rp_sanity_all_vseq
//
//-----------------------------------------------------------------------------

class rp_sanity_all_vseq extends virtual_sequence_base;
  `uvm_object_utils(rp_sanity_all_vseq)

  ltsmc_sequence                    ltsmc_seq;
  rmblink_sanity_lfsr_sequence      rmblink_lfsr_seq;
  rmblink_sanity_clk_sequence       rmblink_clk_seq;
  rmblink_active_sequence           rmblink_active_seq;
  rmblink_sanity_PerLaneID_sequence rmblink_PerLaneID_seq;
  rmblink_sanity_valid_sequence     rmblink_valid_seq;

  extern function new(string name = "rp_sanity_all_vseq");
  extern task pre_body();
  extern task body();
  
  // Helper task to cleanly execute and log each scenario with dynamic lane mapping
  extern task execute_scenario(lane_map_code_t map_code,per_lane_scenario_e scen_rev,per_lane_scenario_e scen_repmb,
                         mixed_lane_mode_e mixed_rev, mixed_lane_mode_e mixed_repmb ,lfsr_scenario_e scen_dvref, lfsr_scenario_e scen_dtc1, lfsr_scenario_e scen_dtvref,
                         lfsr_scenario_e scen_dtc2, lfsr_scenario_e scen_linkspeed , int iters_perlane , int iters_lfsr,int iters_active , string scen_name ,
                         clk_test_mode_e clk_test_mode, valid_test_mode_e valid_test_mode_init, valid_test_mode_e valid_test_mode_vref,
                        valid_test_mode_e valid_test_mode_vtc, valid_test_mode_e valid_test_mode_vtref);

endclass : rp_sanity_all_vseq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

function rp_sanity_all_vseq::new(string name = "rp_sanity_all_vseq");
  super.new(name);
endfunction : new


task rp_sanity_all_vseq::pre_body();
  super.pre_body();
  ltsmc_seq   = ltsmc_sequence::type_id::create("ltsmc_seq");
  rmblink_lfsr_seq =     rmblink_sanity_lfsr_sequence      ::type_id::create("rmblink_lfsr_seq");
  rmblink_clk_seq =      rmblink_sanity_clk_sequence       ::type_id::create("rmblink_clk_seq");
  rmblink_active_seq =   rmblink_active_sequence           ::type_id::create("rmblink_active_seq");
  rmblink_PerLaneID_seq= rmblink_sanity_PerLaneID_sequence ::type_id::create("rmblink_PerLaneID_seq");
  rmblink_valid_seq =    rmblink_sanity_valid_sequence     ::type_id::create("rmblink_valid_seq");
endtask : pre_body


task rp_sanity_all_vseq::execute_scenario(lane_map_code_t map_code,per_lane_scenario_e scen_rev,per_lane_scenario_e scen_repmb,
                         mixed_lane_mode_e mixed_rev, mixed_lane_mode_e mixed_repmb ,lfsr_scenario_e scen_dvref, lfsr_scenario_e scen_dtc1, lfsr_scenario_e scen_dtvref,
                         lfsr_scenario_e scen_dtc2, lfsr_scenario_e scen_linkspeed , int iters_perlane , int iters_lfsr,int iters_active , string scen_name ,
                         clk_test_mode_e clk_test_mode, valid_test_mode_e valid_test_mode_init, valid_test_mode_e valid_test_mode_vref,
                        valid_test_mode_e valid_test_mode_vtc, valid_test_mode_e valid_test_mode_vtref);
  `uvm_info("VSEQ_SCENARIO", $sformatf("========================================"), UVM_LOW)
  `uvm_info("VSEQ_SCENARIO", $sformatf(" RUNNING: %s", scen_name), UVM_LOW)
  `uvm_info("VSEQ_SCENARIO", $sformatf(" MODE:    %0s", map_code.name()), UVM_LOW)
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


  // ===============================
  // REPAIRCLK
  // ===============================

  ltsmc_seq.configure(
     ._next_state_type(TRAVERSE)
    ,._lane_map_code(map_code)
    ,._error_threshold(16'b1)
    ,._half_rate(1'b1)
    ,._target_rx_enc(MBINIT_REPAIRCLK_RX_Pattern_Detection)
  );
  ltsmc_seq.start(ltsmc_seqr);

  rmblink_clk_seq.test_mode = clk_test_mode;
  rmblink_clk_seq.start(rmblink_seqr);

  // ===============================
  // REPAIRVAL
  // ===============================

  ltsmc_seq.configure(
     ._next_state_type(TRAVERSE)
    ,._lane_map_code(map_code)
    ,._error_threshold(16'b1)
    ,._half_rate(1'b1)
    ,._target_rx_enc(MBINIT_REPAIRVAL_RX_Valid_Pattern_Det)
  );
  ltsmc_seq.start(ltsmc_seqr);

  rmblink_valid_seq.test_mode = valid_test_mode_init;
  rmblink_valid_seq.start(rmblink_seqr);

  // ===============================
  // REVERSAL
  // ===============================

  ltsmc_seq.configure(
     ._next_state_type(TRAVERSE)
    ,._lane_map_code(map_code)
    ,._error_threshold(16'b1)
    ,._half_rate(1'b1)
    ,._target_rx_enc(MBINIT_REVERSAL_RX_Per_Lane_ID_Det)
  );
  ltsmc_seq.start(ltsmc_seqr);

  rmblink_PerLaneID_seq.configure(
     ._scenario(scen_rev)
    ,._num_iterations(iters_perlane)
    ,._lane_map_code(map_code)
    ,._mixed_mode(mixed_rev)
  );
  rmblink_PerLaneID_seq.start(rmblink_seqr);

  // ===============================
  // REPAIRMB
  // ===============================

  ltsmc_seq.configure(
     ._next_state_type(TRAVERSE)
    ,._lane_map_code(map_code)
    ,._error_threshold(16'b1)
    ,._half_rate(1'b1)
    ,._target_rx_enc(Data_To_Clock_test_RX_Pattern_Detection_TX_Init)
  );
  ltsmc_seq.start(ltsmc_seqr);

  rmblink_PerLaneID_seq.configure(
     ._scenario(scen_repmb)
    ,._num_iterations(iters_perlane)
    ,._lane_map_code(map_code)
    ,._mixed_mode(mixed_repmb)
  );
  rmblink_PerLaneID_seq.start(rmblink_seqr);

  // ===============================
  // VALVREF
  // ===============================

  ltsmc_seq.configure(
     ._next_state_type(TRAVERSE)
    ,._lane_map_code(map_code)
    ,._error_threshold(16'b1)
    ,._half_rate(1'b1)
    ,._target_rx_enc(Data_To_Clock_test_RX_Pattern_Detection_RX_Init)
  );
  ltsmc_seq.start(ltsmc_seqr);

  rmblink_valid_seq.test_mode = valid_test_mode_vref;
  rmblink_valid_seq.start(rmblink_seqr);

  // ===============================
  // DATAVREF
  // ===============================

  ltsmc_seq.configure(
     ._next_state_type(TRAVERSE)
    ,._lane_map_code(map_code)
    ,._error_threshold(16'b1)
    ,._half_rate(1'b1)
    ,._target_rx_enc(Data_To_Clock_test_RX_LFSR_Clear_Handshake_RX_Init)
  );
  ltsmc_seq.start(ltsmc_seqr);

  rmblink_lfsr_seq.rx_lfsr_pattern_generation (1'b0, 1'b1, rmblink_lfsr_seq.dummy_data);

  ltsmc_seq.configure(
     ._next_state_type(NEXT)
    ,._lane_map_code(map_code)
    ,._error_threshold(16'b1)
    ,._half_rate(1'b1)
    ,._target_rx_enc(Data_To_Clock_test_RX_Pattern_Detection_RX_Init)
  );
  ltsmc_seq.start(ltsmc_seqr);

  rmblink_lfsr_seq.scenario       = scen_dvref;
  rmblink_lfsr_seq.num_iterations = iters_lfsr;
  rmblink_lfsr_seq.train_mode = 1'b1;
  rmblink_lfsr_seq.start(rmblink_seqr);

  // ===============================
  // VALTRAINCENTER
  // ===============================

  ltsmc_seq.configure(
     ._next_state_type(TRAVERSE)
    ,._lane_map_code(map_code)
    ,._error_threshold(16'b1)
    ,._half_rate(1'b1)
    ,._target_rx_enc(Data_To_Clock_test_RX_Pattern_Detection_RX_Init)
  );
  ltsmc_seq.start(ltsmc_seqr);

  rmblink_valid_seq.test_mode = valid_test_mode_vtc;
  rmblink_valid_seq.start(rmblink_seqr);
  
  // ===============================
  // VALTRAINVREF
  // ===============================

  ltsmc_seq.configure(
     ._next_state_type(TRAVERSE)
    ,._lane_map_code(map_code)
    ,._error_threshold(16'b1)
    ,._half_rate(1'b1)
    ,._target_rx_enc(Data_To_Clock_test_RX_Pattern_Detection_RX_Init)
  );
  ltsmc_seq.start(ltsmc_seqr);

  rmblink_valid_seq.test_mode = valid_test_mode_vtref;
  rmblink_valid_seq.start(rmblink_seqr);
  
  // ===============================
  // DTC1
  // ===============================

  ltsmc_seq.configure(
     ._next_state_type(TRAVERSE)
    ,._lane_map_code(map_code)
    ,._error_threshold(16'b1)
    ,._half_rate(1'b1)
    ,._target_rx_enc(Data_To_Clock_test_RX_LFSR_Clear_Handshake_RX_Init)
  );
  ltsmc_seq.start(ltsmc_seqr);

  rmblink_lfsr_seq.rx_lfsr_pattern_generation (1'b0, 1'b1, rmblink_lfsr_seq.dummy_data);

  ltsmc_seq.configure(
     ._next_state_type(NEXT)
    ,._lane_map_code(map_code)
    ,._error_threshold(16'b1)
    ,._half_rate(1'b1)
    ,._target_rx_enc(Data_To_Clock_test_RX_Pattern_Detection_RX_Init)
  );
  ltsmc_seq.start(ltsmc_seqr);

  rmblink_lfsr_seq.scenario       = scen_dtc1;
  rmblink_lfsr_seq.num_iterations = iters_lfsr;
  rmblink_lfsr_seq.train_mode = 1'b1;
  rmblink_lfsr_seq.start(rmblink_seqr);

  // ===============================
  // DTVREF
  // ===============================

  ltsmc_seq.configure(
     ._next_state_type(TRAVERSE)
    ,._lane_map_code(map_code)
    ,._error_threshold(16'b1)
    ,._half_rate(1'b1)
    ,._target_rx_enc(Data_To_Clock_test_RX_LFSR_Clear_Handshake_RX_Init)
  );
  ltsmc_seq.start(ltsmc_seqr);

  rmblink_lfsr_seq.rx_lfsr_pattern_generation (1'b0, 1'b1, rmblink_lfsr_seq.dummy_data);

  ltsmc_seq.configure(
     ._next_state_type(NEXT)
    ,._lane_map_code(map_code)
    ,._error_threshold(16'b1)
    ,._half_rate(1'b1)
    ,._target_rx_enc(Data_To_Clock_test_RX_Pattern_Detection_RX_Init)
  );
  ltsmc_seq.start(ltsmc_seqr);

  rmblink_lfsr_seq.scenario       = scen_dtvref;
  rmblink_lfsr_seq.num_iterations = iters_lfsr;
  rmblink_lfsr_seq.train_mode = 1'b1;
  rmblink_lfsr_seq.start(rmblink_seqr);

   
  // ===============================
  // DTC2
  // ===============================

  ltsmc_seq.configure(
     ._next_state_type(TRAVERSE)
    ,._lane_map_code(map_code)
    ,._error_threshold(16'b1)
    ,._half_rate(1'b1)
    ,._target_rx_enc(Data_To_Clock_test_RX_LFSR_Clear_Handshake_RX_Init)
  );
  ltsmc_seq.start(ltsmc_seqr);

  rmblink_lfsr_seq.rx_lfsr_pattern_generation (1'b0, 1'b1, rmblink_lfsr_seq.dummy_data);

  ltsmc_seq.configure(
     ._next_state_type(NEXT)
    ,._lane_map_code(map_code)
    ,._error_threshold(16'b1)
    ,._half_rate(1'b1)
    ,._target_rx_enc(Data_To_Clock_test_RX_Pattern_Detection_RX_Init)
  );
  ltsmc_seq.start(ltsmc_seqr);

  rmblink_lfsr_seq.scenario       = scen_dtc2;
  rmblink_lfsr_seq.num_iterations = iters_lfsr;
  rmblink_lfsr_seq.train_mode = 1'b1;
  rmblink_lfsr_seq.start(rmblink_seqr);

  
  // ===============================
  // LINKSPEED
  // ===============================

  ltsmc_seq.configure(
     ._next_state_type(TRAVERSE)
    ,._lane_map_code(map_code)
    ,._error_threshold(16'b1)
    ,._half_rate(1'b1)
    ,._target_rx_enc(Data_To_Clock_test_RX_LFSR_Clear_Handshake_TX_Init)
  );
  ltsmc_seq.start(ltsmc_seqr);

  rmblink_lfsr_seq.rx_lfsr_pattern_generation (1'b0, 1'b1, rmblink_lfsr_seq.dummy_data);

  ltsmc_seq.configure(
     ._next_state_type(NEXT)
    ,._lane_map_code(map_code)
    ,._error_threshold(16'b1)
    ,._half_rate(1'b1)
    ,._target_rx_enc(Data_To_Clock_test_RX_Pattern_Detection_TX_Init)
  );
  ltsmc_seq.start(ltsmc_seqr);

  rmblink_lfsr_seq.scenario       = scen_linkspeed;
  rmblink_lfsr_seq.num_iterations = iters_lfsr;
  rmblink_lfsr_seq.train_mode = 1'b1;
  rmblink_lfsr_seq.start(rmblink_seqr);

  
  // ===============================
  // ACTIVE
  // ===============================

  ltsmc_seq.configure(
     ._next_state_type(TRAVERSE)
    ,._lane_map_code(map_code)
    ,._error_threshold(16'b1)
    ,._half_rate(1'b1)
    ,._target_rx_enc(ACTIVE_RX_Active)
  );
  ltsmc_seq.start(ltsmc_seqr);

  rmblink_active_seq.configure(
    ._num_256b_chunks(iters_active),
    ._lane_map_code(map_code),
    ._scenario(ACTIVE_SCENARIO_IDEAL)
  );
  rmblink_active_seq.start(rmblink_seqr);


  
  // Brief delay between scenarios to separate waveform transactions visually
  #50ns; 
endtask


task rp_sanity_all_vseq::body();

   /*execute_scenario(lane_map_code_t map_code,per_lane_scenario_e scen_rev,per_lane_scenario_e scen_repmb,
                         mixed_lane_mode_e mixed_rev, mixed_lane_mode_e mixed_repmb ,lfsr_scenario_e scen_dvref, lfsr_scenario_e scen_dtc1, lfsr_scenario_e scen_dtvref,
                         lfsr_scenario_e scen_dtc2, lfsr_scenario_e scen_linkspeed , int iters_perlane , int iters_lfsr,int iters_active , string scen_name ,
                         clk_test_mode_e clk_test_mode, valid_test_mode_e valid_test_mode_init, valid_test_mode_e valid_test_mode_vref,
                        valid_test_mode_e valid_test_mode_vtc, valid_test_mode_e valid_test_mode_vtref);*/
  // ========================================================================
  // PHASE 1: X8 LOWER MODE (Lanes 0-7)
  // ========================================================================
  // ============================================================================
// Group 1: Ideal & Baseline Scenarios (Exact Match)
// ============================================================================
/*execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 100, "Ideal_Baseline_Active100", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 75, "Ideal_Baseline_RandMixed_Active75", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 50, "Ideal_Baseline_Active50", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 25, "Ideal_Baseline_RandMixed_Active25", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 1, "Ideal_Baseline_EdgeCase_Active1", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
*/
// ============================================================================
// Group 2: Per-Lane Anomalies (Fail Midway, Noise, Threshold Teasers)
// ============================================================================
execute_scenario(X8_LOWER_MODE, SCENARIO_FAIL_MIDWAY, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 80, "Rev_FailMidway_Repmb_Ideal_Active80", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_FAIL_MIDWAY, MIXED_ALTERNATING, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 60, "Rev_Ideal_Repmb_FailMidway_Active60", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_NOISE_THEN_IDEAL, SCENARIO_NOISE_THEN_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 90, "Both_NoiseThenIdeal_Active90", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_WRONG_LANE_ID, SCENARIO_WRONG_LANE_ID, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 15, "Both_WrongLaneID_Active15", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_RANDOM_INTERLEAVED, SCENARIO_MIXED_SUCCESS, MIXED_RANDOM, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 45, "Rev_RandInt_Repmb_MixSuc_Active45", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_LATE_SUCCESS, SCENARIO_LATE_SUCCESS, MIXED_ALTERNATING, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 30, "Both_LateSuccess_Active30", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_THRESHOLD_TEASER, SCENARIO_THRESHOLD_TEASER, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 99, "Both_ThresholdTeaser_Active99", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_FAIL_MIDWAY, SCENARIO_THRESHOLD_TEASER, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 55, "Rev_FailMid_Repmb_ThreshTeaser_Active55", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_NOISE_THEN_IDEAL, SCENARIO_WRONG_LANE_ID, MIXED_RANDOM, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 88, "Rev_NoiseIdeal_Repmb_WrongID_Active88", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_MIXED_SUCCESS, SCENARIO_LATE_SUCCESS, MIXED_ALTERNATING, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 12, "Rev_MixSuc_Repmb_LateSuc_Active12", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
/*
// ============================================================================
// Group 3: LFSR Scenarios (Error Injections Below & Above Threshold)
// ============================================================================
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_ERROR_BELOW_THRESH_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 70, "LFSR_DVREF_ErrBelowThreshRand_Active70", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_ERROR_ABOVE_THRESH_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 65, "LFSR_DTC1_ErrAboveThreshRand_Active65", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_ERROR_BELOW_THRESH_START, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 40, "LFSR_DTVREF_ErrBelowThreshStart_Active40", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_ERROR_BELOW_THRESH_END, SCENARIO_EXACT_MATCH, 32, 64, 85, "LFSR_DTC2_ErrBelowThreshEnd_Active85", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_ERROR_ABOVE_THRESH_START, 32, 64, 20, "LFSR_LinkSpeed_ErrAboveThreshStart_Active20", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_ERROR_ABOVE_THRESH_END, SCENARIO_ERROR_ABOVE_THRESH_END, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 50, "LFSR_DVREF_DTC1_ErrAboveThreshEnd_Active50", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_ERROR_BELOW_THRESH_RANDOM, SCENARIO_ERROR_BELOW_THRESH_RANDOM, SCENARIO_ERROR_BELOW_THRESH_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 95, "LFSR_Multiple_ErrBelowThreshRand_Active95", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_ERROR_ABOVE_THRESH_RANDOM, SCENARIO_ERROR_ABOVE_THRESH_RANDOM, 32, 64, 33, "LFSR_DTC2_LinkSpeed_ErrAboveThresh_Active33", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_RANDOM, SCENARIO_ERROR_BELOW_THRESH_START, SCENARIO_ERROR_BELOW_THRESH_END, SCENARIO_ERROR_BELOW_THRESH_START, SCENARIO_ERROR_BELOW_THRESH_END, SCENARIO_EXACT_MATCH, 32, 64, 18, "LFSR_Mixed_ErrBelowThresh_StartEnd_Active18", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_ERROR_ABOVE_THRESH_START, SCENARIO_ERROR_ABOVE_THRESH_END, SCENARIO_ERROR_ABOVE_THRESH_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 77, "LFSR_Mixed_ErrAboveThresh_StartEndRand_Active77", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);

// ============================================================================
// Group 4: Valid Test Mode Mappings (Injections & Errors)
// ============================================================================
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 42, "Valid_Init_InjectStart_Active42", TEST_CLK_IDEAL_ALL, TEST_INJECT_START, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 58, "Valid_Vref_InjectMiddle_Active58", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_INJECT_MIDDLE, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 8, "Valid_VTC_InjectEnd_Active8", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_INJECT_END, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 73, "Valid_VTREF_SingleError_Active73", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_SINGLE_ERROR);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 61, "Valid_Init_MultiErrAboveThresh_Active61", TEST_CLK_IDEAL_ALL, TEST_MULTI_ERR_ABOVE_THRESH, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 91, "Valid_Vref_ActiveIdleTracking_Active91", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_ACTIVE_IDLE, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 14, "Valid_VTC_ActiveErrorInjection_Active14", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_ACTIVE_ERROR_INJECTION, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 27, "Valid_VTREF_ActiveIdleInjection_Active27", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_ACTIVE_IDLE_INJECTION);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 48, "Valid_Init_IdealValid_RandClks_Active48", TEST_CLK_IDEAL_ALL, TEST_IDEAL_VALID_RANDOM_CLKS, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 82, "Valid_All_ResetMode_Active82", TEST_CLK_IDEAL_ALL, TEST_RESET, TEST_RESET, TEST_RESET, TEST_RESET);

// ============================================================================
// Group 5: Clock Test Mode Variations
// ============================================================================
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 38, "Clk_PureRandom_Active38", TEST_CLK_PURE_RANDOM, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 66, "Clk_InjectStart_Active66", TEST_CLK_INJECT_START, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 22, "Clk_InjectMiddle_Active22", TEST_CLK_INJECT_MIDDLE, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 94, "Clk_InjectEnd_Active94", TEST_CLK_INJECT_END, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 11, "Clk_Reset_Active11", TEST_CLK_RESET, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 87, "Clk_PureRandom_Valid_PureRandom_Active87", TEST_CLK_PURE_RANDOM, TEST_PURE_RANDOM, TEST_PURE_RANDOM, TEST_PURE_RANDOM, TEST_PURE_RANDOM);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 44, "Clk_InjectMiddle_Valid_SingleErr_Active44", TEST_CLK_INJECT_MIDDLE, TEST_SINGLE_ERROR, TEST_SINGLE_ERROR, TEST_SINGLE_ERROR, TEST_SINGLE_ERROR);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 76, "Clk_InjectEnd_Valid_ActiveIdle_Active76", TEST_CLK_INJECT_END, TEST_ACTIVE_IDLE, TEST_ACTIVE_IDLE, TEST_ACTIVE_IDLE, TEST_ACTIVE_IDLE);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 3, "Clk_InjectStart_Valid_MultiErr_Active3", TEST_CLK_INJECT_START, TEST_MULTI_ERR_ABOVE_THRESH, TEST_MULTI_ERR_ABOVE_THRESH, TEST_MULTI_ERR_ABOVE_THRESH, TEST_MULTI_ERR_ABOVE_THRESH);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 69, "Clk_Reset_Valid_Reset_Active69", TEST_CLK_RESET, TEST_RESET, TEST_RESET, TEST_RESET, TEST_RESET);

// ============================================================================
// Group 6: Complex Mixed Interactions (Lane, LFSR, Valid, Clock combos)
// ============================================================================
execute_scenario(X8_LOWER_MODE, SCENARIO_FAIL_MIDWAY, SCENARIO_NOISE_THEN_IDEAL, MIXED_RANDOM, MIXED_ALTERNATING, SCENARIO_ERROR_BELOW_THRESH_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 52, "Mixed_FailMid_Noise_LFSRBelow_Active52", TEST_CLK_IDEAL_ALL, TEST_INJECT_MIDDLE, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_WRONG_LANE_ID, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_ERROR_ABOVE_THRESH_START, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 21, "Mixed_WrongLane_LFSRAboveStart_Active21", TEST_CLK_INJECT_START, TEST_IDEAL_ALL_0F, TEST_SINGLE_ERROR, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_RANDOM_INTERLEAVED, SCENARIO_MIXED_SUCCESS, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_ERROR_BELOW_THRESH_END, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 79, "Mixed_RandInt_MixSuc_LFSRBelowEnd_Active79", TEST_CLK_INJECT_MIDDLE, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_ACTIVE_IDLE, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_THRESHOLD_TEASER, SCENARIO_THRESHOLD_TEASER, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_ERROR_ABOVE_THRESH_RANDOM, SCENARIO_EXACT_MATCH, 32, 64, 34, "Mixed_ThreshTeaser_LFSRAboveRand_Active34", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_MULTI_ERR_ABOVE_THRESH);
execute_scenario(X8_LOWER_MODE, SCENARIO_LATE_SUCCESS, SCENARIO_FAIL_MIDWAY, MIXED_RANDOM, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_ERROR_BELOW_THRESH_START, 32, 64, 62, "Mixed_LateSuc_FailMid_LFSRSpeedBelow_Active62", TEST_CLK_INJECT_END, TEST_INJECT_START, TEST_INJECT_END, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_NOISE_THEN_IDEAL, SCENARIO_WRONG_LANE_ID, MIXED_ALTERNATING, MIXED_RANDOM, SCENARIO_ERROR_ABOVE_THRESH_END, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 17, "Mixed_NoiseIdeal_WrongLane_LFSRAboveEnd_Active17", TEST_CLK_IDEAL_ALL, TEST_IDEAL_VALID_RANDOM_CLKS, TEST_IDEAL_ALL_0F, TEST_ACTIVE_ERROR_INJECTION, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_FAIL_MIDWAY, SCENARIO_MIXED_SUCCESS, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_ERROR_BELOW_THRESH_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 98, "Mixed_FailMid_MixSuc_LFSRBelowRand_Active98", TEST_CLK_PURE_RANDOM, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_ACTIVE_IDLE_INJECTION, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_WRONG_LANE_ID, SCENARIO_THRESHOLD_TEASER, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_ERROR_ABOVE_THRESH_START, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 6, "Mixed_WrongLane_ThreshTeaser_LFSRAboveStart_Active6", TEST_CLK_INJECT_START, TEST_PURE_RANDOM, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_SINGLE_ERROR);
execute_scenario(X8_LOWER_MODE, SCENARIO_RANDOM_INTERLEAVED, SCENARIO_FAIL_MIDWAY, MIXED_RANDOM, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_ERROR_BELOW_THRESH_END, SCENARIO_EXACT_MATCH, 32, 64, 49, "Mixed_RandInt_FailMid_LFSRBelowEnd_Active49", TEST_CLK_INJECT_MIDDLE, TEST_IDEAL_ALL_0F, TEST_MULTI_ERR_ABOVE_THRESH, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_LATE_SUCCESS, SCENARIO_NOISE_THEN_IDEAL, MIXED_ALTERNATING, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_ERROR_ABOVE_THRESH_RANDOM, 32, 64, 71, "Mixed_LateSuc_NoiseIdeal_LFSRAboveRand_Active71", TEST_CLK_RESET, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_RESET, TEST_IDEAL_ALL_0F);

// ============================================================================
// Group 7: Pure Chaos (Heavy Randomization on All Interfaces)
// ============================================================================
execute_scenario(X8_LOWER_MODE, SCENARIO_FAIL_MIDWAY, SCENARIO_WRONG_LANE_ID, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_ERROR_ABOVE_THRESH_RANDOM, SCENARIO_ERROR_ABOVE_THRESH_RANDOM, SCENARIO_ERROR_ABOVE_THRESH_RANDOM, SCENARIO_ERROR_ABOVE_THRESH_RANDOM, SCENARIO_ERROR_ABOVE_THRESH_RANDOM, 32, 64, 84, "Chaos_All_AboveThresh_Random_Active84", TEST_CLK_PURE_RANDOM, TEST_PURE_RANDOM, TEST_PURE_RANDOM, TEST_PURE_RANDOM, TEST_PURE_RANDOM);
execute_scenario(X8_LOWER_MODE, SCENARIO_NOISE_THEN_IDEAL, SCENARIO_THRESHOLD_TEASER, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_ERROR_BELOW_THRESH_START, SCENARIO_ERROR_BELOW_THRESH_END, SCENARIO_ERROR_ABOVE_THRESH_START, SCENARIO_ERROR_ABOVE_THRESH_END, SCENARIO_ERROR_BELOW_THRESH_RANDOM, 32, 64, 29, "Chaos_Mixed_LFSR_Injections_Active29", TEST_CLK_INJECT_MIDDLE, TEST_INJECT_START, TEST_INJECT_MIDDLE, TEST_INJECT_END, TEST_SINGLE_ERROR);
execute_scenario(X8_LOWER_MODE, SCENARIO_RANDOM_INTERLEAVED, SCENARIO_LATE_SUCCESS, MIXED_RANDOM, MIXED_ALTERNATING, SCENARIO_ERROR_ABOVE_THRESH_END, SCENARIO_ERROR_BELOW_THRESH_START, SCENARIO_ERROR_ABOVE_THRESH_RANDOM, SCENARIO_ERROR_BELOW_THRESH_END, SCENARIO_EXACT_MATCH, 32, 64, 54, "Chaos_Mixed_LFSR_And_ValidModes_Active54", TEST_CLK_INJECT_START, TEST_ACTIVE_IDLE, TEST_ACTIVE_ERROR_INJECTION, TEST_ACTIVE_IDLE_INJECTION, TEST_MULTI_ERR_ABOVE_THRESH);
execute_scenario(X8_LOWER_MODE, SCENARIO_MIXED_SUCCESS, SCENARIO_FAIL_MIDWAY, MIXED_ALTERNATING, MIXED_RANDOM, SCENARIO_ERROR_BELOW_THRESH_RANDOM, SCENARIO_ERROR_ABOVE_THRESH_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 9, "Chaos_Failures_And_RandomClks_Active9", TEST_CLK_PURE_RANDOM, TEST_IDEAL_VALID_RANDOM_CLKS, TEST_IDEAL_VALID_RANDOM_CLKS, TEST_IDEAL_VALID_RANDOM_CLKS, TEST_IDEAL_VALID_RANDOM_CLKS);
execute_scenario(X8_LOWER_MODE, SCENARIO_THRESHOLD_TEASER, SCENARIO_RANDOM_INTERLEAVED, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_ERROR_ABOVE_THRESH_START, SCENARIO_ERROR_ABOVE_THRESH_START, SCENARIO_ERROR_ABOVE_THRESH_START, SCENARIO_ERROR_ABOVE_THRESH_START, SCENARIO_ERROR_ABOVE_THRESH_START, 32, 64, 100, "Chaos_Ultimate_StressTest_Active100", TEST_CLK_PURE_RANDOM, TEST_MULTI_ERR_ABOVE_THRESH, TEST_MULTI_ERR_ABOVE_THRESH, TEST_MULTI_ERR_ABOVE_THRESH, TEST_MULTI_ERR_ABOVE_THRESH);
  `uvm_info("VSEQ_SCENARIO", ">>> STARTING X8_LOWER_MODE SCENARIOS <<<", UVM_LOW)
 

 // ============================================================================
// Group 8: Valid Mode Edge Cases (Start/End Injections)
// ============================================================================
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 5, "Valid_EdgeCase_InitStart_Active5", TEST_CLK_IDEAL_ALL, TEST_INJECT_START, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 96, "Valid_EdgeCase_VrefEnd_Active96", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_INJECT_END, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 13, "Valid_EdgeCase_VTCStart_Active13", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_INJECT_START, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 89, "Valid_EdgeCase_VTREFEnd_Active89", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_INJECT_END);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 47, "Valid_EdgeCase_MixedStartEnd_Active47", TEST_CLK_IDEAL_ALL, TEST_INJECT_START, TEST_INJECT_END, TEST_INJECT_START, TEST_INJECT_END);

// ============================================================================
// Group 9: Asymmetric Per-Lane Failures
// ============================================================================
execute_scenario(X8_LOWER_MODE, SCENARIO_NOISE_THEN_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 24, "Asym_RevNoise_RepmbIdeal_Active24", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_WRONG_LANE_ID, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 72, "Asym_RevIdeal_RepmbWrongID_Active72", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_LATE_SUCCESS, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 36, "Asym_RevLateSuc_RepmbIdeal_Active36", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_RANDOM_INTERLEAVED, MIXED_RANDOM, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 81, "Asym_RevIdeal_RepmbRandInt_Active81", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_MIXED_SUCCESS, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 19, "Asym_RevMixSuc_RepmbIdeal_Active19", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);

// ============================================================================
// Group 10: Specific LFSR Error Combinations
// ============================================================================
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_ERROR_BELOW_THRESH_START, SCENARIO_ERROR_ABOVE_THRESH_END, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 53, "LFSRCombo_DVREF_BelowStart_DTC1_AboveEnd_Active53", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_ERROR_BELOW_THRESH_RANDOM, SCENARIO_ERROR_ABOVE_THRESH_RANDOM, SCENARIO_EXACT_MATCH, 32, 64, 92, "LFSRCombo_DTVREF_BelowRand_DTC2_AboveRand_Active92", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_ERROR_ABOVE_THRESH_START, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_ERROR_BELOW_THRESH_END, 32, 64, 31, "LFSRCombo_DVREF_AboveStart_LinkSpeed_BelowEnd_Active31", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_ERROR_BELOW_THRESH_START, SCENARIO_ERROR_BELOW_THRESH_END, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 67, "LFSRCombo_DTC1_BelowStart_DTVREF_BelowEnd_Active67", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_ERROR_ABOVE_THRESH_START, SCENARIO_ERROR_ABOVE_THRESH_END, 32, 64, 16, "LFSRCombo_DTC2_AboveStart_LinkSpeed_AboveEnd_Active16", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
/*
// ============================================================================
// Group 11: Active Error Handling in Valid Mode
// ============================================================================
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 59, "Valid_Init_ActiveError_Vref_Ideal_Active59", TEST_CLK_IDEAL_ALL, TEST_ACTIVE_ERROR_INJECTION, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 83, "Valid_Vref_ActiveIdleInj_VTC_Ideal_Active83", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_ACTIVE_IDLE_INJECTION, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 26, "Valid_VTC_ActiveError_VTREF_Ideal_Active26", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_ACTIVE_ERROR_INJECTION, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 93, "Valid_VTREF_ActiveIdleInj_Init_Ideal_Active93", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_ACTIVE_IDLE_INJECTION);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 43, "Valid_All_ActiveTrackingScenarios_Active43", TEST_CLK_IDEAL_ALL, TEST_ACTIVE_IDLE, TEST_ACTIVE_ERROR_INJECTION, TEST_ACTIVE_IDLE, TEST_ACTIVE_IDLE_INJECTION);

// ============================================================================
// Group 12: Extreme Clock Anomalies with Corrupted Valid Data
// ============================================================================
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 7, "Clk_Random_Valid_MultiError_Active7", TEST_CLK_PURE_RANDOM, TEST_MULTI_ERR_ABOVE_THRESH, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 64, "Clk_InjectStart_Valid_SingleError_Active64", TEST_CLK_INJECT_START, TEST_IDEAL_ALL_0F, TEST_SINGLE_ERROR, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 39, "Clk_InjectMiddle_Valid_RandomClks_Active39", TEST_CLK_INJECT_MIDDLE, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_VALID_RANDOM_CLKS, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 86, "Clk_InjectEnd_Valid_Reset_Active86", TEST_CLK_INJECT_END, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_RESET);
execute_scenario(X8_LOWER_MODE, SCENARIO_IDEAL, SCENARIO_IDEAL, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 2, "Clk_Reset_Valid_PureRandom_Active2", TEST_CLK_RESET, TEST_PURE_RANDOM, TEST_PURE_RANDOM, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);

// ============================================================================
// Group 13: Final Mixed Stress Scenarios (Testing All Bounds)
// ============================================================================
execute_scenario(X8_LOWER_MODE, SCENARIO_FAIL_MIDWAY, SCENARIO_NOISE_THEN_IDEAL, MIXED_ALTERNATING, MIXED_RANDOM, SCENARIO_ERROR_BELOW_THRESH_START, SCENARIO_ERROR_ABOVE_THRESH_RANDOM, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 74, "Stress_RevFail_RepmbNoise_LFSR_ValidMulti_Active74", TEST_CLK_IDEAL_ALL, TEST_MULTI_ERR_ABOVE_THRESH, TEST_INJECT_MIDDLE, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_THRESHOLD_TEASER, SCENARIO_LATE_SUCCESS, MIXED_RANDOM, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_ERROR_BELOW_THRESH_END, SCENARIO_ERROR_ABOVE_THRESH_START, SCENARIO_EXACT_MATCH, 32, 64, 28, "Stress_RevTeaser_RepmbLate_LFSR_ClkInj_Active28", TEST_CLK_INJECT_START, TEST_IDEAL_ALL_0F, TEST_SINGLE_ERROR, TEST_ACTIVE_IDLE, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_WRONG_LANE_ID, SCENARIO_RANDOM_INTERLEAVED, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_ERROR_BELOW_THRESH_RANDOM, 32, 64, 57, "Stress_RevWrongID_RepmbRandInt_LFSRSpeed_Active57", TEST_CLK_PURE_RANDOM, TEST_IDEAL_VALID_RANDOM_CLKS, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_ACTIVE_ERROR_INJECTION);
execute_scenario(X8_LOWER_MODE, SCENARIO_MIXED_SUCCESS, SCENARIO_THRESHOLD_TEASER, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_ERROR_ABOVE_THRESH_END, SCENARIO_EXACT_MATCH, SCENARIO_ERROR_ABOVE_THRESH_START, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 97, "Stress_RevMixSuc_RepmbTeaser_LFSR_ValidEdge_Active97", TEST_CLK_INJECT_END, TEST_INJECT_END, TEST_INJECT_START, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_NOISE_THEN_IDEAL, SCENARIO_FAIL_MIDWAY, MIXED_ALTERNATING, MIXED_RANDOM, SCENARIO_ERROR_BELOW_THRESH_RANDOM, SCENARIO_ERROR_BELOW_THRESH_RANDOM, SCENARIO_ERROR_BELOW_THRESH_RANDOM, SCENARIO_ERROR_BELOW_THRESH_RANDOM, SCENARIO_ERROR_BELOW_THRESH_RANDOM, 32, 64, 35, "Stress_All_LFSRBelowThresh_MixedLanes_Active35", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_RANDOM_INTERLEAVED, SCENARIO_WRONG_LANE_ID, MIXED_RANDOM, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_ERROR_ABOVE_THRESH_END, SCENARIO_EXACT_MATCH, SCENARIO_ERROR_BELOW_THRESH_START, SCENARIO_EXACT_MATCH, 32, 64, 68, "Stress_LaneChaos_MixedLFSR_ClkReset_Active68", TEST_CLK_RESET, TEST_RESET, TEST_ACTIVE_IDLE_INJECTION, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_FAIL_MIDWAY, SCENARIO_FAIL_MIDWAY, MIXED_ALTERNATING, MIXED_ALTERNATING, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, SCENARIO_EXACT_MATCH, 32, 64, 4, "Stress_SymmetricFailMidway_EarlyActive_Active4", TEST_CLK_IDEAL_ALL, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
execute_scenario(X8_LOWER_MODE, SCENARIO_LATE_SUCCESS, SCENARIO_LATE_SUCCESS, MIXED_RANDOM, MIXED_RANDOM, SCENARIO_ERROR_ABOVE_THRESH_RANDOM, SCENARIO_ERROR_ABOVE_THRESH_RANDOM, SCENARIO_ERROR_ABOVE_THRESH_RANDOM, SCENARIO_ERROR_ABOVE_THRESH_RANDOM, SCENARIO_ERROR_ABOVE_THRESH_RANDOM, 32, 64, 78, "Stress_SymmetricLateSuccess_HeavyLFSRErrors_Active78", TEST_CLK_INJECT_MIDDLE, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F, TEST_IDEAL_ALL_0F);
 
 */
 
  // ========================================================================
  // PHASE 2: X8 UPPER MODE (Lanes 8-15)
  // ========================================================================
  `uvm_info("VSEQ_SCENARIO", ">>> STARTING X8_UPPER_MODE SCENARIOS <<<", UVM_LOW)

 

  // ========================================================================
  // PHASE 3: X16 MODE (Lanes 0-15)
  // ========================================================================
  `uvm_info("VSEQ_SCENARIO", ">>> STARTING X16_MODE SCENARIOS <<<", UVM_LOW)

 
  
  `uvm_info("VSEQ_SCENARIO", "All Per-Lane ID Detection Scenarios for X16 Mode and X8 Modes Completed Successfully.", UVM_LOW)

endtask : body
