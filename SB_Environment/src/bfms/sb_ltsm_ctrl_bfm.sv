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

// Interface: sb_ltsm_ctrl_bfm
// Description: Control and status interface between Sideband and Link Training
//              State Machine (LTSM). This interface also generates the reset
//              signal used by all other interfaces.
// Author: Amr El-Batarny; Verification Team
//******************************************************************************

interface sb_ltsm_ctrl_bfm(
  input logic clk
);

  //============================================================================
  // Reset Control (Driven by LTSM agent)
  //============================================================================
  logic reset;  // LTSM agent drives this signal

  //============================================================================
  // LTSM → SB Control Signals
  //============================================================================
  logic i_sb_init_start;   // Trigger SBINIT sequence
  logic i_timer_1ms;           // 1ms timer tick for timeout logic

  //============================================================================
  // SB → LTSM Status Signals
  //============================================================================
  logic o_sb_ready;              // SBINIT initialization complete

  //============================================================================
  // Clocking Blocks
  //============================================================================
  
  // Driver clocking block - LTSM controls reset and sends commands
  clocking driver_cb @(posedge clk);
    default input #1step output #1ns;
    output reset;            // LTSM controls reset timing
    output i_sb_init_start;
    output i_timer_1ms;
    input  o_sb_ready;
  endclocking

  // Monitor clocking block - for sampling all signals
  clocking monitor_cb @(posedge clk);
    default input #1step;
    input reset;
    input i_sb_init_start;
    input i_timer_1ms;
    input o_sb_ready;
  endclocking

  //============================================================================
  // Assertions
  //============================================================================

endinterface : sb_ltsm_ctrl_bfm
