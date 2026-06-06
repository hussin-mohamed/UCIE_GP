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
// CLASS: phyretrain_tx
//description: this class models the l1 state in tx fsm.
//It sets the expected values of the signals for each sequence in this state and compares with the actual values from the sequence items. 
//If they match, it returns 1 to indicate that the sequence is done and we can move to next sequence/state.
//
//------------------------------------------------------------------------------


 class phyretrain_tx extends State;
    //output signals
    logic [8:0] o_tx_encoding_exp;
    logic o_tx_sb_req_expected;
    logic o_pl_stall_req_expected;
    logic [15:0] o_tx_info_expected;
    bit match;

    
    local static phyretrain_tx inst = null; 
 
    protected function new();   endfunction 
     
    static function phyretrain_tx Instance(); 
      if (inst == null) 
        inst = new(); 
      return inst; 
    endfunction 
     
    virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
        if((item_rdi_in.i_lp_state_req == state_req_retrain ||(item_rx_fsm_sb_in.i_rx_decoding == PHYRETRAIN_TX_Retrain_Handshake && item_rx_fsm_sb_in.i_sb_rx_req)) && cntxt.currentstate_tx == active_state_tx::Instance())
        begin
            o_tx_encoding_exp       = PHYRETRAIN_TX_PL_StallReq_Handshake ;
            o_pl_stall_req_expected = 1'b1;
            state_done              = 1'b0; 

                if(o_tx_encoding_exp == item_tx_fsm_sb_out.o_tx_encoding && o_pl_stall_req_expected == item_rdi_out.o_pl_stallreq)
                    match = 1'b1;
                else
                begin
                  `uvm_info("phyretrain_tx", $sformatf("Expected o_tx_encoding: %b, Actual o_tx_encoding: %b, Expected o_pl_stall_req: %b, Actual o_pl_stall_req: %b", o_tx_encoding_exp, item_tx_fsm_sb_out.o_tx_encoding, o_pl_stall_req_expected, item_rdi_out.o_pl_stallreq), UVM_HIGH);
                    match = 1'b0;
                end
        end
        else if(item_tx_fsm_sb_in.i_tx_decoding == PHYRETRAIN_TX_PL_StallReq_Handshake && item_rdi_in.i_lp_stallack == 1'b1 ) 
        begin
            o_tx_encoding_exp       = PHYRETRAIN_TX_Retrain_Handshake ;
            o_tx_sb_req_expected    = 1'b1;
                if(o_tx_encoding_exp == item_tx_fsm_sb_out.o_tx_encoding && o_tx_sb_req_expected == item_tx_fsm_sb_out.o_tx_sb_req)
                    match = 1'b1;
                else
                begin
                  `uvm_info("phyretrain_tx", $sformatf("Expected o_tx_encoding: %b, Actual o_tx_encoding: %b, Expected o_tx_sb_req: %b, Actual o_tx_sb_req: %b", o_tx_encoding_exp, item_tx_fsm_sb_out.o_tx_encoding, o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req), UVM_HIGH);
                    match = 1'b0;
                end
        end
        else if(cntxt.currentstate_tx == mbtrain_tx_linkspeed::Instance()||(item_tx_fsm_sb_in.i_tx_decoding == RX_PHYRETRAIN_Retrain_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1))
        begin
            o_tx_encoding_exp       = PHYRETRAIN_TX_Start_Req_Handshake ;
            o_tx_sb_req_expected    = 1'b1;
            
            // determining the expected value of o_tx_info based on the runtime link test control register and lane map
            
            if((item_controllers_in.i_Runtime_Link_Test_status_register==1'b1 )&&(item_controllers_in.i_Runtime_Link_Test_Control_register[2] == 1'b1))
            begin
                if(lane_map_tx == 3'b000)
                o_tx_info_expected[2:0] = 3'b010 ; // SPEEDIDLE  
                else if((item_controllers_in.i_Runtime_Link_Test_status_register==1'b1 )&&(item_controllers_in.i_Runtime_Link_Test_Control_register[2] == 1'b0))
                o_tx_info_expected[2:0] = 3'b001 ; // TXSELFCAL   
                else
                o_tx_info_expected[2:0] = 3'b100 ; // REPAIR
                        
            end
            else if (item_controllers_in.i_Runtime_Link_Test_status_register==1'b0)
                o_tx_info_expected[2:0] = 3'b001 ; // TXSELFCAL  

            //checking the expected values with the actual values from the sequence item
            
            if(o_tx_encoding_exp == item_tx_fsm_sb_out.o_tx_encoding && o_tx_sb_req_expected == item_tx_fsm_sb_out.o_tx_sb_req && o_tx_info_expected[2:0] == item_tx_fsm_sb_out.o_tx_info[2:0])
                match = 1'b1;
            else
            begin
              `uvm_info("phyretrain_tx", $sformatf("Expected o_tx_encoding: %b, Actual o_tx_encoding: %b, Expected o_tx_sb_req: %b, Actual o_tx_sb_req: %b, Expected o_tx_info: %b, Actual o_tx_info: %b", o_tx_encoding_exp, item_tx_fsm_sb_out.o_tx_encoding, o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req, o_tx_info_expected[2:0], item_tx_fsm_sb_out.o_tx_info[2:0]), UVM_HIGH);
                match = 1'b0;
            end
        end

        else if(item_tx_fsm_sb_in.i_tx_decoding == PHYRETRAIN_TX_Start_Req_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && state_done == 1'b1)
        begin
            if(item_tx_fsm_sb_in.i_tx_info[2:0] == 3'b010) // SPEEDIDLE
                o_tx_encoding_exp   = MBTRAIN_SPEEDIDLE_TX_Speed_Transition ;
            else if(item_tx_fsm_sb_in.i_tx_info[2:0] == 3'b100) // REPAIR
                o_tx_encoding_exp   = MBTRAIN_REPAIR_TX_Start_Handshake ;
            else if(item_tx_fsm_sb_in.i_tx_info[2:0] == 3'b001) // TXSELFCAL
                o_tx_encoding_exp   = MBTRAIN_TXSELFCAL_TX_Calibration ;
            
            if(o_tx_encoding_exp == item_tx_fsm_sb_out.o_tx_encoding)
                match = 1'b1;
            else
            begin
              `uvm_info("phyretrain_tx", $sformatf("Expected o_tx_encoding: %b, Actual o_tx_encoding: %b", o_tx_encoding_exp, item_tx_fsm_sb_out.o_tx_encoding), UVM_HIGH);
                match = 1'b0;
            end

        end
            return match;       
    endfunction 
 
 
    virtual function fsm_t getStateId();   
      return fsm_tx_l1;     
    endfunction 
  endclass 
