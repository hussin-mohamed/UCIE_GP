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

// Interface: rp_ltsmc_bfm
// Description: Control and status interface between RX-Path and Link Training
//              State Machine (LTSM).
//******************************************************************************

`include "uvm_macros.svh"
import rp_shared_pkg::*;
import uvm_pkg::*;

interface rp_ltsmc_bfm(
   input  logic clk
  ,input  logic reset
);
  
  lane_map_code_t         i_lane_map_code;    // Selects lane mapping configuration.
  rx_encoding_t           i_rx_encoding;      // Current state of the RX FSM.
  logic [15:0]            i_error_threshold;  // Error threshold for the valid and data pattern detection.
  logic                   i_half_rate;        // Rate mode selector.
  logic                   o_rx_done;          // Indicates that the RX datapath has finished its opertaion.
  logic [pDATA_WIDTH-1:0] o_rx_data_results;  // One bit for each lane which indicates the successful detection of the LFSR pattern on that lane.
  logic [2:0]             o_clk_result;       // Indicates the successful detection of the clock pattern.
  logic                   o_valid_result;     // Indicates the successful detection of the valid pattern.

  //============================================================================
  // Methods
  //============================================================================
  task clear();
    i_lane_map_code    <= X16_MODE;     
    i_rx_encoding      <= RESET_Reset;
    i_error_threshold  <= 0;
    i_half_rate        <= 1;
  endtask : clear

endinterface : rp_ltsmc_bfm
