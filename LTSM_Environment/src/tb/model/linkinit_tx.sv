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
// CLASS: linkinit_state_tx
//description: this class models the linkinit state in tx fsm.
//It sets the expected values of the signals for each sequence in this state and compares with the actual values from the sequence items. 
//If they match, it returns 1 to indicate that the sequence is done and we can move to next sequence/state.
//
//------------------------------------------------------------------------------


 class linkinit_state_tx extends State;
    //output signals
    logic [8:0] o_tx_encoding_exp;
    logic o_pl_inband_pres_exp;
    logic o_pl_wake_ack_exp;
    
    local static linkinit_state_tx inst = null; 
 
    protected function new();   endfunction 
     
    static function linkinit_state_tx Instance(); 
      if (inst == null) 
        inst = new(); 
      return inst; 
    endfunction 
     
    virtual function bit doSpecificCombAction(FSMContext cntxt, LTSM_controllers_seq_item ctrl_item , ltsm_rdi_sequence_item rdi_item ,rx_fsm_sb_sequence_item  rx_sb_item ,tx_fsm_sb_sequence_item tx_sb_item); 
      if(/*previous state done sequence*/)
      begin
        o_tx_encoding_exp = ACTIVE_LINKINIT_TX_PL_Clk_Req_Handshake ;
        o_pl_inband_pres_exp = 1'b1;
        if(o_tx_encoding_exp == ctrl_item.o_tx_encoding && o_pl_inband_pres_exp == ctrl_item.o_pl_inband_pres)
          return 1'b1;
      end
      else if(ctrl_item.o_tx_encoding == ACTIVE_LINKINIT_TX_PL_Clk_Req_Handshake && rdi_item.i_lp_clk_ack  )
      begin
        o_tx_encoding_exp = ACTIVE_LINKINIT_TX_LP_Wake_Req_Handshake ;
        o_pl_wake_ack_exp = 1'b1;
        if(o_tx_encoding_exp == ctrl_item.o_tx_encoding && o_pl_wake_ack_exp == ctrl_item.o_pl_wake_ack)
          return 1'b1;
      end
      else if(ctrl_item.o_tx_encoding == ACTIVE_LINKINIT_TX_LP_Wake_Req_Handshake && (rdi_item.i_lp_state_req == 4'b0001))
      begin
        o_tx_encoding_exp = ACTIVE_LINKINIT_TX_State_Req_Handshake  ;
        if(o_tx_encoding_exp == ctrl_item.tx_encoding)
          return 1'b1;
      end 
      else if(ctrl_item.o_tx_encoding == ACTIVE_LINKINIT_TX_State_Req_Handshake  && tx_sb_item.i_sb_tx_done) 
      begin
        o_tx_encoding = /*next state*/ ;
      end  
      else
        return 1'b0;
    endfunction 
 
 
    virtual function fsm_t getStateId();   
      return fsm_tx_linkinit;     
    endfunction 
  endclass 