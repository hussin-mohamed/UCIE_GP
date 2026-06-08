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
class trainerror_tx extends State;
    local static trainerror_tx inst = null;
    logic [8:0] o_tx_encoding_expected;
    logic [15:0] o_tx_info_expected;
    logic o_tx_sb_req_expected;
    bit match;
    protected function new(); endfunction

    static function trainerror_tx Instance();
        if (inst == null)
        inst = new();
        return inst;
    endfunction

    virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
        if(cntxt.currentstate_tx != trainerror_tx::Instance()) begin
            o_tx_encoding_expected = TRAINERROR_TX_Handshake;
            o_tx_info_expected = 16'h0000;
            train_end=0;
            o_tx_sb_req_expected = 1'b1;
            error_enter =0;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_tx_sb_req_expected == item_tx_fsm_sb_out.o_tx_sb_req) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("trainerror_tx", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("trainerror_tx", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("trainerror_tx", $sformatf("o_tx_sb_req mismatch expected value: %0b, got %0b", o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            end
        end
        // else if (o_tx_encoding_expected == TRAINERROR_TX_Handshake ) begin
        //     if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_tx_sb_req_expected == item_tx_fsm_sb_out.o_tx_sb_req) begin
        //         match = 1;
        //     end else begin
        //         match = 0;
        //         `uvm_info("trainerror_tx", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
        //         `uvm_info("trainerror_tx", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
        //         `uvm_info("trainerror_tx", $sformatf("o_tx_sb_req mismatch expected value: %0b, got %0b", o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
        //     end
        //     o_tx_encoding_expected =0;
        // end
        else if(cntxt.currentstate_tx == trainerror_tx::Instance() && ((item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1 && item_tx_fsm_sb_in.i_tx_decoding == 'h40)||(counter == item_controllers_in.i_sim_cycles_8-2)))  begin
            o_tx_encoding_expected = TRAINERROR_TX_TrainError;
            train_end=1;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("trainerror_tx", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
            end
        end
        else begin
            match =1;
        end
        
        return match;
    endfunction

    virtual function fsm_t getStateId();
        return fsm_tx_trainerror;
    endfunction


endclass //mbtrain_tx_valvref extends state