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
class mbtrain_rx_linkspeed extends state;
    local static mbtrain_rx_linkspeed inst = null;
    logic [8:0] o_rx_encoding_expected;
    logic [15:0] o_rx_info_expected;
    logic o_sb_rx_req_expected;
    logic o_sb_rx_rsp_expected;
    logic [63:0] o_rx_data_expected;
    bit match;
    protected function new(); endfunction

    static function mbtrain_rx_linkspeed Instance();
        if (inst == null)
        inst = new();
        return inst;
    endfunction

    virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_sequence_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_sequence_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);                                      
        if(item_rx_fsm_sb_in.i_rx_decoding == RX_MBTRAIN_LINKSPEED_Start_Handshake && item_rx_fsm_sb_in.i_sb_rx_req==1'b1 && cntxt.currentstate_rx == mbtrain_rx_dtc2::Instance())begin
            o_rx_encoding_expected = RX_MBTRAIN_LINKSPEED_Start_Handshake;
            end_sweep=0;
            o_rx_info_expected = 16'h0000;
            o_sb_rx_rsp_expected = 1'b1;
            train =1;
            if (o_rx_encoding_expected==item_rx_fsm_sb_out.o_rx_encoding && o_rx_info_expected==item_rx_fsm_sb_out.o_rx_info && o_sb_rx_rsp_expected == item_rx_fsm_sb_out.o_sb_rx_rsp) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("o_sb_rx_rsp mismatch expected value: %0b, got %0b", o_sb_rx_rsp_expected, item_rx_fsm_sb_out.o_sb_rx_rsp), UVM_LOW)
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
            end
        end
        else if(item_rx_fsm_sb_in.i_rx_decoding == DATA_TO_CLOCK_TX_RX_INIT_HANDSHAKE && item_rx_fsm_sb_in.i_sb_rx_req==1'b1)begin
            o_rx_encoding_expected = DATA_TO_CLOCK_TX_RX_INIT_HANDSHAKE;
            o_rx_info_expected = 16'h0000;
            o_error_threshhold_expected=item_rx_fsm_sb_in.i_rx_info;
            o_sb_rx_rsp_expected = 1'b1;
            train =0;
            if (o_rx_encoding_expected==item_rx_fsm_sb_out.o_rx_encoding && o_rx_info_expected==item_rx_fsm_sb_out.o_rx_info && o_sb_rx_rsp_expected == item_rx_fsm_sb_out.o_sb_rx_rsp && o_error_threshhold_expected == item_controllers_out.o_error_threshhold) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("o_sb_rx_rsp mismatch expected value: %0b, got %0b", o_sb_rx_rsp_expected, item_rx_fsm_sb_out.o_sb_rx_rsp), UVM_LOW)
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("o_error_threshhold mismatch expected value: %0h, got %0h", o_error_threshhold_expected, item_controllers_out.o_error_threshhold), UVM_LOW)
            end           
        end
        else if (item_rx_fsm_sb_in.i_rx_decoding == DATA_TO_CLOCK_TX_RX_LFSR_CLEAR_HANDSHAKE && item_rx_fsm_sb_in.i_sb_rx_req==1'b1 ) begin
            o_rx_encoding_expected = DATA_TO_CLOCK_TX_RX_LFSR_CLEAR_HANDSHAKE;
            o_rx_info_expected = 16'h0000;
            o_sb_rx_rsp_expected = 1'b1;
            train =0;
            if (o_rx_encoding_expected==item_rx_fsm_sb_out.o_rx_encoding && o_rx_info_expected==item_rx_fsm_sb_out.o_rx_info && o_sb_rx_rsp_expected == item_rx_fsm_sb_out.o_sb_rx_rsp) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("o_sb_rx_rsp mismatch expected value: %0b, got %0b", o_sb_rx_rsp_expected, item_rx_fsm_sb_out.o_sb_rx_rsp), UVM_LOW)
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
            end 
        end
        else if (item_rx_fsm_sb_in.i_sb_rx_done == 1 && !train) begin
            o_rx_encoding_expected = DATA_TO_CLOCK_TX_RX_PATTERN_GENERATION;
            if (o_rx_encoding_expected == item_rx_fsm_sb_out.o_rx_encoding) begin
                match=1;
            end else begin
                match =0;
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
            end 
        end
        else if (item_rx_fsm_sb_in.i_rx_decoding == DATA_TO_CLOCK_TX_RX_RESULT_HANDSHAKE && item_rx_fsm_sb_in.i_sb_rx_req==1'b1) begin
            o_rx_encoding_expected = DATA_TO_CLOCK_TX_RX_RESULT_HANDSHAKE;
            o_rx_info_expected[5] = item_controllers_in.i_val_error;
            o_rx_info_expected[4] = (&item_controllers_in.i_lane_error);
            o_rx_data_expected = item_controllers_in.i_lane_error;
            o_sb_rx_rsp_expected = 1'b1;
            if (o_rx_encoding_expected==item_rx_fsm_sb_out.o_rx_encoding && o_rx_info_expected[5:4]==item_rx_fsm_sb_out.o_rx_info[5:4] && o_sb_rx_rsp_expected == item_rx_fsm_sb_out.o_sb_rx_rsp && o_rx_data_expected == item_rx_fsm_sb_out.o_rx_data) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("o_sb_rx_rsp mismatch expected value: %0b, got %0b", o_sb_rx_rsp_expected, item_rx_fsm_sb_out.o_sb_rx_rsp), UVM_LOW)
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_data_expected, item_rx_fsm_sb_out.o_rx_data), UVM_LOW)
            end  
        end
        else if (item_rx_fsm_sb_in.i_rx_decoding == DATA_TO_CLOCK_TX_RX_END_INIT_HANDSHAKE && item_rx_fsm_sb_in.i_sb_rx_req==1'b1) begin 
            o_rx_encoding_expected = DATA_TO_CLOCK_TX_RX_END_INIT_HANDSHAKE;
            o_rx_info_expected = 16'h0000;
            o_sb_rx_rsp_expected = 1'b1;
            if (o_rx_encoding_expected == item_rx_fsm_sb_out.o_rx_encoding && o_rx_info_expected == item_rx_fsm_sb_out.o_rx_info && o_sb_rx_rsp_expected == item_rx_fsm_sb_out.o_sb_rx_rsp) begin
                match=1;
            end else begin
                match =0;
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("o_sb_rx_rsp mismatch expected value: %0b, got %0b", o_sb_rx_rsp_expected, item_rx_fsm_sb_out.o_sb_rx_rsp), UVM_LOW)
            end
        end
        // no error
        else if ((item_rx_fsm_sb_in.i_sb_rx_req && item_rx_fsm_sb_in.i_rx_decoding == MBTRAIN_LINKSPEED_TX_Error_Hnd && error_count==0)||(item_rx_fsm_sb_in.i_sb_rx_req && item_rx_fsm_sb_in.i_rx_decoding != MBTRAIN_LINKSPEED_TX_Error_Hnd && error_count!=0) ) begin
            o_rx_encoding_expected = RX_MBTRAIN_LINKSPEED_Send_PhyRetrain_RESP;
            o_rx_info_expected = 16'h0000;
            o_sb_rx_req_expected = 1'b1;
            if (o_rx_encoding_expected == item_rx_fsm_sb_out.o_rx_encoding && o_rx_info_expected == item_rx_fsm_sb_out.o_rx_info && o_sb_rx_rsp_expected == item_rx_fsm_sb_out.o_sb_rx_rsp) begin
                match=1;
            end else begin
                match =0;
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("o_sb_rx_rsp mismatch expected value: %0b, got %0b", o_sb_rx_rsp_expected, item_rx_fsm_sb_out.o_sb_rx_rsp), UVM_LOW)
            end
        end
        // error
        else if (item_rx_fsm_sb_in.i_sb_rx_req && item_rx_fsm_sb_in.i_rx_decoding == MBTRAIN_LINKSPEED_TX_Error_Hnd && error_count!=0) begin
            o_rx_encoding_expected = RX_MBTRAIN_LINKSPEED_Send_Error_RESP;
            o_rx_info_expected = 16'h0000;
            o_sb_rx_rsp_expected = 1'b1;
            if (o_rx_encoding_expected == item_rx_fsm_sb_out.o_rx_encoding && o_rx_info_expected == item_rx_fsm_sb_out.o_rx_info && o_sb_rx_rsp_expected == item_rx_fsm_sb_out.o_sb_rx_rsp) begin
                match=1;
            end else begin
                match =0;
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("o_sb_rx_rsp mismatch expected value: %0b, got %0b", o_sb_rx_rsp_expected, item_rx_fsm_sb_out.o_sb_rx_rsp), UVM_LOW)
            end
        end
        else if (item_rx_fsm_sb_in.i_sb_rx_req && item_rx_fsm_sb_in.i_rx_decoding == MBTRAIN_LINKSPEED_TX_Exit_SpeedDegrade_Hnd ) begin
            o_rx_encoding_expected = RX_MBTRAIN_LINKSPEED_Send_SpeedDegrade_RESP;
            enter_speeddegrade=1'b1;
            o_rx_info_expected = 16'h0000;
            o_sb_rx_rsp_expected = 1'b1;
            state_done=1'b1;
            if (o_rx_encoding_expected == item_rx_fsm_sb_out.o_rx_encoding && o_rx_info_expected == item_rx_fsm_sb_out.o_rx_info && o_sb_rx_rsp_expected == item_rx_fsm_sb_out.o_sb_rx_rsp) begin
                match=1;
            end else begin
                match =0;
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("o_sb_rx_rsp mismatch expected value: %0b, got %0b", o_sb_rx_rsp_expected, item_rx_fsm_sb_out.o_sb_rx_rsp), UVM_LOW)
            end
        end
        else if (item_rx_fsm_sb_in.i_sb_rx_req && item_rx_fsm_sb_in.i_rx_decoding == MBTRAIN_LINKSPEED_TX_Repair_Hnd && lane_map_tx!=3'b000) begin
            o_rx_encoding_expected = RX_MBTRAIN_LINKSPEED_Send_Repair_RESP;
            o_rx_info_expected = 16'h0000;
            o_sb_rx_rsp_expected = 1'b1;
            state_done=1'b1;
            if (o_rx_encoding_expected == item_rx_fsm_sb_out.o_rx_encoding && o_rx_info_expected == item_rx_fsm_sb_out.o_rx_info && o_sb_rx_rsp_expected == item_rx_fsm_sb_out.o_sb_rx_rsp) begin
                match=1;
            end else begin
                match =0;
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("o_sb_rx_rsp mismatch expected value: %0b, got %0b", o_sb_rx_rsp_expected, item_rx_fsm_sb_out.o_sb_rx_rsp), UVM_LOW)
            end
        end
        else if ( item_rx_fsm_sb_in.i_sb_rx_req && item_rx_fsm_sb_in.i_rx_decoding == RX_MBTRAIN_LINKSPEED_Send_Done_RESP && && error_count!=0 ) begin
            o_rx_encoding_expected = RX_MBTRAIN_LINKSPEED_Send_Done_RESP;
            o_rx_info_expected = 16'h0000;
            o_sb_rx_rsp_expected = 1'b1;
            state_done=1'b1;
            if (o_rx_encoding_expected == item_rx_fsm_sb_out.o_rx_encoding && o_rx_info_expected == item_rx_fsm_sb_out.o_rx_info && o_sb_rx_rsp_expected == item_rx_fsm_sb_out.o_sb_rx_rsp) begin
                match=1;
            end else begin
                match =0;
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
                `uvm_info("mbtrain_rx_linkspeed", $sformatf("o_sb_rx_rsp mismatch expected value: %0b, got %0b", o_sb_rx_rsp_expected, item_rx_fsm_sb_out.o_sb_rx_rsp), UVM_LOW)
            end
        end
        
        return match;
    endfunction
    // for coverage and state transistion
    virtual function fsm_t getStateId();
        return fsm_mbtrain_rx_linkspeed;
    endfunction


endclass //mbtrain_rx_datatrainvref extends state