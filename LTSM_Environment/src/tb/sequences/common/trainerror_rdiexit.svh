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
class trainerror_rdiexit extends uvm_sequence#(ltsm_rdi_sequence_item);
    `uvm_object_utils(trainerror_rdiexit)
    ltsm_rdi_sequence_item item;
    function new(string name = "trainerror_rdiexit");
        super.new(name);
    endfunction //new()
    task body();
        item = ltsm_rdi_sequence_item::type_id::create("item");
        start_item(item);
        item.i_lp_linkerror = 0; 
        finish_item(item);
    endtask 
endclass //className extends superClass