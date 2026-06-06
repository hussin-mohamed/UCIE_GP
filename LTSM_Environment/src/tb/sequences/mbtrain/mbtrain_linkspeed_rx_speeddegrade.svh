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

import shared_ltsm_pkg::*;
class mbtrain_linkspeed_rx_speeddegrade extends uvm_sequence#(rx_fsm_sb_sequence_item);
    `uvm_object_utils(mbtrain_linkspeed_rx_speeddegrade)
    rx_fsm_sb_sequence_item item;
    function new(string name = "mbtrain_linkspeed_rx_speeddegrade");
        super.new(name);
    endfunction //new()
    task body();
        item = rx_fsm_sb_sequence_item::type_id::create("item");
        start_item(item);
        item.i_rx_decoding=MBTRAIN_LINKSPEED_TX_Exit_SpeedDegrade_Hnd;
        item.i_sb_rx_done=1'b0;
        item.i_sb_rx_req=1'b1;
        item.i_sb_rx_rsp=1'b0;
        finish_item(item);
        start_item(item);
        item.i_sb_rx_done=1'b0;
        item.i_sb_rx_req=1'b0;
        item.i_sb_rx_rsp=1'b0;
        finish_item(item);
        start_item(item);
        item.i_sb_rx_done=1'b1;
        item.i_sb_rx_req=1'b0;
        item.i_sb_rx_rsp=1'b0;
        finish_item(item);
    endtask 
endclass //className extends superClass