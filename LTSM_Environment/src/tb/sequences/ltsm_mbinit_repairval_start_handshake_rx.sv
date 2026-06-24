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

// CLASS: ltsm_mbinit_repairval_start_handshake_rx
//
// This sequence is used to handle MBINIT repair value start handshake reception.
//
//------------------------------------------------------------------------------

import ltsm_shared_pkg::*;

class ltsm_mbinit_repairval_start_handshake_rx extends uvm_sequence #(rx_fsm_sb_sequence_item);

  `uvm_object_utils(ltsm_mbinit_repairval_start_handshake_rx)

  function new(string name = "ltsm_mbinit_repairval_start_handshake_rx");
    super.new(name);
  endfunction

  virtual task body();
    rx_fsm_sb_sequence_item tr;
    tr = rx_fsm_sb_sequence_item::type_id::create("tr");
    start_item(tr);
        tr.i_sb_rx_req = 1'b1;
        tr.i_rx_decoding = 'h24;
    finish_item(tr);
  endtask

endclass
