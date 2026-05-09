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

interface RX_FSM_SB(input logic					clk);
        logic [8:0] i_rx_decoding;
        logic [8:0] o_rx_encoding;
        logic [63:0] i_rx_data;
        logic [63:0] o_rx_data;
        logic [15:0] i_rx_info;
        logic [15:0] o_rx_info;
        logic i_sb_rx_req;
        logic i_sb_rx_rsp;
        logic i_sb_rx_done;
        logic o_rx_sb_req;
        logic i_reset;
        logic o_rx_sb_rsp;
        logic o_rx_sb_done;
        

        
    endinterface //RX_FSM_SB