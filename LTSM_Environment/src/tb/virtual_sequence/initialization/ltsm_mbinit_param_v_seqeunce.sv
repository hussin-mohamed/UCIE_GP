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

import shared_ltsm_pkg::*;

class ltsm_mbinit_param_v_seqeunce extends virtual_sequence_base;

  `uvm_object_utils(ltsm_mbinit_param_v_seqeunce)

  function new(string name = "ltsm_mbinit_param_v_seqeunce");
    super.new(name);
  endfunction

  virtual task body();
    ltsm_mbinit_param_tx param_tx;
    ltsm_mbinit_param_rx param_rx;
    ltsm_mbinit_param_done_handshake_rx done_rx;
    ltsm_mbinit_param_check_rx param_check_rx;
    ltsm_sb_tx_done_resp sb_tx_done_resp;
    ltsm_sb_rx_done_resp sb_rx_done_resp;

    super.body();
    fork
      begin
        param_tx = ltsm_mbinit_param_tx::type_id::create("param_tx");
        param_tx.start(tx_fsm_sb_seqr);

        // send i_sb_tx_done after sending the req
        sb_tx_done_resp = ltsm_sb_tx_done_resp::type_id::create("sb_tx_done_resp");
        sb_tx_done_resp.start(tx_fsm_sb_seqr);
        

      end

      begin
        param_rx = ltsm_mbinit_param_rx::type_id::create("param_rx");
        param_rx.start(rx_fsm_sb_seqr);

        // send i_sb_rx_done after receiving the req
        sb_rx_done_resp = ltsm_sb_rx_done_resp::type_id::create("sb_rx_done_resp");
        sb_rx_done_resp.start(rx_fsm_sb_seqr);

        done_rx = ltsm_mbinit_param_done_handshake_rx::type_id::create("done_rx");
        done_rx.start(rx_fsm_sb_seqr);

        // send i_sb_rx_done after receiving the req
        sb_rx_done_resp = ltsm_sb_rx_done_resp::type_id::create("sb_rx_done_resp");
        sb_rx_done_resp.start(rx_fsm_sb_seqr);

        /*param_check_rx = ltsm_mbinit_param_check_rx::type_id::create("param_check_rx");
        param_check_rx.start(rx_fsm_sb_seqr);*/
      end
    join

  endtask

endclass