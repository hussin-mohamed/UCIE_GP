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

// Interface: rp_rdi_bfm
// Description: Register access and configuration interface between RX-Path 
//              and D2D Adapter Layer (RDI - Raw Die Interface)
//******************************************************************************

`include "uvm_macros.svh"
import rp_shared_pkg::*;
import uvm_pkg::*;

interface rp_rdi_bfm(
  input logic clk
 ,input logic reset
);
  //============================================================================
  // Phy → RDI Signals (Outputs from DUT)
  //============================================================================
  
  logic [pNBYTES-1:0][7:0]    pl_data;
  logic                       pl_valid;
  
  task clear();
    
  endtask : clear
endinterface : rp_rdi_bfm
