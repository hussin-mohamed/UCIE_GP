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


 class phyretrain_rx extends State;
    //output signals
    logic [8:0] o_rx_encoding_exp;
    logic o_rx_sb_req_expected;
    logic o_rx_sb_rsp_expected;
    logic o_pl_stall_req_expected;
    logic [15:0] o_rx_info_expected;
    bit match;

    
    local static phyretrain_rx inst = null; 
 
    protected function new();   endfunction 
     
    static function phyretrain_rx Instance(); 
      if (inst == null) 
        inst = new(); 
      return inst; 
    endfunction 
     
   virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out); 
        if(item_rx_fsm_sb_in.i_rx_decoding == PHYRETRAIN_TX_Retrain_Handshake && item_rx_fsm_sb_in.i_sb_rx_req && cntxt.currentstate_rx == active_state_rx::Instance())
        begin
            state_done              = 1'b0; // to make sure rx waits for the phy retrain handshake to be done before moving forward with the next sequence since phy retrain handshake is initiated from tx side
            o_rx_encoding_exp       = RX_PHYRETRAIN_PL_StallReq_Handshake ;
            o_pl_stall_req_expected = 1'b1;

                if(o_rx_encoding_exp == item_rx_fsm_sb_out.o_rx_encoding && o_pl_stall_req_expected == item_rdi_out.o_pl_stallreq)
                    match = 1'b1;
                else
                begin
                  `uvm_info("phyretrain_rx", $sformatf("Expected o_rx_encoding: %b, Actual o_rx_encoding: %b, Expected o_pl_stall_req: %b, Actual o_pl_stall_req: %b", o_rx_encoding_exp, item_rx_fsm_sb_out.o_rx_encoding, o_pl_stall_req_expected, item_rdi_out.o_pl_stallreq), UVM_HIGH);
                    match = 1'b0;
                end
        end
        else if(item_rx_fsm_sb_in.i_rx_decoding == RX_PHYRETRAIN_PL_StallReq_Handshake &&  item_rdi_in.i_lp_stallack == 1'b1 )
        begin
            o_rx_encoding_exp       = RX_PHYRETRAIN_Retrain_Handshake ;
            o_rx_sb_rsp_expected    = 1'b1;
                if(o_rx_encoding_exp == item_rx_fsm_sb_out.o_rx_encoding && o_rx_sb_rsp_expected == item_rx_fsm_sb_out.o_rx_sb_rsp)
                    match = 1'b1;
                else
                begin
                  `uvm_info("phyretrain_rx", $sformatf("Expected o_rx_encoding: %b, Actual o_rx_encoding: %b, Expected o_rx_sb_rsp: %b, Actual o_rx_sb_rsp: %b", o_rx_encoding_exp, item_rx_fsm_sb_out.o_rx_encoding, o_rx_sb_rsp_expected, item_rx_fsm_sb_out.o_rx_sb_rsp), UVM_HIGH);
                    match = 1'b0;
                end
        end
        else if(item_rx_fsm_sb_in.i_rx_decoding == PHYRETRAIN_TX_Start_Req_Handshake && item_rx_fsm_sb_in.i_sb_rx_req)
        begin
            o_rx_encoding_exp       = RX_PHYRETRAIN_Start_RSP_Handshake;
            o_rx_sb_rsp_expected    = 1'b1;
            state_done       = 1'b1; // to allow tx to move forward with the next sequence since phy retrain handshake is done from rx side
            if((item_rx_fsm_sb_in.i_rx_info[2:0]==3'b010)||(item_controllers_in.i_Runtime_Link_Test_status_register==1'b1)&&(item_controllers_in.i_Runtime_Link_Test_Control_register[2] == 1'b1)&&(lane_map_tx == 3'b000))
                o_rx_info_expected[2:0] = 3'b010; // SPEEDIDLE
            else if((item_rx_fsm_sb_in.i_rx_info[2:0]==3'b100)||(item_controllers_in.i_Runtime_Link_Test_status_register==1'b1)&&(item_controllers_in.i_Runtime_Link_Test_Control_register[2] == 1'b1)&&(lane_map_tx != 3'b000))
                o_rx_info_expected[2:0] = 3'b100; // REPAIR
            else if((item_rx_fsm_sb_in.i_rx_info[2:0]==3'b001)||(item_controllers_in.i_Runtime_Link_Test_status_register==1'b0))
                o_rx_info_expected[2:0] = 3'b001; // TXSELFCAL
            else if((item_rx_fsm_sb_in.i_rx_info[2:0]==3'b100)||(item_controllers_in.i_Runtime_Link_Test_status_register==1'b1)&&(item_controllers_in.i_Runtime_Link_Test_Control_register[2] == 1'b0))
                o_rx_info_expected[2:0] = 3'b001; // TXSELFCAL

            if(o_rx_encoding_exp == item_rx_fsm_sb_out.o_rx_encoding && o_rx_sb_rsp_expected == item_rx_fsm_sb_out.o_rx_sb_rsp && o_rx_info_expected[2:0] == item_rx_fsm_sb_out.i_rx_info[2:0])
                    match = 1'b1;
                else
                begin
                  `uvm_info("phyretrain_rx", $sformatf("Expected o_rx_encoding: %b, Actual o_rx_encoding: %b, Expected o_rx_sb_rsp: %b, Actual o_rx_sb_rsp: %b, Expected o_rx_info: %b, Actual o_rx_info: %b", o_rx_encoding_exp, item_rx_fsm_sb_out.o_rx_encoding, o_rx_sb_rsp_expected, item_rx_fsm_sb_out.o_rx_sb_rsp, o_rx_info_expected[2:0], item_rx_fsm_sb_out.i_rx_info[2:0]), UVM_HIGH);
                    match = 1'b0;
                end
        end
        else if(item_tx_fsm_sb_in.i_tx_decoding == PHYRETRAIN_TX_Start_Req_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 )
        begin
            if(item_tx_fsm_sb_in.i_tx_info[2:0] == 3'b010) // SPEEDIDLE
                o_rx_encoding_exp   = RX_MBTRAIN_SPEEDIDLE_Speed_Transition  ;
            else if(item_tx_fsm_sb_in.i_tx_info[2:0] == 3'b100) // REPAIR
                o_rx_encoding_exp   = RX_MBTRAIN_REPAIR_Start_Handshake ;
            else if(item_tx_fsm_sb_in.i_tx_info[2:0] == 3'b001) // TXSELFCAL
                o_rx_encoding_exp   = RX_MBTRAIN_TXSELFCAL_End_Handshake ;
            
            if(o_rx_encoding_exp == item_rx_fsm_sb_out.o_rx_encoding)
                match = 1'b1;
            else
            begin
              `uvm_info("phyretrain_rx", $sformatf("Expected o_rx_encoding: %b, Actual o_rx_encoding: %b", o_rx_encoding_exp, item_rx_fsm_sb_out.o_rx_encoding), UVM_HIGH);
                match = 1'b0;
            end

        end

            return match;       
    endfunction 
 
 
    virtual function fsm_t getStateId();   
      return fsm_tx_l1;     
    endfunction 
  endclass 
