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

// CLASS: ltsm_mbinit_reversal_result_data_path_rx
//
// This sequence is used to handle MBINIT reversal result datapath reception.
//
//------------------------------------------------------------------------------

import ltsm_shared_pkg::*;

class ltsm_mbinit_reversal_result_data_path_rx#(string REVERSAL_PASS = "pass") extends uvm_sequence #(LTSM_controllers_seq_item);

  `uvm_object_param_utils(ltsm_mbinit_reversal_result_data_path_rx)

  function new(string name = "ltsm_mbinit_reversal_result_data_path_rx");
    super.new(name);
  endfunction

  virtual task body();
    LTSM_controllers_seq_item tr;
    tr = LTSM_controllers_seq_item::type_id::create("tr");
    start_item(tr);
        case (REVERSAL_PASS)
            "pass": tr.i_rx_data_results[15:0] = `RESULT_THRESHOLD +1;
            "fail": tr.i_rx_data_results[15:0] = `RESULT_THRESHOLD -1; 
        endcase
    finish_item(tr);
  endtask

endclass
