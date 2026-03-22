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
    logic o_sb_tx_req_expected;
    logic [3:0] o_pl_state_sts_exp;
    bit match;
    
    local static linkinit_state_tx inst = null; 
 
    protected function new();   endfunction 
     
    static function linkinit_state_tx Instance(); 
      if (inst == null) 
        inst = new(); 
      return inst; 
    endfunction 
     
    virtual function bit doSpecificCombAction(FSMContext cntxt, LTSM_controllers_seq_item ctrl_item , ltsm_rdi_sequence_item rdi_item ,rx_fsm_sb_sequence_item  rx_sb_item ,tx_fsm_sb_sequence_item tx_sb_item); 
      if(ctrl_item.i_tx_decoding == RX_MBTRAIN_SPEEDIDLE_End_Handshake && tx_sb_item.i_sb_tx_rsp && cntxt.currentstate_tx == linkspeed_state_tx::instance())
      begin
        o_tx_encoding_exp = ACTIVE_LINKINIT_TX_PL_Clk_Req_Handshake ;
        o_pl_inband_pres_exp = 1'b1;
          if(o_tx_encoding_exp == tx_sb_item.o_tx_encoding && o_pl_inband_pres_exp == rdi_item.o_pl_inband_pres)
            match = 1'b1;
          else
          begin
            `uvm_info("linkinit_state_tx", $sformatf("Expected o_tx_encoding: %b, Actual o_tx_encoding: %b, Expected o_pl_inband_pres: %b, Actual o_pl_inband_pres: %b", o_tx_encoding_exp, tx_sb_item.o_tx_encoding, o_pl_inband_pres_exp, rdi_item.o_pl_inband_pres), UVM_LOW);
            match = 1'b0;
          end
      end
      else if(o_tx_encoding_exp == ACTIVE_LINKINIT_TX_PL_Clk_Req_Handshake && rdi_item.i_lp_clk_ack /*&& rdi_item.i_lp_wake_req */ )
      begin
        o_tx_encoding_exp = ACTIVE_LINKINIT_TX_LP_Wake_Req_Handshake ;
        o_pl_wake_ack_exp = 1'b1;
          if(o_tx_encoding_exp == tx_sb_item.o_tx_encoding && o_pl_wake_ack_exp == rdi_item.o_pl_wake_ack)
            match = 1'b1;
          else
          begin
            `uvm_info("linkinit_state_tx", $sformatf("Expected o_tx_encoding: %b, Actual o_tx_encoding: %b, Expected o_pl_wake_ack: %b, Actual o_pl_wake_ack: %b", o_tx_encoding_exp, tx_sb_item.o_tx_encoding, o_pl_wake_ack_exp, rdi_item.o_pl_wake_ack), UVM_LOW);
            match = 1'b0;
          end
      end
      else if(o_tx_encoding_exp == ACTIVE_LINKINIT_TX_LP_Wake_Req_Handshake && (rdi_item.i_lp_state_req == state_req_active))
      begin
        o_tx_encoding_exp = ACTIVE_LINKINIT_TX_State_Req_Handshake  ;
        o_sb_tx_req_expected = 1'b1 ;
          if(o_tx_encoding_exp == tx_sb_item.o_tx_encoding && o_sb_tx_req_expected == tx_sb_item.o_sb_tx_req)
            match = 1'b1;
            else
          begin
            `uvm_info("linkinit_state_tx", $sformatf("Expected o_tx_encoding: %b, Actual o_tx_encoding: %b, Expected o_sb_tx_req: %b, Actual o_sb_tx_req: %b", o_tx_encoding_exp, ctrl_item.o_tx_encoding, o_sb_tx_req_expected, tx_sb_item.o_sb_tx_req), UVM_LOW);
            match = 1'b0;
          end
      end
      else if (tx_sb_item.i_tx_decoding == RX_ACTIVE_LINKINIT_State_Rsp_Handshake && tx_sb_item.i_sb_tx_rsp && rx_handshake_done ==1'b0 )
      begin
        tx_handshake_done = 1'b1;
      end
       else if (tx_sb_item.i_tx_decoding == RX_ACTIVE_LINKINIT_State_Rsp_Handshake && tx_sb_item.i_sb_tx_rsp && rx_handshake_done ==1'b1 )
      begin
        o_pl_state_sts_exp = state_req_active;
        tx_handshake_done = 1'b1;
        state_done = 1'b1; 
        if(o_tx_encoding_exp == tx_sb_item.o_tx_encoding && o_pl_state_sts_exp == rdi_item.o_pl_state_sts)
            match = 1'b1;
          else
          begin
            `uvm_info("linkinit_state_tx", $sformatf("Expected o_tx_encoding: %b, Actual o_tx_encoding: %b, Expected o_pl_state_sts: %b, Actual o_pl_state_sts: %b", o_tx_encoding_exp, ctrl_item.o_tx_encoding, o_pl_state_sts_exp, rdi_item.o_pl_state_sts), UVM_LOW);
            match = 1'b0;
          end
      end
      else
        match = 1'b0;
        
        return match;
    endfunction 
 
 
    virtual function fsm_t getStateId();   
      return fsm_tx_linkinit;     
    endfunction 
  endclass 
