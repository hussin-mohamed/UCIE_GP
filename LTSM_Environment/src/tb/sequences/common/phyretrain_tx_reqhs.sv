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
class phyretrain_tx_reqhs extends uvm_sequence#(tx_fsm_sb_sequence_item);
    `uvm_object_utils(phyretrain_tx_reqhs)
    tx_fsm_sb_sequence_item item;
    
    function new(string name = "phyretrain_tx_reqhs");
        super.new(name);
    endfunction //new()
    
    task body();
         item = tx_fsm_sb_sequence_item::type_id::create("item");
        start_item(item);
        item.i_tx_decoding      = RX_PHYRETRAIN_Start_RSP_Handshake;
        item.i_sb_tx_rsp        = 1'b1;
        item.i_sb_tx_req        = 1'b0;
        item.i_sb_tx_done       = 1'b0;
        item.i_tx_info[2:0]     = 3'b010; 
        finish_item(item);
    endtask 
endclass //className extends superClass


