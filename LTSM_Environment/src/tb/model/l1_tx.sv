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
// CLASS: l1_state_tx
//description: this class models the l1 state in tx fsm.
//It sets the expected values of the signals for each sequence in this state and compares with the actual values from the sequence items. 
//If they match, it returns 1 to indicate that the sequence is done and we can move to next sequence/state.
//
//------------------------------------------------------------------------------


 class l1_state_tx extends State;
    //output signals
    logic [8:0] o_tx_encoding_exp;
    logic rx_handshake_done;

    
    local static l1_state_tx inst = null; 
 
    protected function new();   endfunction 
     
    static function l1_state_tx Instance(); 
      if (inst == null) 
        inst = new(); 
      return inst; 
    endfunction 
     
    virtual function bit doSpecificCombAction(FSMContext cntxt, LTSM_controllers_seq_item ctrl_item , ltsm_rdi_sequence_item rdi_item ,rx_fsm_sb_sequence_item  rx_sb_item ,tx_fsm_sb_sequence_item tx_sb_item); 
        if(rdi_item.i_lp_state_req == 4'b0100 && rx_handshake_done == 1'b0)
        begin
            o_tx_encoding_exp = ACTIVE_L1_TX_handshake ;
            if(o_tx_encoding_exp == ctrl_item.o_tx_encoding)
            return 1'b1;
        end
        else if(o_tx_encoding_exp == ACTIVE_L1_TX_handshake && rx_sb_item.i_sb_rx_done /*&& RSP.L1*/)      
        begin
            o_tx_encoding_exp = ACTIVE_L1_TX_L1_State;
            if(o_tx_encoding_exp == ctrl_item.o_tx_encoding)
            return 1'b1;
        end
        else if(o_tx_encoding_exp == ACTIVE_L1_TX_handshake /*&& RSP.PMNAK*/)
        begin
            o_tx_encoding_exp =  ACTIVE_TX_Active ;
            if(o_tx_encoding_exp == ctrl_item.o_tx_encoding)
            return 1'b1;
        end
        else if(rdi_item.i_lp_state_req == 4'b0100 && rx_handshake_done == 1'b1)
        begin
            o_tx_encoding_exp = ACTIVE_L1_TX_handshake ;
            if(o_tx_encoding_exp == ctrl_item.o_tx_encoding)
            return 1'b1;
        end
        else if(o_tx_encoding_exp == ACTIVE_L1_TX_handshake && tx_sb_item.i_sb_tx_rsp && rx_handshake_done == 1'b1 /*&& RSP.L1*/ )      
        begin
            o_tx_encoding_exp = ACTIVE_L1_TX_L1_State;
            o_tx_sb_done_exp = 1'b1;
             if(o_tx_encoding_exp == ctrl_item.o_tx_encoding && o_tx_sb_done_exp == tx_sb_item.i_sb_tx_done)
            if(o_tx_encoding_exp == ctrl_item.o_tx_encoding)
            return 1'b1;
        end
        else if(rdi_item.i_lp_state_req == 4'b0001)
        begin
            o_tx_encoding_exp = ACTIVE_EXIT_HS_TX_Exit_Handshake;
            if(o_tx_encoding_exp == ctrl_item.o_tx_encoding)
            return 1'b1;
        end
        else 
            return 1'b0;       
    endfunction 
 
 
    virtual function fsm_t getStateId();   
      return fsm_tx_l1;     
    endfunction 
  endclass 
