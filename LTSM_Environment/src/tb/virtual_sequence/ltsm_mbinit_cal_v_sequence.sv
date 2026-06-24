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

// CLASS: ltsm_mbinit_cal_v_sequence
//
// This virtual sequence starts mbinit_cal TX and RX in parallel over their
// respective sequencers.
//
//------------------------------------------------------------------------------

import ltsm_shared_pkg::*;

class ltsm_mbinit_cal_v_sequence extends virtual_sequence_base;

  `uvm_object_utils(ltsm_mbinit_cal_v_sequence)

  function new(string name = "ltsm_mbinit_cal_v_sequence");
    super.new(name);
  endfunction

  virtual task body();
    super.body();
    fork
      begin
        ltsm_mbinit_cal_tx cal_tx = ltsm_mbinit_cal_tx::type_id::create("cal_tx");
        cal_tx.start(tx_fsm_sb_seqr);
      end

      begin
        ltsm_mbinit_cal_rx cal_rx = ltsm_mbinit_cal_rx::type_id::create("cal_rx");
        cal_rx.start(rx_fsm_sb_seqr);
      end
    join
  endtask

endclass