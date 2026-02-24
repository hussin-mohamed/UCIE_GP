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
import shared_ltsm_pkg::*;
class mbtrain_tx_valtraincenter extends state;
    local static mbtrain_tx_valtraincenter inst = null;
    logic [8:0] o_tx_encoding_expected;
    logic [15:0] o_tx_info_expected;
    logic o_sb_tx_req_expected;
    bit match;
    protected function new(); endfunction

    static function mbtrain_tx_valtraincenter Instance();
        if (inst == null)
        inst = new();
        return inst;
    endfunction

    virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_sequence_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_sequence_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
        if(item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_RXCLKCAL_TX_End_Handshake && item_rx_fsm_sb_in.i_rx_decoding == RX_MBTRAIN_RXCLKCAL_End_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1 && cntxt.currentstate_tx == mbtrain_tx_rxclkcal::instance())begin
            o_tx_encoding_expected = MBTRAIN_VALTRAINCENTER_TX_Start_Handshake;
            o_tx_info_expected = 16'h0000;
            o_sb_tx_req_expected = 1'b1;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_sb_tx_req_expected == item_tx_fsm_sb_out.o_sb_tx_req) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_valtraincenter", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_valtraincenter", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_valtraincenter", $sformatf("o_sb_tx_req mismatch expected value: %0b, got %0b", o_sb_tx_req_expected, item_tx_fsm_sb_out.o_sb_tx_req), UVM_LOW)
            end
        end
        else if((item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_VALTRAINCENTER_TX_Start_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1 && cntxt.currentstate_tx == mbtrain_tx_valtraincenter::instance()))begin
             o_tx_encoding_expected = MBTRAIN_VALTRAINCENTER_TX_Pattern_Generation;
            if (o_tx_encoding_expected == item_tx_fsm_sb_out.o_tx_encoding) begin
                match=1;
            end else begin
                match =0;
                `uvm_info("mbtrain_tx_valtraincenter", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
            end           
        end
        else if (item_controllers_in.i_tx_done && cntxt.currentstate_tx == data_to_clock_sweep::instance()) begin
            o_tx_encoding_expected = MBTRAIN_VALTRAINCENTER_TX_End_Handshake;
            o_tx_info_expected = 16'h0000;
            o_sb_tx_req_expected =1;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_sb_tx_req_expected == item_tx_fsm_sb_out.o_sb_tx_req) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_valvref", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_valvref", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_valvref", $sformatf("o_sb_tx_req mismatch expected value: %0b, got %0b", o_sb_tx_req_expected, item_tx_fsm_sb_out.o_sb_tx_req), UVM_LOW)
            end
        end
        
        return match;
    endfunction

    virtual function fsm_t getStateId();
        return fsm_mbtrain_tx_valtraincenter;
    endfunction


endclass //mbtrain_tx_valtraincenter extends state