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
  
class FSMContext extends uvm_object;
    
    `uvm_object_utils(FSMContext)
    State currentstate_tx, currentstate_rx;
    bit  match;
    function new( string name = "FSMContext" );
        super.new(name);
        `uvm_info("FSMContext", "Creating FSMContext object", UVM_LOW)
        //currentstate_tx = new();
        currentstate_tx = ResetState_tx::Instance();
        currentstate_rx = ResetState_rx::Instance();
        `uvm_info("FSMContext", "Initialized current states to ResetState_rx", UVM_LOW)
    endfunction

    function void setState(State s_tx, State s_rx);
        currentstate_tx = s_tx;
        currentstate_rx = s_rx;
    endfunction

    function bit doAction(LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
        //`uvm_info("FSMContext", $sformatf("Performing action for current state: TX: %s, RX: %s", currentstate_tx.getStateId(), currentstate_rx.getStateId()), UVM_LOW)
        match = currentstate_tx.doAction(this, item_controllers_in,item_rdi_in,item_rx_fsm_sb_in,item_tx_fsm_sb_in,item_controllers_out,item_rdi_out,item_rx_fsm_sb_out,item_tx_fsm_sb_out);
        return match;
    endfunction
 endclass