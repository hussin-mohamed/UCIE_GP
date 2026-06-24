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

// CLASS: ltsm_mbinit_repairval_result_exit_tx
//
// This sequence is used to handle MBINIT repair value result exit transmission.
//
//------------------------------------------------------------------------------

import ltsm_shared_pkg::*;

class ltsm_mbinit_repairval_result_exit_tx#(val_result_t val_result = PASS_VAL) extends uvm_sequence #(tx_fsm_sb_sequence_item);

  `uvm_object_param_utils(ltsm_mbinit_repairval_result_exit_tx)


  function new(string name = "ltsm_mbinit_repairval_result_exit_tx");
    super.new(name);
    val_result = PASS_VAL; // default value
  endfunction

  function new(string name = "ltsm_mbinit_repairval_result_exit_tx", val_result_t val_result_i);
    super.new(name);
    val_result = val_result_i;
  endfunction

  virtual task body();
    tx_fsm_sb_sequence_item tr;
    tr = tx_fsm_sb_sequence_item::type_id::create("tr");
    start_item(tr);
        tr.i_sb_tx_rsp = 1'b1;
        tr.i_tx_decoding = 'h2A;
        tr.i_tx_info[0] = val_result;
    finish_item(tr);
  endtask

endclass
