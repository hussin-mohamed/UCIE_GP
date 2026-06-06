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
class phyretrain_RDI_init extends uvm_sequence#(ltsm_rdi_sequence_item);
    `uvm_object_utils(phyretrain_RDI_init)
    ltsm_rdi_sequence_item item;
    
    function new(string name = "phyretrain_RDI_init");
        super.new(name);
    endfunction //new()
    
    task body();
    item = ltsm_rdi_sequence_item::type_id::create("item");
        start_item(item);
        item.i_lp_state_req     = state_req_retrain;
	    item.i_lp_stallack      = 1'b0;
	    item.i_lp_clk_ack       = 1'b0;
	    item.i_lp_wake_req      = 1'b0;
	    item.i_lp_linkerror     = 1'b0;
		finish_item(item);
    endtask 
endclass //className extends superClass



