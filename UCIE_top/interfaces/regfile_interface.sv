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

interface regfile_interface(input logic clk);
    logic [2:0] i_speedreg,o_speedreg;
    logic [15:0] i_local_cap;
    logic i_Runtime_Link_Test_status_register,o_Runtime_Link_Test_status_register;
    logic [36:0] i_Runtime_Link_Test_Control_register,o_Runtime_Link_Test_Control_register;

endinterface : LTSM_controllers_if
