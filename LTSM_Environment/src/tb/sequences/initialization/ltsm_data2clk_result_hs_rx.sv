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

// CLASS: ltsm_data2clk_result_hs_rx
//
// This sequence is used to handle data-to-clock result handshake reception.
//
//------------------------------------------------------------------------------

import shared_ltsm_pkg::*;

class ltsm_data2clk_result_hs_rx extends uvm_sequence #(rx_fsm_sb_sequence_item);

  `uvm_object_utils(ltsm_data2clk_result_hs_rx)

  function new(string name = "ltsm_data2clk_result_hs_rx");
    super.new(name);
  endfunction

  virtual task body();
    rx_fsm_sb_sequence_item tr;
    tr = rx_fsm_sb_sequence_item::type_id::create("tr");
    start_item(tr);
        tr.i_rx_decoding = 'h183;
        tr.i_sb_rx_req = 1'b1;
    finish_item(tr);
    start_item(tr);
        tr.i_sb_rx_done=1'b0;
        tr.i_sb_rx_req=1'b0;
        tr.i_sb_rx_rsp=1'b0;
    finish_item(tr);
    start_item(tr);
        tr.i_sb_rx_done=1'b1;
        tr.i_sb_rx_req=1'b0;
        tr.i_sb_rx_rsp=1'b0;
    finish_item(tr);
  endtask

endclass
