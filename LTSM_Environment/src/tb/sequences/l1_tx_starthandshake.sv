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
class l1_start_handshake extends uvm_sequence#(tx_fsm_sb_sequence_item);
    `uvm_object_utils(l1_start_handshake)
    tx_fsm_sb_sequence_item item;
    
    function new(string name = "l1_start_handshake");
        super.new(name);
    endfunction //new()
    
    task body();
        item = seq_item::type_id::create("item");
        start_item(item);
        item.i_lp_state_req     = state_req_l1;
	    item.i_lp_stallack      = 1'b0;
	    item.i_lp_clk_ack       = 1'b0;
	    item.i_lp_wake_req      = 1'b0;
	    item.i_lp_linkerror     = 1'b0;
        finish_item(item);
    endtask 
endclass //className extends superClass


