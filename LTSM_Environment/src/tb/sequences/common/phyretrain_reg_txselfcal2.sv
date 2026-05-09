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
class phyretrain_reg_txself_2 extends uvm_sequence#(LTSM_controllers_seq_item);
    `uvm_object_utils(phyretrain_reg_txself_2)
    LTSM_controllers_seq_item item;
    
    function new(string name = "phyretrain_reg_txself_2");
        super.new(name);
    endfunction //new()
    
    task body();
    item = LTSM_controllers_seq_item::type_id::create("item");
        start_item(item);
        item.i_Runtime_Link_Test_status_register         =  1'b0; //link up;
	    item.i_Runtime_Link_Test_Control_register[2]     =  1'b0; //retrain request
		finish_item(item);
    endtask 
endclass //className extends superClass



