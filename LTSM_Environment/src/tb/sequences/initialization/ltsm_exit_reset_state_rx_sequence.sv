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

// CLASS: ltsm_exit_reset_state_rx_sequence
//
// this sequences is used to exit reset state in rx_fsm, by providing the needes condition to proceed the next state.
//
//------------------------------------------------------------------------------

import shared_ltsm_pkg::*;

class ltsm_exit_reset_state_rx_sequence extends uvm_sequence #(LTSM_controllers_seq_item);

  `uvm_object_utils(ltsm_exit_reset_state_rx_sequence)

  function new(string name = "ltsm_exit_reset_state_rx_sequence");
    super.new(name);
  endfunction

  virtual task body();
    LTSM_controllers_seq_item tr;
    tr = LTSM_controllers_seq_item::type_id::create("tr");
    start_item(tr);
        tr.i_supply_stable = 1;
        tr.i_pll_stable = 1;
        tr.i_reset = 0;
    finish_item(tr);
  endtask

endclass