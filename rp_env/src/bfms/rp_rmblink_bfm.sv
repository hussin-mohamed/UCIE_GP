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

`include "uvm_macros.svh"
import shared_pkg::*;
import uvm_pkg::*;


// Interface: rp_rmblink_bfm
// Description: Serial RX-Path communication interface with partner UCIe die
//              (RMBLINK - RX Mainband Link)
//******************************************************************************

interface rp_rmblink_bfm(
  input logic clk
  input logic i_hclk
  input logic i_dclk
 ,input logic reset
);

  logic                  i_clk_p;
  logic                  i_clk_n;
  logic                  i_track;
  logic [pNUM_LANES-1:0] i_data;
  logic                  i_valid;

  //============================================================================
  // Methods
  //============================================================================
  task clear();
    // ...
  endtask : clear

  //============================================================================
  // Amr
  //============================================================================

  task serialize_data(
     input logic [pDATA_WIDTH-1:0] _data  [pNUM_LANES]
    ,input logic [7:0]             _valid
  );
    // ...
  endtask : serialize_data

  task serialize_data_pattern(
     input logic [pDATA_WIDTH-1:0] _data  [pNUM_LANES]
    ,input rate_mode_t _rate_mode
    ,input logic       _valid
    ,input int         _dat_iter_cnt
  );
    // ...
  endtask : serialize_data_pattern

  task deserialize_data(
     input logic [pDATA_WIDTH-1:0] _data  [pNUM_LANES]
    ,input logic [7:0]             _valid
  );
    // ...
  endtask : deserialize_data

  task deserialize_data_pattern(
     input logic [pDATA_WIDTH-1:0] _data  [pNUM_LANES]
    ,input rate_mode_t _rate_mode
    ,input logic       _valid
    ,input int         _dat_iter_cnt
  );
    // ...
  endtask : deserialize_data_pattern

  
  //============================================================================
  // Araby
  //============================================================================

  task serialize_valid_pattern(
      input logic [7:0] _valid
  );
    // ...
  endtask : serialize_valid_pattern

  task serialize_clk_pattern(
     // ...
  );
    // ...
  endtask : serialize_clk_pattern
  
  task deserialize_valid_pattern(
     // ...
  );
    // ...
  endtask : deserialize_valid_pattern

   task deserialize_clk_pattern(
     // ...
  );
    // ...
  endtask : deserialize_clk_pattern


endinterface : rp_rmblink_bfm
