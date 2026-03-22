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
class mbtrain_tx_linkspeed extends state;
    local static mbtrain_tx_linkspeed inst = null;
    logic [8:0] o_tx_encoding_expected;
    logic [15:0] o_tx_info_expected;
    logic o_sb_tx_req_expected;
    logic o_sb_tx_rsp_expected;
    logic[63:0] o_tx_data_expected;
    bit match;
    logic [63:0] data;
        protected function new(); endfunction

    static function mbtrain_tx_linkspeed Instance();
        if (inst == null)
        inst = new();
        return inst;
    endfunction

    virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_sequence_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_sequence_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
        if(item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_DTC2_TX_End_Handshake && state_done && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1 && cntxt.currentstate_tx == mbtrain_tx_dtc2::Instance()) begin
            o_tx_encoding_expected = MBTRAIN_LINKSPEED_TX_Start_Handshake ;
            state_done=1'b0;
            o_tx_info_expected = 16'h0000;
            o_sb_tx_req_expected = 1'b1;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_sb_tx_req_expected == item_tx_fsm_sb_out.o_sb_tx_req) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_sb_tx_req mismatch expected value: %0b, got %0b", o_sb_tx_req_expected, item_tx_fsm_sb_out.o_sb_tx_req), UVM_LOW)
            end
        end
        else if((item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_DTC2_TX_End_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1 )) begin
            o_tx_encoding_expected = DATA_TO_CLOCK_TX_RX_INIT_HANDSHAKE;
            train = 1;
            o_tx_info_expected = 16'h0000 ;
            o_tx_data_expected = /*will be known*/ ;
            o_sb_tx_req_expected = 1'b1;
            error_count = 0;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_sb_tx_req_expected == item_tx_fsm_sb_out.o_sb_tx_req && o_tx_data_expected == item_tx_fsm_sb_out.o_tx_data ) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_sb_tx_rsp_expected mismatch expected value: %0b, got %0b", o_sb_tx_req_expected, item_tx_fsm_sb_out.o_sb_tx_req), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_data_expected, item_tx_fsm_sb_out.o_tx_data), UVM_LOW)
            end
        end
        else if ((item_tx_fsm_sb_in.i_tx_decoding == DATA_TO_CLOCK_TX_RX_INIT_HANDSHAKE && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1 ) ) begin
            o_tx_encoding_expected = DATA_TO_CLOCK_TX_RX_LFSR_CLEAR_HANDSHAKE;
            error_count=0;
            o_tx_info_expected = 16'h0000;
            o_sb_tx_req_expected = 1'b1;
            if (!item_tx_fsm_sb_in.i_tx_info[4]) begin
                error_count++;
            end
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_sb_tx_req_expected == item_tx_fsm_sb_out.o_sb_tx_req) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_sb_tx_req mismatch expected value: %0b, got %0b", o_sb_tx_req_expected, item_tx_fsm_sb_out.o_sb_tx_req), UVM_LOW)
            end
        end
        else if (item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1 && item_tx_fsm_sb_in.i_tx_decoding == DATA_TO_CLOCK_TX_RX_LFSR_CLEAR_HANDSHAKE) begin
            o_tx_encoding_expected = DATA_TO_CLOCK_TX_RX_PATTERN_GENERATION;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
            end
        end
        else if (item_controllers_in.i_tx_done && train)begin
            o_tx_encoding_expected = DATA_TO_CLOCK_TX_RX_RESULT_HANDSHAKE;
            o_tx_info_expected = 16'h0000;
            o_sb_tx_req_expected = 1'b1;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_sb_tx_req_expected == item_tx_fsm_sb_out.o_sb_tx_req) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_sb_tx_req mismatch expected value: %0b, got %0b", o_sb_tx_req_expected, item_tx_fsm_sb_out.o_sb_tx_req), UVM_LOW)
            end
        end
        // else if ((item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1 && item_tx_fsm_sb_in.i_tx_decoding == DATA_TO_CLOCK_TX_RX_RESULT_HANDSHAKE && !retry )) begin
        //     o_tx_encoding_expected = DATA_TO_CLOCK_RX_RX_SWEEP_RESULT_HANDSHAKE;
        //     if (!item_tx_fsm_sb_in.i_tx_info[4]) begin
        //         error_count++;
        //     end
        //     data=item_tx_fsm_sb_in.i_tx_data;
        //     o_tx_info_expected = 16'h0000;
        //     o_sb_tx_req_expected = 1'b1;
        //     train =0;
        //     if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_sb_tx_req_expected == item_tx_fsm_sb_out.o_sb_tx_req) begin
        //         match = 1;
        //     end else begin
        //         match = 0;
        //         `uvm_info("mbtrain_tx_valtraincenter", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
        //         `uvm_info("mbtrain_tx_valtraincenter", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
        //         `uvm_info("mbtrain_tx_valtraincenter", $sformatf("o_sb_tx_req mismatch expected value: %0b, got %0b", o_sb_tx_req_expected, item_tx_fsm_sb_out.o_sb_tx_req), UVM_LOW)
        //     end
        // end
        else if (item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1 && item_tx_fsm_sb_in.i_tx_decoding == DATA_TO_CLOCK_TX_RX_RESULT_HANDSHAKE) begin
            o_tx_encoding_expected = DATA_TO_CLOCK_RX_RX_END_INIT_HANDSHAKE;
            o_tx_info_expected = 16'h0000;
            if (!item_tx_fsm_sb_in.i_tx_info[4]) begin
                error_count++;
            end
            data=item_tx_fsm_sb_in.i_tx_data;
            if (data[15:8]<8'b1111_1111 && data[7:0] == 8'b1111_1111 ) begin
                lane_map_tx=3'b001;
            end
            else if (data[7:0]<8'b1111_1111 && data[15:8] == 8'b1111_1111 ) begin
                lane_map_tx=3'b010;
            end
            else if (data[15:8] == 8'b1111_1111 && data[7:0] == 8'b1111_1111 ) begin
                lane_map_tx=3'b011;
            end
            else if (data[15:8]<8'b1111_1111 && data[7:4] < 4'b1111 ) begin
                lane_map_tx=3'b100;
            end
            else if (data[15:8]<8'b1111_1111 && data[3:0] < 4'b1111 ) begin
                lane_map_tx=3'b101;
            end
            else begin
                lane_map_tx=3'b000;
            end
            o_sb_tx_rsp_expected = 1'b1;
            train =0;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_sb_tx_rsp_expected == item_tx_fsm_sb_out.o_sb_tx_rsp) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_valtraincenter", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_valtraincenter", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_valtraincenter", $sformatf("o_sb_tx_req mismatch expected value: %0b, got %0b", o_sb_tx_rsp_expected, item_tx_fsm_sb_out.o_sb_tx_rsp), UVM_LOW)
            end
        end
        else if(error_count==0 && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1 && item_tx_fsm_sb_in.i_tx_decoding == DATA_TO_CLOCK_RX_RX_END_INIT_HANDSHAKE && !train) begin
            o_tx_encoding_expected = MBTRAIN_LINKSPEED_TX_LinkSpeed_Done_Hnd ;
            o_tx_info_expected = 16'h0000;
            o_sb_tx_req_expected = 1'b1;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_sb_tx_req_expected == item_tx_fsm_sb_out.o_sb_tx_req) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_sb_tx_req mismatch expected value: %0b, got %0b", o_sb_tx_req_expected, item_tx_fsm_sb_out.o_sb_tx_req), UVM_LOW)
            end
        end
        else if(error_count!=0 && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1 && item_tx_fsm_sb_in.i_tx_decoding == DATA_TO_CLOCK_RX_RX_END_INIT_HANDSHAKE && !train) begin
            o_tx_encoding_expected = MBTRAIN_LINKSPEED_TX_Error_Hnd ;
            o_tx_info_expected = 16'h0000;
            // if (data[15:8]<8'b1111_1111 && data[7:0] == 8'b1111_1111 ) begin
            //     lane_map_tx=3'b001;
            // end
            // else if (data[7:0]<8'b1111_1111 && data[15:8] == 8'b1111_1111 ) begin
            //     lane_map_tx=3'b010;
            // end
            // else if (data[15:8] == 8'b1111_1111 && data[7:0] == 8'b1111_1111 ) begin
            //     lane_map_tx=3'b011;
            // end
            // else if (data[15:8]<8'b1111_1111 && data[7:4] < 4'b1111 ) begin
            //     lane_map_tx=3'b100;
            // end
            // else if (data[15:8]<8'b1111_1111 && data[3:0] < 4'b1111 ) begin
            //     lane_map_tx=3'b101;
            // end
            // else begin
            //     lane_map_tx=3'b000;
            // end
            o_sb_tx_req_expected = 1'b1;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_sb_tx_req_expected == item_tx_fsm_sb_out.o_sb_tx_req) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_sb_tx_req mismatch expected value: %0b, got %0b", o_sb_tx_req_expected, item_tx_fsm_sb_out.o_sb_tx_req), UVM_LOW)
            end
        end
        else if((item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_LINKSPEED_TX_Phy_Retrain_Hnd && item_tx_fsm_sb_in.i_sb_tx_req==1'b1 )) begin
            o_tx_encoding_expected = MBTRAIN_LINKSPEED_TX_Phy_Retrain_Hnd;
            o_tx_info_expected = 16'h0000 ;
            o_sb_tx_rsp_expected = 1'b1;
            state_done = 1;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_sb_tx_rsp_expected == item_tx_fsm_sb_out.o_sb_tx_rsp && o_tx_data_expected == item_tx_fsm_sb_out.o_tx_data ) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_sb_tx_rsp_expected mismatch expected value: %0b, got %0b", o_sb_tx_rsp_expected, item_tx_fsm_sb_out.o_sb_tx_rsp), UVM_LOW)
            end
        end
        else if ((lane_map_tx==0 && item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_LINKSPEED_TX_Error_Hnd && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1)) begin
            o_tx_encoding_expected = MBTRAIN_LINKSPEED_TX_Exit_SpeedDegrade_Hnd ;
            o_tx_info_expected = 16'h0000;
            o_sb_tx_req_expected = 1'b1;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_sb_tx_req_expected == item_tx_fsm_sb_out.o_sb_tx_req) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_sb_tx_req mismatch expected value: %0b, got %0b", o_sb_tx_req_expected, item_tx_fsm_sb_out.o_sb_tx_req), UVM_LOW)
            end
        end
        else if (lane_map_tx!=0 && item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_LINKSPEED_TX_Error_Hnd && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1) begin
            o_tx_encoding_expected = MBTRAIN_LINKSPEED_TX_Repair_Hnd ;
            o_tx_info_expected = 16'h0000;
            o_sb_tx_req_expected = 1'b1;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_sb_tx_req_expected == item_tx_fsm_sb_out.o_sb_tx_req) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_sb_tx_req mismatch expected value: %0b, got %0b", o_sb_tx_req_expected, item_tx_fsm_sb_out.o_sb_tx_req), UVM_LOW)
            end
        end
        return match;
    endfunction

    virtual function fsm_t getStateId();
        return fsm_mbtrain_tx_speedidle;
    endfunction
endclass //mbtrain_tx_txselfcal extends state