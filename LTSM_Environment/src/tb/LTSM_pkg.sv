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


package LTSM_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
  typedef class State ;
  typedef class ResetState_rx;
  typedef class SbInitState_rx;
  typedef class MbInitParamState_rx;
  typedef class MbInitCalState_rx;
  typedef class MbInitRepairClkState_rx;
  typedef class MbInitRepairValState_rx;
  typedef class MbInitReversalMbState_rx;
  typedef class MbInitRepairMbState_rx;
  typedef class mbtrain_rx_valvref;
  typedef class mbtrain_rx_datavref;
  typedef class mbtrain_rx_speedidle;
  typedef class mbtrain_rx_txselfcal;
  typedef class mbtrain_rx_rxclkcal;
  typedef class mbtrain_rx_valtraincenter;
  typedef class mbtrain_rx_valtrainvref;
  typedef class mbtrain_rx_dtc1;
  typedef class mbtrain_rx_datatrainvref;
  typedef class mbtrain_rx_rxdeskew;
  typedef class mbtrain_rx_dtc2;
  typedef class mbtrain_rx_linkspeed;
  typedef class mbtrain_rx_repair;
  typedef class phyretrain_rx;
  typedef class linkinit_state_rx;
  typedef class active_state_rx;
  typedef class l1_state_rx;
  typedef class trainerror_rx;
  typedef class ResetState_tx;
  typedef class SbInitState_tx;
  typedef class MbInitParamState_tx;
  typedef class MbInitCalState_tx;
  typedef class MbInitRepairClkState_tx;
  typedef class MbInitRepairValState_tx;
  typedef class MbInitReversalMbState_tx;
  typedef class MbInitRepairMbState_tx;
  typedef class mbtrain_tx_valvref;
  typedef class mbtrain_tx_datavref;
  typedef class mbtrain_tx_speedidle;
  typedef class mbtrain_tx_txselfcal;
  typedef class mbtrain_tx_rxclkcal;
  typedef class mbtrain_tx_valtraincenter;
  typedef class mbtrain_tx_valtrainvref;
  typedef class mbtrain_tx_dtc1;
  typedef class mbtrain_tx_datatrainvref;
  typedef class mbtrain_tx_rxdeskew;
  typedef class mbtrain_tx_dtc2;
  typedef class mbtrain_tx_linkspeed;
  typedef class mbtrain_tx_repair;
  typedef class phyretrain_tx;
  typedef class linkinit_state_tx;
  typedef class active_state_tx;
  typedef class l1_state_tx;
  typedef class trainerror_tx;
  typedef class StateTransitionUtil_rx;
  typedef class StateTransitionUtil_tx;
  

    // Sequence Items
    `include "sequence_items/LTSM_controllers_sequence_item.sv"
    `include "sequence_items/ltsm_rdi_sequence_item.sv"
    `include "sequence_items/rx_fsm_sb_sequence_item.svh"
    `include "sequence_items/tx_fsm_sb_sequence_item.svh"
    
    // Sequencers
    `include "sequencers/LTSM_controllers_sqr.sv"
    `include "sequencers/ltsm_rdi_sequencer.sv"
    `include "sequencers/rx_fsm_sb_sequencer.svh"
    `include "sequencers/tx_fsm_sb_sequencer.svh"
    `include "virtual_sequencer.svh"
    
    // Configuration Objects
    `include "env_config.svh"
    `include "agents/agent_config.svh"
    `include "agents/controller_agent_config.sv"
    `include "agents/rdi_agent_config.sv"

    // Monitors
    `include "monitors/LTSM_monitor_base.svh"
    `include "monitors/LTSM_controllers_monitor.sv"
    `include "monitors/ltsm_rdi_monitor.svh"
    `include "monitors/rx_fsm_sb_monitor.svh"
    `include "monitors/tx_fsm_sb_monitor.svh"
    
    // Drivers
    `include "drivers/LTSM_driver_base.svh"
    `include "drivers/LTSM_controllers_driver.sv"
    `include "drivers/ltsm_rdi_driver.sv"
    `include "drivers/rx_fsm_sb_driver.svh"
    `include "drivers/tx_fsm_sb_driver.svh"
    
    // Agents 
    `include "agents/ltsm_rdi_agent.sv"
    `include "agents/rx_fsm_sb_agent.svh"
    `include "agents/tx_fsm_sb_agent.svh"
    `include "agents/TX_RX_controllers_agent.sv"
    
    // model
    `include "model/fsm_context.svh"
    `include "model/state.svh"
    `include "model/common/phyretrain_rx.sv"
    `include "model/common/phyretrain_tx.sv"
    `include "model/mbtrain/mbtrain_rx_valvref.svh"
    `include "model/mbtrain/mbtrain_rx_valtrainvref.svh"
    `include "model/mbtrain/mbtrain_rx_valtraincenter.svh"
    `include "model/mbtrain/mbtrain_rx_dtc2.svh"
    `include "model/mbtrain/mbtrain_rx_dtc1.svh"
    `include "model/mbtrain/mbtrain_rx_datavref.svh"
    `include "model/mbtrain/mbtrain_rx_datatrainvref.svh"
    `include "model/mbtrain/mbtrain_rx_rxclkcal.svh"
    `include "model/mbtrain/mbtrain_rx_repair.svh"
    `include "model/mbtrain/mbtrain_tx_repair.svh"
    `include "model/mbtrain/mbtrain_tx_linkspeed.svh"
    `include "model/mbtrain/mbtrain_rx_speedidle.svh"
    `include "model/mbtrain/mbtrain_tx_speedidle.svh"
    `include "model/mbtrain/mbtrain_tx_dtc2.svh"
    `include "model/mbtrain/mbtrain_rx_linkspeed.svh"
    `include "model/mbtrain/mbtrain_rx_txselfcal.svh"
    `include "model/mbtrain/mbtrain_tx_datatrainvref.svh"
    `include "model/mbtrain/mbtrain_tx_datavref.svh"
    `include "model/mbtrain/mbtrain_tx_dtc1.svh"
    `include "model/mbtrain/mbtrain_tx_rxclkcal.svh"
    `include "model/mbtrain/mbtrain_rx_rxdeskew.svh"
    `include "model/mbtrain/mbtrain_tx_valtraincenter.svh"
    `include "model/mbtrain/mbtrain_tx_valtrainvref.svh"
    `include "model/mbtrain/mbtrain_tx_valvref.svh"
    `include "model/mbtrain/mbtrain_tx_rxdeskew.svh"
    `include "model/mbtrain/mbtrain_tx_txselfcal.svh"
    `include "model/initialization/reset_state_rx.sv"
    `include "model/initialization/reset_state_tx.sv"
    `include "model/initialization/sbinit_state_rx.sv"
    `include "model/initialization/sbinit_state_tx.sv"
    `include "model/initialization/mbinit_repairmb_state_rx.sv"
    `include "model/initialization/mbinit_cal_state_rx.sv"
    `include "model/initialization/mbinit_cal_state_tx.sv"
    `include "model/initialization/mbinit_param_state_rx.sv"
    `include "model/initialization/mbinit_param_state_tx.sv"
    `include "model/initialization/mbinit_repairclk_state_rx.sv"
    `include "model/initialization/mbinit_repairclk_state_tx.sv"
    `include "model/initialization/mbinit_repairmb_state_tx.sv"
    `include "model/initialization/mbinit_repairval_state_rx.sv"
    `include "model/initialization/mbinit_repairval_state_tx.sv"
    `include "model/initialization/mbinit_reversalmb_state_rx.sv"
    `include "model/initialization/mbinit_reversalmb_state_tx.sv"
    `include "model/common/trainerror_rx.svh"
    `include "model/common/trainerror_tx.svh"
    `include "model/active/linkinit_tx.sv"
    `include "model/active/linkinit_rx.sv"
    `include "model/active/l1_rx.sv"
    `include "model/active/l1_tx.sv"
    `include "model/active/active_rx.svh"
    `include "model/active/active_tx.svh"
    `include "model/statetransition_rx.svh"
    `include "model/statetransition_tx.svh"

    // scoreboard
    `include "scoreboards/scoreboard.svh"

    // Environment
    `include "env.svh"
    // initialization base sequences
    `include "sequences/initialization/ltsm_data2clk_result_datapath_rx.sv"
    `include "sequences/initialization/ltsm_result_setup_rx.sv"
    `include "sequences/initialization/ltsm_result_setup_tx.sv"
    `include "sequences/initialization/ltsm_data2clk_result_exit_rx.sv"
    `include "sequences/initialization/ltsm_data2clk_result_exit_tx.sv"
    `include "sequences/initialization/ltsm_data2clk_result_hs_rx.sv"
    `include "sequences/initialization/ltsm_data2clk_result_hs_tx.sv"
    `include "sequences/initialization//ltsm_data2clk_lfsr_clear_hs_rx.sv"
    `include "sequences/initialization//ltsm_data2clk_lfsr_clear_hs_tx.sv"
    `include "sequences/initialization/ltsm_data2clk_result_hs_rx2.sv"
    `include "sequences/initialization/ltsm_data2clk_pattern_detection_rx.sv"
    `include "sequences/initialization/ltsm_data2clk_pattern_gen_tx.sv"
    `include "sequences/initialization/ltsm_enter_reset.sv"
    `include "sequences/initialization/ltsm_exit_reset_state_rx_sequence.sv"
    `include "sequences/initialization/ltsm_exit_reset_state_tx_sequence.sv"
    `include "sequences/initialization/ltsm_mbinit__repairmb_degrade_setup_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_apply_reversal_entery_tx.sv"
    `include "sequences/initialization/ltsm_mbinit_apply_reversal_exit_hs_tx.sv"
    `include "sequences/initialization/ltsm_mbinit_cal_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_cal_tx.sv"
    `include "sequences/initialization/ltsm_mbinit_param_done_handshake_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_param_check_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_param_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_param_tx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairclk_done_handshake_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairclk_res_data_path_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairclk_res_hs_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairclk_res_hs_tx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairclk_init_hs_tx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairclk_init_hs_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairclk_result_exit_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairclk_result_exit_tx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairclk_start_handshake_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairclk_start_handshake_tx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairmb_data2clk_entry_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairmb_data2clk_entry_tx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairmb_degrade_exit_tx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairmb_exit_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairmb_exit_tx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairmb_degrade_setup_tx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairmb_degrage_checking_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairmb_done_handshake_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairmb_start_handshake_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairmb_start_handshake_tx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairval_done_handshake_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairval_result_datapath_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairval_init_hs_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairval_init_hs_tx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairval_result_exit_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairval_result_exit_tx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairval_result_hs_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairval_result_hs_tx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairval_start_handshake_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_repairval_start_handshake_tx.sv"
    `include "sequences/initialization/ltsm_mbinit_reversal_done_handshake_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_reversal_result_data_path_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_reversal_result_exit_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_reversal_result_exit_tx.sv"
    `include "sequences/initialization/ltsm_mbinit_reversal_init_hs_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_reversal_init_hs_tx.sv"
    `include "sequences/initialization/ltsm_mbinit_reversal_clearlog_hs_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_reversal_clearlog_hs_tx.sv"
    `include "sequences/initialization/ltsm_mbinit_reversal_result_hs_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_reversal_result_hs_tx.sv"
    `include "sequences/initialization/ltsm_mbinit_reversal_starthandshake_rx.sv"
    `include "sequences/initialization/ltsm_mbinit_reversal_starthandshake_tx.sv"
    `include "sequences/initialization/ltsm_sbinit_done_handshake_rx.sv"
    `include "sequences/initialization/ltsm_sbinit_done_handshake_tx.sv"
    `include "sequences/initialization/ltsm_sbinit_sb_ready.sv"
    `include "sequences/initialization/ltsm_sbinit_out_of_reset_msg_tx.sv"
    `include "sequences/initialization/ltsm_sb_tx_done_resp.sv"
    `include "sequences/initialization/ltsm_sb_rx_done_resp.sv"

    // mbtrain base sequences
    `include "sequences/mbtrain/controllers_done.svh"
    `include "sequences/mbtrain/mbtrain_datatrainvref_rx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_datatrainvref_rx_starthandshake.svh"
    `include "sequences/mbtrain/mbtrain_datatrainvref_tx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_datatrainvref_tx_starthandshake.svh"
    `include "sequences/mbtrain/mbtrain_datavref_rx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_datavref_rx_starthandshake.svh"
    `include "sequences/mbtrain/mbtrain_datavref_speedidle_tx.svh"
    `include "sequences/mbtrain/mbtrain_datavref_tx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_datavref_tx_starthandshake.svh"
    `include "sequences/mbtrain/mbtrain_dtc1_rx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_dtc1_rx_starthandshake.svh"
    `include "sequences/mbtrain/mbtrain_dtc1_tx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_dtc1_tx_starthandshake.svh"
    `include "sequences/mbtrain/mbtrain_dtc2_rx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_dtc2_rx_starthandshake.svh"
    `include "sequences/mbtrain/mbtrain_dtc2_tx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_dtc2_tx_starthandshake.svh"
    `include "sequences/mbtrain/mbtrain_linkspeed_linkinit_tx.svh"
    `include "sequences/mbtrain/mbtrain_linkspeed_phyretrain_rx.svh"
    `include "sequences/mbtrain/mbtrain_linkspeed_repair_tx.svh"
    `include "sequences/mbtrain/mbtrain_linkspeed_rx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_linkspeed_rx_error_req.svh"
    `include "sequences/mbtrain/mbtrain_linkspeed_rx_repair.svh"
    `include "sequences/mbtrain/mbtrain_linkspeed_rx_speeddegrade.svh"
    `include "sequences/mbtrain/mbtrain_linkspeed_rx_starthandshake.svh"
    `include "sequences/mbtrain/mbtrain_linkspeed_speedidle_tx.svh"
    `include "sequences/mbtrain/mbtrain_linkspeed_tx_datatoclockstart.svh"
    `include "sequences/mbtrain/mbtrain_linkspeed_tx_error_rsp.svh"
    `include "sequences/mbtrain/mbtrain_linkspeed_tx_phyretrainreq.svh"
    `include "sequences/mbtrain/mbtrain_linkspeed_tx_starthandshake.svh"
    `include "sequences/mbtrain/mbtrain_repair_rx_degrade_0.svh"
    `include "sequences/mbtrain/mbtrain_repair_rx_degrade_0_3.svh"
    `include "sequences/mbtrain/mbtrain_repair_rx_degrade_0_7.svh"
    `include "sequences/mbtrain/mbtrain_repair_rx_degrade_0_15.svh"
    `include "sequences/mbtrain/mbtrain_repair_rx_degrade_4_7.svh"
    `include "sequences/mbtrain/mbtrain_repair_rx_degrade_8_15.svh"
    `include "sequences/mbtrain/mbtrain_repair_rx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_repair_rx_starthandshake.svh"
    `include "sequences/mbtrain/mbtrain_repair_tx_applydegrade.svh"
    `include "sequences/mbtrain/mbtrain_repair_tx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_repair_tx_starthandshake.svh"
    `include "sequences/mbtrain/mbtrain_repair_txselfcal_tx.svh"
    `include "sequences/mbtrain/mbtrain_rxclkcal_rx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_rxclkcal_rx_starthandshake.svh"
    `include "sequences/mbtrain/mbtrain_rxclkcal_tx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_rxclkcal_tx_starthandshake.svh"
    `include "sequences/mbtrain/mbtrain_rxdeskew_rx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_rxdeskew_rx_starthandshake.svh"
    `include "sequences/mbtrain/mbtrain_rxdeskew_tx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_rxdeskew_tx_starthandshake.svh"
    `include "sequences/mbtrain/mbtrain_speedidle_rx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_speedidle_tx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_txselfcal_calibration_tx.svh"
    `include "sequences/mbtrain/mbtrain_txselfcal_rx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_txselfcal_tx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_valtraincenter_rx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_valtraincenter_rx_starthandshake.svh"
    `include "sequences/mbtrain/mbtrain_valtraincenter_tx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_valtraincenter_tx_starthandshake.svh"
    `include "sequences/mbtrain/mbtrain_valtrainvref_rx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_valtrainvref_rx_starthandshake.svh"
    `include "sequences/mbtrain/mbtrain_valtrainvref_tx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_valtrainvref_tx_starthandshake.svh"
    `include "sequences/mbtrain/mbtrain_valvref_rx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_valvref_rx_starthandshake.svh"
    `include "sequences/mbtrain/mbtrain_valvref_tx_endhandshake.svh"
    `include "sequences/mbtrain/mbtrain_valvref_tx_starthandshake.svh"
    `include "sequences/mbtrain/rx_done.svh"
    `include "sequences/mbtrain/tx_done.svh"
    
    //active base sequences
    `include "sequences/active/linkinit_rx_clkreqhandshake.sv"
    `include "sequences/active/linkinit_statereqhandshake.sv"
    `include "sequences/active/linkinit_tx_clkreqhandshake.sv"
    `include "sequences/active/linkinit_wakereqhandshake.sv"
    `include "sequences/active/linkinit_reset.sv"
    `include "sequences/active/active_rx_sequence.sv"
    `include "sequences/active/active_tx_sequence.sv"
    `include "sequences/active/l1_rx_enter_l1.sv"
    `include "sequences/active/l1_rx_exit_l1.sv"
    `include "sequences/active/l1_rx_refuse_l1.sv"
    `include "sequences/active/l1_rx_refuse_done.sv"
    `include "sequences/active/l1_rx_rsp_l1.sv"
    `include "sequences/active/l1_rx_start_handshake.sv"
    `include "sequences/active/l1_rx_wait_seq.sv"
    `include "sequences/active/l1_tx_enter_l1_txinit.sv"
    `include "sequences/active/l1_tx_enter_l1_rxinit.sv"
    `include "sequences/active/l1_tx_exit_l1.sv"
    `include "sequences/active/l1_tx_starthandshake.sv"
    `include "sequences/active/l1_tx_rsp_pmnak.sv"
    `include "sequences/active/l1_tx_refuse_l1.sv"
   /*
    //phyretrain sequences
    `include "sequences/phyretrain/phyretrain_tx_retr_hs.sv"
    `include "sequences/phyretrain/phyretrain_tx_reqhs.sv"
    `include "sequences/phyretrain/phyretrain_stallack.sv"
    `include "sequences/phyretrain/phyretrain_rx_rsphs.sv"
    `include "sequences/phyretrain/phyretrain_rx_retr_hs.sv"
    `include "sequences/phyretrain/phyretrain_rx_frame_error.sv"
    `include "sequences/phyretrain/phyretrain_reg_txselfcal2.sv"
    `include "sequences/phyretrain/phyretrain_reg_txself.sv"
    `include "sequences/phyretrain/phyretrain_reg_speedidle.sv"
    `include "sequences/phyretrain/phyretrain_RDI_init.sv"
    */

    // results base sequences
    `include "sequences/results/result_fail_0_3_8_15.svh"
    `include "sequences/results/result_fail_0_7.svh"
    `include "sequences/results/result_fail_4_15.svh"
    `include "sequences/results/result_fail_8_15.svh"
    `include "sequences/results/result_success.svh"
    `include "sequences/results/results_all_fail.svh"

    // rxinit_datasweep base sequences
    `include "sequences/rxinit_datasweep/mbtrain_rxinit_datasweep_rx_lfsrclear.svh"
    `include "sequences/rxinit_datasweep/mbtrain_rxinit_datasweep_rx_pattern.svh"
    `include "sequences/rxinit_datasweep/mbtrain_rxinit_datasweep_rx_result.svh"
    `include "sequences/rxinit_datasweep/mbtrain_rxinit_datasweep_rx_starthandshake.svh"
    `include "sequences/rxinit_datasweep/mbtrain_rxinit_datasweep_rx_sweep.svh"
    `include "sequences/rxinit_datasweep/mbtrain_rxinit_datasweep_tx_end.svh"
    `include "sequences/rxinit_datasweep/mbtrain_rxinit_datasweep_tx_lfsrclear.svh"
    `include "sequences/rxinit_datasweep/mbtrain_rxinit_datasweep_tx_pattern.svh"
    `include "sequences/rxinit_datasweep/mbtrain_rxinit_datasweep_tx_result.svh"
    `include "sequences/rxinit_datasweep/mbtrain_rxinit_datasweep_tx_result_rsp_allfail.svh"
    `include "sequences/rxinit_datasweep/mbtrain_rxinit_datasweep_tx_result_rsp_fail_0_3_8_15.svh"
    `include "sequences/rxinit_datasweep/mbtrain_rxinit_datasweep_tx_result_rsp_fail_0_7.svh"
    `include "sequences/rxinit_datasweep/mbtrain_rxinit_datasweep_tx_result_rsp_fail_4_15.svh"
    `include "sequences/rxinit_datasweep/mbtrain_rxinit_datasweep_tx_result_rsp_fail_8_15.svh"
    `include "sequences/rxinit_datasweep/mbtrain_rxinit_datasweep_tx_result_rsp_succes.svh"
    `include "sequences/rxinit_datasweep/mbtrain_rxinit_datasweep_tx_starthandshake.svh"

    // txinit_datasweep base sequences
    `include "sequences/txinit_datasweep/mbtrain_txinit_datasweep_rx_endhandshake.svh"
    `include "sequences/txinit_datasweep/mbtrain_txinit_datasweep_rx_lfsrclear.svh"
    `include "sequences/txinit_datasweep/mbtrain_txinit_datasweep_rx_pattern.svh"
    `include "sequences/txinit_datasweep/mbtrain_txinit_datasweep_rx_result.svh"
    `include "sequences/txinit_datasweep/mbtrain_txinit_datasweep_rx_starthandshake.svh"
    `include "sequences/txinit_datasweep/mbtrain_txinit_datasweep_tx_endhandshake.svh"
    `include "sequences/txinit_datasweep/mbtrain_txinit_datasweep_tx_lfsrclear.svh"
    `include "sequences/txinit_datasweep/mbtrain_txinit_datasweep_tx_pattern.svh"
    `include "sequences/txinit_datasweep/mbtrain_txinit_datasweep_tx_result.svh"
    `include "sequences/txinit_datasweep/mbtrain_txinit_datasweep_tx_result_rsp_allfail.svh"
    `include "sequences/txinit_datasweep/mbtrain_txinit_datasweep_tx_result_rsp_fail_0_3_8_15.svh"
    `include "sequences/txinit_datasweep/mbtrain_txinit_datasweep_tx_result_rsp_fail_0_7.svh"
    `include "sequences/txinit_datasweep/mbtrain_txinit_datasweep_tx_result_rsp_fail_4_15.svh"
    `include "sequences/txinit_datasweep/mbtrain_txinit_datasweep_tx_result_rsp_fail_8_15.svh"
    `include "sequences/txinit_datasweep/mbtrain_txinit_datasweep_tx_result_rsp_succes.svh"

    //common base sequences
    `include "sequences/common/nothing_rx.svh"
    `include "sequences/common/nothing_tx.svh"
    `include "sequences/common/trainerror_exitreset.svh"
    `include "sequences/common/trainerror_rx_rsp.svh"
    `include "sequences/common/trainerror_tx_rsp.svh"
    `include "sequences/common/trainerror_rx_starthandshake.svh"
    `include "sequences/common/trainerror_rdiexit.svh"
    `include "sequences/common/phyretrain_tx_retr_hs.sv"
    `include "sequences/common/phyretrain_tx_reqhs.sv"
    `include "sequences/common/phyretrain_stallack.sv"
    `include "sequences/common/phyretrain_rx_rsphs.sv"
    `include "sequences/common/phyretrain_rx_retr_hs.sv"
    `include "sequences/common/phyretrain_rx_frame_error.sv"
    `include "sequences/common/phyretrain_reg_txselfcal2.sv"
    `include "sequences/common/phyretrain_reg_txself.sv"
    `include "sequences/common/phyretrain_reg_speedidle.sv"
    `include "sequences/common/phyretrain_RDI_init.sv"

    // virtual Sequences
    `include "virtual_sequence/virtual_sequence_base.svh"

    // rxinit_datasweep
    `include "virtual_sequence/rxinit_datasweep/mbtrain_rxinit_datasweep_allfail.svh"
    `include "virtual_sequence/rxinit_datasweep/mbtrain_rxinit_datasweep_fail_0_3_8_15.svh"
    `include "virtual_sequence/rxinit_datasweep/mbtrain_rxinit_datasweep_fail_0_7.svh"
    `include "virtual_sequence/rxinit_datasweep/mbtrain_rxinit_datasweep_fail_4_15.svh"
    `include "virtual_sequence/rxinit_datasweep/mbtrain_rxinit_datasweep_fail_8_15.svh"
    `include "virtual_sequence/rxinit_datasweep/mbtrain_rxinit_datasweep_success.svh"
    `include "virtual_sequence/rxinit_datasweep/mbtrain_rxinit_datasweep_loop.svh"

    // txinit_datasweep
    `include "virtual_sequence/txinit_datasweep/mbtrain_txinit_datasweep_allfail.svh"
    `include "virtual_sequence/txinit_datasweep/mbtrain_txinit_datasweep_fail_0_3_8_15.svh"
    `include "virtual_sequence/txinit_datasweep/mbtrain_txinit_datasweep_fail_0_7.svh"
    `include "virtual_sequence/txinit_datasweep/mbtrain_txinit_datasweep_fail_4_15.svh"
    `include "virtual_sequence/txinit_datasweep/mbtrain_txinit_datasweep_fail_8_15.svh"
    `include "virtual_sequence/txinit_datasweep/mbtrain_txinit_datasweep_success.svh"
    `include "virtual_sequence/txinit_datasweep/mbtrain_txinit_datasweep_txallfail_rxpass.svh"
    `include "virtual_sequence/txinit_datasweep/mbtrain_txinit_datasweep_txfail_0_7_rxpass.svh"
    `include "virtual_sequence/txinit_datasweep/mbtrain_txinit_datasweep_txnotallfail_rxallfail.svh"
    `include "virtual_sequence/txinit_datasweep/mbtrain_txinit_datasweep_txpass_rxfail_0_7.svh"
    `include "virtual_sequence/txinit_datasweep/mbtrain_txinit_datasweep_txpass_rxfallfail.svh"
    // initialization
    `include "virtual_sequence/initialization/ltsm_mbinit_cal_v_sequence.sv"
    `include "virtual_sequence/initialization/ltsm_mbinit_param_v_seqeunce.sv"
    `include "virtual_sequence/initialization/ltsm_mbinit_repairclk_v_sequence.sv"
    `include "virtual_sequence/initialization/ltsm_mbinit_repairval_v_sequence.sv"
    `include "virtual_sequence/initialization/ltsm_mbinit_repiarmb_v_sequence.sv"
    `include "virtual_sequence/initialization/ltsm_mbinit_reversalmb_v_sequence.sv"
    `include "virtual_sequence/initialization/ltsm_reset_v_sequence.sv"
    `include "virtual_sequence/initialization/reset_train_error_v_sequence.sv"

    `include "virtual_sequence/initialization/ltsm_sbinit_v_sequence.sv"
    `include "virtual_sequence/initialization/initialization_success.svh"
    `include "virtual_sequence/initialization/ltsm_mbinit_repairclk_fail_v_sequence.sv"
    `include "virtual_sequence/initialization/ltsm_mbinit_repairval_fail_v_sequence.sv"
    `include "virtual_sequence/initialization/ltsm_mbinit_reversalmb_fail_v_seqeunce.sv"
    `include "virtual_sequence/initialization/ltsm_mbinit_repairmb_fail_v_sequence.sv"
    `include "virtual_sequence/initialization/trainerror.svh"
    `include "virtual_sequence/initialization/ltsm_init_clk_fail_v_sequence.sv"
    `include "virtual_sequence/initialization/ltsm_init_val_fail_v_sequence.sv"
    `include "virtual_sequence/initialization/ltsm_init_reversal_fail_v_sequence.sv"
    `include "virtual_sequence/initialization/ltsm_init_repairmb_fail_v_sequence.sv"
    
    // mbtrain
    `include "virtual_sequence/mbtrain/mbtrain_datatrainvref_looptillerror.svh"
    `include "virtual_sequence/mbtrain/mbtrain_datatrainvref_success.svh"
    `include "virtual_sequence/mbtrain/mbtrain_datatrainvref_timeout.svh"
    `include "virtual_sequence/mbtrain/mbtrain_datatrainvref_trainerror.svh"
    `include "virtual_sequence/mbtrain/mbtrain_datavref_looptillerror.svh"
    `include "virtual_sequence/mbtrain/mbtrain_datavref_success.svh"
    `include "virtual_sequence/mbtrain/mbtrain_datavref_timeout.svh"
    `include "virtual_sequence/mbtrain/mbtrain_datavref_trainerror.svh"
    `include "virtual_sequence/mbtrain/mbtrain_dtc1_success.svh"
    `include "virtual_sequence/mbtrain/mbtrain_dtc1_timeout.svh"
    `include "virtual_sequence/mbtrain/mbtrain_dtc1_trainerror.svh"
    `include "virtual_sequence/mbtrain/mbtrain_dtc2_success.svh"
    `include "virtual_sequence/mbtrain/mbtrain_dtc2_timeout.svh"
    `include "virtual_sequence/mbtrain/mbtrain_dtc2_trainerror.svh"
    `include "virtual_sequence/mbtrain/mbtrain_linkspeed_phyretrain_lanepossible_rxfail.svh"
    `include "virtual_sequence/mbtrain/mbtrain_linkspeed_phyretrain_lanepossible_txfail.svh"
    `include "virtual_sequence/mbtrain/mbtrain_linkspeed_phyretrain_nolanepossible_rxfail.svh"
    `include "virtual_sequence/mbtrain/mbtrain_linkspeed_phyretrain_nolanepossible_txfail.svh"
    `include "virtual_sequence/mbtrain/mbtrain_linkspeed_repair_fail_0_3_8_15.svh"
    `include "virtual_sequence/mbtrain/mbtrain_linkspeed_repair_fail_0_7.svh"
    `include "virtual_sequence/mbtrain/mbtrain_linkspeed_repair_fail_4_15.svh"
    `include "virtual_sequence/mbtrain/mbtrain_linkspeed_repair_fail_8_15.svh"
    `include "virtual_sequence/mbtrain/mbtrain_linkspeed_repair_trainerror.svh"
    `include "virtual_sequence/mbtrain/mbtrain_linkspeed_speeddegrade_rxinit.svh"
    `include "virtual_sequence/mbtrain/mbtrain_linkspeed_speeddegrade_txinit.svh"
    `include "virtual_sequence/mbtrain/mbtrain_linkspeed_success.svh"
    `include "virtual_sequence/mbtrain/mbtrain_rxclkcal_success.svh"
    `include "virtual_sequence/mbtrain/mbtrain_rxclkcal_timeout.svh"
    `include "virtual_sequence/mbtrain/mbtrain_rxclkcal_trainerror.svh"
    `include "virtual_sequence/mbtrain/mbtrain_rxdeskew_success.svh"
    `include "virtual_sequence/mbtrain/mbtrain_rxdeskew_timeout.svh"
    `include "virtual_sequence/mbtrain/mbtrain_rxdeskew_trainerror.svh"
    `include "virtual_sequence/mbtrain/mbtrain_valtraincenter_success.svh"
    `include "virtual_sequence/mbtrain/mbtrain_valtraincenter_timeout.svh"
    `include "virtual_sequence/mbtrain/mbtrain_valtraincenter_trainerror.svh"
    `include "virtual_sequence/mbtrain/mbtrain_valtrainvref_success.svh"
    `include "virtual_sequence/mbtrain/mbtrain_valtrainvref_looptillerror.svh"
    `include "virtual_sequence/mbtrain/mbtrain_valtrainvref_timeout.svh"
    `include "virtual_sequence/mbtrain/mbtrain_valtrainvref_trainerror.svh"
    `include "virtual_sequence/mbtrain/mbtrain_valvref_looptillerror.svh"
    `include "virtual_sequence/mbtrain/mbtrain_valvref_success.svh"
    `include "virtual_sequence/mbtrain/mbtrain_valvref_timeout.svh"
    `include "virtual_sequence/mbtrain/mbtrain_valvref_trainerror.svh"
    `include "virtual_sequence/mbtrain/mbtrain_success.svh"

    //active
    `include "virtual_sequence/active/active_virtual_sequence.sv"
    `include "virtual_sequence/active/linkinit_virtual_sequence.sv"
    `include "virtual_sequence/active/linkinit_reset_rdi.sv"
    `include "virtual_sequence/active/linkinit_vs_timeout.svh"
    `include "virtual_sequence/active/l1_txinit_exit_l1.sv"
    `include "virtual_sequence/active/l1_tx_vs_rsp_pmnak.sv"
    `include "virtual_sequence/active/l1_tx_virtual_seq_rsp_l1.sv"
    `include "virtual_sequence/active/l1_rx_vs_refuse_l1.sv"
    `include "virtual_sequence/active/l1_rx_seq_rsp_l1.sv"
    `include "virtual_sequence/active/l1_rxinit_exit_l1.sv"
      

    // phyretrain
    `include "virtual_sequence/phyretrain/rdi_init_speedidle.sv"
    `include "virtual_sequence/phyretrain/rdi_init_txselfcal.sv"
    `include "virtual_sequence/phyretrain/rdi_init_txselfcal_2.sv"
    `include "virtual_sequence/phyretrain/remote_die_init_speedidle.sv"
    `include "virtual_sequence/phyretrain/remote_die_init_txselcal.sv"
    `include "virtual_sequence/phyretrain/remote_die_init_txselfcal_2.sv"
    `include "virtual_sequence/phyretrain/valid_frame_speedidle.sv"
    `include "virtual_sequence/phyretrain/valid_frame_txselfcal.sv"
    `include "virtual_sequence/phyretrain/valid_frame_txselfcal_2.sv"


  
    
    
    // Tests    
    `include "MBTRAIN_test.svh"

    `include "ACTIVE_tests.sv"
      
    `include "mbinit_clk_fail_test.sv"
    `include "mbinit_val_fail_test.sv"
    `include "mbinit_reversal_fail_test.sv"
    `include "mbinit_repairmb_fail_test.sv"
    `include "init_pass_test.sv"
    
endpackage : LTSM_pkg
