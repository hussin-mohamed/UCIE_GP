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
class StateTransitionUtil_rx extends State;
 local static State validStateTransitions[State][$];
 static bit firsttime;

//  function new();
        
//         `uvm_info("StateTransitionUtil_rx", "initializing StateTransitionUtil_rx object", UVM_LOW)
//         init();
//         `uvm_info("StateTransitionUtil_rx", "finished initializing StateTransitionUtil_rx object", UVM_LOW)
//  endfunction

 static function void init();

    validStateTransitions[ResetState_rx::Instance()] = { ResetState_rx::Instance(), SbInitState_rx::Instance()};
    
    validStateTransitions[SbInitState_rx::Instance()] = { SbInitState_rx::Instance(), MbInitParamState_rx::Instance(), trainerror_rx::Instance(), ResetState_rx::Instance()};
    
    validStateTransitions[MbInitParamState_rx::Instance()] = { MbInitParamState_rx::Instance(), MbInitCalState_rx::Instance(), trainerror_rx::Instance(), ResetState_rx::Instance()};
    
    validStateTransitions[MbInitCalState_rx::Instance()] = { MbInitCalState_rx::Instance(), MbInitRepairClkState_rx::Instance(), trainerror_rx::Instance(), ResetState_rx::Instance()};
    
    validStateTransitions[MbInitRepairClkState_rx::Instance()] = { MbInitRepairClkState_rx::Instance(), MbInitRepairValState_rx::Instance(), trainerror_rx::Instance(), ResetState_rx::Instance()};
    
    validStateTransitions[MbInitRepairValState_rx::Instance()] = { MbInitRepairValState_rx::Instance(), MbInitReversalMbState_rx::Instance(), trainerror_rx::Instance(), ResetState_rx::Instance()};
    
    validStateTransitions[MbInitReversalMbState_rx::Instance()] = { MbInitReversalMbState_rx::Instance(), MbInitRepairMbState_rx::Instance(), trainerror_rx::Instance(), ResetState_rx::Instance()};
    
    validStateTransitions[MbInitRepairMbState_rx::Instance()] = { MbInitRepairMbState_rx::Instance(), mbtrain_rx_valvref::Instance(), trainerror_rx::Instance(), ResetState_rx::Instance()};
    
    validStateTransitions[mbtrain_rx_valvref::Instance()] = { mbtrain_rx_valvref::Instance(), mbtrain_rx_datavref::Instance(), trainerror_rx::Instance(), ResetState_rx::Instance()};
    
    validStateTransitions[mbtrain_rx_datavref::Instance()] = { mbtrain_rx_datavref::Instance(), mbtrain_rx_speedidle::Instance(), trainerror_rx::Instance(), ResetState_rx::Instance()};
    
    validStateTransitions[mbtrain_rx_speedidle::Instance()] = { mbtrain_rx_speedidle::Instance(), mbtrain_rx_txselfcal::Instance(), trainerror_rx::Instance(), ResetState_rx::Instance()};
    
    validStateTransitions[mbtrain_rx_txselfcal::Instance()] = { mbtrain_rx_txselfcal::Instance(), mbtrain_rx_rxclkcal::Instance(), trainerror_rx::Instance(), ResetState_rx::Instance()};
    
    validStateTransitions[mbtrain_rx_rxclkcal::Instance()] = { mbtrain_rx_rxclkcal::Instance(), mbtrain_rx_valtraincenter::Instance(), trainerror_rx::Instance(), ResetState_rx::Instance()};
    
    validStateTransitions[mbtrain_rx_valtraincenter::Instance()] = { mbtrain_rx_valtraincenter::Instance(), mbtrain_rx_valtrainvref::Instance(), trainerror_rx::Instance(), ResetState_rx::Instance()};

    validStateTransitions[mbtrain_rx_valtrainvref::Instance()] = { mbtrain_rx_valtrainvref::Instance(), mbtrain_rx_dtc1::Instance(), trainerror_rx::Instance(), ResetState_rx::Instance()};
    
    validStateTransitions[mbtrain_rx_dtc1::Instance()] = { mbtrain_rx_dtc1::Instance(), mbtrain_rx_datatrainvref::Instance(), trainerror_rx::Instance(), ResetState_rx::Instance()};
    
    validStateTransitions[mbtrain_rx_datatrainvref::Instance()] = { mbtrain_rx_datatrainvref::Instance(), mbtrain_rx_rxdeskew::Instance(), trainerror_rx::Instance(), ResetState_rx::Instance()};
    
    validStateTransitions[mbtrain_rx_rxdeskew::Instance()] = { mbtrain_rx_rxdeskew::Instance(), mbtrain_rx_dtc2::Instance(), trainerror_rx::Instance(), ResetState_rx::Instance()};
    
    validStateTransitions[mbtrain_rx_dtc2::Instance()] = { mbtrain_rx_dtc2::Instance(), mbtrain_rx_linkspeed::Instance(), trainerror_rx::Instance(), ResetState_rx::Instance()};
    
    validStateTransitions[mbtrain_rx_linkspeed::Instance()] = { mbtrain_rx_linkspeed::Instance(), mbtrain_rx_speedidle::Instance(),  mbtrain_rx_repair::Instance(), phyretrain_rx::Instance(), linkinit_state_rx::Instance(), trainerror_rx::Instance(), ResetState_rx::Instance()};
    
    validStateTransitions[mbtrain_rx_repair::Instance()] = { mbtrain_rx_repair::Instance(), mbtrain_rx_txselfcal::Instance(), trainerror_rx::Instance(), ResetState_rx::Instance()};
    
    validStateTransitions[phyretrain_rx::Instance()] = { phyretrain_rx::Instance(), mbtrain_rx_txselfcal::Instance(), mbtrain_rx_speedidle::Instance(), mbtrain_rx_repair::Instance() , trainerror_rx::Instance(), ResetState_rx::Instance()};
    
    validStateTransitions[linkinit_state_rx::Instance()] = { linkinit_state_rx::Instance(), active_state_rx::Instance(), trainerror_rx::Instance(), ResetState_rx::Instance()};
    
    validStateTransitions[active_state_rx::Instance()] = { active_state_rx::Instance(), trainerror_rx::Instance(), ResetState_rx::Instance(),l1_state_rx::Instance()};

    validStateTransitions[l1_state_rx::Instance()] = { l1_state_rx::Instance(), mbtrain_rx_speedidle::Instance(), ResetState_rx::Instance()};

    validStateTransitions[trainerror_rx::Instance()] = { trainerror_rx::Instance(), ResetState_rx::Instance()};

 endfunction

 static function State calculate(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in);
 State nextState = null;
 
 State nextValid[$];
  //`uvm_info("StateTransitionUtil_rx", $sformatf("Calculating next state for current RX state: %s", cntxt.currentstate_rx.getStateId()), UVM_LOW)

 if (!firsttime) begin
   init();
   firsttime = 1'b1;
 end
 nextState = calculateNextState(cntxt,item_controllers_in,item_rdi_in,item_rx_fsm_sb_in,item_tx_fsm_sb_in);
