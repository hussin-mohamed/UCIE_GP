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
  SCENARIO_LATE_SUCCESS,
  SCENARIO_THRESHOLD_TEASER
} per_lane_scenario_e;

//-----------------------------------------------------------------------------
// ENUM: mixed_lane_mode_e
// Defines how lanes are chosen to pass/fail in mixed scenarios
//-----------------------------------------------------------------------------
typedef enum {
  MIXED_ALTERNATING, // Even lanes pass, Odd lanes fail
  MIXED_RANDOM       // Lanes are randomly chosen to pass or fail
} mixed_lane_mode_e;

//-----------------------------------------------------------------------------
// ENUM: error_inject_region_e
// Defines which lane regions are allowed to have errors injected during X16_MODE
//-----------------------------------------------------------------------------
typedef enum {
  ERR_INJECT_ALL_LANES,
  ERR_INJECT_LOWER_LANES_ONLY,
  ERR_INJECT_UPPER_LANES_ONLY
} error_inject_region_e;

//-----------------------------------------------------------------------------
//
// CLASS: rmblink_sanity_PerLaneID_sequence
//
//-----------------------------------------------------------------------------

class rmblink_sanity_PerLaneID_sequence extends rp_sequence_base #(rmblink_seq_item);
  `uvm_object_utils(rmblink_sanity_PerLaneID_sequence)

  rmblink_sequencer seqr;

  // --- Internal Protected Configuration Variables ---
  protected bit                   m_is_configured = 0;
  protected per_lane_scenario_e   m_scenario;
  protected int                   m_num_iterations;
  protected lane_map_code_t       m_lane_map_code;
  protected mixed_lane_mode_e     m_mixed_mode;
  protected error_inject_region_e m_err_region;
  protected bit [31:0]            m_random_success_mask; // Supports up to 32 lanes

  extern function new(string name = "rmblink_sanity_PerLaneID_sequence");
  
  // Configuration API
  extern function void configure(
    per_lane_scenario_e   _scenario, 
    int                   _num_iterations,
    lane_map_code_t       _lane_map_code = X16_MODE,
    mixed_lane_mode_e     _mixed_mode    = MIXED_ALTERNATING,
    error_inject_region_e _err_region    = ERR_INJECT_ALL_LANES
  );

  extern task pre_body();
  extern task body();

endclass : rmblink_sanity_PerLaneID_sequence


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

function rmblink_sanity_PerLaneID_sequence::new(string name = "rmblink_sanity_PerLaneID_sequence");
  super.new(name);
endfunction : new


function void rmblink_sanity_PerLaneID_sequence::configure(
  per_lane_scenario_e   _scenario, 
  int                   _num_iterations, 
  lane_map_code_t       _lane_map_code = X16_MODE,
  mixed_lane_mode_e     _mixed_mode    = MIXED_ALTERNATING,
  error_inject_region_e _err_region    = ERR_INJECT_ALL_LANES
);
  m_scenario       = _scenario;
  m_num_iterations = _num_iterations;
  m_lane_map_code  = _lane_map_code;
  m_mixed_mode     = _mixed_mode;
  m_err_region     = _err_region;
  
  // Pre-compute the random mask so that a "randomly" chosen passing lane 
  // stays consistent throughout the entire iteration loop.
  m_random_success_mask = $urandom();
  
  m_is_configured  = 1;
endfunction : configure


task rmblink_sanity_PerLaneID_sequence::pre_body();
  super.pre_body();
  $cast(seqr, get_sequencer());
endtask : pre_body


task rmblink_sanity_PerLaneID_sequence::body();
  int start_lane;
  int num_active_lanes;

  // 1. Enforce Configuration
  if (!m_is_configured) begin
    `uvm_fatal("SEQ_CFG_ERR", "Sequence must be configured via configure() before starting!")
  end

  // 2. Decode the lane map configuration
  case (m_lane_map_code)
    X8_LOWER_MODE: begin start_lane = 0; num_active_lanes = 8;  end 
    X8_UPPER_MODE: begin start_lane = 8; num_active_lanes = 8;  end 
    X16_MODE:      begin start_lane = 0; num_active_lanes = 16; end 
    X4_LOWER_MODE: begin start_lane = 0; num_active_lanes = 4;  end 
    X4_UPPER_MODE: begin start_lane = 4; num_active_lanes = 4;  end 
    default:       begin start_lane = 0; num_active_lanes = 16; end
  endcase

  // 3. Main Stimulus Loop
  for (int cycle = 0; cycle < m_num_iterations; cycle++) begin
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
      
      bit is_lane_active;
      bit lane_should_pass;
      bit lane_eligible_for_error;

      // Check if the current lane is active based on the map code
      is_lane_active = (lane >= start_lane) && (lane < (start_lane + num_active_lanes));

      // --- NEW LOGIC: Determine if this lane is allowed to have errors injected (X16_MODE feature) ---
      if (m_lane_map_code == X16_MODE) begin
        case (m_err_region)
          ERR_INJECT_LOWER_LANES_ONLY: lane_eligible_for_error = (lane < 8);
          ERR_INJECT_UPPER_LANES_ONLY: lane_eligible_for_error = (lane >= 8);
          ERR_INJECT_ALL_LANES:        lane_eligible_for_error = 1'b1;
        endcase
      end else begin
        lane_eligible_for_error = 1'b1; // Default behavior for non-X16 modes
      end

      // Determine if this specific lane is designated to pass or fail (used in mixed scenarios)
      if (m_mixed_mode == MIXED_ALTERNATING) begin
        lane_should_pass = (lane % 2 == 0);
      end else begin
        lane_should_pass = m_random_success_mask[lane];
      end

      for (int word = 0; word < pDATA_WIDTH/16; word++) begin
        logic [15:0] chunk;
        logic [15:0] valid_chunk = {4'b1010, 8'(lane), 4'b1010};
        
        if (!is_lane_active) begin
          chunk = 'z; 
        end else begin
          
          // Generate the chunk based on the selected scenario
          case (m_scenario)
            SCENARIO_IDEAL: begin
              chunk = valid_chunk;
            end
            
            SCENARIO_FAIL_MIDWAY: begin
              chunk = (cycle == 10) ? $urandom() : valid_chunk;
            end
            
            SCENARIO_NOISE_THEN_IDEAL: begin
              chunk = (cycle < 15) ? $urandom() : valid_chunk;
            end
            
            SCENARIO_WRONG_LANE_ID: begin
              chunk = {4'b1010, 8'((lane + 1) % pNUM_LANES), 4'b1010}; 
            end
            
            SCENARIO_RANDOM_INTERLEAVED: begin
              chunk = ($urandom_range(0, 1)) ? valid_chunk : $urandom();
            end

            SCENARIO_MIXED_SUCCESS: begin
              chunk = lane_should_pass ? valid_chunk : $urandom();
            end

            SCENARIO_LATE_SUCCESS: begin
              // Wait until the very last 4 cycles (equivalent to 16 word iterations)
              if (lane_should_pass && (cycle >= (m_num_iterations - 4))) begin
                chunk = valid_chunk;
              end else begin
                chunk = $urandom();
              end
            end
            
            SCENARIO_THRESHOLD_TEASER: begin
              // Calculates the absolute word index across all cycles
              int absolute_word_idx = (cycle * (pDATA_WIDTH/16)) + word;
              
              // Sends exactly 15 valid words, then 1 garbage word, then repeats.
              if ((absolute_word_idx % 16) == 15) begin
                chunk = $urandom();
              end else begin
                chunk = valid_chunk;
              end
            end
          endcase

          // If the scenario generated a bad chunk (injected an error), but this lane is 
          // NOT in the eligible error region, we override it back to a valid chunk.
          if (!lane_eligible_for_error) begin
            chunk = valid_chunk;
          end

        end // End Active Lane Block
        
        req.data[lane][word*16 +: 16] = chunk;
      end
    end
    finish_item(req);
  end

endtask : body