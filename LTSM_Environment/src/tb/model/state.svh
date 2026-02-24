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



virtual class State;
    bit match_tx, match_rx, match;
    function bit doAction(FSMContext cntxt,LTSM_controllers_sequence_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                          LTSM_controllers_sequence_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
        State nextState_tx, nextState_rx;
        nextState_tx = StateTransitionUtil::calculate(this, item_controllers_in,item_rdi_in,item_rx_fsm_sb_in,item_tx_fsm_sb_in,item_controllers_out,item_rdi_out,item_rx_fsm_sb_out,item_tx_fsm_sb_out);
        nextState_rx = StateTransitionUtil::calculate(this, item_controllers_in,item_rdi_in,item_rx_fsm_sb_in,item_tx_fsm_sb_in,item_controllers_out,item_rdi_out,item_rx_fsm_sb_out,item_tx_fsm_sb_out);
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
