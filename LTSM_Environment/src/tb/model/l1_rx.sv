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
// CLASS: l1_state_rx
//description: this class models the l1 state in rx fsm.
//It sets the expected values of the signals for each sequence in this state and compares with the actual values from the sequence items. 
//If they match, it returns 1 to indicate that the sequence is done and we can move to next sequence/state.
//
//------------------------------------------------------------------------------


 class l1_state_rx extends State;
    //output signals
    logic [8:0] o_rx_encoding_exp;
    logic tx_handshake_done;
    
    local static l1_state_rx inst = null; 
 
    protected function new();   endfunction 
     
    static function l1_state_rx Instance(); 
      if (inst == null) 
        inst = new(); 
      return inst; 
    endfunction 
     
    virtual function bit doSpecificCombAction(FSMContext cntxt, LTSM_controllers_seq_item ctrl_item , ltsm_rdi_sequence_item rdi_item ,rx_fsm_sb_sequence_item  rx_sb_item ,tx_fsm_sb_sequence_item tx_sb_item); 
        if(rdi_item.i_lp_state_req == 4'b0100 && tx_handshake_done == 1'b1 && /*&& RSP.L1*/)
        begin
            o_rx_encoding_exp = RX_ACTIVE_L1_Start_HS ;
            if(o_rx_encoding_exp == ctrl_item.o_rx_encoding)
            return 1'b1;
        end
        else if(o_rx_encoding_exp == RX_ACTIVE_L1_Start_HS && rx_sb_item.i_sb_rx_done )      
        begin
            o_rx_encoding_exp = RX_ACTIVE_L1_L1_State  ;
            if(o_rx_encoding_exp == ctrl_item.o_rx_encoding)
            return 1'b1;
        end
        else if(rdi_item.i_lp_state_req == 4'b0100 && tx_handshake_done == 1'b0)
        begin
            o_rx_encoding_exp =  RX_ACTIVE_L1_Wait1us  ;
            if(o_rx_encoding_exp == ctrl_item.o_rx_encoding)
            return 1'b1;
        end
        else if(o_rx_encoding_exp == RX_ACTIVE_L1_Wait1us && rdi_item.i_lp_state_req == 4'b0100)
        begin
            o_rx_encoding_exp = RX_ACTIVE_L1_L1_State ;
            if(o_rx_encoding_exp == ctrl_item.o_rx_encoding)
            return 1'b1;
        end
        else if(o_rx_encoding_exp == RX_ACTIVE_L1_Wait1us && rdi_item.i_lp_state_req != 4'b0100)
        begin
            o_rx_encoding_exp =  RX_ACTIVE_L1_Refuse ;
            if(o_rx_encoding_exp == ctrl_item.o_rx_encoding)
            return 1'b1;
        end
        else if(o_rx_encoding_exp == RX_ACTIVE_L1_Refuse && rx_sb_item.i_sb_rx_done)
        begin
            o_rx_encoding_exp = RX_ACTIVE_Active ;
            if(o_rx_encoding_exp == ctrl_item.o_rx_encoding)
            return 1'b1;
        end
        else
            return 1'b0;
  
    endfunction 
 
 
    virtual function fsm_t getStateId();   
      return fsm_rx_l1;     
    endfunction 
  endclass 

