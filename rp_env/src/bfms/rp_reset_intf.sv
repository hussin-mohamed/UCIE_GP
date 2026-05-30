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

// Interface: rp_reset_intf
// Description: This interface generates the reset signal used by all other 
//              interfaces.
//******************************************************************************

interface rp_reset_intf (
`ifndef UCIE_SYS_LVL
    input  logic clk,
    output logic reset
`else
    input  logic clk
`endif
);
`ifdef UCIE_SYS_LVL
    logic reset; // Internal signal only, not a port!
`endif
endinterface : rp_reset_intf