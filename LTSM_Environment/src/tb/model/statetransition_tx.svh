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

import shared_ltsm_pkg::*;
class StateTransitionUtil_tx extends State;
 local static State validStateTransitions[State][$];
 static bit firsttime;
//    function new();
//         init();
//  endfunction

 static function void init();

    validStateTransitions[ResetState_tx::Instance()] = { ResetState_tx::Instance(), SbInitState_tx::Instance()};
    
    validStateTransitions[SbInitState_tx::Instance()] = { SbInitState_tx::Instance(), MbInitParamState_tx::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[MbInitParamState_tx::Instance()] = { MbInitParamState_tx::Instance(), MbInitCalState_tx::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[MbInitCalState_tx::Instance()] = { MbInitCalState_tx::Instance(), MbInitRepairClkState_tx::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[MbInitRepairClkState_tx::Instance()] = { MbInitRepairClkState_tx::Instance(), MbInitRepairValState_tx::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[MbInitRepairValState_tx::Instance()] = { MbInitRepairValState_tx::Instance(), MbInitReversalMbState_tx::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[MbInitReversalMbState_tx::Instance()] = { MbInitReversalMbState_tx::Instance(), MbInitRepairMbState_tx::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[MbInitRepairMbState_tx::Instance()] = { MbInitRepairMbState_tx::Instance(), mbtrain_tx_valvref::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_valvref::Instance()] = { mbtrain_tx_valvref::Instance(), mbtrain_tx_datavref::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_datavref::Instance()] = { mbtrain_tx_datavref::Instance(), mbtrain_tx_speedidle::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_speedidle::Instance()] = { mbtrain_tx_speedidle::Instance(), mbtrain_tx_txselfcal::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_txselfcal::Instance()] = { mbtrain_tx_txselfcal::Instance(), mbtrain_tx_rxclkcal::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_rxclkcal::Instance()] = { mbtrain_tx_rxclkcal::Instance(), mbtrain_tx_valtraincenter::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_valtraincenter::Instance()] = { mbtrain_tx_valtraincenter::Instance(), mbtrain_tx_valtrainvref::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};

    validStateTransitions[mbtrain_tx_valtrainvref::Instance()] = { mbtrain_tx_valtrainvref::Instance(), mbtrain_tx_dtc1::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_dtc1::Instance()] = { mbtrain_tx_dtc1::Instance(), mbtrain_tx_datatrainvref::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_datatrainvref::Instance()] = { mbtrain_tx_datatrainvref::Instance(), mbtrain_tx_rxdeskew::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_rxdeskew::Instance()] = { mbtrain_tx_rxdeskew::Instance(), mbtrain_tx_dtc2::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_dtc2::Instance()] = { mbtrain_tx_dtc2::Instance(), mbtrain_tx_linkspeed::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_linkspeed::Instance()] = { mbtrain_tx_linkspeed::Instance(), mbtrain_tx_repair::Instance(), mbtrain_tx_speedidle::Instance(), phyretrain_tx::Instance(), linkinit_state_tx::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_repair::Instance()] = { mbtrain_tx_repair::Instance(), mbtrain_tx_txselfcal::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[phyretrain_tx::Instance()] = { phyretrain_tx::Instance(), mbtrain_tx_txselfcal::Instance(), mbtrain_tx_speedidle::Instance(), mbtrain_tx_repair::Instance() , trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[linkinit_state_tx::Instance()] = { linkinit_state_tx::Instance(), active_state_tx::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[active_state_tx::Instance()] = { active_state_tx::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance(),l1_state_tx::Instance()};

    validStateTransitions[l1_state_tx::Instance()] = { l1_state_tx::Instance(), mbtrain_tx_speedidle::Instance(), ResetState_tx::Instance()};

    validStateTransitions[trainerror_tx::Instance()] = { trainerror_tx::Instance(), ResetState_tx::Instance()};
    
 endfunction

 static function State calculate(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in);
 State nextState = null;
 
 State nextValid[$];
 if (!firsttime) begin
   init();
   firsttime = 1'b1;
 end
 
    //`uvm_info("StateTransitionUtil_tx", $sformatf("Calculating next state for current TX state: %s", cntxt.currentstate_tx.getStateId()), UVM_LOW)

 nextState = calculateNextState(cntxt,item_controllers_in,item_rdi_in,item_rx_fsm_sb_in,item_tx_fsm_sb_in);
//`uvm_info("state transition", $sformatf("Current State: TX: %s, RX: %s", cntxt.currentstate_tx.getStateId(), cntxt.currentstate_rx.getStateId()), UVM_MEDIUM)

 nextValid = validStateTransitions[cntxt.currentstate_tx].find(x) with ( x == nextState );
 if (nextValid.size() != 0) begin
 return nextState;
 end
 else begin
 $display("da5lna hena");
 $display("Invalid state transition from state %s", cntxt.currentstate_tx.getStateId());
 $display("Invalid state transition from state %s to state %s", cntxt.currentstate_tx.getStateId(), nextState.getStateId());
 //`uvm_error($sformatf("Invalid state transition from state %0d to state %0d", cntxt.currentstate_rx.getStateId(), nextState.getStateId()));
 end
 endfunction

 static function State calculateNextState(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in);
        case (cntxt.currentstate_tx.getStateId())
            fsm_tx_reset: begin

              if (item_controllers_in.i_supply_stable===1'b1 && item_controllers_in.i_pll_stable===1'b1 && item_controllers_in.i_reset===1'b0 && counter > ((((item_controllers_in.i_sim_cycles_4)-6)))) begin
                  return SbInitState_tx::Instance();
               end
               else begin
                  return ResetState_tx::Instance();
               end
            end
            fsm_tx_sbinit: begin
              if (item_controllers_in.i_reset)begin
                  //`uvm_info("StateTransitionUtil_tx", "Transitioning to ResetState_tx due to reset being asserted", UVM_LOW)
                  return ResetState_tx::Instance();
               end
               else if (item_tx_fsm_sb_in.i_tx_decoding == SBINIT_TX_Done_Handshake  && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1) begin
                 // `uvm_info("StateTransitionUtil_tx", "Transitioning to MbInitParamState_tx due to completion of SBINIT sequence", UVM_LOW)
                  return MbInitParamState_tx::Instance();
               end
               else begin
                  //`uvm_info("StateTransitionUtil_tx", "Remaining in SbInitState_tx", UVM_LOW)
                  return SbInitState_tx::Instance();
               end
            end
            fsm_mbinit_tx_param : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               else if (item_tx_fsm_sb_in.i_tx_decoding == MBINIT_PARAM_TX_Config_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1) begin
                  return MbInitCalState_tx::Instance();
               end
               else begin
                  return MbInitParamState_tx::Instance();
               end
            end
            fsm_mbinit_tx_cal : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               else if (item_tx_fsm_sb_in.i_tx_decoding == MBINIT_CAL_TX_Done_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1) begin
                  return MbInitRepairClkState_tx::Instance();
               end
               else begin
                  return MbInitCalState_tx::Instance();
               end
            end
            fsm_mbinit_tx_repairclk : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               else if (item_tx_fsm_sb_in.i_tx_decoding == MBINIT_REPAIRCLK_TX_Done_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1) begin
                  return MbInitRepairValState_tx::Instance();
               end
               else begin
                  return MbInitRepairClkState_tx::Instance();
               end
            end
            fsm_mbinit_tx_repairval : begin
            // $display("In mbinit_tx_repairval state with i_tx_decoding: %0h and i_sb_tx_rsp: %0b", item_tx_fsm_sb_in.i_tx_decoding, item_tx_fsm_sb_in.i_sb_tx_rsp);
               
              if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               else if (item_tx_fsm_sb_in.i_tx_decoding == MBINIT_REPAIRVAL_TX_Done_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1) begin
                  return MbInitReversalMbState_tx::Instance();
               end
               else begin
                  return MbInitRepairValState_tx::Instance();
               end
            end
            fsm_mbinit_tx_reversal : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               else if (item_tx_fsm_sb_in.i_tx_decoding == MBINIT_REVERSAL_TX_Done_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1) begin
                  return MbInitRepairMbState_tx::Instance();
               end
               else begin
                  return MbInitReversalMbState_tx::Instance();
               end
            end
            fsm_mbinit_tx_repairmb : begin
               // $display("In mbinit_tx_repairmb state with i_tx_decoding: %0h and i_sb_tx_rsp: %0b", item_tx_fsm_sb_in.i_tx_decoding, item_tx_fsm_sb_in.i_sb_tx_rsp);
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               else if (item_tx_fsm_sb_in.i_tx_decoding == MBINIT_REPAIRMB_TX_Done_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1) begin
                  return mbtrain_tx_valvref::Instance();
                  state_done = 1;
               end
               else begin
                  return MbInitRepairMbState_tx::Instance();
               end
            end
            fsm_tx_trainerror : begin
               // `uvm_info("l1_state_rx", $sformatf("i_reset: %0b, i_sb_cur_msg_done = %0b , i_lp_linkerror = %0b ", item_controllers_in.i_reset,item_controllers_in.i_sb_cur_msg_done, item_rdi_in.i_lp_linkerror), UVM_LOW);
               if (item_controllers_in.i_reset || (item_controllers_in.i_sb_cur_msg_done && !item_rdi_in.i_lp_linkerror))begin
                  return ResetState_tx::Instance();
               end
               else begin
                  return trainerror_tx::Instance();
               end 

            end
            fsm_mbtrain_tx_valvref : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               else if (item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_VALVREF_TX_End_Handshake && state_done && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1) begin
                  return mbtrain_tx_datavref::Instance();
               end
               else if (error_count == 4 && !item_tx_fsm_sb_in.i_tx_info[4] && item_tx_fsm_sb_in.i_tx_decoding == DATA_TO_CLOCK_RX_RX_RESULT_HANDSHAKE) begin
                  return trainerror_tx::Instance();
               end
               else begin
                  return mbtrain_tx_valvref::Instance();
               end
            end
            fsm_mbtrain_tx_datavref : begin 
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               else if (item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_DATAVREF_TX_End_Handshake && state_done && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1) begin
                  return mbtrain_tx_speedidle::Instance();
               end
               else begin
                  return mbtrain_tx_datavref::Instance();
               end
            end
            fsm_mbtrain_tx_dtc1 : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               else if (item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_DTC1_TX_End_Handshake && state_done && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1) begin
                  return mbtrain_tx_datatrainvref::Instance();
               end
               else begin
                  return mbtrain_tx_dtc1::Instance();
               end
            end
            fsm_mbtrain_tx_rxclkcal : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               else if (item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_RXCLKCAL_TX_End_Handshake && state_done && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1) begin
                  return mbtrain_tx_valtraincenter::Instance();
               end
               else begin
                  return mbtrain_tx_rxclkcal::Instance();
               end
            end
            fsm_mbtrain_tx_valtraincenter : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               else if (item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_VALTRAINCENTER_TX_End_Handshake && state_done && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1) begin
                  return mbtrain_tx_valtrainvref::Instance();
               end
               else begin
                  return mbtrain_tx_valtraincenter::Instance();
               end
            end 
            fsm_mbtrain_tx_valtrainvref : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               else if (item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_VALTRAINVREF_TX_End_Handshake && state_done && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1) begin
                  return mbtrain_tx_dtc1::Instance();
               end
               else begin
                  return mbtrain_tx_valtrainvref::Instance();
               end
            end 
            fsm_mbtrain_tx_rxdeskew : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               else if (item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_RXDESKEW_TX_End_Handshake && state_done && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1) begin
                  return mbtrain_tx_dtc2::Instance();
               end
               else begin
                  return mbtrain_tx_rxdeskew::Instance();
               end
            end
            fsm_mbtrain_tx_dtc2 : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               else if (item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_DTC2_TX_End_Handshake && state_done && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1) begin
                  return mbtrain_tx_linkspeed::Instance();
               end
               else begin
                  return mbtrain_tx_dtc2::Instance();
               end
            end
            fsm_mbtrain_tx_datatrainvref : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               else if (item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_DATATRAINVREF_TX_End_Handshake && state_done && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1) begin
                  return mbtrain_tx_rxdeskew::Instance();
               end
               else begin
                  return mbtrain_tx_datatrainvref::Instance();
               end
            end
            fsm_mbtrain_tx_linkspeed : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               // speed idle
               else if ((item_tx_fsm_sb_in.i_tx_decoding == 'hbe && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1 && state_done)) begin
                  return mbtrain_tx_speedidle::Instance();
               end
               // repair
               else if (item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_LINKSPEED_TX_Repair_Hnd && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1 && state_done) begin
                  return mbtrain_tx_repair::Instance();
               end
               // done
               else if (item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_LINKSPEED_TX_LinkSpeed_Done_Hnd && state_done && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1) begin
                  return linkinit_state_tx::Instance();
               end
               // phyretrian
               else if (item_rx_fsm_sb_in.i_rx_decoding == MBTRAIN_LINKSPEED_TX_Phy_Retrain_Hnd && item_rx_fsm_sb_in.i_sb_rx_rsp==1'b1 && state_done) begin
                  return phyretrain_tx::Instance();
               end
               else begin
                  return mbtrain_tx_linkspeed::Instance();
               end
            end
            fsm_mbtrain_tx_repair : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               else if (item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_REPAIR_TX_End_Handshake && state_done && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1) begin
                  return mbtrain_tx_txselfcal::Instance();
               end
               else begin
                  return mbtrain_tx_repair::Instance();
               end
            end
            fsm_mbtrain_tx_speedidle : begin
               if (item_tx_fsm_sb_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               else if (item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_SPEEDIDLE_TX_End_Handshake && state_done && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1) begin
                  return mbtrain_tx_txselfcal::Instance();
               end
               else begin
                  return mbtrain_tx_speedidle::Instance();
               end
            end
            fsm_mbtrain_tx_txselfcal : begin
               // `uvm_info("mbtrain_tx_txselfcal", $sformatf("state_done: %0b ", state_done), UVM_LOW);
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               else if (item_tx_fsm_sb_in.i_tx_decoding == 'hd1 && state_done && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1) begin
                  return mbtrain_tx_rxclkcal::Instance();
               end
               else begin
                  return mbtrain_tx_txselfcal::Instance();
               end
            end
            fsm_tx_phyretrain : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               if(item_tx_fsm_sb_in.i_tx_decoding == PHYRETRAIN_TX_Start_Req_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && state_done == 1'b1)begin
                  if(item_tx_fsm_sb_in.i_tx_info[2:0] == 3'b010) // SPEEDIDLE
                  return mbtrain_tx_speedidle::Instance() ;
               else if(item_tx_fsm_sb_in.i_tx_info[2:0] == 3'b100) // REPAIR
                  return mbtrain_tx_repair::Instance() ;
               else if(item_tx_fsm_sb_in.i_tx_info[2:0] == 3'b001) // TXSELFCAL
                  return mbtrain_tx_txselfcal::Instance() ;
               end
            end
            fsm_tx_l1 : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               else if(item_rdi_in.i_lp_state_req == state_req_active || item_rx_fsm_sb_in.i_rx_decoding == ACTIVE_EXIT_HS_TX_Exit_Handshake && item_rx_fsm_sb_in.i_sb_rx_req)begin
                  return mbtrain_tx_speedidle::Instance();
               end
               else begin
                  return l1_state_tx::Instance();
               end
            end
            fsm_tx_linkinit : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               else if (item_tx_fsm_sb_in.i_tx_decoding == 'h102 && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1) begin
                  return active_state_tx::Instance();
               end
               else begin
                  return linkinit_state_tx::Instance();
               end
            end
            fsm_tx_active : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               else if ((item_rx_fsm_sb_in.i_rx_decoding == ACTIVE_TX_Active && item_rx_fsm_sb_in.i_sb_rx_req == 1'b1) || (item_rdi_in.i_lp_state_req == state_req_l1)) begin
                  return l1_state_tx::Instance();
                end
               else begin
                  return active_state_tx::Instance();
                end
            end
        endcase
  endfunction
  virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
   return 0; // dummmy value, no specific action in this state
   
  endfunction
   virtual function fsm_t getStateId();
        return fsm_mbtrain_rx_datatrainvref; // dummy value, not used
    endfunction
 endclass