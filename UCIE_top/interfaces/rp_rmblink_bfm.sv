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
 ,input logic reset
);
 // ...

  //============================================================================
  // Methods
  //============================================================================
  task clear();
    // ...
  endtask : clear
endinterface : rp_rmblink_bfm
