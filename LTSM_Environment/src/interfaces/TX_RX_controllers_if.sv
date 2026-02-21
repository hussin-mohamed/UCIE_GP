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

interface LTSM_controllers_if(input logic clk);
  logic i_clk;
  logic i_power;
  logic i_pll_stable;
  logic i_rx_error;
  logic i_rx_done;
  logic i_tx_done;
  logic i_val_error;
  logic o_sbinit_start;
  logic i_sb_ready;
  logic o_t1_ms;
  logic [63:0] i_lane_error;
  logic [8:0] o_tx_encoding;
  logic [8:0] o_rx_encoding;
    
endinterface : LTSM_controllers_if
