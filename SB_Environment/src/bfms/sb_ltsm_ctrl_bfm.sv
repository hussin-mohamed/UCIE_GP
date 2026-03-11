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
//              State Machine (LTSM).
//******************************************************************************

interface sb_ltsm_ctrl_bfm(
   input  logic clk
  ,input  logic reset
  ,output logic o_sb_ready // SBINIT initialization complete
);

  //============================================================================
  // LTSM → SB Control Signals
  //============================================================================
  logic i_sb_init_start;  // Trigger SBINIT sequence
  logic i_timer_1ms;      // 1ms timer tick for timeout logic

  //============================================================================
  // Methods
  //============================================================================

  task start();
    @(negedge clk);
    i_sb_init_start = 1'b1;
    @(negedge clk);
    i_sb_init_start = 1'b0;
  endtask : start

  task t1ms();
    @(negedge clk);
    i_timer_1ms = 1'b1;
    @(negedge clk);
    i_timer_1ms = 1'b0;
  endtask : t1ms

  task wait_for_ready();
    @(negedge o_sb_ready);
    repeat(2) @(negedge clk);
  endtask : wait_for_ready
endinterface : sb_ltsm_ctrl_bfm
