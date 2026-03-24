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
    logic o_pl_stall_req_expected;
    bit match;

    
    local static phyretrain_rx inst = null; 
 
    protected function new();   endfunction 
     
    static function phyretrain_rx Instance(); 
      if (inst == null) 
        inst = new(); 
      return inst; 
    endfunction 
     
    virtual function bit doSpecificCombAction(FSMContext cntxt, LTSM_controllers_seq_item ctrl_item , ltsm_rdi_sequence_item rdi_item ,rx_fsm_sb_sequence_item  rx_sb_item ,tx_fsm_sb_sequence_item tx_sb_item); 
        if(rx_sb_item.i_rx_decoding == PHYRETRAIN_TX_Retrain_Handshake && rx_sb_item.i_sb_rx_req && cntxt.currentstate_rx == active_state_rx::instance())
        begin
            o_rx_encoding_exp = RX_PHYRETRAIN_PL_StallReq_Handshake ;
            o_pl_stall_req_expected = 1'b1;

                if(o_rx_encoding_exp == rx_sb_item.o_rx_encoding && o_pl_stall_req_expected == rdi_item.o_pl_stall_req)
                    match = 1'b1;
                else
                begin
                  `uvm_info("phyretrain_rx", $sformatf("Expected o_rx_encoding: %b, Actual o_rx_encoding: %b, Expected o_pl_stall_req: %b, Actual o_pl_stall_req: %b", o_rx_encoding_exp, rx_sb_item.o_rx_encoding, o_pl_stall_req_expected, rdi_item.o_pl_stall_req), UVM_LOW);
                    match = 1'b0;
                end
        end
        else if(rx_sb_item.i_rx_decoding == RX_PHYRETRAIN_PL_StallReq_Handshake &&  rdi_item.i_lp_stall_ack == 1'b1 )
        begin
            o_rx_encoding_exp = RX_PHYRETRAIN_Retrain_Handshake ;
            o_rx_sb_rsp_expected = 1'b1;
                if(o_rx_encoding_exp == rx_sb_item.o_rx_encoding && o_rx_sb_rsp_expected == rx_sb_item.o_sb_rx_rsp)
                    match = 1'b1;
                else
                begin
                  `uvm_info("phyretrain_rx", $sformatf("Expected o_rx_encoding: %b, Actual o_rx_encoding: %b, Expected o_rx_sb_rsp: %b, Actual o_rx_sb_rsp: %b", o_rx_encoding_exp, rx_sb_item.o_rx_encoding, o_rx_sb_rsp_expected, rx_sb_item.o_sb_rx_rsp), UVM_LOW);
                    match = 1'b0;
                end
        end
        else if(rx_sb_item.i_rx_decoding == PHYRETRAIN_TX_Start_Req_Handshake && rx_sb_item.i_sb_rx_req)
        begin
            o_rx_encoding_exp = RX_PHYRETRAIN_Start_RSP_Handshake;
            o_rx_sb_rsp_expected = 1'b1;
            if((rx_sb_item.i_rx_info[2:0]==3'b010)||(ctrl_item.i_Runtime_Link_Test_status_register==1'b1)&&(ctrl_item.i_Runtime_Link_Test_Control_register[2] == 1'b1)&&(lane_map == 3'b000))
                o_rx_info_expected[2:0] = 3'b010; // SPEEDIDLE
            else if((rx_sb_item.i_rx_info[2:0]==3'b100)||(ctrl_item.i_Runtime_Link_Test_status_register==1'b1)&&(ctrl_item.i_Runtime_Link_Test_Control_register[2] == 1'b1)&&(lane_map != 3'b000))
                o_rx_info_expected[2:0] = 3'b100; // REPAIR
            else if((rx_sb_item.i_rx_info[2:0]==3'b001)||(ctrl_item.i_Runtime_Link_Test_status_register==1'b0))
                o_rx_info_expected[2:0] = 3'b001; // TXSELFCAL
            else if((rx_sb_item.i_rx_info[2:0]==3'b100)||(ctrl_item.i_Runtime_Link_Test_status_register==1'b1)&&(ctrl_item.i_Runtime_Link_Test_Control_register[2] == 1'b0))
                o_rx_info_expected[2:0] = 3'b001; // TXSELFCAL

            if(o_rx_encoding_exp == rx_sb_item.o_rx_encoding && o_rx_sb_rsp_expected == rx_sb_item.o_sb_rx_rsp && o_rx_info_expected[2:0] == rx_sb_item.i_rx_info[2:0])
                    match = 1'b1;
                else
                begin
                  `uvm_info("phyretrain_rx", $sformatf("Expected o_rx_encoding: %b, Actual o_rx_encoding: %b, Expected o_rx_sb_rsp: %b, Actual o_rx_sb_rsp: %b, Expected o_rx_info: %b, Actual o_rx_info: %b", o_rx_encoding_exp, rx_sb_item.o_rx_encoding, o_rx_sb_rsp_expected, rx_sb_item.o_sb_rx_rsp, o_rx_info_expected[2:0], rx_sb_item.i_rx_info[2:0]), UVM_LOW);
                    match = 1'b0;
                end
        end

            return match;       
    endfunction 
 
 
    virtual function fsm_t getStateId();   
      return fsm_tx_l1;     
    endfunction 
  endclass 
