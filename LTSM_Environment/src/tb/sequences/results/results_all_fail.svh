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
class result_all_fail extends uvm_sequence#(LTSM_controllers_seq_item);
    `uvm_object_utils(result_all_fail)
    LTSM_controllers_seq_item item;
    function new(string name = "result_all_fail");
        super.new(name);
    endfunction //new()
    task body();
        item = LTSM_controllers_seq_item::type_id::create("item");
        start_item(item);
        item.i_rx_error=1'b0;
        item.i_rx_data_results = 64'hFFFF_FFFF_FFFF_0000;
        item.i_rx_valid_results =1'b0;
        finish_item(item);
    endtask 
endclass //className extends superClass