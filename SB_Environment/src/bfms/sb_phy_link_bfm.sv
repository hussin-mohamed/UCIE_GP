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

// Interface: sb_phy_link_bfm
// Description: Serial sideband communication interface with partner UCIe die
//              (MDI - Module Die Interface)
// Author: Amr El-Batarny; Verification Team
//******************************************************************************

interface sb_phy_link_bfm(
  input logic clk
 ,input logic reset
);

  //============================================================================
  // From Partner Die Signals (Inputs to DUT)
  //============================================================================
  logic i_rx_sb_data;      // Serial data from partner
  logic i_rx_sb_clk;       // Serial clock from partner

  //============================================================================
  // To Partner Die Signals (Outputs from DUT)
  //============================================================================
  logic o_tx_sb_data;      // Serial data to partner
  logic o_tx_sb_clk;       // Serial clock to partner

  //============================================================================
  // Clocking Blocks
  //============================================================================
  
  // Driver clocking block - for driving partner die signals
  clocking driver_cb @(posedge clk);
    default input #1step output #1ns;
    output i_rx_sb_data;
    output i_rx_sb_clk;
    input  o_tx_sb_data;
  endclocking

  // Monitor clocking block - for sampling all signals
  clocking monitor_cb @(posedge clk);
    default input #1step;
    input i_rx_sb_data;
    input i_rx_sb_clk;
    input o_tx_sb_data;
  endclocking 

  //============================================================================
  // Assertions
  //============================================================================

endinterface : sb_phy_link_bfm
