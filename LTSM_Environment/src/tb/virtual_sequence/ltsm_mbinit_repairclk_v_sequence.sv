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

// CLASS: ltsm_mbinit_repairclk_v_sequence
//
// This virtual sequence follows MBINIT repairclk flow based on notes:
// 1) start handshake (TX/RX)
// 2) result setup + result handshake
// 3) result exit and (RX) data path and done handshake
//
//------------------------------------------------------------------------------

import ltsm_shared_pkg::*;

class ltsm_mbinit_repairclk_v_sequence extends virtual_sequence_base;

  `uvm_object_utils(ltsm_mbinit_repairclk_v_sequence)

  function new(string name = "ltsm_mbinit_repairclk_v_sequence");
    super.new(name);
  endfunction

  virtual task body();
    super.body();
    // Start handshake on both sides in parallel
    fork
      begin
        ltsm_mbinit_repairclk_start_handshake_tx start_tx = ltsm_mbinit_repairclk_start_handshake_tx::type_id::create("start_tx");
        start_tx.start(tx_fsm_sb_seqr);
      end

      begin
        ltsm_mbinit_repairclk_start_handshake_rx start_rx = ltsm_mbinit_repairclk_start_handshake_rx::type_id::create("start_rx");
        start_rx.start(rx_fsm_sb_seqr);
      end
    join

    // tx fsm process
        // start  the ltsm_result_setup_tx in parallel with result_hs 
        // start the result exit sequence with PASS parameter 

    //rx fsm process
        // start the ltsm_result_setup_rx in parallel with result_hs
        // start the ltsm_data_path with PASS parameter in parallel with result_exit sequence 
        // start the done handshake sequence 

    fork
      begin
        // TX process
        fork
          begin
            ltsm_result_setup_tx setup_tx = ltsm_result_setup_tx::type_id::create("setup_tx");
            setup_tx.start(LTSM_ctrl_seqr);
          end
          begin
            ltsm_mbinit_repairclk_res_hs_tx res_hs_tx = ltsm_mbinit_repairclk_res_hs_tx::type_id::create("res_hs_tx");
            res_hs_tx.start(tx_fsm_sb_seqr);
          end
        join
        ltsm_mbinit_repairclk_result_exit_tx #(PASS) res_exit_tx = ltsm_mbinit_repairclk_result_exit_tx#(PASS)::type_id::create("res_exit_tx");
        res_exit_tx.start(tx_fsm_sb_seqr);
      end

      begin
        // RX process
        fork
          begin
            ltsm_result_setup_rx setup_rx = ltsm_result_setup_rx::type_id::create("setup_rx");
            setup_rx.start(LTSM_ctrl_seqr);
          end
          begin
            ltsm_mbinit_repairclk_res_hs_rx res_hs_rx = ltsm_mbinit_repairclk_res_hs_rx::type_id::create("res_hs_rx");
            res_hs_rx.start(rx_fsm_sb_seqr);
          end
        join
        fork
          begin
            ltsm_mbinit_repairclk_res_data_path_rx #(PASS) data_path_rx = ltsm_mbinit_repairclk_res_data_path_rx#(PASS)::type_id::create("data_path_rx");
            data_path_rx.start(LTSM_ctrl_seqr);
          end
          begin
            ltsm_mbinit_repairclk_result_exit_rx res_exit_rx = ltsm_mbinit_repairclk_result_exit_rx::type_id::create("res_exit_rx");
            res_exit_rx.start(rx_fsm_sb_seqr);
          end
        join
        ltsm_mbinit_repairclk_done_handshake_rx done_rx = ltsm_mbinit_repairclk_done_handshake_rx::type_id::create("done_rx");
        done_rx.start(rx_fsm_sb_seqr);
      end
    join 


   
  endtask

endclass