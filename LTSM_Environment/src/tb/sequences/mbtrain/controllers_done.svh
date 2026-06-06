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
class controllers_done extends uvm_sequence#(LTSM_controllers_seq_item);
    `uvm_object_utils(controllers_done)
    LTSM_controllers_seq_item item;
    function new(string name = "controllers_done");
        super.new(name);
    endfunction //new()
    task body();
        item = LTSM_controllers_seq_item::type_id::create("item");
        start_item(item);
        item.i_tx_done=1'b0;
        item.i_rx_done=1'b0;
        finish_item(item);
        start_item(item);
        item.i_tx_done=1'b1;
        item.i_rx_done=1'b1;
        finish_item(item);
        start_item(item);
        item.i_tx_done=1'b1;
        item.i_rx_done=1'b1;
        finish_item(item);
        start_item(item);
        item.i_speedreg = item.o_speedreg;
        item.i_tx_done=1'b0;
        item.i_rx_done=1'b0;
        finish_item(item);
    endtask 
endclass //className extends superClass