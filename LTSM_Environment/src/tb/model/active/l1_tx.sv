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
    logic [3:0] o_pl_state_sts_exp;
    bit match;

    
    local static l1_state_tx inst = null; 
 
    protected function new();   endfunction 
     
    static function l1_state_tx Instance(); 
      if (inst == null) 
        inst = new(); 
      return inst; 
    endfunction 
     
    virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
        if(item_rdi_in.i_lp_state_req == state_req_l1 && cntxt.currentstate_tx == active_state_tx::Instance())
        begin
            o_tx_encoding_exp       = ACTIVE_L1_TX_handshake ;
            o_tx_sb_req_expected    = 1'b1;
            tx_handshake_done       = 1'b0;

                if(o_tx_encoding_exp == item_tx_fsm_sb_out.o_tx_encoding && o_tx_sb_req_expected == item_tx_fsm_sb_out.o_tx_sb_req)
                begin
                    match = 1'b1;
                end 
                else
                begin
                  `uvm_info("l1_state_tx", $sformatf("Expected o_tx_encoding: %b, Actual o_tx_encoding: %b, Expected o_tx_sb_req: %b, Actual o_tx_sb_req: %b", o_tx_encoding_exp, item_tx_fsm_sb_out.o_tx_encoding, o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW);
                    match = 1'b0;
                end
        end
        else if(item_tx_fsm_sb_in.i_tx_decoding ==  RX_ACTIVE_L1_Start_HS && item_tx_fsm_sb_in.i_sb_tx_done)begin
            o_tx_sb_req_expected    = 1'b0;
                if(o_tx_sb_req_expected == item_tx_fsm_sb_out.o_tx_sb_req)
                begin
                    match = 1'b1;
                end 
                else
                begin
                  `uvm_info("l1_state_tx", $sformatf("Expected o_tx_sb_req: %b, Actual o_tx_sb_req: %b", o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW);
                    match = 1'b0;
                end
        end
        
        else if(item_tx_fsm_sb_in.i_tx_decoding ==  RX_ACTIVE_L1_Start_HS && item_tx_fsm_sb_in.i_sb_tx_rsp )  // waiting for rx handshake to be done before accepting the next sequence    
        begin
            tx_handshake_done       = 1'b1;
        end 
          
        else if(tx_handshake_done == 1'b1 &&  rx_handshake_done == 1'b1)      
        begin
            o_tx_encoding_exp       = ACTIVE_L1_TX_L1_State;
                if(o_tx_encoding_exp == item_tx_fsm_sb_out.o_tx_encoding)
                    match = 1'b1;
                else
                begin
                  `uvm_info("l1_state_tx", $sformatf("Expected o_tx_encoding: %b, Actual o_tx_encoding: %b", o_tx_encoding_exp, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW);
                    match = 1'b0;
                end
        end
        else if( item_tx_fsm_sb_in.i_tx_decoding == RX_ACTIVE_L1_Refuse && item_tx_fsm_sb_in.i_sb_tx_rsp )
        begin
            o_tx_encoding_exp       =  ACTIVE_TX_Active ;
            o_pl_state_sts_exp      = 4'b0011; //active.pmnak
                if(o_tx_encoding_exp == item_tx_fsm_sb_out.o_tx_encoding && o_pl_state_sts_exp == item_rdi_out.o_pl_state_sts)
                    match = 1'b1;
                else
                begin
                  `uvm_info("l1_state_tx", $sformatf("Expected o_tx_encoding: %b, Actual o_tx_encoding: %b, Expected o_pl_state_sts: %b, Actual o_pl_state_sts: %b", o_tx_encoding_exp, item_tx_fsm_sb_out.o_tx_encoding, o_pl_state_sts_exp, item_rdi_out.o_pl_state_sts), UVM_LOW);
                    match = 1'b0;
                end
        end 

        //////////////////Exit L1 state ///////////////////////

        else if(item_rdi_in.i_lp_state_req == state_req_active || item_rx_fsm_sb_in.i_rx_decoding == ACTIVE_EXIT_HS_TX_Exit_Handshake && item_rx_fsm_sb_in.i_sb_rx_req )
        begin
            o_tx_encoding_exp       = ACTIVE_EXIT_HS_TX_Exit_Handshake;
            tx_handshake_done       = 1'b0;
             
            
                if(o_tx_encoding_exp == item_tx_fsm_sb_out.o_tx_encoding )
                    match = 1'b1;
                else
                begin
                  `uvm_info("l1_state_tx", $sformatf("Expected o_tx_encoding: %b, Actual o_tx_encoding: %b", o_tx_encoding_exp, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW);
                    match = 1'b0;
                end
        end
        else 
        match = 1'b1;
        
            return match;       
    endfunction 
 
 
    virtual function fsm_t getStateId();   
      return fsm_tx_l1;     
    endfunction 
  endclass 
