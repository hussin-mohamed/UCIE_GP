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

// CLASS: ltsm_mbinit_reversalmb_v_sequence
//
// This virtual sequence follows MBINIT reversal flow in parallel TX/RX, then done hs.
//
//------------------------------------------------------------------------------

import shared_ltsm_pkg::*;

class ltsm_mbinit_reversalmb_v_sequence extends virtual_sequence_base;

  `uvm_object_utils(ltsm_mbinit_reversalmb_v_sequence)

  function new(string name = "ltsm_mbinit_reversalmb_v_sequence");
    super.new(name);
  endfunction

  virtual task body();
    ltsm_mbinit_reversal_starthandshake_tx start_tx;
    ltsm_mbinit_reversal_starthandshake_rx start_rx;
    ltsm_result_setup_tx setup_tx;
    ltsm_mbinit_reversal_result_hs_tx res_hs_tx;
    ltsm_mbinit_reversal_result_exit_tx res_exit_tx;
    ltsm_result_setup_rx setup_rx;
    ltsm_mbinit_reversal_result_hs_rx res_hs_rx;
    ltsm_mbinit_reversal_result_data_path_rx data_path_rx;
    ltsm_mbinit_reversal_result_exit_rx res_exit_rx;
    ltsm_mbinit_reversal_done_handshake_rx done_rx;

    ltsm_mbinit_reversal_init_hs_rx init_hs_rx;
    ltsm_mbinit_reversal_init_hs_tx init_hs_tx;

    ltsm_mbinit_reversal_clearlog_hs_tx clear_log_hs_tx;

    ltsm_mbinit_reversal_clearlog_hs_rx clear_log_hs_rx;
    ltsm_sb_tx_done_resp sb_tx_done_resp;

    ltsm_sb_rx_done_resp sb_rx_done_resp;
    

    super.body();
    // start handshakes on both sides in parallel
    fork
      begin
        start_tx = ltsm_mbinit_reversal_starthandshake_tx::type_id::create("start_tx");
        start_tx.start(tx_fsm_sb_seqr);

        sb_tx_done_resp = ltsm_sb_tx_done_resp::type_id::create("sb_tx_done_resp");
        sb_tx_done_resp.start(tx_fsm_sb_seqr);
      end

      begin
        start_rx = ltsm_mbinit_reversal_starthandshake_rx::type_id::create("start_rx");
        start_rx.start(rx_fsm_sb_seqr);

        sb_rx_done_resp = ltsm_sb_rx_done_resp::type_id::create("sb_rx_done_resp");
        sb_rx_done_resp.start(rx_fsm_sb_seqr);
      end
    join

    // tx fsm process
    fork
      begin
        // ltsm_result_setup_tx + result_hs in parallel
        init_hs_tx = ltsm_mbinit_reversal_init_hs_tx::type_id::create("init_hs_tx");
        init_hs_tx.start(tx_fsm_sb_seqr);

        sb_tx_done_resp = ltsm_sb_tx_done_resp::type_id::create("sb_tx_done_resp");
        sb_tx_done_resp.start(tx_fsm_sb_seqr);

        clear_log_hs_tx = ltsm_mbinit_reversal_clearlog_hs_tx::type_id::create("clear_log_hs_tx"); 
        clear_log_hs_tx.start(tx_fsm_sb_seqr);
        fork
          begin
            setup_tx = ltsm_result_setup_tx::type_id::create("setup_tx");
            setup_tx.start(LTSM_ctrl_seqr);
          end
          begin
            res_hs_tx = ltsm_mbinit_reversal_result_hs_tx::type_id::create("res_hs_tx");
            res_hs_tx.start(tx_fsm_sb_seqr);
          end
        join

        sb_tx_done_resp = ltsm_sb_tx_done_resp::type_id::create("sb_tx_done_resp");
        sb_tx_done_resp.start(tx_fsm_sb_seqr);

        // result exit
        res_exit_tx = ltsm_mbinit_reversal_result_exit_tx#("pass")::type_id::create("res_exit_tx");
        res_exit_tx.start(tx_fsm_sb_seqr);

        sb_tx_done_resp = ltsm_sb_tx_done_resp::type_id::create("sb_tx_done_resp");
        sb_tx_done_resp.start(tx_fsm_sb_seqr);

      end

      begin
        // rx fsm process
        init_hs_rx = ltsm_mbinit_reversal_init_hs_rx::type_id::create("init_hs_rx");
        init_hs_rx.start(rx_fsm_sb_seqr);

        sb_rx_done_resp = ltsm_sb_rx_done_resp::type_id::create("sb_rx_done_resp");
        sb_rx_done_resp.start(rx_fsm_sb_seqr);

        clear_log_hs_rx = ltsm_mbinit_reversal_clearlog_hs_rx::type_id::create("clear_log_hs_rx"); 
        clear_log_hs_rx.start(rx_fsm_sb_seqr);



        fork
          begin
            setup_rx = ltsm_result_setup_rx::type_id::create("setup_rx");
            setup_rx.start(LTSM_ctrl_seqr);
          end
          begin
            res_hs_rx = ltsm_mbinit_reversal_result_hs_rx::type_id::create("res_hs_rx");
            res_hs_rx.start(rx_fsm_sb_seqr);
          end
        join

        fork
          begin
            data_path_rx = ltsm_mbinit_reversal_result_data_path_rx#("pass")::type_id::create("data_path_rx");
            data_path_rx.start(LTSM_ctrl_seqr);
          end
          begin
            res_exit_rx = ltsm_mbinit_reversal_result_exit_rx::type_id::create("res_exit_rx");
            res_exit_rx.start(rx_fsm_sb_seqr);
          end
        join

        fork
          begin
            data_path_rx = ltsm_mbinit_reversal_result_data_path_rx#("pass")::type_id::create("data_path_rx");
            data_path_rx.start(LTSM_ctrl_seqr);
          end
          
          begin
            done_rx = ltsm_mbinit_reversal_done_handshake_rx::type_id::create("done_rx");
            done_rx.start(rx_fsm_sb_seqr);
          end
        join

        sb_rx_done_resp = ltsm_sb_rx_done_resp::type_id::create("sb_rx_done_resp");
        sb_rx_done_resp.start(rx_fsm_sb_seqr);

        
      end
    join
  endtask

endclass