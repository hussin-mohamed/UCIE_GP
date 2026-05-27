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
// CLASS: ltsm_sequence
//
//
//-----------------------------------------------------------------------------

class ltsm_sequence extends rp_sequence_base #(ltsmc_seq_item);
  `uvm_object_utils(ltsm_sequence)

  ltsmc_sequencer seqr;
  rx_encoding_t   current_state_enc;
  rx_encoding_t   previous_state_enc;
  rx_encoding_t   resume_state_enc;

  // Local Configuration Storage
  lane_map_code_t m_lane_map_code;
  logic [15:0]    m_error_threshold;
  logic           m_half_rate;


  // Function: new
  //
  // Creates a new ltsm_sequence instance with the given name.

  extern function new(string name = "ltsm_sequence");

  extern virtual function void configure(
     input next_state_type_t _next_state_type
    ,input lane_map_code_t   _lane_map_code
    ,input logic [15:0]      _error_threshold
    ,input logic             _half_rate
    ,input rx_encoding_t     _next_rx_enc=RESET_Reset
  );


  // Task: body
  //
  // Sends randomized RX items and synchronizes with the reactive FIFO.

  extern task body();

  // Task: pre_body
  //
  // Captures the typed sequencer handle before the sequence starts.

  extern task pre_body();

endclass : ltsm_sequence


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: ltsm_sequence
//
//-----------------------------------------------------------------------------


// new
// ---

function ltsm_sequence::new(string name = "ltsm_sequence");
  super.new(name);
  current_state_enc = RESET_Reset;
  resume_state_enc  = RESET_Reset;
endfunction : new


function void ltsm_sequence::configure(
   input next_state_type_t _next_state_type
  ,input lane_map_code_t   _lane_map_code
  ,input logic [15:0]      _error_threshold
  ,input logic             _half_rate
  ,input rx_encoding_t     _next_rx_enc = RESET_Reset // Default at the end
);
  
  rx_encoding_t next_calculated_state;

  m_lane_map_code   = _lane_map_code;
  m_error_threshold = _error_threshold;
  m_half_rate       = _half_rate;

  if (_next_state_type == NEXT) begin
    previous_state_enc = current_state_enc;
    
    // Are we exiting the Data-To-Clock test phase?
    if (current_state_enc == Data_To_Clock_test_RX_End_Init_Handshake_TX_Init ||
        current_state_enc == Data_To_Clock_test_RX_End_Init_Handshake_RX_Init) begin
        
      // Defensive check: Ensure we have a valid return address
      if (resume_state_enc == RESET_Reset) begin
        `uvm_warning("FSM_RESUME", "Attempting to resume from Data-To-Clock but resume_state is RESET. Defaulting to SBINIT.")
      end

      // Use standard .next() to resume the FSM sequentially, 
      current_state_enc = resume_state_enc.next();
      
    end else begin
      
      // Calculate the next state (which might be a jump to Data_To_Clock)
      next_calculated_state = get_next_rx_state(current_state_enc);
      
      // Did get_next_rx_state() just trigger a jump into Data-To-Clock?
      // If yes, save the CURRENT state so we know where to return to later.
      if (next_calculated_state == Data_To_Clock_test_RX_INIT_Handshake_TX_Init ||
          next_calculated_state == Data_To_Clock_test_RX_INIT_Handshake_RX_Init) begin
        resume_state_enc = current_state_enc; 
      end
      
      current_state_enc = next_calculated_state;
    end
    
  end else if (_next_state_type == CUSTOM) begin
    current_state_enc  = _next_rx_enc;

    // Clear the stack if we are forced into Reset or Error
    if (_next_rx_enc == RESET_Reset || _next_rx_enc == TRAINERROR_RX_Handshake) begin
       resume_state_enc = RESET_Reset; 
    end
  end

endfunction : configure


// pre_body
// --------

task ltsm_sequence::pre_body();
  super.pre_body();
  $cast(seqr, get_sequencer());
endtask : pre_body


// body
// ----

task ltsm_sequence::body();
  start_item(req);
  req.rx_encoding     = current_state_enc;
  req.lane_map_code   = m_lane_map_code;
  req.error_threshold = m_error_threshold;
  req.half_rate       = m_half_rate;
  finish_item(req);
endtask : body
