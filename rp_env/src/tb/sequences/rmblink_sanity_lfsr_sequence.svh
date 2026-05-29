// ****************************************************************************
// * *
// * Copyright (c) 2014-2015 Synopsys Inc. All rights reserved.               *
// * *
// * Synopsys Proprietary and Confidential.                                   *
// * This file contains confidential information and the trade secrets of     *
// * Synopsys Inc. Use, disclosure, or reproduction is prohibited without     *
// * the prior express written permission of Synopsys, Inc.                   *
// * *
// * Synopsys, Inc.                                                           *
// * 700 East Middlefield Road                                                *
// * Mountain View, California 94043                                          *
// * (800) 541-7737                                                           *
// * *
// ****************************************************************************

//-----------------------------------------------------------------------------
// ENUM: lfsr_scenario_e
// Defines the stress test scenarios for the LFSR sequence
//-----------------------------------------------------------------------------
typedef enum {
  SCENARIO_EXACT_MATCH,                 
  SCENARIO_ERROR_BELOW_THRESH_RANDOM,           
  SCENARIO_ERROR_ABOVE_THRESH_RANDOM,
	SCENARIO_ERROR_BELOW_THRESH_START,
	SCENARIO_ERROR_BELOW_THRESH_END,
	SCENARIO_ERROR_ABOVE_THRESH_START,
	SCENARIO_ERROR_ABOVE_THRESH_END
} lfsr_scenario_e;

parameter DATA_WIDTH = 64;
parameter LFSR_TAPS = 23;
parameter LANES_NUMBER = 16;

parameter logic [LFSR_TAPS-1:0] LANE_ID [0:7] = '{
    23'h1DBFBC, // Lane 0,8
    23'h0607BB, // Lane 1,9
    23'h1EC760, // Lane 2,10
    23'h18C0DB, // Lane 3,11
    23'h010F12, // Lane 4,12
    23'h19CFC9, // Lane 5,13
    23'h0277CE, // Lane 6,14
    23'h1BB807  // Lane 7,15
    };

//-----------------------------------------------------------------------------
//
// CLASS: rmblink_sanity_lfsr_sequence
//
//
//-----------------------------------------------------------------------------

