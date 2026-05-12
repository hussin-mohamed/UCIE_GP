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

//------------------------------------------------------------------------------
//
// CLASS: active_state_tx
//description: this class models the active state in tx fsm.
//It sets the expected values of the signals for each sequence in this state and compares with the actual values from the sequence items. 
//If they match, it returns 1 to indicate that the sequence is done and we can move to next sequence/state.
//
//------------------------------------------------------------------------------


 class active_state_tx extends State;
    //output signals
    logic [8:0] o_tx_encoding_exp;
    bit match;

    
    local static active_state_tx inst = null; 

    protected function new();   endfunction 
     
    static function active_state_tx Instance(); 
      if (inst == null) 
        inst = new(); 
      return inst; 
    endfunction 
     
    virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
    if(rx_handshake_done == 1'b1 && tx_handshake_done == 1'b1 && cntxt.currentstate_tx == linkinit_state_tx::Instance()) 
      begin
        o_tx_encoding_exp     = ACTIVE_TX_Active ;
        tx_handshake_done     = 1'b0; // to make sure we only set the expected values once when entering the active state
          if(o_tx_encoding_exp == item_tx_fsm_sb_out.o_tx_encoding)
            match = 1'b1;
          else
          begin
            `uvm_info("active_state_tx", $sformatf("Expected o_tx_encoding: %b, Actual o_tx_encoding: %b", o_tx_encoding_exp, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW);
            match = 1'b0;
          end
      end
      else 
        match = 1'b1;
          
      return match;
    endfunction
 
 
    virtual function fsm_t getStateId();   
      return fsm_tx_active;     
    endfunction 
  endclass 

