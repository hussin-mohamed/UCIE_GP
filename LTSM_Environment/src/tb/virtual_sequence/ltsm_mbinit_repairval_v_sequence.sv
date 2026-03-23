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

// CLASS: ltsm_mbinit_repairval_v_sequence
//
// This virtual sequence follows MBINIT repairval flow in parallel TX/RX, then done hs.
//
//------------------------------------------------------------------------------

import ltsm_shared_pkg::*;

class ltsm_mbinit_repairval_v_sequence extends virtual_sequence_base;

  `uvm_object_utils(ltsm_mbinit_repairval_v_sequence)

  function new(string name = "ltsm_mbinit_repairval_v_sequence");
    super.new(name);
  endfunction

  virtual task body();
    super.body();
    // start handshakes on both sides in parallel
    fork
      begin
        ltsm_mbinit_repairval_start_handshake_tx start_tx = ltsm_mbinit_repairval_start_handshake_tx::type_id::create("start_tx");
        start_tx.start(tx_fsm_sb_seqr);
      end

      begin
        ltsm_mbinit_repairval_start_handshake_rx start_rx = ltsm_mbinit_repairval_start_handshake_rx::type_id::create("start_rx");
        start_rx.start(rx_fsm_sb_seqr);
      end
    join

    // tx fsm process
    fork
      begin
        // ltsm_result_setup_tx + result_hs in parallel
        fork
          begin
            ltsm_result_setup_tx setup_tx = ltsm_result_setup_tx::type_id::create("setup_tx");
            setup_tx.start(LTSM_ctrl_seqr);
          end
          begin
            ltsm_mbinit_repairval_res_hs_tx res_hs_tx = ltsm_mbinit_repairval_res_hs_tx::type_id::create("res_hs_tx");
            res_hs_tx.start(tx_fsm_sb_seqr);
          end
        join

        // result exit
        ltsm_mbinit_repairval_result_exit_tx #(PASS_VAL) res_exit_tx = ltsm_mbinit_repairval_result_exit_tx#(PASS_VAL)::type_id::create("res_exit_tx");
        res_exit_tx.start(tx_fsm_sb_seqr);
      end

      begin
        // rx fsm process
        fork
          begin
            ltsm_result_setup_rx setup_rx = ltsm_result_setup_rx::type_id::create("setup_rx");
            setup_rx.start(LTSM_ctrl_seqr);
          end
          begin
            ltsm_mbinit_repairval_res_hs_rx res_hs_rx = ltsm_mbinit_repairval_res_hs_rx::type_id::create("res_hs_rx");
            res_hs_rx.start(rx_fsm_sb_seqr);
          end
        join

        fork
          begin
            ltsm_mbinit_repairval_result_data_path_rx #(PASS_VAL) data_path_rx = ltsm_mbinit_repairval_result_data_path_rx#(PASS_VAL)::type_id::create("data_path_rx");
            data_path_rx.start(LTSM_ctrl_seqr);
          end
          begin
            ltsm_mbinit_repairval_result_exit_rx res_exit_rx = ltsm_mbinit_repairval_result_exit_rx::type_id::create("res_exit_rx");
            res_exit_rx.start(rx_fsm_sb_seqr);
          end
        join

        ltsm_mbinit_repairval_done_handshake_rx done_rx = ltsm_mbinit_repairval_done_handshake_rx::type_id::create("done_rx");
        done_rx.start(rx_fsm_sb_seqr);
      end
    join
  endtask

endclass