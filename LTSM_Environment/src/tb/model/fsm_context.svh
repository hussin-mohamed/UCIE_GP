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


class FSMContext;
    local state_t currentState;
    bit match;
    function new(state_t initialState);
        currentState = initialState;
    endfunction

    function void setState(state_t s);
        currentState = s;
    endfunction

    function bit doAction(LTSM_controllers_sequence_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,LTSM_controllers_sequence_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
        match = currentState.doAction(this, item_controllers_in,item_rdi_in,item_rx_fsm_sb_in,item_tx_fsm_sb_in,item_controllers_out,item_rdi_out,item_rx_fsm_sb_out,item_tx_fsm_sb_out);
        return match;
    endfunction
 endclass