//`uvm_info("state transition", $sformatf("Current State: TX: %s, RX: %s, Next State: TX: %s", cntxt.currentstate_tx.getStateId(), cntxt.currentstate_rx.getStateId(), nextState.getStateId()), UVM_MEDIUM)

 nextValid = validStateTransitions[cntxt.currentstate_rx].find(x) with ( x == nextState );
 if (nextValid.size() != 0) begin
 return nextState;
 end
 else begin
   $display("Invalid state transition from state %0s to state %0s", cntxt.currentstate_rx.getStateId(), nextState.getStateId());
 //`uvm_error($sformatf("Invalid state transition from state %0d to state %0d", cntxt.currentstate_rx.getStateId(), nextState.getStateId()));
 end
 endfunction

  static function State calculateNextState(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in);
        case (cntxt.currentstate_rx.getStateId())
            fsm_rx_reset: begin
               //`uvm_info("l1_state_rx", $sformatf("i_reset: %0b, counter = %0d ", item_controllers_in.i_reset,counter), UVM_LOW);
               if (item_controllers_in.i_supply_stable===1'b1 && item_controllers_in.i_pll_stable===1'b1 && item_controllers_in.i_reset===1'b0 && counter == ((((item_controllers_in.i_sim_cycles_4)-5)))) begin
                  return SbInitState_rx::Instance();
               end
               else begin
                  return ResetState_rx::Instance();
               end
            end
            fsm_rx_sbinit: begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               else if(item_rx_fsm_sb_in.i_rx_decoding == RX_MBINIT_PARAM_Wait_Config_REQ && item_rx_fsm_sb_in.i_sb_rx_req==1'b1)begin
                  return MbInitParamState_rx::Instance();
               end

               else begin
                  return SbInitState_rx::Instance();
               end
            end
            fsm_mbinit_rx_param : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               else if (item_rx_fsm_sb_in.i_rx_decoding == RX_MBINIT_CAL_Done_Handshake && item_rx_fsm_sb_in.i_sb_rx_req==1'b1) begin
                  return MbInitCalState_rx::Instance();
               end

               else begin
                  return MbInitParamState_rx::Instance();
               end
            end
            fsm_mbinit_rx_cal : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               else if (item_rx_fsm_sb_in.i_rx_decoding == RX_MBINIT_REPAIRCLK_Init_Handshake && item_rx_fsm_sb_in.i_sb_rx_req==1'b1) begin
                  return MbInitRepairClkState_rx::Instance();
               end

               else begin
                  return MbInitCalState_rx::Instance();
               end
            end
            fsm_mbinit_rx_repairclk : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               else if (item_rx_fsm_sb_in.i_rx_decoding == RX_MBINIT_REPAIRVAL_Init_Handshake && item_rx_fsm_sb_in.i_sb_rx_req==1'b1) begin
                  return MbInitRepairValState_rx::Instance();
               end

               else begin
                  return MbInitRepairClkState_rx::Instance();
               end
            end
            fsm_mbinit_rx_repairval : begin
              if (item_controllers_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               else if (item_rx_fsm_sb_in.i_rx_decoding == RX_MBINIT_REPAIRVAL_Done_Handshake && item_rx_fsm_sb_in.i_sb_rx_req==1'b1) begin
                  return MbInitReversalMbState_rx::Instance();
               end

               else begin
                  return MbInitRepairValState_rx::Instance();
               end
            end
            fsm_mbinit_rx_reversal : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               else if (item_rx_fsm_sb_in.i_rx_decoding == RX_MBINIT_REPAIRMB_Init_Handshake && item_rx_fsm_sb_in.i_sb_rx_req==1'b1) begin
                  return MbInitRepairMbState_rx::Instance();
               end

               else begin
                  return MbInitReversalMbState_rx::Instance();
               end
            end
            fsm_mbinit_rx_repairmb : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               else if (item_tx_fsm_sb_in.i_tx_decoding == MBINIT_REPAIRMB_TX_Done_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1) begin
                  return mbtrain_rx_valvref::Instance();
                  state_done = 1;
               end

               else begin
                  return MbInitRepairMbState_rx::Instance();
               end
            end
            fsm_rx_trainerror : begin
               // `uvm_info("l1_state_rx", $sformatf("i_reset: %0b, i_sb_cur_msg_done = %0b , i_lp_linkerror = %0b ", item_controllers_in.i_reset,item_controllers_in.i_sb_cur_msg_done, item_rdi_in.i_lp_linkerror), UVM_LOW);
               if (item_controllers_in.i_reset || (item_controllers_in.i_sb_cur_msg_done && !item_rdi_in.i_lp_linkerror && train_end) || sbinit_entry)begin
                  return ResetState_rx::Instance();
               end
               else begin
                  return trainerror_rx::Instance();
               end 
            end
            fsm_mbtrain_rx_valvref : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               else if(item_rx_fsm_sb_in.i_rx_decoding == RX_MBTRAIN_DATAVREF_Start_Handshake && item_rx_fsm_sb_in.i_sb_rx_req==1'b1)begin
                  return mbtrain_rx_datavref::Instance();
               end
               else begin
                  return mbtrain_rx_valvref::Instance();
               end
            end
            fsm_mbtrain_rx_datavref : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               else if(item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_DATAVREF_TX_End_Handshake && state_done && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1)begin
                  return mbtrain_rx_speedidle::Instance();
               end
               else begin
                  return mbtrain_rx_datavref::Instance();
               end
            end
            fsm_mbtrain_rx_dtc1 : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               else if (item_rx_fsm_sb_in.i_rx_decoding == RX_MBTRAIN_DATATRAINVREF_Start_Handshake && item_rx_fsm_sb_in.i_sb_rx_req==1'b1) begin
                  return mbtrain_rx_datatrainvref::Instance();
               end
               else begin
                  return mbtrain_rx_dtc1::Instance();
               end
            end
            fsm_mbtrain_rx_rxclkcal : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               else if (item_rx_fsm_sb_in.i_rx_decoding == RX_MBTRAIN_VALTRAINCENTER_Start_Handshake && item_rx_fsm_sb_in.i_sb_rx_req==1'b1) begin
                  return mbtrain_rx_valtraincenter::Instance();
               end
               else begin
                  return mbtrain_rx_rxclkcal::Instance();
               end
            end
            fsm_mbtrain_rx_valtraincenter : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               else if (item_rx_fsm_sb_in.i_rx_decoding == RX_MBTRAIN_VALTRAINVREF_Start_Handshake && item_rx_fsm_sb_in.i_sb_rx_req==1'b1) begin
                  return mbtrain_rx_valtrainvref::Instance();
               end
               else begin
                  return mbtrain_rx_valtraincenter::Instance();
               end
            end 
            fsm_mbtrain_rx_valtrainvref : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               else if (item_rx_fsm_sb_in.i_rx_decoding == RX_MBTRAIN_DTC1_Start_Handshake && item_rx_fsm_sb_in.i_sb_rx_req==1'b1) begin
                  return mbtrain_rx_dtc1::Instance();
               end
               else begin
                  return mbtrain_rx_valtrainvref::Instance();
               end
            end
            fsm_mbtrain_rx_rxdeskew : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               else if (item_rx_fsm_sb_in.i_rx_decoding == RX_MBTRAIN_DTC2_Start_Handshake && item_rx_fsm_sb_in.i_sb_rx_req==1'b1) begin
                  return mbtrain_rx_dtc2::Instance();
               end
               else begin
                  return mbtrain_rx_rxdeskew::Instance();
               end
            end
            fsm_mbtrain_rx_dtc2 : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               else if (item_rx_fsm_sb_in.i_rx_decoding == RX_MBTRAIN_LINKSPEED_Start_Handshake && item_rx_fsm_sb_in.i_sb_rx_req==1'b1) begin
                  return mbtrain_rx_linkspeed::Instance();
               end
               else begin
                  return mbtrain_rx_dtc2::Instance();
               end
            end
            fsm_mbtrain_rx_datatrainvref : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               else if (item_rx_fsm_sb_in.i_rx_decoding == RX_MBTRAIN_RXDESKEW_Start_Handshake && item_rx_fsm_sb_in.i_sb_rx_req==1'b1) begin
                  return mbtrain_rx_rxdeskew::Instance();
               end
               else begin
                  return mbtrain_rx_datatrainvref::Instance();
               end
            end
            fsm_mbtrain_rx_linkspeed : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               // speedidle
               else if (state_done && item_tx_fsm_sb_in.i_tx_decoding == 'hbe && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1) begin
                  return mbtrain_rx_speedidle::Instance();
               end
               // repair
               else if (item_rx_fsm_sb_in.i_sb_rx_req && item_rx_fsm_sb_in.i_rx_decoding == MBTRAIN_REPAIR_TX_Start_Handshake) begin
                  return mbtrain_rx_repair::Instance();
               end
               // done 
               else if (state_done && item_tx_fsm_sb_in.i_tx_decoding == RX_MBTRAIN_LINKSPEED_Send_Done_RESP && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1) begin
                  return linkinit_state_rx::Instance();
               end
               // phyretrain
               else if (item_rx_fsm_sb_in.i_sb_rx_req && item_rx_fsm_sb_in.i_rx_decoding == PHYRETRAIN_TX_Start_Req_Handshake) begin
                  return phyretrain_rx::Instance();
               end
               else begin
                  return mbtrain_rx_linkspeed::Instance();
               end
            end
            fsm_mbtrain_rx_repair : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               else if (item_rx_fsm_sb_in.i_rx_decoding == RX_MBTRAIN_TXSELFCAL_End_Handshake && item_rx_fsm_sb_in.i_sb_rx_req==1'b1) begin
                  return mbtrain_rx_txselfcal::Instance();
               end
               else begin
                  return mbtrain_rx_repair::Instance();
               end
            end
            fsm_mbtrain_rx_speedidle : begin
            //    `uvm_info("l1_state_rx", $sformatf("i_reset: %0b ", item_controllers_in.i_reset), UVM_LOW);
            //   `uvm_info("l1_state_rx", $sformatf("i_reset_1: %0b ", item_rx_fsm_sb_in.i_reset), UVM_LOW);  
               if (item_rx_fsm_sb_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               else if (item_rx_fsm_sb_in.i_rx_decoding == RX_MBTRAIN_TXSELFCAL_End_Handshake-1 && item_rx_fsm_sb_in.i_sb_rx_req==1'b1) begin
                  return mbtrain_rx_txselfcal::Instance();
               end
               else begin
                  return mbtrain_rx_speedidle::Instance();
               end
            end
            fsm_mbtrain_rx_txselfcal : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               else if (item_rx_fsm_sb_in.i_rx_decoding == RX_MBTRAIN_RXCLKCAL_Start_Handshake && item_rx_fsm_sb_in.i_sb_rx_req==1'b1) begin
                  return mbtrain_rx_rxclkcal::Instance();
               end
               else begin
                  return mbtrain_rx_txselfcal::Instance();
               end
            end
            fsm_rx_phyretrain : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               if(item_tx_fsm_sb_in.i_tx_decoding == PHYRETRAIN_TX_Start_Req_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1)begin
                  if(item_tx_fsm_sb_in.i_tx_info[2:0] == 3'b010) // SPEEDIDLE
                  return mbtrain_rx_speedidle::Instance() ;
               else if(item_tx_fsm_sb_in.i_tx_info[2:0] == 3'b100) // REPAIR
                  return mbtrain_rx_repair::Instance() ;
               else if(item_tx_fsm_sb_in.i_tx_info[2:0] == 3'b001) // TXSELFCAL
                  return mbtrain_rx_txselfcal::Instance() ;
               end
            end
            fsm_rx_l1 : begin
                if (item_controllers_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               else if (item_rdi_in.i_lp_state_req == state_req_active || item_rx_fsm_sb_in.i_rx_decoding == ACTIVE_EXIT_HS_TX_Exit_Handshake && item_rx_fsm_sb_in.i_sb_rx_req)begin
                  return mbtrain_rx_speedidle::Instance();
               end
               else begin
                  return l1_state_rx::Instance();
               end
            end
            fsm_rx_linkinit : begin
                if (item_controllers_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               else if (item_tx_fsm_sb_in.i_tx_decoding == 'h102 && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1)begin
                  return active_state_rx::Instance();
               end
               else begin
                  return linkinit_state_rx::Instance();
               end
            end
            fsm_rx_active : begin
                if (item_controllers_in.i_reset)begin
                  return ResetState_rx::Instance();
               end
               else if ((item_rx_fsm_sb_in.i_rx_decoding == RX_ACTIVE_Active && item_rx_fsm_sb_in.i_sb_rx_req == 1'b1) || (item_rdi_in.i_lp_state_req == state_req_l1))begin
                  return l1_state_rx::Instance();
               end
               else begin
                  return active_state_rx::Instance();
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