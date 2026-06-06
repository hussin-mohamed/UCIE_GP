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

// CLASS: ltsm_result_setup_tx
//
// This sequence is used to provide the result setup fields like i_tx_done
//
 // this also used by apply_reversal_entry_tx and reversal_result_exit_tx to set the i_tx_done field, so that the tx_fsm can move to the next state.
//------------------------------------------------------------------------------

import shared_ltsm_pkg::*;

class ltsm_result_setup_tx extends uvm_sequence #(LTSM_controllers_seq_item);

  `uvm_object_utils(ltsm_result_setup_tx)

  function new(string name = "ltsm_result_setup_tx");
    super.new(name);
  endfunction

  virtual task body();
    LTSM_controllers_seq_item tr;
    tr = LTSM_controllers_seq_item::type_id::create("tr");
    start_item(tr);
        tr.i_tx_done = 1;
        tr.i_rx_done = 1;
    finish_item(tr);

  

  endtask

endclass
