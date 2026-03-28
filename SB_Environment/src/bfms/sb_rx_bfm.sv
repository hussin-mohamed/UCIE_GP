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

// Interface: sb_rx_bfm
// Description: Bidirectional message exchange interface between Sideband and 
//              RX block
//******************************************************************************

interface sb_rx_bfm(
  input logic clk
 ,input logic reset
 ,input logic o_sb_ready
);

  //============================================================================
  // RX → SB Signals (Inputs to DUT)
  //============================================================================
  logic        i_rx_sb_req;      // RX indicates request message
  logic        i_rx_sb_rsp;      // RX indicates response message
  logic        i_rx_sb_done;     // RX consumed SB's message
  logic [8:0]  i_rx_encoding;    // Message encoding from RX
  logic [63:0] i_rx_data;        // Message data from RX
  logic [15:0] i_rx_info;        // Message info from RX 
  //============================================================================
  // SB → RX Signals (Outputs from DUT)
  //============================================================================
  logic        o_sb_rx_req;      // SB indicates request to RX
  logic        o_sb_rx_rsp;      // SB indicates response to RX
  logic        o_sb_rx_done;     // SB consumed RX's message
  logic [8:0]  o_rx_decoding;    // Message decoding to RX
  logic [63:0] o_rx_data;        // Message data to RX
  logic [15:0] o_rx_info;        // Message info to RX
  logic        o_rx_valid;       // SB indicates to RX that the message has no parity errors

  //============================================================================
  // Methods
  //============================================================================
  task clear();
    i_rx_sb_req   <= 0;
    i_rx_sb_rsp   <= 0;
    i_rx_sb_done  <= 0;
    i_rx_encoding <= 0;
    i_rx_data     <= 0;
    i_rx_info     <= 0;
  endtask : clear

endinterface : sb_rx_bfm
