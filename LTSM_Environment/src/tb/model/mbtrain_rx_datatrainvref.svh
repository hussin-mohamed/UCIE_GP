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
class mbtrain_rx_datatrainvref extends state;
    local static mbtrain_rx_datatrainvref inst = null;
    logic [8:0] o_rx_encoding_expected;
    logic [15:0] o_rx_info_expected;
    logic o_sb_rx_rsp_expected;
    bit match;
    protected function new(); endfunction

    static function mbtrain_rx_datatrainvref Instance();
        if (inst == null)
        inst = new();
        return inst;
    endfunction

    virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_sequence_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_sequence_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
        if(item_rx_fsm_sb_in.i_rx_decoding == RX_MBTRAIN_DATATRAINVREF_Start_Handshake && item_rx_fsm_sb_in.i_sb_rx_req==1'b1 && cntxt.currentstate_rx == mbtrain_rx_dtc1::instance())begin
            o_rx_encoding_expected = RX_MBTRAIN_DATATRAINVREF_Start_Handshake;
            o_rx_info_expected = 16'h0000;
            o_sb_rx_rsp_expected = 1'b1;
            if (o_rx_encoding_expected==item_rx_fsm_sb_out.o_rx_encoding && o_rx_info_expected==item_rx_fsm_sb_out.o_rx_info && o_sb_rx_rsp_expected == item_rx_fsm_sb_out.o_sb_rx_rsp) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_rx_datatrainvref", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                `uvm_info("mbtrain_rx_datatrainvref", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
                `uvm_info("mbtrain_rx_datatrainvref", $sformatf("o_sb_rx_rsp mismatch expected value: %0b, got %0b", o_sb_rx_rsp_expected, item_rx_fsm_sb_out.o_sb_rx_rsp), UVM_LOW)
            end
        end
        else if((item_rx_fsm_sb_in.i_sb_rx_done == 1 && cntxt.currentstate_rx == mbtrain_rx_datatrainvref::instance()) || 
        (item_tx_fsm_sb_in.i_tx_decoding == Data_To_Clock_sweep_TX_End_Init_Handshake && item_controllers_in.i_rx_error==1'b1 && cntxt.currentstate_rx == data_to_clock_sweep::instance()))begin
             o_rx_encoding_expected = RX_MBTRAIN_DATATRAINVREF_Data_to_Clock_Test;
            if (o_rx_encoding_expected == item_rx_fsm_sb_out.o_rx_encoding) begin
                match=1;
            end else begin
                match =0;
                `uvm_info("mbtrain_rx_datatrainvref", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
            end           
        end
        else if (item_controllers_in.i_tx_done && item_controllers_in.i_rx_done && item_rx_fsm_sb_in.i_sb_rx_req && cntxt.currentstate_rx == mbtrain_rx_datatrainvref::instance()) begin
            o_rx_encoding_expected = RX_MBTRAIN_DATATRAINVREF_End_Handshake;
            o_rx_info_expected = 16'h0000;
            o_sb_rx_rsp_expected = 1'b1;
            if (o_rx_encoding_expected == item_rx_fsm_sb_out.o_rx_encoding && o_rx_info_expected == item_rx_fsm_sb_out.o_rx_info && o_sb_rx_rsp_expected == item_rx_fsm_sb_out.o_sb_rx_rsp) begin
                match=1;
            end else begin
                match =0;
                `uvm_info("mbtrain_rx_datatrainvref", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                `uvm_info("mbtrain_rx_datatrainvref", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
                `uvm_info("mbtrain_rx_datatrainvref", $sformatf("o_sb_rx_rsp mismatch expected value: %0b, got %0b", o_sb_rx_rsp_expected, item_rx_fsm_sb_out.o_sb_rx_rsp), UVM_LOW)
            end
        end
        
        return match;
    endfunction

    virtual function fsm_t getStateId();
        return fsm_mbtrain_rx_datatrainvref;
    endfunction


endclass //mbtrain_rx_datatrainvref extends state