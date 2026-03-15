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
    logic  o_rx_sb_rsp_expected;
    logic o_pl_state_sts_exp;
    static logic rx_handshake_done;
    bit match;
    
    local static l1_state_rx inst = null; 
 
    protected function new();   endfunction 
     
    static function l1_state_rx Instance(); 
      if (inst == null) 
        inst = new(); 
      return inst; 
    endfunction 
     
    virtual function bit doSpecificCombAction(FSMContext cntxt, LTSM_controllers_seq_item ctrl_item , ltsm_rdi_sequence_item rdi_item ,rx_fsm_sb_sequence_item  rx_sb_item ,tx_fsm_sb_sequence_item tx_sb_item); 
        if(rdi_item.i_lp_state_req == state_req_l1 && rx_sb_item.i_rx_decoding == ACTIVE_L1_TX_handshake && rx_sb_item.i_sb_rx_req && tx_handshake_done == 1'b1 && cntxt.currentstate_rx == active_state_rx::instance())
        begin
            o_rx_encoding_exp = RX_ACTIVE_L1_Start_HS ;
            o_rx_sb_rsp_expected = 1'b1;
            if(o_rx_encoding_exp == ctrl_item.o_rx_encoding && o_rx_sb_rsp_expected == rx_sb_item.o_sb_rx_rsp )
                match = 1'b1;
            else
            begin
              `uvm_info("l1_state_rx", $sformatf("Expected o_rx_encoding: %b, Expected o_rx_sb_rsp: %b, Expected o_pl_state_sts: %b, Actual o_rx_encoding: %b , Actual o_rx_sb_rsp: %b, Actual o_pl_state_sts: %b", o_rx_encoding_exp, o_rx_sb_rsp_expected, o_pl_state_sts_exp, ctrl_item.o_rx_encoding, rx_sb_item.o_sb_rx_rsp, ctrl_item.o_pl_state_sts), UVM_LOW);
                match = 1'b0;
            end
        end
        else if(rx_sb_item.i_rx_decoding == ACTIVE_L1_TX_L1_State && rx_sb_item.i_sb_rx_done && tx_handshake_done == 1'b1 )      
        begin
            o_rx_encoding_exp = RX_ACTIVE_L1_L1_State  ;
            if(o_rx_encoding_exp == ctrl_item.o_rx_encoding)
                match = 1'b1;
            else
            begin
              `uvm_info("l1_state_rx", $sformatf("Expected o_rx_encoding: %b, Actual o_rx_encoding: %b", o_rx_encoding_exp, ctrl_item.o_rx_encoding), UVM_LOW);
                match = 1'b0;
            end
        end
        else if(rx_sb_item.i_rx_decoding == ACTIVE_L1_TX_handshake && rx_sb_item.i_sb_rx_req && tx_handshake_done == 1'b0 && cntxt.currentstate_rx == active_state_rx::instance())
        begin
            o_rx_encoding_exp =  RX_ACTIVE_L1_Wait1us  ;
            if(o_rx_encoding_exp == ctrl_item.o_rx_encoding)
                match = 1'b1;
            else
            begin
              `uvm_info("l1_state_rx", $sformatf("Expected o_rx_encoding: %b, Actual o_rx_encoding: %b", o_rx_encoding_exp, ctrl_item.o_rx_encoding), UVM_LOW);
                match = 1'b0;
            end
        end
        else if(o_rx_encoding_exp == RX_ACTIVE_L1_Wait1us && rdi_item.i_lp_state_req == state_req_l1 )
        begin
            o_rx_encoding_exp = RX_ACTIVE_L1_L1_State ;
            o_rx_sb_rsp_expected = 1'b1;
            if(o_rx_encoding_exp == ctrl_item.o_rx_encoding && o_rx_sb_rsp_expected == rx_sb_item.o_sb_rx_rsp)
                match = 1'b1;
            else
            begin
              `uvm_info("l1_state_rx", $sformatf("Expected o_rx_encoding: %b, Expected o_rx_sb_rsp: %b,  Actual o_rx_encoding: %b , Actual o_rx_sb_rsp: %b", o_rx_encoding_exp, o_rx_sb_rsp_expected, ctrl_item.o_rx_encoding, rx_sb_item.o_sb_rx_rsp), UVM_LOW);      
                match = 1'b0;
            end
        end
        else if(rx_sb_item.i_rx_decoding == ACTIVE_L1_TX_L1_State && rx_sb_item.i_sb_rx_done )
        begin
            rx_handshake_done = 1'b1; 
        end
        else if(o_rx_encoding_exp == RX_ACTIVE_L1_Wait1us && rdi_item.i_lp_state_req != state_req_l1 )
        begin
            o_rx_encoding_exp =  RX_ACTIVE_L1_Refuse ;
            o_rx_sb_rsp_expected = 1'b1;
            if(o_rx_encoding_exp == ctrl_item.o_rx_encoding && o_rx_sb_rsp_expected == rx_sb_item.o_sb_rx_rsp)
                match = 1'b1;
            else
            begin
              `uvm_info("l1_state_rx", $sformatf("Expected o_rx_encoding: %b, Expected o_rx_sb_rsp: %b,  Actual o_rx_encoding: %b , Actual o_rx_sb_rsp: %b", o_rx_encoding_exp, o_rx_sb_rsp_expected, ctrl_item.o_rx_encoding, rx_sb_item.o_sb_rx_rsp), UVM_LOW);      
                match = 1'b0;
            end
        end
        else if(rx_sb_item.i_rx_decoding == ACTIVE_EXIT_HS_TX_Exit_Handshake && rx_sb_item.i_sb_rx_done)
        begin
            o_rx_encoding_exp = RX_ACTIVE_Active ;
            if(o_rx_encoding_exp == ctrl_item.o_rx_encoding)
                match = 1'b1;
            else
            begin
              `uvm_info("l1_state_rx", $sformatf("Expected o_rx_encoding: %b, Actual o_rx_encoding: %b", o_rx_encoding_exp, ctrl_item.o_rx_encoding), UVM_LOW);
                match = 1'b0;
            end
        end
        else if(rx_sb_item.i_rx_decoding == ACTIVE_EXIT_HS_TX_Exit_Handshake && rx_sb_item.i_sb_rx_req)
        begin
            o_rx_encoding_exp = RX_ACTIVE_L1_Exit_HS ;
            o_rx_sb_rsp_expected = 1'b1;
            if(o_rx_encoding_exp == ctrl_item.o_rx_encoding && o_rx_sb_rsp_expected == rx_sb_item.o_sb_rx_rsp)
                match = 1'b1;
            else
            begin
              `uvm_info("l1_state_rx", $sformatf("Expected o_rx_encoding: %b, Expected o_rx_sb_rsp: %b,  Actual o_rx_encoding: %b , Actual o_rx_sb_rsp: %b", o_rx_encoding_exp, o_rx_sb_rsp_expected, ctrl_item.o_rx_encoding, rx_sb_item.o_sb_rx_rsp), UVM_LOW);      
                match = 1'b0;
            end
        end
        else
            match = 1'b0;
            
            return match;
    endfunction 
 
 
    virtual function fsm_t getStateId();   
      return fsm_rx_l1;     
    endfunction 
  endclass 

