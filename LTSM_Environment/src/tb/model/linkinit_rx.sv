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
// CLASS: linkinit_state_rx
//description: this class models the linkinit state in rx fsm.
//It sets the expected values of the signals for each sequence in this state and compares with the actual values from the sequence items. 
//If they match, it returns 1 to indicate that the sequence is done and we can move to next sequence/state.
//
//------------------------------------------------------------------------------


 class linkinit_state_rx extends State;
    //output signals
    logic [8:0] o_rx_encoding_exp;
    logic o_pl_inband_pres_exp;
    logic o_pl_wake_ack_exp;
    bit match;
    
    local static linkinit_state_rx inst = null; 
 
    protected function new();   endfunction 
     
    static function linkinit_state_rx Instance(); 
      if (inst == null) 
        inst = new(); 
      return inst; 
    endfunction 
     
    virtual function bit doSpecificCombAction(FSMContext cntxt, LTSM_controllers_seq_item ctrl_item , ltsm_rdi_sequence_item rdi_item ,rx_fsm_sb_sequence_item  rx_sb_item ,tx_fsm_sb_sequence_item tx_sb_item); 
      if(ctrl_item.i_rx_decoding == MBTRAIN_SPEEDIDLE_TX_End_Handshake && rx_sb_item.i_sb_rx_done && cntxt.currentstate_rx == linkspeed_state_rx::instance())
      begin
        o_rx_encoding_exp = RX_ACTIVE_LINKINIT_PL_Clk_Req_Handshake ;
        o_pl_inband_pres_exp = 1'b1;
            if(o_rx_encoding_exp == ctrl_item.o_rx_encoding && o_pl_inband_pres_exp == ctrl_item.o_pl_inband_pres)
                match = 1'b1;
            else 
            begin
              `uvm_info("linkinit_state_rx", $sformatf("Expected o_rx_encoding: %b, Actual o_rx_encoding: %b, Expected o_pl_inband_pres: %b, Actual o_pl_inband_pres: %b", o_rx_encoding_exp, ctrl_item.o_rx_encoding, o_pl_inband_pres_exp, ctrl_item.o_pl_inband_pres), UVM_LOW);
                match = 1'b0;
            end
            
      end
      else if(o_rx_encoding_exp == RX_ACTIVE_LINKINIT_PL_Clk_Req_Handshake && rdi_item.i_lp_clk_ack && cntxt.currentstate_rx == linkinit_state_rx::instance())
      begin
        o_rx_encoding_exp = RX_ACTIVE_LINKINIT_LP_Wake_Req_Handshake ;
        o_pl_wake_ack_exp = 1'b1;
            if(o_rx_encoding_exp == ctrl_item.o_rx_encoding && o_pl_wake_ack_exp == ctrl_item.o_pl_wake_ack)
                match = 1'b1;
            else
            begin
              `uvm_info("linkinit_state_rx", $sformatf("Expected o_rx_encoding: %b, Actual o_rx_encoding: %b, Expected o_pl_wake_ack: %b, Actual o_pl_wake_ack: %b", o_rx_encoding_exp, ctrl_item.o_rx_encoding, o_pl_wake_ack_exp, ctrl_item.o_pl_wake_ack), UVM_LOW);
                match = 1'b0;
            end
      end
      else if(o_rx_encoding_exp == RX_ACTIVE_LINKINIT_LP_Wake_Req_Handshake && (rdi_item.i_lp_state_req == 4'b0001))
      begin
        o_rx_encoding_exp = RX_ACTIVE_LINKINIT_State_Rsp_Handshake ;
        o_rx_sb_rsp_exp = 1'b1;
            if(o_rx_encoding_exp == ctrl_item.o_rx_encoding && o_rx_sb_rsp_exp == rx_sb_item.o_rx_sb_rsp)
                match = 1'b1;
            else
            begin
              `uvm_info("linkinit_state_rx", $sformatf("Expected o_rx_encoding: %b, Actual o_rx_encoding: %b, Expected o_rx_sb_rsp: %b, Actual o_rx_sb_rsp: %b", o_rx_encoding_exp, ctrl_item.o_rx_encoding, o_rx_sb_rsp_exp, rx_sb_item.o_rx_sb_rsp), UVM_LOW);
                match = 1'b0;
            end
      end  
        return match;
    endfunction 
 
 
    virtual function fsm_t getStateId();   
      return fsm_rx_linkinit;     
    endfunction 
  endclass 
