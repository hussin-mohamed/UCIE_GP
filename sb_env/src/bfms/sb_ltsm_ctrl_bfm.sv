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
   input  logic clk,
   input  logic clk_l
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

  // Millisecond Counter ranging from 0ms to 7ms and Timeout logic
  bit [2:0] tms;
  bit       timeout;
  reg       sb_init_start_d;
  reg       timer_1ms_d;
  reg [2:0] delay_line;

  always @(posedge clk) begin
    if (reset) begin
      sb_init_start_d <= 0;
      timer_1ms_d     <= 0;
      delay_line      <= 0;
      tms             <= 0;
      timeout         <= 0;
    end else begin
      sb_init_start_d <= i_sb_init_start;
      timer_1ms_d     <= i_timer_1ms;

      if (i_sb_init_start && !sb_init_start_d) begin
        // Reset counter and timeout flag on the rising edge of start initialization
        tms        <= 0;
        timeout    <= 0;
        delay_line <= 0;
      end else begin
        delay_line <= {delay_line[1:0], (i_timer_1ms && !timer_1ms_d)};
        if (delay_line[1]) begin
          if (i_sb_init_start) begin
            tms <= tms + 1;
          end
        end
        if (tms == 7 && i_timer_1ms) begin
          timeout <= 1;
        end
      end
    end
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
      if (ms_counter == 82 || ms_counter == 83) begin
        i_timer_1ms <= 1'b1;
      end else begin
        i_timer_1ms <= 1'b0;
      end

      if (ms_counter == 83) begin
        ms_counter  <= 0;
      end else begin
        ms_counter  <= ms_counter + 1;
      end
    end
  end
`endif
endinterface : sb_ltsm_ctrl_bfm
