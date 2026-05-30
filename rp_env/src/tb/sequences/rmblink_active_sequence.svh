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
// ENUM: active_scenario_e
// Defines the test scenarios for the ACTIVE data transmission state
//-----------------------------------------------------------------------------
typedef enum {
  ACTIVE_SCENARIO_IDEAL,
  ACTIVE_SCENARIO_VALID_ERROR // Injects a corruption in the valid stream midway
} active_scenario_e;

//-----------------------------------------------------------------------------
//
// CLASS: rmblink_active_sequence
//
// Drives a generic, randomized payload on the rmblink interface during 
// the ACTIVE state. Automatically calculates required cycles based on 
// the requested number of 256-Byte chunks and active lane count.
//
//-----------------------------------------------------------------------------

class rmblink_active_sequence extends rp_sequence_base #(rmblink_seq_item);
  `uvm_object_utils(rmblink_active_sequence)

  rmblink_sequencer seqr;

  // --- Internal Protected Configuration Variables ---
  protected bit               m_is_configured = 0;
  protected int               m_num_256b_chunks; // <--- Changed parameter
  protected lane_map_code_t   m_lane_map_code;
  protected active_scenario_e m_scenario;

  extern function new(string name = "rmblink_active_sequence");
  
  // Configuration API
  extern function void configure(
    int _num_256b_chunks,                        // <--- Changed parameter
    lane_map_code_t _lane_map_code = X16_MODE,
    active_scenario_e _scenario = ACTIVE_SCENARIO_IDEAL
  );

  extern task pre_body();
  extern task body();

endclass : rmblink_active_sequence


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

function rmblink_active_sequence::new(string name = "rmblink_active_sequence");
  super.new(name);
endfunction : new


function void rmblink_active_sequence::configure(
  int _num_256b_chunks, 
  lane_map_code_t _lane_map_code = X16_MODE,
  active_scenario_e _scenario = ACTIVE_SCENARIO_IDEAL
);
  m_num_256b_chunks = _num_256b_chunks;
  m_lane_map_code   = _lane_map_code;
  m_scenario        = _scenario;
  m_is_configured   = 1;
endfunction : configure


task rmblink_active_sequence::pre_body();
  super.pre_body();
  $cast(seqr, get_sequencer());
endtask : pre_body


task rmblink_active_sequence::body();
  int start_lane;
  int num_active_lanes;
  int cycles_per_256B;
  int m_num_iterations; // Calculated internally now

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

  // 3. Dynamic Calculation for Total Iterations
  // pDATA_WIDTH = 64 bits (8 bytes) per lane. 
  // Formula: 256 Bytes / (Active Lanes * 8 Bytes per lane)
  cycles_per_256B = 256 / (num_active_lanes * (pDATA_WIDTH / 8));
  
  // Calculate total cycles needed to satisfy the requested chunk count
  m_num_iterations = m_num_256b_chunks * cycles_per_256B;

  // 4. Main Stimulus Loop
  for (int cycle = 0; cycle < m_num_iterations; cycle++) begin
    start_item(req);
    assert(req.randomize());

    // Basic streams for ACTIVE operation
    req.clk_stream_p = get_ideal_clkp_stream(pDATA_WIDTH);
    req.clk_stream_n = get_ideal_clkn_stream(pDATA_WIDTH);
    req.track_stream = get_ideal_clkp_stream(pDATA_WIDTH);
    req.rp_opmode    = DATA_PATTERN;

    // --- IDLE UI INJECTION LOGIC ---
    if ((((cycle + 1) % cycles_per_256B) == 0) && cycle != 0) begin
      req.idle_ui_cnt = 64;
    end else begin
      req.idle_ui_cnt = 0;
    end

    // --- VALID STREAM SCENARIO LOGIC ---
    if (m_scenario == ACTIVE_SCENARIO_VALID_ERROR && cycle == (m_num_iterations / 2)) begin
      // Inject an error in the valid stream halfway through the iteration
      for (int i = 0; i < pDATA_WIDTH/8; i++) begin
        req.val_stream[i] = 8'b0000_1111;
      end
    end else begin
      req.val_stream = get_ideal_valid_stream(pDATA_WIDTH/8);
    end

    // Identify the first data pattern
    if (cycle == 0) begin
      req.is_first_data_pat = 1;
    end else begin
      req.is_first_data_pat = 0;
    end

    // --- DATA GENERATION & HIGH-Z HANDLING ---
    for (int lane = 0; lane < pNUM_LANES; lane++) begin
      bit is_lane_active = (lane >= start_lane) && (lane < (start_lane + num_active_lanes));

      for (int word = 0; word < pDATA_WIDTH/16; word++) begin
        if (!is_lane_active) begin
          req.data[lane][word*16 +: 16] = 'z; // Drive deactivated lanes with High Impedance
        end else begin
          req.data[lane][word*16 +: 16] = $urandom(); // Drive random active payload
        end
      end
    end
    
    finish_item(req);
  end
endtask : body