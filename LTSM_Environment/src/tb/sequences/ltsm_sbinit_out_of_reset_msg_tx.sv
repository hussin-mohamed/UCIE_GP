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

// CLASS: ltsm_sbinit_out_of_reset_msg_tx
//
// This sequence is used to send the SBINIT out of reset message on the TX side.
//
//------------------------------------------------------------------------------

import shared_ltsm_pkg::*;

class ltsm_sbinit_out_of_reset_msg_tx extends uvm_sequence #(tx_fsm_sb_sequence_item);

  `uvm_object_utils(ltsm_sbinit_out_of_reset_msg_tx)

  function new(string name = "ltsm_sbinit_out_of_reset_msg_tx");
    super.new(name);
  endfunction

  virtual task body();
    tx_fsm_sb_sequence_item tr;
    tr = tx_fsm_sb_sequence_item::type_id::create("tr");
    start_item(tr);
      // stop generating the pattern and send the out of reset_msg
      tr.i_tx_decoding = 'h8;
      tr.i_stop = 1'b1;
      
    finish_item(tr);
  endtask

endclass
