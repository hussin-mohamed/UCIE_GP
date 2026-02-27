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
class StateTransitionUtil_tx extends uvm_object;
 `uvm_object_utils(StateTransitionUtil_tx)
 local static State validStateTransitions[State][$];
 local static CovergroupWrapper cgWrapper;

   function new(string name = "StateTransitionUtil_rx" );
        super.new(name);
        init();
 endfunction

 static function void init();

    validStateTransitions[ResetState_tx::Instance()] = { ResetState_tx::Instance(), SbInitState_tx::Instance()};
    
    validStateTransitions[SbInitState_tx::Instance()] = { SbInitState_tx::Instance(), MbInitParamState_tx::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[MbInitParamState_tx::Instance()] = { MbInitParamState_tx::Instance(), MbInitCalState_tx::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[MbInitCalState_tx::Instance()] = { MbInitCalState_tx::Instance(), MbInitRepairClkState_tx::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[MbInitRepairClkState_tx::Instance()] = { MbInitRepairClkState_tx::Instance(), MbInitRepairValState_tx::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[MbInitRepairValState_tx::Instance()] = { MbInitRepairValState_tx::Instance(), MbInitReversalMbState_tx::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[MbInitReversalMbState_tx::Instance()] = { MbInitReversalMbState_tx::Instance(), MbInitRepairMbState_tx::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[MbInitRepairMbState_tx::Instance()] = { MbInitRepairMbState_tx::Instance(), mbtrain_tx_valvref::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_valvref::Instance()] = { mbtrain_tx_valvref::Instance(), data_to_clock_sweep::Instance(), mbtrain_tx_datavref::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_datavref::Instance()] = { mbtrain_tx_datavref::Instance(), data_to_clock_sweep::Instance(), mbtrain_tx_speedidle::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_speedidle::Instance()] = { mbtrain_tx_speedidle::Instance(), mbtrain_tx_txselfcal::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_txselfcal::Instance()] = { mbtrain_tx_txselfcal::Instance(), mbtrain_tx_rxclkcal::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_rxclkcal::Instance()] = { mbtrain_tx_rxclkcal::Instance(), mbtrain_tx_valtraincenter::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_valtraincenter::Instance()] = { mbtrain_tx_valtraincenter::Instance(), data_to_clock_sweep::Instance(), mbtrain_tx_valtrainvref::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};

    validStateTransitions[mbtrain_tx_valtrainvref::Instance()] = { mbtrain_tx_valtrainvref::Instance(), data_to_clock_sweep::Instance(), mbtrain_tx_dtc1::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_dtc1::Instance()] = { mbtrain_tx_dtc1::Instance(), data_to_clock_sweep::Instance(), mbtrain_tx_datatrainvref::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_datatrainvref::Instance()] = { mbtrain_tx_datatrainvref::Instance(), data_to_clock_sweep::Instance(), mbtrain_tx_rxdeskew::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_rxdeskew::Instance()] = { mbtrain_tx_rxdeskew::Instance(), data_to_clock_sweep::Instance(), mbtrain_tx_dtc2::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_dtc2::Instance()] = { mbtrain_tx_dtc2::Instance(), data_to_clock_sweep::Instance(), mbtrain_tx_linkspeed::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_linkspeed::Instance()] = { mbtrain_tx_linkspeed::Instance(), data_to_clock_sweep::Instance(), mbtrain_tx_repair::Instance(), phyretrain_tx::Instance(), linkinit_state_tx::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[mbtrain_tx_repair::Instance()] = { mbtrain_tx_repair::Instance(), mbtrain_tx_txselfcal::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[phyretrain_tx::Instance()] = { phyretrain_tx::Instance(), mbtrain_tx_txselfcal::Instance(), mbtrain_tx_speedidle::Instance(), mbtrain_tx_repair::Instance() , trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[linkinit_state_tx::Instance()] = { linkinit_state_tx::Instance(), active_tx::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    validStateTransitions[active_tx::Instance()] = { active_tx::Instance(), trainerror_tx::Instance(), ResetState_tx::Instance()};

    validStateTransitions[l1_state_tx::Instance()] = { l1_state_tx::Instance(), mbtrain_tx_speedidle::Instance(), ResetState_tx::Instance()};

    validStateTransitions[trainerror_tx::Instance()] = { trainerror_tx::Instance(), ResetState_tx::Instance()};
    
    cgWrapper = new();
 endfunction

 static function State calculate(FSMContext cntxt,LTSM_controllers_sequence_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in);
 State nextState = null;
 State nextValid[$];

 nextState = calculateNextState(cntxt,item_controllers_in,item_rdi_in,item_rx_fsm_sb_in,item_tx_fsm_sb_in);

 nextValid = validStateTransitions[cntxt.currentState_tx].find(x) with ( x == nextState );
 if (nextValid.size() != 0) begin
 cgWrapper.sample(cntxt.currentState_tx.getStateId(), nextState.getStateId());
 return nextState;
 end
 else begin
 `uvm_error($sformatf("Invalid state transition from state %0d to state %0d", cntxt.currentState_tx.getStateId(), nextState.getStateId()));
 end
 endfunction

 static function State calculateNextState(FSMContext cntxt,LTSM_controllers_sequence_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in);
        case (cntxt.currentState_tx.getStateId())
            fsm_tx_reset: begin
               if (item_controllers_in.i_power && item_controllers_in.i_pll_stable && !item_controllers_in.i_reset) begin
                  return SbInitState_tx::Instance();
               end
               else begin
                  return ResetState_tx::Instance();
               end
            end
            fsm_rx_sbinit: begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
               else if (item_controllers_in.o_rx_encoding == 'h9 && item_rx_fsm_sb_in.i_sb_rx_done == 1'b1) begin
                  return MbInitParamState_tx::Instance();
               end
               else begin
                  return SbInitState_tx::Instance();
               end
            end
            fsm_mbinit_tx_param : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
            end
            fsm_mbinit_tx_cal : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
            end
            fsm_mbinit_tx_repairclk : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
            end
            fsm_mbinit_tx_repairval : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
            end
            fsm_mbinit_tx_reversal : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
            end
            fsm_mbinit_tx_repairmb : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
            end
            fsm_tx_trainerror : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
            end
            fsm_mbtrain_tx_valvref : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
            end
            fsm_mbtrain_tx_datavref : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
            end
            fsm_mbtrain_tx_dtc1 : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
            end
            fsm_mbtrain_tx_rxclkcal : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
            end
            fsm_mbtrain_tx_valtraincenter : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
            end 
            fsm_mbtrain_tx_rxdeskew : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
            end
            fsm_mbtrain_tx_dtc2 : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
            end
            fsm_mbtrain_tx_datatrainvref : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
            end
            fsm_mbtrain_tx_linkspeed : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
            end
            fsm_mbtrain_tx_repair : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
            end
            fsm_mbtrain_tx_speedidle : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
            end
            fsm_mbtrain_tx_txselfcal : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
            end
            fsm_tx_phyretrain : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
            end
            fsm_tx_linkinit : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
            end
            fsm_tx_active : begin
               if (item_controllers_in.i_reset)begin
                  return ResetState_tx::Instance();
               end
            end
            default: 
        endcase
  endfunction
 endclass