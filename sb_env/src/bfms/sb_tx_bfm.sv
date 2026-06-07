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

import sb_shared_pkg::*;

interface sb_tx_bfm(
  input logic clk
 ,input logic reset
 ,input logic o_sb_ready
);
  rx_encoding_t rx_encoding;

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
  // Methods
  //============================================================================
  task clear();
  `ifndef UCIE_SYS_LVL
    i_tx_sb_req   <= 0;
    i_tx_sb_rsp   <= 0;
    i_tx_sb_done  <= 0;
    i_tx_encoding <= 0;
    i_tx_data     <= 0;
    i_tx_info     <= 0;
  `endif
  endtask : clear

endinterface : sb_tx_bfm
