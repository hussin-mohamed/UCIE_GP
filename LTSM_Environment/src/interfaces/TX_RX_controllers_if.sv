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

interface LTSM_controllers_if (
    input logic clk
);
  logic i_clk;
  logic i_supply_stable;
  logic i_reset;
  logic i_pll_stable;
  logic i_rx_error;
  logic i_rx_done;
  logic i_tx_done;
  logic i_rx_valid_results;
  logic i_sb_cur_msg_done;
  logic [2:0] i_clk_results;
  logic o_sbinit_start;
  logic i_sb_ready;
  logic o_t1_ms;
  logic [63:0] i_rx_data_results;
  logic [8:0] o_tx_encoding;
  logic [8:0] o_rx_encoding;
  logic [3:0] o_lane_map_tx, o_lane_map_rx;
  logic [15:0] o_error_threshhold;
  logic [2:0] i_speedreg, o_speedreg;
  logic i_par_check_done;
  logic [15:0] i_local_cap;
  logic i_Runtime_Link_Test_status_register, o_Runtime_Link_Test_status_register;
  logic [36:0] i_Runtime_Link_Test_Control_register, o_Runtime_Link_Test_Control_register;

endinterface : LTSM_controllers_if
