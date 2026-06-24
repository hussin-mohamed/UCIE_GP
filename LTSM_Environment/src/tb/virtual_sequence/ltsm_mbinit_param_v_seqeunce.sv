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

// CLASS: ltsm_mbinit_param_v_seqeunce
//
// This virtual sequence starts the MBINIT param TX and RX sequences in parallel,
// then starts the param done handshake RX sequence.
//
//------------------------------------------------------------------------------

import ltsm_shared_pkg::*;

class ltsm_mbinit_param_v_seqeunce extends virtual_sequence_base;

  `uvm_object_utils(ltsm_mbinit_param_v_seqeunce)

  function new(string name = "ltsm_mbinit_param_v_seqeunce");
    super.new(name);
  endfunction

  virtual task body();
    super.body();
    fork
      begin
        ltsm_mbinit_param_tx param_tx = ltsm_mbinit_param_tx::type_id::create("param_tx");
        param_tx.start(tx_fsm_sb_seqr);
      end

      begin
        ltsm_mbinit_param_rx param_rx = ltsm_mbinit_param_rx::type_id::create("param_rx");
        param_rx.start(rx_fsm_sb_seqr);
      end
    join

    ltsm_mbinit_param_done_handshake_rx done_rx = ltsm_mbinit_param_done_handshake_rx::type_id::create("done_rx");
    done_rx.start(rx_fsm_sb_seqr);
  endtask

endclass