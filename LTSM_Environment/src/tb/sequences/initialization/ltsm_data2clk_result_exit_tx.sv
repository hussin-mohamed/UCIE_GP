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

// CLASS: ltsm_data2clk_result_exit_tx
//
// This sequence is used to handle data-to-clock result exit transmission.
//
//------------------------------------------------------------------------------

import shared_ltsm_pkg::*;

class ltsm_data2clk_result_exit_tx #(parameter lane_results_t lane_result = ALL_LANES_FUNCTIONAL ) extends uvm_sequence #(tx_fsm_sb_sequence_item);

  `uvm_object_param_utils(ltsm_data2clk_result_exit_tx#(lane_result))

  function new(string name = "ltsm_data2clk_result_exit_tx");
    super.new(name);
  endfunction

  virtual task body();
    tx_fsm_sb_sequence_item tr;
    tr = tx_fsm_sb_sequence_item::type_id::create("tr");
    start_item(tr);
        tr.i_sb_tx_rsp = 1'b1;
        tr.i_tx_decoding = 'h183;
        tr.i_tx_data[15:0] = lane_result;
        tr.i_tx_info[4] = &lane_result; // if all lanes are functional, set i_tx_info[4] to 1, otherwise set it to 0.
    finish_item(tr);
    start_item(tr);
        tr.i_sb_tx_done=1'b0;
        tr.i_sb_tx_req=1'b0;
        tr.i_sb_tx_rsp=1'b0;
    finish_item(tr);
    start_item(tr);
        tr.i_sb_tx_done=1'b1;
        tr.i_sb_tx_req=1'b0;
        tr.i_sb_tx_rsp=1'b0;
    finish_item(tr);
  endtask

endclass
