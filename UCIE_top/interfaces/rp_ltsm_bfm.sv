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

// Interface: rp_ltsm_bfm
// Description: Control and status interface between RX-Path and Link Training
//              State Machine (LTSM).
//******************************************************************************

interface rp_ltsm_bfm(
   input  logic clk
  ,input  logic reset
);

  //============================================================================
  // Methods
  //============================================================================
  task clear();
    // ...
  endtask : clear

endinterface : rp_ltsm_bfm
