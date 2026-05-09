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
class mbtrain_valtraincenter_tx_endhandshake extends uvm_sequence#(tx_fsm_sb_sequence_item);
    `uvm_object_utils(mbtrain_valtraincenter_tx_endhandshake)
    tx_fsm_sb_sequence_item item;
    function new(string name = "mbtrain_valtraincenter_tx_endhandshake");
        super.new(name);
    endfunction //new()
    task body();
        item = tx_fsm_sb_sequence_item::type_id::create("item");
        start_item(item);
        item.i_sb_tx_rsp=1'b0;
        item.i_sb_tx_req=1'b0;
        item.i_sb_tx_done=1'b1;
        finish_item(item);
        start_item(item);
        item.i_sb_tx_rsp=1'b0;
        item.i_sb_tx_req=1'b0;
        item.i_sb_tx_done=1'b0;
        finish_item(item);
        start_item(item);
        item.i_sb_tx_rsp=1'b0;
        item.i_sb_tx_req=1'b0;
        item.i_sb_tx_done=1'b1;
        finish_item(item);
    endtask 
endclass //className extends superClass