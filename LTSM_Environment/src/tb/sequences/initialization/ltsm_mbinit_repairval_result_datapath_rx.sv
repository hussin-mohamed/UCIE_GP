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

// CLASS: ltsm_mbinit_repairval_result_datapath_rx
//
// This sequence is used to handle MBINIT repair value result datapath reception.
// Parametrized with val_result_t type.
//
//------------------------------------------------------------------------------

import shared_ltsm_pkg::*;

class ltsm_mbinit_repairval_result_datapath_rx#(parameter val_result_t val_result = PASS_VAL) extends uvm_sequence #(LTSM_controllers_seq_item);

  `uvm_object_param_utils(ltsm_mbinit_repairval_result_datapath_rx)


  function new(string name = "ltsm_mbinit_repairval_result_datapath_rx", val_result_t val_result_i = PASS_VAL);
    super.new(name);
  endfunction

  virtual task body();
    LTSM_controllers_seq_item tr;
    tr = LTSM_controllers_seq_item::type_id::create("tr");
    start_item(tr);
        tr.i_rx_valid_results = val_result;
    finish_item(tr);
  endtask

endclass
