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
virtual class State extends uvm_object;
    `uvm_object_utils(State)
    bit match_tx, match_rx, match;
    int counter;
    static bit train ;
    static bit apply;
    static bit retry;
    static bit end_sweep;
    static int error_count;
    static logic [2:0] lane_map;
    StateTransitionUtil_tx st_trans_tx;
    StateTransitionUtil_rx st_trans_rx;
    st_trans_tx = new();
    st_trans_rx = new();
    function new(string name = "State" );
        super.new(name);
    endfunction
    function bit doAction(FSMContext cntxt,LTSM_controllers_sequence_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                          LTSM_controllers_sequence_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
        State nextState_tx, nextState_rx;
        nextState_tx = st_trans_tx.calculate(cntxt, item_controllers_in,item_rdi_in,item_rx_fsm_sb_in,item_tx_fsm_sb_in);
        nextState_rx = st_trans_rx.calculate(cntxt, item_controllers_in,item_rdi_in,item_rx_fsm_sb_in,item_tx_fsm_sb_in);
        if ((nextstate_rx == cntxt.currentState_rx || nextState_tx == cntxt.currentState_tx || nextstate_tx == data_to_clock_sweep::Instance() || nextstate_rx == data_to_clock_sweep::Instance() ) 
        && cntxt.currentState_tx != trainerror_tx::Instance() && cntxt.currentState_rx != trainerror_rx::Instance() && cntxt.currentState_rx != ResetState_rx::Instance()
        && cntxt.currentState_tx != ResetState_tx::Instance()&& cntxt.currentState_tx != active_tx::Instance() && cntxt.currentState_rx != active_rx::Instance() 
        && cntxt.currentState_tx != l1_state_tx::Instance() && cntxt.currentState_rx != l1_state_rx::Instance()) begin
            counter++;  
        end
        else begin
            counter = 0;
        end
        if (counter == timeout) begin
            nextState_tx = trainerror_tx::Instance();
        end
        if ((nextState_tx==mbtrain_tx_speedidle::Instance() || nextState_rx==mbtrain_rx_speedidle::Instance()) && 
        (cntxt.currentState_tx == mbtrain_tx_linkspeed::Instance() || cntxt.currentState_tx == phyretrain_tx::Instance() || cntxt.currentState_rx == mbtrain_rx_linkspeed::Instance() || cntxt.currentState_rx == phyretrain_rx::Instance() ) &&
        /*speed 2a2al haga*/) begin
            nextState_tx = trainerror_tx::Instance();
        end
        if (error_count == 2 && !item_tx_fsm_sb_in.i_tx_info[4]) begin
            nextState_tx = trainerror_tx::Instance();
            error_count  = 0;
        end
        if ((cntxt.currentState_tx == mbtrain_tx_linkspeed::Instance() || cntxt.currentState_rx == mbtrain_rx_linkspeed::Instance() ) && nextState_tx!=nextState_rx) begin
            if (nextState_tx==mbtrain_tx_speedidle::Instance()) begin
                nextState_rx==mbtrain_rx_speedidle::Instance()
            end
            else if (nextState_rx==mbtrain_rx_speedidle::Instance()) begin
                nextState_tx==mbtrain_tx_speedidle::Instance()
            end
        end
        if (cntxt.currentState_tx == mbtrain_tx_repair::Instance() && apply && lane_map == 3'b000) begin
            nextState_tx = trainerror_tx::Instance();
        end
        if (item_rx_fsm_sb_in.i_rx_decoding == RX_TRAINERROR_Handshake && item_rx_fsm_sb_in.i_sb_rx_req==1'b1) begin
            nextState_rx = trainerror_rx::Instance();
        end
        match_tx = nextState_tx.doSpecificCombAction(cntxt, item_controllers_in,item_rdi_in,item_rx_fsm_sb_in,item_tx_fsm_sb_in,item_controllers_out,item_rdi_out,item_rx_fsm_sb_out,item_tx_fsm_sb_out);
        match_rx = nextState_rx.doSpecificCombAction(cntxt, item_controllers_in,item_rdi_in,item_rx_fsm_sb_in,item_tx_fsm_sb_in,item_controllers_out,item_rdi_out,item_rx_fsm_sb_out,item_tx_fsm_sb_out);
        match = match_tx & match_rx;
        cntxt.setState(nextState_tx, nextState_rx);
        return match;
 endfunction
 pure virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_sequence_item item_controllers,ltsm_rdi_sequence_item item_rdi,rx_fsm_sb_sequence_item item_rx_fsm_sb,tx_fsm_sb_sequence_item item_tx_fsm_sb);
 //pure virtual function void doSpecificSeqAction (FSMContext cntxt, Input inputs);

 pure virtual function fsm_t getStateId();
 endclass
