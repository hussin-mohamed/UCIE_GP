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
class mbtrain_rx_repair extends State;
    local static mbtrain_rx_repair inst = null;
    logic [8:0] o_rx_encoding_expected;
    logic [15:0] o_rx_info_expected;
    logic o_rx_sb_rsp_expected;
    bit match;
    protected function new(); endfunction

    static function mbtrain_rx_repair Instance();
        if (inst == null)
        inst = new();
        return inst;
    endfunction

    virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
        if(item_rx_fsm_sb_in.i_rx_decoding == RX_MBTRAIN_REPAIR_Start_Handshake && item_rx_fsm_sb_in.i_sb_rx_req==1'b1 && cntxt.currentstate_rx == mbtrain_rx_linkspeed::Instance())begin
            o_rx_encoding_expected = RX_MBTRAIN_REPAIR_Start_Handshake;
            o_rx_info_expected = 16'h0000;
            o_rx_sb_rsp_expected = 1'b1;
            if (o_rx_encoding_expected==item_rx_fsm_sb_out.o_rx_encoding) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_rx_repair", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                // `uvm_info("mbtrain_rx_repair", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
                // `uvm_info("mbtrain_rx_repair", $sformatf("o_rx_sb_req mismatch expected value: %0b, got %0b", o_rx_sb_rsp_expected, item_rx_fsm_sb_out.o_rx_sb_rsp), UVM_LOW)
            end
        end
        else if (o_rx_encoding_expected == RX_MBTRAIN_REPAIR_Start_Handshake) begin
            if (o_rx_encoding_expected==item_rx_fsm_sb_out.o_rx_encoding && o_rx_info_expected==item_rx_fsm_sb_out.o_rx_info && o_rx_sb_rsp_expected == item_rx_fsm_sb_out.o_rx_sb_rsp) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_rx_repair", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                `uvm_info("mbtrain_rx_repair", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
                `uvm_info("mbtrain_rx_repair", $sformatf("o_rx_sb_req mismatch expected value: %0b, got %0b", o_rx_sb_rsp_expected, item_rx_fsm_sb_out.o_rx_sb_rsp), UVM_LOW)
            end
            o_rx_encoding_expected =0;
        end
        else if (item_rx_fsm_sb_in.i_rx_decoding == RX_MBTRAIN_REPAIR_Send_Apply_Degrade_RESP && item_rx_fsm_sb_in.i_sb_rx_req==1'b1 && item_rx_fsm_sb_in.i_rx_info[2:0] != 3'b000) begin 
            o_rx_encoding_expected = RX_MBTRAIN_REPAIR_Send_Apply_Degrade_RESP;
            o_rx_info_expected = 16'h0000;
            o_rx_sb_rsp_expected = 1'b1;
            lane_map_rx=item_rx_fsm_sb_in.i_rx_info[2:0];
            if (o_rx_encoding_expected==item_rx_fsm_sb_out.o_rx_encoding ) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_rx_repair", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                // `uvm_info("mbtrain_rx_repair", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
                // `uvm_info("mbtrain_rx_repair", $sformatf("o_rx_sb_req mismatch expected value: %0b, got %0b", o_rx_sb_rsp_expected, item_rx_fsm_sb_out.o_rx_sb_rsp), UVM_LOW)
                // `uvm_info("mbtrain_rx_repair", $sformatf("lane_map_rx mismatch expected value: %0h, got %0h", lane_map_rx, item_controllers_out.o_lane_map_rx), UVM_LOW)
            end
        end
        else if (o_rx_encoding_expected == RX_MBTRAIN_REPAIR_Send_Apply_Degrade_RESP) begin
            if (o_rx_encoding_expected==item_rx_fsm_sb_out.o_rx_encoding && o_rx_info_expected==item_rx_fsm_sb_out.o_rx_info && o_rx_sb_rsp_expected == item_rx_fsm_sb_out.o_rx_sb_rsp && lane_map_rx==item_controllers_out.o_lane_map_rx) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_rx_repair", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                `uvm_info("mbtrain_rx_repair", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
                `uvm_info("mbtrain_rx_repair", $sformatf("o_rx_sb_req mismatch expected value: %0b, got %0b", o_rx_sb_rsp_expected, item_rx_fsm_sb_out.o_rx_sb_rsp), UVM_LOW)
                `uvm_info("mbtrain_rx_repair", $sformatf("lane_map_rx mismatch expected value: %0h, got %0h", lane_map_rx, item_controllers_out.o_lane_map_rx), UVM_LOW)
            end
            o_rx_encoding_expected =0;
        end
        else if (item_rx_fsm_sb_in.i_rx_decoding == RX_MBTRAIN_REPAIR_End_Handshake && item_rx_fsm_sb_in.i_sb_rx_req==1'b1) begin
            o_rx_encoding_expected = RX_MBTRAIN_REPAIR_End_Handshake;
            o_rx_info_expected = 16'h0000;
            o_rx_sb_rsp_expected = 1'b1;
            state_done=1'b1;
            if (o_rx_encoding_expected==item_rx_fsm_sb_out.o_rx_encoding ) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_rx_repair", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                // `uvm_info("mbtrain_rx_repair", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
                // `uvm_info("mbtrain_rx_repair", $sformatf("o_rx_sb_req mismatch expected value: %0b, got %0b", o_rx_sb_rsp_expected, item_rx_fsm_sb_out.o_rx_sb_rsp), UVM_LOW)
            end         
        end
        else if (o_rx_encoding_expected == RX_MBTRAIN_REPAIR_End_Handshake) begin
            if (o_rx_encoding_expected==item_rx_fsm_sb_out.o_rx_encoding && o_rx_info_expected==item_rx_fsm_sb_out.o_rx_info && o_rx_sb_rsp_expected == item_rx_fsm_sb_out.o_rx_sb_rsp) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_rx_repair", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                `uvm_info("mbtrain_rx_repair", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
                `uvm_info("mbtrain_rx_repair", $sformatf("o_rx_sb_req mismatch expected value: %0b, got %0b", o_rx_sb_rsp_expected, item_rx_fsm_sb_out.o_rx_sb_rsp), UVM_LOW)
            end
            o_rx_encoding_expected=0;
        end
        else begin
            match = 1'b1; // Default to match if no specific condition is met
        end
        return match;
    endfunction

    virtual function fsm_t getStateId();
        return fsm_mbtrain_rx_repair;
    endfunction
endclass //mbtrain_rx_rxclkcal extends state