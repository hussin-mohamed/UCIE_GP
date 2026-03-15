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
    logic o_tx_sb_req_expected;
    static logic tx_handshake_done;
    bit match;

    
    local static l1_state_tx inst = null; 
 
    protected function new();   endfunction 
     
    static function l1_state_tx Instance(); 
      if (inst == null) 
        inst = new(); 
      return inst; 
    endfunction 
     
    virtual function bit doSpecificCombAction(FSMContext cntxt, LTSM_controllers_seq_item ctrl_item , ltsm_rdi_sequence_item rdi_item ,rx_fsm_sb_sequence_item  rx_sb_item ,tx_fsm_sb_sequence_item tx_sb_item); 
        if(rdi_item.i_lp_state_req == state_req_l1 && cntxt.currentstate_tx == active_state_tx::instance())
        begin
            o_tx_encoding_exp = ACTIVE_L1_TX_handshake ;
            o_tx_sb_req_expected = 1'b1;

                if(o_tx_encoding_exp == ctrl_item.o_tx_encoding && o_tx_sb_req_expected == tx_sb_item.o_tx_sb_req)
                    match = 1'b1;
                else
                begin
                  `uvm_info("l1_state_tx", $sformatf("Expected o_tx_encoding: %b, Actual o_tx_encoding: %b, Expected o_tx_sb_req: %b, Actual o_tx_sb_req: %b", o_tx_encoding_exp, ctrl_item.o_tx_encoding, o_tx_sb_req_expected, tx_sb_item.o_tx_sb_req), UVM_LOW);
                    match = 1'b0;
                end
        end
         else if(tx_sb_item.i_tx_decoding == RX_ACTIVE_L1_L1_State  && rx_sb_item.i_sb_rx_rsp && rx_handshake_done == 1'b0)      
        begin
            tx_handshake_done = 1'b1;
        end   
        else if(tx_sb_item.i_tx_decoding == RX_ACTIVE_L1_L1_State  && rx_sb_item.i_sb_rx_done && rx_handshake_done == 1'b0)      
        begin
            o_tx_encoding_exp = ACTIVE_L1_TX_L1_State;
                if(o_tx_encoding_exp == ctrl_item.o_tx_encoding)
                    match = 1'b1;
                else
                begin
                  `uvm_info("l1_state_tx", $sformatf("Expected o_tx_encoding: %b, Actual o_tx_encoding: %b", o_tx_encoding_exp, ctrl_item.o_tx_encoding), UVM_LOW);
                    match = 1'b0;
                end
        end
        else if(tx_sb_item.i_tx_decoding == RX_ACTIVE_L1_L1_State  && rx_sb_item.i_sb_tx_rsp && rx_handshake_done == 1'b1)      
        begin
            o_tx_encoding_exp = ACTIVE_L1_TX_L1_State;
                if(o_tx_encoding_exp == ctrl_item.o_tx_encoding)
                    match = 1'b1;
                else
                begin
                  `uvm_info("l1_state_tx", $sformatf("Expected o_tx_encoding: %b, Actual o_tx_encoding: %b", o_tx_encoding_exp, ctrl_item.o_tx_encoding), UVM_LOW);
                    match = 1'b0;
                end
        end
        else if( tx_sb_item.i_tx_decoding == RX_ACTIVE_L1_Refuse && tx_sb_item.i_sb_tx_rsp )
        begin
            o_tx_encoding_exp =  ACTIVE_TX_Active ;
                if(o_tx_encoding_exp == ctrl_item.o_tx_encoding)
                    match = 1'b1;
                else
                begin
                  `uvm_info("l1_state_tx", $sformatf("Expected o_tx_encoding: %b, Actual o_tx_encoding: %b", o_tx_encoding_exp, ctrl_item.o_tx_encoding), UVM_LOW);
                    match = 1'b0;
                end
        end  
        else if(rdi_item.i_lp_state_req == state_req_active && cntxt.currentstate_tx == l1_state_tx::instance())
        begin
            o_tx_encoding_exp = ACTIVE_EXIT_HS_TX_Exit_Handshake;
            o_tx_sb_req_expected = 1'b1;
                if(o_tx_encoding_exp == ctrl_item.o_tx_encoding )
                    match = 1'b1;
                else
                begin
                  `uvm_info("l1_state_tx", $sformatf("Expected o_tx_encoding: %b, Actual o_tx_encoding: %b, Expected o_tx_sb_done: %b, Actual o_tx_sb_done: %b", o_tx_encoding_exp, ctrl_item.o_tx_encoding, o_tx_sb_done_exp, tx_sb_item.o_tx_sb_done), UVM_LOW);
                    match = 1'b0;
                end
        end
        else if(tx_sb_item.i_tx_decoding == ACTIVE_EXIT_HS_TX_Exit_Handshake && tx_sb_item.i_sb_rx_done && rx_handshake_done == 1'b1)
        begin
            o_tx_encoding_exp = ACTIVE_TX_Active ;
                if(o_tx_encoding_exp == ctrl_item.o_tx_encoding)
                    match = 1'b1;
                else
                begin
                  `uvm_info("l1_state_tx", $sformatf("Expected o_tx_encoding: %b, Actual o_tx_encoding: %b", o_tx_encoding_exp, ctrl_item.o_tx_encoding), UVM_LOW);
                    match = 1'b0;
                end
        end
            return match;       
    endfunction 
 
 
    virtual function fsm_t getStateId();   
      return fsm_tx_l1;     
    endfunction 
  endclass 
