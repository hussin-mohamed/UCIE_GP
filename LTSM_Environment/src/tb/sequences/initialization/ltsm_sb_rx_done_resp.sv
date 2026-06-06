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

// CLASS: ltsm_mbinit_reversal_init_hs_tx
//
// This sequence is used to handle MBINIT reversal init handshake transmission.
//
//------------------------------------------------------------------------------

import shared_ltsm_pkg::*;

class ltsm_sb_rx_done_resp extends uvm_sequence #(rx_fsm_sb_sequence_item);

  `uvm_object_utils(ltsm_sb_rx_done_resp)

  function new(string name = "ltsm_sb_rx_done_resp");
    super.new(name);
  endfunction

  virtual task body();
    rx_fsm_sb_sequence_item tr;
    tr = rx_fsm_sb_sequence_item::type_id::create("tr");
    start_item(tr);
        tr.i_sb_rx_done = 1;
        tr.i_sb_rx_req = 0;
    finish_item(tr);
  endtask

endclass