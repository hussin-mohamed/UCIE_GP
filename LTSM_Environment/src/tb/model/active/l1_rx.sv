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
    bit match;
    
    local static l1_state_rx inst = null; 
 
    protected function new();   endfunction 
     
    static function l1_state_rx Instance(); 
      if (inst == null) 
        inst = new(); 
      return inst; 
    endfunction 
     
    virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out); 
        if(item_rdi_in.i_lp_state_req == state_req_l1 && item_rx_fsm_sb_in.i_rx_decoding == ACTIVE_L1_TX_handshake && item_rx_fsm_sb_in.i_sb_rx_req && tx_handshake_done == 1'b1 && cntxt.currentstate_rx == active_state_rx::Instance())
        begin
            o_rx_encoding_exp       = RX_ACTIVE_L1_Start_HS ;
            o_rx_sb_rsp_expected    = 1'b1;
            rx_handshake_done       = 1'b0; 
        
            if(o_rx_encoding_exp == item_rx_fsm_sb_out.o_rx_encoding && o_rx_sb_rsp_expected == item_rx_fsm_sb_out.o_rx_sb_rsp )
                match = 1'b1;
            else
            begin
              `uvm_info("l1_state_rx", $sformatf("Expected o_rx_encoding: %b, Expected o_rx_sb_rsp: %b, Expected o_pl_state_sts: %b, Actual o_rx_encoding: %b , Actual o_rx_sb_rsp: %b, Actual o_pl_state_sts: %b", o_rx_encoding_exp, o_rx_sb_rsp_expected, o_pl_state_sts_exp, item_rx_fsm_sb_out.o_rx_encoding, item_rx_fsm_sb_out.o_rx_sb_rsp, item_rdi_out.o_pl_state_sts), UVM_LOW);
                match = 1'b0;
            end
        end
        else if(item_rx_fsm_sb_in.i_rx_decoding == ACTIVE_L1_TX_L1_State && item_rx_fsm_sb_in.i_sb_rx_done )      
        begin
            o_rx_encoding_exp       = RX_ACTIVE_L1_L1_State  ;
            rx_handshake_done       = 1'b0;
            `uvm_info("l1_state_rx", $sformatf("expected rx_handshake_done: %b, expected o_rx_sb_rsp: %b", rx_handshake_done, o_rx_sb_rsp_expected), UVM_LOW);  
            if(o_rx_encoding_exp == item_rx_fsm_sb_out.o_rx_encoding)
                match = 1'b1;
            else
            begin
              `uvm_info("l1_state_rx", $sformatf("Expected o_rx_encoding: %b, Actual o_rx_encoding: %b", o_rx_encoding_exp, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW);
                match = 1'b0;
            end
        end

        //////////////////////remote die initiates the handshake//////////////////////
        
        else if(item_rx_fsm_sb_in.i_rx_decoding == ACTIVE_L1_TX_handshake && item_rx_fsm_sb_in.i_sb_rx_req && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b0 && cntxt.currentstate_rx == active_state_rx::Instance())
        begin
            o_rx_encoding_exp       =  RX_ACTIVE_L1_Wait1us  ;
            if(o_rx_encoding_exp == item_rx_fsm_sb_out.o_rx_encoding)
                match = 1'b1;
            else
            begin
              `uvm_info("l1_state_rx", $sformatf("Expected o_rx_encoding: %b, Actual o_rx_encoding: %b", o_rx_encoding_exp, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW);
                match = 1'b0;
            end
        end
        else if(o_rx_encoding_exp == RX_ACTIVE_L1_Wait1us && item_rdi_in.i_lp_state_req == state_req_l1 )
        begin
            o_rx_encoding_exp       = RX_ACTIVE_L1_L1_State ;
            o_rx_sb_rsp_expected    = 1'b1;
            rx_handshake_done       = 1'b1;
            if(o_rx_encoding_exp == item_rx_fsm_sb_out.o_rx_encoding && o_rx_sb_rsp_expected == item_rx_fsm_sb_out.o_rx_sb_rsp)
                match = 1'b1;
            else
            begin
              `uvm_info("l1_state_rx", $sformatf("Expected o_rx_encoding: %b, Expected o_rx_sb_rsp: %b,  Actual o_rx_encoding: %b , Actual o_rx_sb_rsp: %b", o_rx_encoding_exp, o_rx_sb_rsp_expected, item_rx_fsm_sb_out.o_rx_encoding, item_rx_fsm_sb_out.o_rx_sb_rsp), UVM_LOW);      
                match = 1'b0;
            end
        end
        else if(o_rx_encoding_exp == RX_ACTIVE_L1_Wait1us && item_rdi_in.i_lp_state_req != state_req_l1 )
        begin
            o_rx_encoding_exp       =  RX_ACTIVE_L1_Refuse ;
            o_rx_sb_rsp_expected    = 1'b1;
            rx_handshake_done       = 1'b0;
             if(o_rx_encoding_exp == item_rx_fsm_sb_out.o_rx_encoding && o_rx_sb_rsp_expected == item_rx_fsm_sb_out.o_rx_sb_rsp)
                match = 1'b1;
            else
            if(o_rx_encoding_exp == item_rx_fsm_sb_out.o_rx_encoding && o_rx_sb_rsp_expected == item_rx_fsm_sb_out.o_rx_sb_rsp)
                match = 1'b1;
            else
            begin
              `uvm_info("l1_state_rx", $sformatf("Expected o_rx_encoding: %b, Expected o_rx_sb_rsp: %b,  Actual o_rx_encoding: %b , Actual o_rx_sb_rsp: %b", o_rx_encoding_exp, o_rx_sb_rsp_expected, item_rx_fsm_sb_out.o_rx_encoding, item_rx_fsm_sb_out.o_rx_sb_rsp), UVM_LOW);      
                match = 1'b0;
            end
        end
        else if(item_rx_fsm_sb_in.i_rx_decoding == ACTIVE_EXIT_HS_TX_Exit_Handshake && item_rx_fsm_sb_in.i_sb_rx_done)
        begin
            o_rx_encoding_exp       = RX_ACTIVE_Active ;
            if(o_rx_encoding_exp == item_rx_fsm_sb_out.o_rx_encoding)
                match = 1'b1;
            else
            begin
              `uvm_info("l1_state_rx", $sformatf("Expected o_rx_encoding: %b, Actual o_rx_encoding: %b", o_rx_encoding_exp, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW);
                match = 1'b0;
            end
        end

        /////////////////////////Exit L1 state /////////////////////////////////////////// 

        else if(item_rdi_in.i_lp_state_req == state_req_active || item_rx_fsm_sb_in.i_rx_decoding == ACTIVE_EXIT_HS_TX_Exit_Handshake && item_rx_fsm_sb_in.i_sb_rx_req)
        begin
            o_rx_encoding_exp       = RX_ACTIVE_EXIT_HS_Exit_Handshake ;
            o_rx_sb_rsp_expected    = 1'b1;
            rx_handshake_done       = 1'b0;
            if(o_rx_encoding_exp == item_rx_fsm_sb_out.o_rx_encoding && o_rx_sb_rsp_expected == item_rx_fsm_sb_out.o_rx_sb_rsp)
                match = 1'b1;
            else
            begin
              `uvm_info("l1_state_rx", $sformatf("Expected o_rx_encoding: %b, Expected o_rx_sb_rsp: %b,  Actual o_rx_encoding: %b , Actual o_rx_sb_rsp: %b", o_rx_encoding_exp, o_rx_sb_rsp_expected, item_rx_fsm_sb_out.o_rx_encoding, item_rx_fsm_sb_out.o_rx_sb_rsp), UVM_LOW);      
                match = 1'b0;
            end
        end
        else
            match = 1'b1;
            
            return match;
    endfunction 
 
 
    virtual function fsm_t getStateId();   
      return fsm_rx_l1;     
    endfunction 
  endclass 

