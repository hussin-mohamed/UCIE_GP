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
// ENUM: per_lane_scenario_e
// Defines the stress test scenarios for the Per-Lane ID detector
//-----------------------------------------------------------------------------
typedef enum {
  SCENARIO_IDEAL,
  SCENARIO_FAIL_MIDWAY,
  SCENARIO_NOISE_THEN_IDEAL,
  SCENARIO_WRONG_LANE_ID,
  SCENARIO_RANDOM_INTERLEAVED,
  SCENARIO_MIXED_SUCCESS,
  SCENARIO_LATE_SUCCESS
} per_lane_scenario_e;

//-----------------------------------------------------------------------------
//
// CLASS: rmblink_sanity_PerLaneID_sequence
//
//
//-----------------------------------------------------------------------------

class rmblink_sanity_PerLaneID_sequence extends rp_sequence_base #(rmblink_seq_item);
  `uvm_object_utils(rmblink_sanity_PerLaneID_sequence)

  rmblink_sequencer seqr;

  // --- Configuration Knobs for Virtual Sequence ---
  per_lane_scenario_e scenario       = SCENARIO_IDEAL;
  int                 num_iterations = 32;
  bit is_first_data_pat;

  extern function new(string name = "rmblink_sanity_PerLaneID_sequence");
  extern task pre_body();
  extern task body();

endclass : rmblink_sanity_PerLaneID_sequence


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

function rmblink_sanity_PerLaneID_sequence::new(string name = "rmblink_sanity_PerLaneID_sequence");
  super.new(name);
endfunction : new

task rmblink_sanity_PerLaneID_sequence::pre_body();
  super.pre_body();
  $cast(seqr, get_sequencer());
endtask : pre_body


task rmblink_sanity_PerLaneID_sequence::body();
  for (int cycle = 0; cycle < num_iterations; cycle++) begin
    start_item(req);
    assert(req.randomize());

    // Standard generic streams
    req.val_stream   = get_ideal_valid_stream(pDATA_WIDTH/8);
    req.clk_stream_p = get_ideal_clkp_stream(pDATA_WIDTH);
    req.clk_stream_n = get_ideal_clkn_stream(pDATA_WIDTH);
    req.track_stream = get_ideal_clkp_stream(pDATA_WIDTH);
    req.rp_opmode    = DATA_PATTERN;
    req.idle_ui_cnt  = 0;
    if (cycle == 0) begin
      req.is_first_data_pat = 1;
    end else begin
      req.is_first_data_pat = 0;
    end

    // Generate specific payload based on the requested scenario
    for (int lane = 0; lane < pNUM_LANES; lane++) begin
      for (int word = 0; word < pDATA_WIDTH/16; word++) begin
        
        logic [15:0] chunk;
        
        case (scenario)
          SCENARIO_IDEAL: begin
            chunk = {4'b1010, 8'(lane), 4'b1010};
          end
          
          SCENARIO_FAIL_MIDWAY: begin
            chunk = (cycle == 10) ? 16'hDEAD : {4'b1010, 8'(lane), 4'b1010};
          end
          
          SCENARIO_NOISE_THEN_IDEAL: begin
            chunk = (cycle < 15) ? $urandom() : {4'b1010, 8'(lane), 4'b1010};
          end
          
          SCENARIO_WRONG_LANE_ID: begin
            chunk = {4'b1010, 8'((lane + 1) % pNUM_LANES), 4'b1010}; // Cross-talk / shift simulation
          end
          
          SCENARIO_RANDOM_INTERLEAVED: begin
            chunk = ($urandom_range(0, 1)) ? {4'b1010, 8'(lane), 4'b1010} : $urandom();
          end

          SCENARIO_MIXED_SUCCESS: begin
            // Even lanes send correct framing, Odd lanes send bad framing
            chunk = (lane % 2 == 0) ? {4'b1010, 8'(lane), 4'b1010} : 16'hBADD;
          end

          SCENARIO_LATE_SUCCESS: begin
            // 32 cycles * 4 words/cycle = 128 words.
            // The last 16 words perfectly align with the last 4 cycles (cycles 28, 29, 30, 31).
            // Even lanes pass at the end, Odd lanes fail completely.
            if ((lane % 2 == 0) && (cycle >= 28)) begin
              chunk = {4'b1010, 8'(lane), 4'b1010};
            end else begin
              chunk = 16'hBADD;
            end
          end
        endcase
        
        req.data[lane][word*16 +: 16] = chunk;
      end
    end
    finish_item(req);
  end

endtask : body