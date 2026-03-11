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

// Interface: sb_tx_bfm
// Description: Bidirectional message exchange interface between Sideband and
//              TX block
//******************************************************************************

interface sb_tx_bfm(
  input logic clk
 ,input logic reset
 ,input logic o_sb_ready
);

  //============================================================================
  // TX → SB Signals (Inputs to DUT)
  //============================================================================
  logic        i_tx_sb_req;      // TX indicates request message
  logic        i_tx_sb_rsp;      // TX indicates response message
  logic        i_tx_sb_done;     // TX consumed SB's message
  logic [8:0]  i_tx_encoding;    // Message encoding from TX
  logic [63:0] i_tx_data;        // Message data from TX
  logic [15:0] i_tx_info;        // Message info from TX

  //============================================================================
  // SB → TX Signals (Outputs from DUT)
  //============================================================================
  logic        o_sb_tx_req;      // SB indicates request to TX
  logic        o_sb_tx_rsp;      // SB indicates response to TX
  logic        o_sb_tx_done;     // SB consumed TX's message
  logic [8:0]  o_tx_decoding;    // Message decoding to TX
  logic [63:0] o_tx_data;        // Message data to TX
  logic [15:0] o_tx_info;        // Message info to TX
  logic        o_tx_valid;       // SB indicates to TX that the message has no parity errors

  //============================================================================
  // Clocking Blocks
  //============================================================================
  
  // Driver clocking block - for driving TX→SB signals
  clocking driver_cb @(posedge clk);
  default input #1step output #1ns;
  output i_tx_sb_req;
  output i_tx_sb_rsp;
  output i_tx_sb_done;
  output i_tx_encoding;
  output i_tx_data;
  input  o_sb_tx_req;
  input  o_sb_tx_rsp;
  input  o_sb_tx_done;
  input  o_tx_decoding;
  input  o_tx_data;
  endclocking

  // Monitor clocking block - for sampling all signals
  clocking monitor_cb @(posedge clk);
  default input #1step;
  input i_tx_sb_req;
  input i_tx_sb_rsp;
  input i_tx_sb_done;
  input i_tx_encoding;
  input i_tx_data;
  input o_sb_tx_req;
  input o_sb_tx_rsp;
  input o_sb_tx_done;
  input o_tx_decoding;
  input o_tx_data;
  endclocking

  //============================================================================
  // Assertions
  //============================================================================

endinterface : sb_tx_bfm
