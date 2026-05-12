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

// CLASS: ltsm_mbinit_repairval_fail_v_sequence
//
// This virtual sequence follows MBINIT repairval flow in parallel TX/RX, then done hs.
//
//------------------------------------------------------------------------------

import shared_ltsm_pkg::*;

class ltsm_mbinit_repairval_fail_v_sequence extends virtual_sequence_base;
  process p1;
  `uvm_object_utils(ltsm_mbinit_repairval_fail_v_sequence)

  function new(string name = "ltsm_mbinit_repairval_fail_v_sequence");
    super.new(name);
  endfunction

  virtual task body();
    ltsm_mbinit_repairval_start_handshake_tx start_tx;
    ltsm_mbinit_repairval_start_handshake_rx start_rx;
    ltsm_result_setup_tx setup_tx;
    ltsm_mbinit_repairval_result_hs_tx res_hs_tx;
    ltsm_mbinit_repairval_result_exit_tx #(FAIL_VAL) res_exit_tx;
    ltsm_result_setup_rx setup_rx;
    ltsm_mbinit_repairval_result_hs_rx res_hs_rx;
    ltsm_mbinit_repairval_result_datapath_rx #(PASS_VAL) data_path_rx;
    ltsm_mbinit_repairval_result_exit_rx res_exit_rx;
    ltsm_mbinit_repairval_done_handshake_rx done_rx;

    ltsm_mbinit_repairval_init_hs_tx init_hs_tx;
    ltsm_mbinit_repairval_init_hs_rx init_hs_rx;

    super.body();
    // start handshakes on both sides in parallel
    fork
      begin
        start_tx = ltsm_mbinit_repairval_start_handshake_tx::type_id::create("start_tx");
        start_tx.start(tx_fsm_sb_seqr);
      end

      begin
        start_rx = ltsm_mbinit_repairval_start_handshake_rx::type_id::create("start_rx");
        start_rx.start(rx_fsm_sb_seqr);
      end
    join

    // tx fsm process
    fork
      begin
        init_hs_tx = ltsm_mbinit_repairval_init_hs_tx::type_id::create("init_hs_tx");
        init_hs_tx.start(tx_fsm_sb_seqr);
        // ltsm_result_setup_tx + result_hs in parallel
        fork
          begin
            setup_tx = ltsm_result_setup_tx::type_id::create("setup_tx");
            setup_tx.start(LTSM_ctrl_seqr);
          end
          begin
            res_hs_tx = ltsm_mbinit_repairval_result_hs_tx::type_id::create("res_hs_tx");
            res_hs_tx.start(tx_fsm_sb_seqr);
          end
        join

        // result exit
        res_exit_tx = ltsm_mbinit_repairval_result_exit_tx#(FAIL_VAL)::type_id::create("res_exit_tx");
        res_exit_tx.start(tx_fsm_sb_seqr);
        p1.kill();
      end

      begin
        // rx fsm process
        p1 = process::self();
        init_hs_rx = ltsm_mbinit_repairval_init_hs_rx::type_id::create("init_hs_rx");
        init_hs_rx.start(rx_fsm_sb_seqr);
        fork
          begin
            setup_rx = ltsm_result_setup_rx::type_id::create("setup_rx");
            setup_rx.start(LTSM_ctrl_seqr);
          end
          begin
            res_hs_rx = ltsm_mbinit_repairval_result_hs_rx::type_id::create("res_hs_rx");
            res_hs_rx.start(rx_fsm_sb_seqr);
          end
        join

        fork
          begin
            data_path_rx = ltsm_mbinit_repairval_result_datapath_rx#(PASS_VAL)::type_id::create("data_path_rx");
            data_path_rx.start(LTSM_ctrl_seqr);
          end
          begin
            res_exit_rx = ltsm_mbinit_repairval_result_exit_rx::type_id::create("res_exit_rx");
            res_exit_rx.start(rx_fsm_sb_seqr);
          end
        join

        done_rx = ltsm_mbinit_repairval_done_handshake_rx::type_id::create("done_rx");
        done_rx.start(rx_fsm_sb_seqr);
      end
    join
  endtask

endclass