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

// CLASS: ltsm_enter_reset
//
// This sequence is used to handle entering reset state.
//
//------------------------------------------------------------------------------

import ltsm_shared_pkg::*;

class ltsm_enter_reset extends uvm_sequence #(LTSM_controllers_seq_item);

  `uvm_object_utils(ltsm_enter_reset)

  function new(string name = "ltsm_enter_reset");
    super.new(name);
  endfunction

  virtual task body();
    LTSM_controllers_seq_item tr;
    tr = LTSM_controllers_seq_item::type_id::create("tr");
    start_item(tr);
        tr.i_reset = 1'b1;
    finish_item(tr);
  endtask

endclass