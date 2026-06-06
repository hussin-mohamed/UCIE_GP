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

// CLASS: ltsm_mbinit_repairmb_fail_v_sequence
//
// This virtual sequence starts the MBINIT repairmb start handshakes in parallel,
// then continues with the prescribed tx/rx flow.
//
//------------------------------------------------------------------------------

import shared_ltsm_pkg::*;

class ltsm_mbinit_repairmb_fail_v_sequence extends virtual_sequence_base;
  

  `uvm_object_utils(ltsm_mbinit_repairmb_fail_v_sequence)

  function new(string name = "ltsm_mbinit_repairmb_fail_v_sequence");
    super.new(name);
  endfunction

  virtual task body();
    ltsm_mbinit_repairmb_start_handshake_tx start_tx;
    ltsm_mbinit_repairmb_start_handshake_rx start_rx;
    ltsm_mbinit_repairmb_data2clk_entry_tx data2clk_entry_tx;
    ltsm_data2clk_result_hs_tx data2clk_res_hs_tx;
    ltsm_result_setup_tx result_setup_tx;
    ltsm_data2clk_result_exit_tx #(NO_LANES_FUNCTIONAL) result_exit_tx;
    ltsm_mbinit_repairmb_degrade_setup_tx degrade_setup_tx;
    ltsm_mbinit_repairmb_degrade_exit_tx #(NO_LANES_FUNCTIONAL) degrade_exit_tx;
    ltsm_mbinit_repairmb_data2clk_entry_rx data2clk_entry_rx;
    ltsm_data2clk_result_hs_rx data2clk_res_hs_rx;
    ltsm_result_setup_rx result_setup_rx;
    ltsm_data2clk_result_hs_rx2 data2clk_res_hs_rx2;
    ltsm_data2clk_result_exit_rx result_exit_rx;
    ltsm_data2clk_result_datapath_rx #(ALL_LANES_FUNCTIONAL) datapath_rx;
    ltsm_mbinit_repairmb_degrage_checking_rx #(NOT_POSSIBLE) degrade_checking_rx;
    ltsm_mbinit_repairmb_done_handshake_rx done_hs_rx;

    ltsm_data2clk_lfsr_clear_hs_tx data2clk_lfsr_clear_hs_tx;
    ltsm_data2clk_lfsr_clear_hs_rx data2clk_lfsr_clear_hs_rx;

    ltsm_data2clk_pattern_gen_tx data2clk_pattern_gen_tx;
    ltsm_data2clk_pattern_detection_rx  data2clk_pattern_detection_rx;

    ltsm_mbinit_repairmb_exit_rx exit_rx;
    ltsm_mbinit_repairmb_exit_tx exit_tx;

    super.body();
    // Start handshakes on TX and RX in parallel
    fork
      begin
        start_tx = ltsm_mbinit_repairmb_start_handshake_tx::type_id::create("start_tx");
        start_tx.start(tx_fsm_sb_seqr);
      end
      begin
        start_rx = ltsm_mbinit_repairmb_start_handshake_rx::type_id::create("start_rx");
        start_rx.start(rx_fsm_sb_seqr);
      end
    join

    // tx fsm process
        // 1. enter the data2clk sequence 
        // 2. data2clk result_hs sequence and result_setpup sequence in parallel
        // 3. result_exit with all_lane_functional paramter 
        // 4. degrade setup 
        // 5. degrade exit with all_lane_functional parameter
    
    // rx fsm process
        // 1. enter the data2clk sequence 
        // 2. data2clk result_hs sequence and result_setpup sequence in parallel
        // 3. data2clk result_hs sequence 
        // 4. result_exit sequence and datapath with all_lane_functional parameter in parallel 
        // 5. degrade checking sequence with matched parmeter 
        // done handshake sequenec

  fork
    begin
      process p1;
      p1 = process::self();
    fork
      begin
        // TX process
        
        data2clk_entry_tx = ltsm_mbinit_repairmb_data2clk_entry_tx::type_id::create("data2clk_entry_tx");
        data2clk_entry_tx.start(tx_fsm_sb_seqr);

        // lfsr_clear_hs_tx

        data2clk_lfsr_clear_hs_tx = ltsm_data2clk_lfsr_clear_hs_tx::type_id::create("data2clk_lfsr_clear_hs_tx");
        data2clk_lfsr_clear_hs_tx.start(tx_fsm_sb_seqr);

        // pattern_gen_tx sequence

        data2clk_pattern_gen_tx = ltsm_data2clk_pattern_gen_tx::type_id::create("data2clk_pattern_gen_tx");
        data2clk_pattern_gen_tx.start(tx_fsm_sb_seqr);

        fork
          begin
            data2clk_res_hs_tx = ltsm_data2clk_result_hs_tx::type_id::create("data2clk_res_hs_tx");
            data2clk_res_hs_tx.start(tx_fsm_sb_seqr);
          end
          begin
            result_setup_tx = ltsm_result_setup_tx::type_id::create("result_setup_tx");
            result_setup_tx.start(LTSM_ctrl_seqr);
          end
        join

        result_exit_tx = ltsm_data2clk_result_exit_tx#(NO_LANES_FUNCTIONAL)::type_id::create("result_exit_tx");
        result_exit_tx.start(tx_fsm_sb_seqr);


        degrade_setup_tx = ltsm_mbinit_repairmb_degrade_setup_tx::type_id::create("degrade_setup_tx");
        degrade_setup_tx.start(tx_fsm_sb_seqr);

        p1.kill();

        degrade_exit_tx = ltsm_mbinit_repairmb_degrade_exit_tx#(NO_LANES_FUNCTIONAL)::type_id::create("degrade_exit_tx");
        degrade_exit_tx.start(tx_fsm_sb_seqr);
        
       
        

        // exit tx
        exit_tx = ltsm_mbinit_repairmb_exit_tx::type_id::create("exit_tx");
        exit_tx.start(tx_fsm_sb_seqr);
      end

      begin
        // RX process
        data2clk_entry_rx = ltsm_mbinit_repairmb_data2clk_entry_rx::type_id::create("data2clk_entry_rx");
        data2clk_entry_rx.start(rx_fsm_sb_seqr);

        // lfsr_clear_hs_rx
        data2clk_lfsr_clear_hs_rx = ltsm_data2clk_lfsr_clear_hs_rx::type_id::create("data2clk_lfsr_clear_hs_rx");
        data2clk_lfsr_clear_hs_rx.start(rx_fsm_sb_seqr);

        //pattern_detection_rx sequence 
        data2clk_pattern_detection_rx = ltsm_data2clk_pattern_detection_rx::type_id::create("data2clk_pattern_detection_rx");
        data2clk_pattern_detection_rx.start(rx_fsm_sb_seqr);

        fork
          begin
            data2clk_res_hs_rx = ltsm_data2clk_result_hs_rx::type_id::create("data2clk_res_hs_rx");
            data2clk_res_hs_rx.start(rx_fsm_sb_seqr);
          end
          begin
            result_setup_rx = ltsm_result_setup_rx::type_id::create("result_setup_rx");
            result_setup_rx.start(LTSM_ctrl_seqr);
          end
        join

      
        data2clk_res_hs_rx2 = ltsm_data2clk_result_hs_rx2::type_id::create("data2clk_res_hs_rx2");
        data2clk_res_hs_rx2.start(rx_fsm_sb_seqr);
      
        fork
          begin
            result_exit_rx = ltsm_data2clk_result_exit_rx::type_id::create("result_exit_rx");
            result_exit_rx.start(rx_fsm_sb_seqr);
          end
          begin
            datapath_rx = ltsm_data2clk_result_datapath_rx#(ALL_LANES_FUNCTIONAL)::type_id::create("datapath_rx");
            datapath_rx.start(LTSM_ctrl_seqr);
          end
        join

        degrade_checking_rx = ltsm_mbinit_repairmb_degrage_checking_rx#(NOT_POSSIBLE)::type_id::create("degrade_checking_rx");
        degrade_checking_rx.start(rx_fsm_sb_seqr);
        

        done_hs_rx = ltsm_mbinit_repairmb_done_handshake_rx::type_id::create("done_hs_rx");
        done_hs_rx.start(rx_fsm_sb_seqr);

        exit_rx = ltsm_mbinit_repairmb_exit_rx::type_id::create("exit_rx");
        exit_rx.start(rx_fsm_sb_seqr);
      end
    join

    end
  join
endtask

endclass