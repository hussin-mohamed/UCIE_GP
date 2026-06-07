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
class trainerror_rx extends State;
    local static trainerror_rx inst = null;
    logic [8:0] o_rx_encoding_expected;
    logic [15:0] o_rx_info_expected;
    logic        o_rx_sb_rsp_expected;
    bit match;
    protected function new(); endfunction

    static function trainerror_rx Instance();
        if (inst == null)
        inst = new();
        return inst;
    endfunction

    virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
        if(item_rx_fsm_sb_in.i_rx_decoding == RX_TRAINERROR_Handshake && item_rx_fsm_sb_in.i_sb_rx_req == 1'b1) begin
            o_rx_encoding_expected = RX_TRAINERROR_Handshake;

            o_rx_info_expected = 16'h0000; // No specific info expected during handshake
            o_rx_sb_rsp_expected = 1'b1; // Expecting a request during handshake
            if (o_rx_encoding_expected==item_rx_fsm_sb_out.o_rx_encoding && o_rx_info_expected==item_rx_fsm_sb_out.o_rx_info && o_rx_sb_rsp_expected==item_rx_fsm_sb_out.o_rx_sb_rsp) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("trainerror_rx", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                `uvm_info("trainerror_rx", $sformatf("Mismatch in o_rx_info: expected %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
                `uvm_info("trainerror_rx", $sformatf("Mismatch in o_rx_sb_rsp: expected %0b, got %0b", o_rx_sb_rsp_expected, item_rx_fsm_sb_out.o_rx_sb_rsp), UVM_LOW)
            end
        end
        // else if (o_rx_encoding_expected == RX_TRAINERROR_Handshake) begin
        //     if (o_rx_encoding_expected==item_rx_fsm_sb_out.o_rx_encoding && o_rx_info_expected==item_rx_fsm_sb_out.o_rx_info && o_rx_sb_rsp_expected==item_rx_fsm_sb_out.o_rx_sb_rsp) begin
        //         match = 1;
        //     end else begin
        //         match = 0;
        //         `uvm_info("trainerror_rx", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
        //         `uvm_info("trainerror_rx", $sformatf("Mismatch in o_rx_info: expected %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
        //         `uvm_info("trainerror_rx", $sformatf("Mismatch in o_rx_sb_rsp: expected %0b, got %0b", o_rx_sb_rsp_expected, item_rx_fsm_sb_out.o_rx_sb_rsp), UVM_LOW)
        //     end
        //     o_rx_encoding_expected =0
        // end
        else if(cntxt.currentstate_rx == trainerror_rx::Instance() && ((item_rx_fsm_sb_in.i_sb_rx_done==1'b1)||(counter == item_controllers_in.i_sim_cycles_8+1)))  begin
            o_rx_encoding_expected = RX_TRAINERROR_TrainError;
            if (o_rx_encoding_expected==item_rx_fsm_sb_out.o_rx_encoding) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("trainerror_rx", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
            end
        end
        else begin
            match =1;
        end
        
        return match;
    endfunction

    virtual function fsm_t getStateId();
        return fsm_rx_trainerror;
    endfunction


endclass //mbtrain_tx_valvref extends state