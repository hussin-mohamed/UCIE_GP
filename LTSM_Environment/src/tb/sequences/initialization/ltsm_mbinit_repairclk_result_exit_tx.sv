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

// CLASS: ltsm_mbinit_repairclk_result_exit_tx
//
// This sequence is used to handle MBINIT repair clock result exit hs (decoding and the response).
//
//------------------------------------------------------------------------------

import shared_ltsm_pkg::*;

class ltsm_mbinit_repairclk_result_exit_tx#(parameter clk_result_t clk_result = PASS) extends uvm_sequence #(tx_fsm_sb_sequence_item);

  `uvm_object_param_utils(ltsm_mbinit_repairclk_result_exit_tx#(clk_result))

  function new(string name = "ltsm_mbinit_repairclk_result_exit_tx");
    super.new(name);
  endfunction

  virtual task body();
    tx_fsm_sb_sequence_item tr;
    tr = tx_fsm_sb_sequence_item::type_id::create("tr");
    start_item(tr);
        tr.i_tx_decoding = 'h22;
        tr.i_sb_tx_rsp = 1; 
        tr.i_tx_info[2:0] = clk_result;
    finish_item(tr);
  endtask

endclass
