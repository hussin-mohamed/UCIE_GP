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

// CLASS: ltsm_mbinit_repairclk_res_data_path_rx
//
// This sequence is used to handle MBINIT repair clock result data path reception.
//
//------------------------------------------------------------------------------

import shared_ltsm_pkg::*;

class ltsm_mbinit_repairclk_res_data_path_rx#(parameter clk_result_t clk_result = PASS) extends uvm_sequence #(LTSM_controllers_seq_item);

  `uvm_object_param_utils(ltsm_mbinit_repairclk_res_data_path_rx)

  function new(string name = "ltsm_mbinit_repairclk_res_data_path_rx");
    super.new(name);
  endfunction

  virtual task body();
    LTSM_controllers_seq_item tr;
    tr = LTSM_controllers_seq_item::type_id::create("tr");
    start_item(tr);
        tr.i_clk_results = clk_result;
    finish_item(tr);
  endtask

endclass
