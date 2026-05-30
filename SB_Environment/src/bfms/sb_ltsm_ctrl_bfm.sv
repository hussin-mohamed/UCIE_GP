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
  ,input  logic o_sb_ready // SBINIT initialization complete
);

  //============================================================================
  // LTSM → SB Control Signals
  //============================================================================
  logic i_sb_init_start;      // Trigger SBINIT sequence
  logic i_timer_1ms;          // 1ms timer tick for timeout logic

  task clear();
  `ifndef UCIE_SYS_LVL
    i_sb_init_start <= 0;
  `endif
  endtask : clear

  // Millisecond Counter ranging from 0ms to 7ms
  bit [2:0] tms;
  always @(posedge clk) begin
    if (reset) begin
      tms <= 0;
    end else begin
      if (i_timer_1ms) begin
        tms <= tms + 1;
      end
    end
  end

  // Timout flag generator
  bit timeout;
  always @(posedge clk) begin
    if (tms == 7 && i_timer_1ms) begin
      timeout = 1;
    end
  end
  always @(posedge i_sb_init_start) begin
    timeout = 0;
  end

  // Latch the start pulse and clear it on reset or timeout
  bit timer_en = 0;
  always @(posedge clk) begin
    if (reset || timeout) begin
      timer_en <= 1'b0; // Stop the timer when timeout asserts
    end else if (i_sb_init_start) begin
      timer_en <= 1'b1; // Latches high on the pulse
    end
  end

  // Generate the 1ms pulse exactly fitting 7 pattern iterations (84 clk cycles)
`ifndef UCIE_SYS_LVL
  int ms_counter = 0;
  always @(posedge clk) begin
    // USE THE LATCHED ENABLE HERE
    if (reset || !timer_en) begin
      ms_counter  <= 0;
      i_timer_1ms <= 1'b0;
    end else begin
      // Count 0 to 83 to create an exact 84-cycle interval
      if (ms_counter == 83) begin
        i_timer_1ms <= 1'b1;  // Pulse high for 1 logic cycle
        ms_counter  <= 0;
      end else begin
        i_timer_1ms <= 1'b0;
        ms_counter  <= ms_counter + 1;
      end
    end
  end
`endif
endinterface : sb_ltsm_ctrl_bfm
