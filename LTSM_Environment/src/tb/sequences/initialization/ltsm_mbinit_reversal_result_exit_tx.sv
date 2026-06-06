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

// CLASS: ltsm_mbinit_reversal_result_exit_tx
//
// This sequence is used to handle MBINIT reversal result exit transmission.
//
//------------------------------------------------------------------------------

import shared_ltsm_pkg::*;

class ltsm_mbinit_reversal_result_exit_tx#(parameter string REVERSAL_RESULT = "pass") extends uvm_sequence #(tx_fsm_sb_sequence_item);

  `uvm_object_param_utils(ltsm_mbinit_reversal_result_exit_tx#(REVERSAL_RESULT))

  function new(string name = "ltsm_mbinit_reversal_result_exit_tx");
    super.new(name);
  endfunction

  virtual task body();
    tx_fsm_sb_sequence_item tr;
    tr = tx_fsm_sb_sequence_item::type_id::create("tr");
    start_item(tr);
        tr.i_sb_tx_rsp = 1'b1;
        tr.i_tx_decoding = 'h33;
        case (REVERSAL_RESULT)
          "pass": tr.i_tx_data[15:0] = `RESULT_THRESHOLD;
          "fail": tr.i_tx_data[15:0] = `RESULT_THRESHOLD >> 1;
        endcase
        
    finish_item(tr);
  endtask

endclass
