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

interface TX_FSM_SB(clk);
        logic [8:0] i_tx_decoding;
        logic [8:0] o_tx_encoding;
        logic [63:0] i_tx_data;
        logic [63:0] o_tx_data;
        logic [15:0] i_tx_info;
        logic [15:0] o_tx_info;
        logic i_sb_tx_req;
        logic i_sb_tx_rsp;
        logic i_sb_tx_done;
        logic o_tx_sb_req;
        logic o_tx_sb_rsp;
        logic o_tx_sb_done;
        input clk;
        
        sequence rsp_out_tx;
            $rose(o_tx_sb_rsp)
        endsequence

        sequence req_out_tx;
            $rose(o_tx_sb_req)
        endsequence

        sequence req_rsp_in_tx;
            $rose(i_tx_sb_req) || $rose(i_tx_sb_rsp) 
        endsequence

        property done_handshake_tx;
            @(posedge clk) req_rsp_in |=> o_tx_sb_done
        endproperty

        property rsp_handshake_tx;
            @(posedge clk) rsp_out |-> (o_tx_sb_rsp throughout i_sb_tx_done[->1])
        endproperty

        property req_handshake_tx;
            @(posedge clk) req_out |-> (o_tx_sb_req throughout i_sb_tx_done[->1])
        endproperty
        
        assert property(done_handshake_tx);
        assert property(rsp_handshake_tx);
        assert property(req_handshake_tx);
    endinterface //TX_FSM_SB
