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
 virtual class State ;
    
    bit match_tx, match_rx, match;
    static int counter;
    static bit train ;
    static bit apply;
    static bit tx_handshake_done;
    static bit rx_handshake_done;
    static logic [15:0] o_error_threshhold_expected;
    static bit retry;
    static bit end_sweep;
    static int error_count;
    static logic [2:0] o_pl_speedmode_expected;
    static logic [2:0] lane_map_tx,lane_map_rx;
    static bit first;
    static bit trainerror;

    static bit tx_done;
    static bit rx_done;

    static logic[2:0]lane_map_code_tx;
    
    StateTransitionUtil_tx st_trans_tx;
    StateTransitionUtil_rx st_trans_rx;
    // function  new();
    //     if (!first) begin
    //         st_trans_tx= new();
    //         st_trans_rx= new();
    //     end
    //     first =1;
    // endfunction
     function bit doAction(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                          LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
        State nextState_tx, nextState_rx;
        fsm_t current_tx,current_rx,next_tx,next_rx;
        //`uvm_info("State", $sformatf("Evaluating state: TX: %s, RX: %s", cntxt.currentstate_tx.getStateId(), cntxt.currentstate_rx.getStateId()), UVM_LOW)
        nextState_tx = StateTransitionUtil_tx::calculate(cntxt, item_controllers_in,item_rdi_in,item_rx_fsm_sb_in,item_tx_fsm_sb_in);
        nextState_rx = StateTransitionUtil_rx::calculate(cntxt, item_controllers_in,item_rdi_in,item_rx_fsm_sb_in,item_tx_fsm_sb_in);
        if ((nextState_rx == cntxt.currentstate_rx ) 
        && cntxt.currentstate_tx != trainerror_tx::Instance() && cntxt.currentstate_rx != trainerror_rx::Instance() 
        && cntxt.currentstate_tx != active_state_tx::Instance() && cntxt.currentstate_rx != active_state_rx::Instance() 
        && cntxt.currentstate_tx != l1_state_tx::Instance() && cntxt.currentstate_rx != l1_state_rx::Instance()) begin
            counter++;  
        end
        // else if (item_controllers_in.i_reset) begin
        //     counter=0;
        // end
        else begin
            counter = 0;
        end
        if (counter == (timeout+1) && cntxt.currentstate_tx != ResetState_tx::Instance()) begin
            nextState_tx = trainerror_tx::Instance();
        end
        if (trainerror && item_controllers_in.i_tx_done && cntxt.currentstate_tx == mbtrain_tx_speedidle::Instance()) begin
            nextState_tx = trainerror_tx::Instance();
        end
        if (error_count == 4 && !item_tx_fsm_sb_in.i_tx_info[4]) begin
            nextState_tx = trainerror_tx::Instance();
            error_count  = 0;
        end
        if ((cntxt.currentstate_tx == mbtrain_tx_linkspeed::Instance() || cntxt.currentstate_rx == mbtrain_rx_linkspeed::Instance() ) && nextState_tx!=nextState_rx) begin
            if (nextState_tx==mbtrain_tx_speedidle::Instance()) begin
                nextState_rx=mbtrain_rx_speedidle::Instance();
            end
            else if (nextState_rx==mbtrain_rx_speedidle::Instance()) begin
                nextState_tx=mbtrain_tx_speedidle::Instance();
            end
        end
        if (cntxt.currentstate_tx == mbtrain_tx_repair::Instance() && apply && lane_map_tx == 3'b000) begin
            nextState_tx = trainerror_tx::Instance();
        end
        if (item_rx_fsm_sb_in.i_rx_decoding == RX_TRAINERROR_Handshake && item_rx_fsm_sb_in.i_sb_rx_req==1'b1) begin
            nextState_rx = trainerror_rx::Instance();
            nextState_tx = trainerror_tx::Instance();
            
        end
        if (cntxt.currentstate_tx != nextState_tx || cntxt.currentstate_rx != nextState_rx) begin
            `uvm_info("state", $sformatf("Current State: TX: %s, RX: %s, Next State: TX: %s, RX: %s", cntxt.currentstate_tx.getStateId(), cntxt.currentstate_rx.getStateId(), nextState_tx.getStateId(), nextState_rx.getStateId()), UVM_MEDIUM)
        end

        // trainerror transitions for initialization states

        if(cntxt.currentstate_tx == MbInitRepairClkState_tx::Instance() &&item_tx_fsm_sb_in.i_tx_decoding =='h22 && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && 
            &item_tx_fsm_sb_in.i_tx_info[2:0] == 1'b0 ) begin
                nextState_tx = trainerror_tx::Instance();
                nextState_rx = trainerror_rx::Instance();
               
            end

        if(cntxt.currentstate_tx == MbInitRepairValState_tx::Instance() &&item_tx_fsm_sb_in.i_tx_decoding =='h2A && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && 
            item_tx_fsm_sb_in.i_tx_info[0] == 1'b0 ) begin
                nextState_tx = trainerror_tx::Instance();
                nextState_rx = trainerror_rx::Instance();
               
            end


        if(cntxt.currentstate_tx == MbInitRepairMbState_tx::Instance() && item_tx_fsm_sb_in.i_tx_decoding == 'h3a && lane_map_code_tx == 3'b000 )begin
                `uvm_info("trainerror_state" , "entered" , UVM_LOW)
                nextState_tx = trainerror_tx::Instance();
                nextState_rx = trainerror_rx::Instance();
                
                
        end
        
        match_tx = nextState_tx.doSpecificCombAction(cntxt, item_controllers_in,item_rdi_in,item_rx_fsm_sb_in,item_tx_fsm_sb_in,item_controllers_out,item_rdi_out,item_rx_fsm_sb_out,item_tx_fsm_sb_out);
        match_rx = nextState_rx.doSpecificCombAction(cntxt, item_controllers_in,item_rdi_in,item_rx_fsm_sb_in,item_tx_fsm_sb_in,item_controllers_out,item_rdi_out,item_rx_fsm_sb_out,item_tx_fsm_sb_out);
        if(nextState_tx == mbtrain_tx_valvref::Instance() || nextState_rx == mbtrain_rx_valvref::Instance()) begin
            match = 1;
        end
        else begin
            match = match_tx & match_rx;
        end
        
      
        

        cntxt.setState(nextState_tx, nextState_rx);
        return match;
 endfunction
 
 pure virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                          LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
 //pure virtual function void doSpecificSeqAction (FSMContext cntxt, Input inputs);
 pure virtual function fsm_t getStateId();
 endclass
