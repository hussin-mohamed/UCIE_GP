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
class phyretrain_rx_frame_error extends uvm_sequence#(LTSM_controllers_seq_item);
    `uvm_object_utils(phyretrain_rx_frame_error)
    LTSM_controllers_seq_item item;
    
    function new(string name = "phyretrain_rx_frame_error");
        super.new(name);
    endfunction //new()
    
    task body();
         item = LTSM_controllers_seq_item::type_id::create("item");
        start_item(item);
        item.i_rx_valid_results = 1'b1;
        finish_item(item);
    endtask 
endclass //className extends superClass


