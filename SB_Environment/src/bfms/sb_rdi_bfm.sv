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

// Interface: sb_rdi_bfm
// Description: Register access and configuration interface between Sideband 
//              and D2D Adapter Layer (RDI - Raw Die Interface)
//******************************************************************************

interface sb_rdi_bfm(
  input logic clk
 ,input logic reset
 ,input logic o_sb_ready
);

  //============================================================================
  // Adapter → SB Signals (lp_*: from the D2D Adapter to the Physical Layer)
  //============================================================================
  logic        i_lp_cfg_vld;     // Adapter has message for SB
  logic        i_lp_cfg_crd;     // Credit return from adapter
  logic [31:0] i_lp_cfg;         // Register access data

  //============================================================================
  // SB → Adapter Signals (pl_*: from the Physical Layer to the D2D Adapter)
  //============================================================================
  logic        o_pl_cfg_vld;     // SB has message for adapter
  logic        o_pl_cfg_crd;     // Credit return to adapter
  logic [31:0] o_pl_cfg;         // Register access data

  //============================================================================
  // Clocking Blocks
  //============================================================================
  
  // Driver clocking block - for driving Adapter→SB signals
  clocking driver_cb @(posedge clk);
  default input #1step output #1ns;
  output i_lp_cfg_vld;
  output i_lp_cfg_crd;
  output i_lp_cfg;
  input  o_pl_cfg_vld;
  input  o_pl_cfg_crd;
  input  o_pl_cfg;
  endclocking

  // Monitor clocking block - for sampling all signals
  clocking monitor_cb @(posedge clk);
  default input #1step;
  input i_lp_cfg_vld;
  input i_lp_cfg_crd;
  input i_lp_cfg;
  input o_pl_cfg_vld;
  input o_pl_cfg_crd;
  input o_pl_cfg;
  endclocking

  //============================================================================
  // Assertions
  //============================================================================

endinterface : sb_rdi_bfm