class rmblink_sanity_lfsr_sequence extends rp_sequence_base #(rmblink_seq_item);
  `uvm_object_utils(rmblink_sanity_lfsr_sequence)

  rmblink_sequencer seqr;

// --- Configuration Knobs for Virtual Sequence ---

  lfsr_scenario_e scenario       = SCENARIO_EXACT_MATCH;

  int num_iterations = 32;
  bit is_first_data_pat;
  bit train_mode;
  bit load_mode;
  logic [DATA_WIDTH-1:0] dummy_data [LANES_NUMBER];

// --- Internal Variables for LFSR Pattern Generation --
  static logic [LFSR_TAPS-1:0] lfsr_state [LANES_NUMBER];
  static logic [LFSR_TAPS-1:0] lfsr_last_state [LANES_NUMBER];

  logic expected_bit;

  extern function new(string name = "rmblink_sanity_lfsr_sequence");
  extern task pre_body();
  extern task body();

  extern task load_lfsr_state (output logic [DATA_WIDTH-1:0] out_data [LANES_NUMBER], input int _bit_index);
  extern task train_detection(input int _bit_index, output logic [DATA_WIDTH-1:0] out_data [LANES_NUMBER]);
  extern task update_lfsr_state(input bit load);
  extern task rx_lfsr_pattern_generation (input bit _train , input bit _load, output logic [DATA_WIDTH-1:0] _out_data [LANES_NUMBER]);

endclass : rmblink_sanity_lfsr_sequence


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

function rmblink_sanity_lfsr_sequence::new(string name = "rmblink_sanity_lfsr_sequence");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Simple LFSR implementation for generating expected data patterns and error injection
//-----------------------------------------------------------------------------


task static rmblink_sanity_lfsr_sequence::load_lfsr_state (output logic [DATA_WIDTH-1:0] out_data [LANES_NUMBER], input int _bit_index);
    for (int i = 0; i < LANES_NUMBER; i++) begin
        lfsr_state[i] = LANE_ID[i % 8];
        out_data[i][_bit_index] = lfsr_state[i][LFSR_TAPS-1];
    end
endtask

task static rmblink_sanity_lfsr_sequence::train_detection(input int _bit_index, output logic [DATA_WIDTH-1:0] out_data [LANES_NUMBER]);
    for (int i = 0; i < LANES_NUMBER; i++) begin
         expected_bit = lfsr_state[i][LFSR_TAPS-1];
         out_data[i][_bit_index] = lfsr_state[i][LFSR_TAPS-1];
    end
endtask

task static rmblink_sanity_lfsr_sequence::update_lfsr_state(input bit load);
    if (!load) begin
        foreach (lfsr_state[i,j]) begin
            if ((j == 2) || (j == 5) || (j == 8) || (j == 16) || (j == 21)) begin
                lfsr_state[i][j] = lfsr_last_state[i][j-1] ^ lfsr_last_state[i][LFSR_TAPS-1];
            end else if (j == 0) begin
                lfsr_state[i][j] = lfsr_last_state[i][LFSR_TAPS-1];
            end else begin
                lfsr_state[i][j] = lfsr_last_state[i][j-1];
            end
        end
    end

   lfsr_last_state = lfsr_state;
endtask

task static rmblink_sanity_lfsr_sequence::rx_lfsr_pattern_generation (input bit _train , input bit _load, output logic [DATA_WIDTH-1:0] _out_data [LANES_NUMBER]);
    for (int bit_index = 0; bit_index < DATA_WIDTH; bit_index++) begin   
        if (_load)begin
            load_lfsr_state(_out_data,bit_index);
        end
        else if (_train) begin
            train_detection(bit_index,_out_data);
        end
         
        update_lfsr_state(_load);
    end  
endtask

task rmblink_sanity_lfsr_sequence::pre_body();
  super.pre_body();
  $cast(seqr, get_sequencer());
endtask : pre_body


task rmblink_sanity_lfsr_sequence::body();
  // Arrays to hold the pre-calculated random cycle and bit index for each lane
  int err_cycle_1 [LANES_NUMBER];
  int err_bit_1   [LANES_NUMBER];
  int err_cycle_2 [LANES_NUMBER];
  int err_bit_2   [LANES_NUMBER];
	int err_bit_fixed1 = 0; // For scenarios where error is injected at a fixed bit position
	int err_bit_fixed2 = 0; // For scenarios where two errors are injected at fixed bit positions

  // 1. Pre-calculate the exact cycle and bit for the errors for each lane
  for (int i = 0; i < LANES_NUMBER; i++) begin
    err_cycle_1[i] = $urandom_range(num_iterations - 1, 0);
    err_bit_1[i]   = $urandom_range(pDATA_WIDTH - 1, 0);

    if (scenario == SCENARIO_ERROR_ABOVE_THRESH_RANDOM) begin
      err_cycle_2[i] = $urandom_range(num_iterations - 1, 0);
      err_bit_2[i]   = $urandom_range(pDATA_WIDTH - 1, 0);

      // Ensure the second error doesn't flip the exact same bit in the exact same cycle, 
      // which would cancel the error out.
      while (err_cycle_1[i] == err_cycle_2[i] && err_bit_1[i] == err_bit_2[i]) begin
        err_cycle_2[i] = $urandom_range(num_iterations - 1, 0);
        err_bit_2[i]   = $urandom_range(pDATA_WIDTH - 1, 0);
      end
    end
  end

  // 2. Start the main sequence loop
  for (int cycle = 0; cycle < num_iterations; cycle++) begin
    start_item(req);
    
    // Standard generic streams [cite: 33]
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
    case (scenario)
      SCENARIO_EXACT_MATCH: begin
        rx_lfsr_pattern_generation(train_mode, 1'b0, req.data);
      end

      SCENARIO_ERROR_BELOW_THRESH_RANDOM: begin
        rx_lfsr_pattern_generation(train_mode, 1'b0, req.data);
        
        // Inject exactly one error per lane across ALL iterations
        for (int i = 0; i < LANES_NUMBER; i++) begin
          if (cycle == err_cycle_1[i]) begin
            req.data[i][err_bit_1[i]] = ~req.data[i][err_bit_1[i]];
          end
        end
      end
      
      SCENARIO_ERROR_ABOVE_THRESH_RANDOM: begin
        rx_lfsr_pattern_generation(train_mode, 1'b0, req.data);
        
        // Inject exactly two errors per lane across ALL iterations
        for (int i = 0; i < LANES_NUMBER; i++) begin
          // First random error
          if (cycle == err_cycle_1[i]) begin
            req.data[i][err_bit_1[i]] = ~req.data[i][err_bit_1[i]];
          end
          // Second random error
          if (cycle == err_cycle_2[i]) begin
            req.data[i][err_bit_2[i]] = ~req.data[i][err_bit_2[i]];
          end
        end
      end

			SCENARIO_ERROR_BELOW_THRESH_START: begin
        rx_lfsr_pattern_generation(train_mode, 1'b0, req.data);
        // Inject exactly one error per lane across in first itration
				if (cycle == 0) begin
        for (int i = 0; i < LANES_NUMBER; i++) begin
          err_bit_fixed1 = $urandom_range(pDATA_WIDTH - 1, 0);
						req.data[i][err_bit_fixed1] = ~req.data[i][err_bit_fixed1];
					end
        end
      end

			SCENARIO_ERROR_BELOW_THRESH_END: begin
				rx_lfsr_pattern_generation(train_mode, 1'b0, req.data);
				// Inject exactly one error per lane across in last itration
				if (cycle == num_iterations - 1) begin
				for (int i = 0; i < LANES_NUMBER; i++) begin
					err_bit_fixed1 = $urandom_range(pDATA_WIDTH - 1, 0);
					req.data[i][err_bit_fixed1] = ~req.data[i][err_bit_fixed1];
					end
				end
			end

			SCENARIO_ERROR_ABOVE_THRESH_START: begin
				rx_lfsr_pattern_generation(train_mode, 1'b0, req.data);
				// Inject exactly two errors per lane across in first itration
				if (cycle == 0) begin
				for (int i = 0; i < LANES_NUMBER; i++) begin
					err_bit_fixed1 = $urandom_range(pDATA_WIDTH - 1, 0);
					err_bit_fixed2 = $urandom_range(pDATA_WIDTH - 1, 0);
					while (err_bit_fixed1 == err_bit_fixed2) begin
						err_bit_fixed2 = $urandom_range(pDATA_WIDTH - 1, 0);
          end
					req.data[i][err_bit_fixed1] = ~req.data[i][err_bit_fixed1];
					req.data[i][err_bit_fixed2] = ~req.data[i][err_bit_fixed2];
					end
				end
			end

			SCENARIO_ERROR_ABOVE_THRESH_END: begin
				rx_lfsr_pattern_generation(train_mode, 1'b0, req.data);
				// Inject exactly two errors per lane across in last itration
				if (cycle == num_iterations - 1) begin
				for (int i = 0; i < LANES_NUMBER; i++) begin
					err_bit_fixed1 = $urandom_range(pDATA_WIDTH - 1, 0);
					err_bit_fixed2 = $urandom_range(pDATA_WIDTH - 1, 0);
					while (err_bit_fixed1 == err_bit_fixed2) begin
						err_bit_fixed2 = $urandom_range(pDATA_WIDTH - 1, 0);
          end
					req.data[i][err_bit_fixed1] = ~req.data[i][err_bit_fixed1];
					req.data[i][err_bit_fixed2] = ~req.data[i][err_bit_fixed2];
					end
				end
			end

    endcase

    finish_item(req);
  end

endtask : body