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

// CLASS: ltsm_mbinit_repairmb_degrage_checking_rx
//
// This sequence is used to handle MBINIT repair MB degrade checking reception.
//
//------------------------------------------------------------------------------

import shared_ltsm_pkg::*;

class ltsm_mbinit_repairmb_degrage_checking_rx#(parameter degrade_t degrade_code = MATCHED) extends uvm_sequence #(rx_fsm_sb_sequence_item);

  `uvm_object_param_utils(ltsm_mbinit_repairmb_degrage_checking_rx#(degrade_code))

  function new(string name = "ltsm_mbinit_repairmb_degrage_checking_rx");
    super.new(name);
  endfunction

  virtual task body();
    rx_fsm_sb_sequence_item tr;
    tr = rx_fsm_sb_sequence_item::type_id::create("tr");
    start_item(tr);
        tr.i_rx_decoding = 'h3A;
        tr.i_rx_info[2:0] = degrade_code;
        tr.i_sb_rx_req = 1'b1;
    finish_item(tr);
  endtask

endclass