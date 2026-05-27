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
// CLASS: ltsmc_sequence
//
//
//-----------------------------------------------------------------------------

class ltsmc_sequence extends rp_sequence_base #(ltsmc_seq_item);
  `uvm_object_utils(ltsmc_sequence)

  ltsmc_sequencer seqr;

  // FSM Tracking
  rx_encoding_t current_state_enc;
  int           flow_index;
  
  // Traversal Controls
  bit           traverse_mode;
  int           target_flow_index;

  // Local Configuration Storage
  lane_map_code_t m_lane_map_code;
  logic [15:0]    m_error_threshold;
  logic           m_half_rate;

  extern function new(string name = "ltsmc_sequence");

  extern virtual function void configure(
     input next_state_type_t _next_state_type
    ,input lane_map_code_t   _lane_map_code
    ,input logic [15:0]      _error_threshold
    ,input logic             _half_rate
    ,input rx_encoding_t     _target_rx_enc=RESET_Reset
  );

  extern task body();
  extern task pre_body();

endclass : ltsmc_sequence

//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

// new
// ---

function ltsmc_sequence::new(string name = "ltsmc_sequence");
  super.new(name);
  flow_index = 0;
  traverse_mode = 0;
  current_state_enc = rx_flow_array[0];
endfunction : new

// configure
// ---------

function void ltsmc_sequence::configure(
   input next_state_type_t _next_state_type
  ,input lane_map_code_t   _lane_map_code
  ,input logic [15:0]      _error_threshold
  ,input logic             _half_rate
  ,input rx_encoding_t     _target_rx_enc = RESET_Reset
);

  m_lane_map_code   = _lane_map_code;
  m_error_threshold = _error_threshold;
  m_half_rate       = _half_rate;
  traverse_mode     = 0; // Default to single-step

  if (_next_state_type == NEXT) begin
    if (flow_index < rx_flow_array.size() - 1) begin
      flow_index++;
    end
    current_state_enc = rx_flow_array[flow_index];

  end else if (_next_state_type == CUSTOM) begin
    current_state_enc = _target_rx_enc;
    
    if (_target_rx_enc == RESET_Reset) begin
      flow_index = 0;
    end else begin
      foreach (rx_flow_array[i]) begin
        if (rx_flow_array[i] == _target_rx_enc) begin
          flow_index = i;
          break; 
        end
      end
    end

  end else if (_next_state_type == TRAVERSE) begin
    int found_idx = -1;
    
    // Search for the target state in the linear array
    foreach (rx_flow_array[i]) begin
      if (rx_flow_array[i] == _target_rx_enc) begin
        found_idx = i;
        break;
      end
    end

    // Fatal 1: State is not in the happy-path array (e.g. TRAINERROR)
    if (found_idx == -1) begin
      `uvm_fatal("LTSMC_SEQ", $sformatf("TRAVERSE target state '%0s' is unreachable via the linear array flow.", _target_rx_enc.name()))
    end
    // Fatal 2: Target state is behind or equal to the current state
    else if (found_idx <= flow_index) begin
      `uvm_fatal("LTSMC_SEQ", $sformatf("TRAVERSE target state '%0s' (index %0d) is behind or equal to current state '%0s' (index %0d).", 
                 _target_rx_enc.name(), found_idx, rx_flow_array[flow_index].name(), flow_index))
    end
    // Valid Traversal
    else begin
      traverse_mode = 1;
      target_flow_index = found_idx;
    end
  end

endfunction : configure

// pre_body
// --------
task ltsmc_sequence::pre_body();
  super.pre_body();
  $cast(seqr, get_sequencer());
endtask : pre_body

// body
// ----
task ltsmc_sequence::body();
  
  if (traverse_mode == 0) begin
    // Standard Single-Step Mode
    start_item(req);
    req.rx_encoding     = current_state_enc;
    req.lane_map_code   = m_lane_map_code;
    req.error_threshold = m_error_threshold;
    req.half_rate       = m_half_rate;
    finish_item(req);
    
  end else begin
    // Multi-Step Traversal Mode
    for (int i = flow_index + 1; i <= target_flow_index; i++) begin
      start_item(req);
      req.rx_encoding     = rx_flow_array[i];
      req.lane_map_code   = m_lane_map_code;
      req.error_threshold = m_error_threshold;
      req.half_rate       = m_half_rate;
      finish_item(req);
      
      // Update the sequence's internal tracking as it traverses
      flow_index = i;
      current_state_enc = rx_flow_array[i];
    end
    
    // Reset traverse mode after completion so future NEXT calls behave normally
    traverse_mode = 0; 
  end

endtask : body
