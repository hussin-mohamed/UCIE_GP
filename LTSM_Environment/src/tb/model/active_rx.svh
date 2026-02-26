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
// CLASS: active_state_rx
//description: this class models the active state in rx fsm.
//It sets the expected values of the signals for each sequence in this state and compares with the actual values from the sequence items. 
//If they match, it returns 1 to indicate that the sequence is done and we can move to next sequence/state.
//
//------------------------------------------------------------------------------


 class active_state_rx extends State;
    //output signals
    logic [8:0] o_rx_encoding_exp;
    bit match;

    
    local static active_state_rx inst = null; 

    protected function new();   endfunction 
     
    static function active_state_rx Instance(); 
      if (inst == null) 
        inst = new(); 
      return inst; 
    endfunction 
     
    virtual function bit doSpecificCombAction(FSMContext cntxt, LTSM_controllers_seq_item ctrl_item , ltsm_rdi_sequence_item rdi_item ,rx_fsm_sb_sequence_item  rx_sb_item ,tx_fsm_sb_sequence_item tx_sb_item); 
    o_rx_encoding_exp = RX_ACTIVE_Active ;
        if(o_rx_encoding_exp == ctrl_item.o_rx_encoding)
            match = 1'b1;
        else 
        begin
          `uvm_info("active_state_rx", $sformatf("Expected o_rx_encoding: %b, Actual o_rx_encoding: %b", o_rx_encoding_exp, ctrl_item.o_rx_encoding), UVM_LOW);
            match = 1'b0;
        end 
            return match;
    endfunction 
 
 
    virtual function fsm_t getStateId();   
      return fsm_rx_active;     
    endfunction 
  endclass 
