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

interface RX_FSM_SB(clk);
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
        logic o_rx_sb_rsp;
        logic o_rx_sb_done;
        
        input clk;

        sequence rsp_out_rx;
            $rose(o_rx_sb_rsp)
        endsequence

        sequence req_out_rx;
            $rose(o_rx_sb_req)
        endsequence

        sequence req_rsp_in_rx;
            $rose(i_rx_sb_req) || $rose(i_rx_sb_rsp) 
        endsequence

        property done_handshake_rx;
            @(posedge clk) req_rsp_in |=> o_rx_sb_done
        endproperty

        property rsp_handshake_rx;
            @(posedge clk) rsp_out |-> (o_rx_sb_rsp throughout i_sb_rx_done[->1])
        endproperty

        property req_handshake_rx;
            @(posedge clk) req_out |-> (o_rx_sb_req throughout i_sb_rx_done[->1])
        endproperty
        
        assert property(done_handshake_rx);
        assert property(rsp_handshake_rx);
        assert property(req_handshake_rx);
    endinterface //RX_FSM_SB
