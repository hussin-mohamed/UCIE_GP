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
class mbtrain_txinit_datasweep_tx_result_rsp_fai_8_15 extends uvm_sequence#(tx_fsm_sb_sequence_item);
    `uvm_object_utils(mbtrain_txinit_datasweep_tx_result_rsp_fai_8_15)
    tx_fsm_sb_sequence_item item;
    function new(string name = "mbtrain_txinit_datasweep_tx_result_rsp_fai_8_15");
        super.new(name);
    endfunction //new()
    task body();
        item = tx_fsm_sb_sequence_item::type_id::create("item");
        start_item(item);
        item.i_tx_decoding=DATA_TO_CLOCK_TX_RX_RESULT_HANDSHAKE;
        item.i_tx_info =0;
        item.i_tx_info[4]=1'b0;
        item.i_tx_info[5]=1'b0;
        item.i_tx_data=64'hFFFF_FFFF_FFFF_00FF;
        item.i_sb_tx_rsp=1'b1;
        item.i_sb_tx_req=1'b0;
        item.i_sb_tx_done=1'b0;
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