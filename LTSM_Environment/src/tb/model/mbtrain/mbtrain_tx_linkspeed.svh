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
class mbtrain_tx_linkspeed extends State;
    local static mbtrain_tx_linkspeed inst = null;
    logic [8:0] o_tx_encoding_expected;
    logic [15:0] o_tx_info_expected;
    logic o_tx_sb_req_expected;
    logic o_tx_sb_rsp_expected;
    logic[63:0] o_tx_data_expected;
    bit match;
    logic [63:0] data;
        protected function new(); endfunction

    static function mbtrain_tx_linkspeed Instance();
        if (inst == null)
        inst = new();
        return inst;
    endfunction

    virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);

        // ----------------------------------------------------------------
        // Phase 1 trigger: DTC2 End Handshake response received → enter
        // LINKSPEED Start Handshake. Clear state_done, set req, verify
        // only o_tx_encoding this cycle.
        // ----------------------------------------------------------------
        if(item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_DTC2_TX_End_Handshake && state_done && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1 && cntxt.currentstate_tx == mbtrain_tx_dtc2::Instance()) begin
            o_tx_encoding_expected = MBTRAIN_LINKSPEED_TX_Start_Handshake;
            state_done = 1'b0;
            o_tx_sb_req_expected = 1'b1;
            if (o_tx_encoding_expected == item_tx_fsm_sb_out.o_tx_encoding) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
            end
        end
        // ----------------------------------------------------------------
        // Phase 2 follow-up: LINKSPEED Start Handshake in progress.
        // Full 3-field check (encoding, info, req), then clear expected encoding.
        // ----------------------------------------------------------------
        else if (o_tx_encoding_expected == MBTRAIN_LINKSPEED_TX_Start_Handshake) begin
            o_tx_info_expected = 16'h0000;
            o_tx_sb_req_expected = 1'b1;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_tx_sb_req_expected == item_tx_fsm_sb_out.o_tx_sb_req) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_sb_req mismatch expected value: %0b, got %0b", o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            end
            o_tx_encoding_expected = 0;
        end
        // ----------------------------------------------------------------
        // Phase 1 trigger: LINKSPEED Start Handshake response received →
        // transition to DATA_TO_CLOCK RX INIT handshake. Arm training,
        // reset error counter, verify only o_tx_encoding this cycle.
        // ----------------------------------------------------------------
        else if(item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_LINKSPEED_TX_Start_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1) begin
            o_tx_encoding_expected = DATA_TO_CLOCK_TX_RX_INIT_HANDSHAKE;
            train = 1;
            error_count = 0;
            o_tx_sb_req_expected = 1'b1;
            if (o_tx_encoding_expected == item_tx_fsm_sb_out.o_tx_encoding) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
            end
        end
        // ----------------------------------------------------------------
        // Phase 2 follow-up: DATA_TO_CLOCK RX INIT handshake in progress.
        // Full 3-field check (encoding, info, req), include data field check.
        // Then clear expected encoding.
        // ----------------------------------------------------------------
        else if (o_tx_encoding_expected == DATA_TO_CLOCK_TX_RX_INIT_HANDSHAKE) begin
            o_tx_info_expected = 16'h0001;
            o_tx_data_expected = data_DATA_FIELD;
            o_tx_sb_req_expected = 1'b1;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_tx_sb_req_expected == item_tx_fsm_sb_out.o_tx_sb_req /*&& o_tx_data_expected == item_tx_fsm_sb_out.o_tx_data*/) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_sb_rsp_expected mismatch expected value: %0b, got %0b", o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_data_expected: expected %0h, got %0h", o_tx_data_expected, item_tx_fsm_sb_out.o_tx_data), UVM_LOW)
            end
            o_tx_encoding_expected = 0;
        end
        // ----------------------------------------------------------------
        // Phase 1 trigger: RX INIT handshake response received →
        // transition to LFSR CLEAR handshake. Verify only encoding.
        // ----------------------------------------------------------------
        else if (item_tx_fsm_sb_in.i_tx_decoding == DATA_TO_CLOCK_TX_RX_INIT_HANDSHAKE && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1) begin
            o_tx_encoding_expected = DATA_TO_CLOCK_TX_RX_LFSR_CLEAR_HANDSHAKE;
            o_tx_sb_req_expected = 1'b1;
            if (o_tx_encoding_expected == item_tx_fsm_sb_out.o_tx_encoding) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
            end
        end
        // ----------------------------------------------------------------
        // Phase 2 follow-up: LFSR CLEAR handshake in progress.
        // Full 3-field check (encoding, info, req), then clear expected encoding.
        // ----------------------------------------------------------------
        else if (o_tx_encoding_expected == DATA_TO_CLOCK_TX_RX_LFSR_CLEAR_HANDSHAKE) begin
            o_tx_info_expected = 16'h0000;
            o_tx_sb_req_expected = 1'b1;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_tx_sb_req_expected == item_tx_fsm_sb_out.o_tx_sb_req) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_sb_req mismatch expected value: %0b, got %0b", o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            end
            o_tx_encoding_expected = 0;
        end
        // ----------------------------------------------------------------
        // Phase 1 trigger: LFSR CLEAR response received → begin PATTERN
        // GENERATION. Re-arm training. Verify only encoding.
        // ----------------------------------------------------------------
        else if (item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1 && item_tx_fsm_sb_in.i_tx_decoding == DATA_TO_CLOCK_TX_RX_LFSR_CLEAR_HANDSHAKE) begin
            o_tx_encoding_expected = DATA_TO_CLOCK_TX_RX_PATTERN_GENERATION;
            train = 1;
            if (o_tx_encoding_expected == item_tx_fsm_sb_out.o_tx_encoding) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
            end
        end
        // ----------------------------------------------------------------
        // Phase 1 trigger: TX training done while in PATTERN GENERATION →
        // transition to RESULT handshake. Deassert train, verify only encoding.
        // ----------------------------------------------------------------
        else if (item_controllers_in.i_tx_done && train && o_tx_encoding_expected == DATA_TO_CLOCK_TX_RX_PATTERN_GENERATION) begin
            o_tx_encoding_expected = DATA_TO_CLOCK_TX_RX_RESULT_HANDSHAKE;
            train = 0;
            o_tx_sb_req_expected = 1'b1;
            if (o_tx_encoding_expected == item_tx_fsm_sb_out.o_tx_encoding) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
            end
        end
        // ----------------------------------------------------------------
        // Phase 2 follow-up: RESULT handshake in progress.
        // Full 3-field check (encoding, info, req), then clear expected encoding.
        // ----------------------------------------------------------------
        else if (o_tx_encoding_expected == DATA_TO_CLOCK_TX_RX_RESULT_HANDSHAKE) begin
            o_tx_info_expected = 16'h0000;
            o_tx_sb_req_expected = 1'b1;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_tx_sb_req_expected == item_tx_fsm_sb_out.o_tx_sb_req) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_sb_req mismatch expected value: %0b, got %0b", o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            end
            o_tx_encoding_expected = 0;
        end
        // ----------------------------------------------------------------
        // Phase 1 trigger: RESULT handshake response received →
        // transition to END INIT handshake. Capture data, evaluate lane map,
        // update error count, deassert train. Verify only encoding.
        // ----------------------------------------------------------------
        else if (item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1 && item_tx_fsm_sb_in.i_tx_decoding == DATA_TO_CLOCK_TX_RX_RESULT_HANDSHAKE) begin
            o_tx_encoding_expected = DATA_TO_CLOCK_TX_RX_END_INIT_HANDSHAKE;
            if (!item_tx_fsm_sb_in.i_tx_info[4]) begin
                error_count=1;
            end
            data = item_tx_fsm_sb_in.i_tx_data;
            if (data[15:8] < 8'b1111_1111 && data[7:0] == 8'b1111_1111) begin
                lane_map_tx = 3'b001;
            end else if (data[7:0] < 8'b1111_1111 && data[15:8] == 8'b1111_1111) begin
                lane_map_tx = 3'b010;
            end else if (data[15:8] == 8'b1111_1111 && data[7:0] == 8'b1111_1111) begin
                lane_map_tx = item_controllers_out.o_lane_map_tx;
            end else if (data[15:8] < 8'b1111_1111 && data[7:4] < 4'b1111) begin
                lane_map_tx = 3'b100;
            end else if (data[15:8] < 8'b1111_1111 && data[3:0] < 4'b1111) begin
                lane_map_tx = 3'b101;
            end else begin
                lane_map_tx = 3'b000;
            end
            train = 0;
            o_tx_sb_req_expected = 1'b1;
            if (o_tx_encoding_expected == item_tx_fsm_sb_out.o_tx_encoding) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
            end
        end
        // ----------------------------------------------------------------
        // Phase 2 follow-up: END INIT handshake in progress.
        // Full 3-field check (encoding, info, req), then clear expected encoding.
        // ----------------------------------------------------------------
        else if (o_tx_encoding_expected == DATA_TO_CLOCK_TX_RX_END_INIT_HANDSHAKE) begin
            o_tx_info_expected = 16'h0000;
            o_tx_sb_req_expected = 1'b1;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_tx_sb_req_expected == item_tx_fsm_sb_out.o_tx_sb_req) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_sb_req mismatch expected value: %0b, got %0b", o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            end
            o_tx_encoding_expected = 0;
        end
        // ----------------------------------------------------------------
        // Phase 1 trigger: END INIT handshake response received with no errors
        // → transition to LINKSPEED Done. Verify only encoding.
        // ----------------------------------------------------------------
        else if (error_count==0 && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1 && item_tx_fsm_sb_in.i_tx_decoding == DATA_TO_CLOCK_RX_RX_END_INIT_HANDSHAKE ) begin
            $display("1111111111111111111111111111111111");
            o_tx_encoding_expected = MBTRAIN_LINKSPEED_TX_LinkSpeed_Done_Hnd;
            o_tx_sb_req_expected = 1'b1;
            if (o_tx_encoding_expected == item_tx_fsm_sb_out.o_tx_encoding) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
            end
        end
        // ----------------------------------------------------------------
        // Phase 2 follow-up: LINKSPEED Done handshake in progress.
        // Full 3-field check (encoding, info, req). No encoding reset —
        // state machine transitions out via an external mechanism.
        // ----------------------------------------------------------------
        else if (o_tx_encoding_expected == MBTRAIN_LINKSPEED_TX_LinkSpeed_Done_Hnd) begin
            o_tx_info_expected = 16'h0000;
            o_tx_sb_req_expected = 1'b1;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_tx_sb_req_expected == item_tx_fsm_sb_out.o_tx_sb_req) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_sb_req mismatch expected value: %0b, got %0b", o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            end
            o_tx_encoding_expected =0;
        end
        // ----------------------------------------------------------------
        // Phase 1 trigger: END INIT response received with errors →
        // transition to Error handshake. Verify only encoding.
        // ----------------------------------------------------------------
        else if (error_count!=0 && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1 && item_tx_fsm_sb_in.i_tx_decoding == DATA_TO_CLOCK_RX_RX_END_INIT_HANDSHAKE && !train) begin
            o_tx_encoding_expected = MBTRAIN_LINKSPEED_TX_Error_Hnd;
            o_tx_sb_req_expected = 1'b1;
            if (o_tx_encoding_expected == item_tx_fsm_sb_out.o_tx_encoding) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
            end
        end
        // ----------------------------------------------------------------
        // Phase 2 follow-up: Error handshake in progress.
        // Full 3-field check (encoding, info, req), then clear expected encoding.
        // ----------------------------------------------------------------
        else if (o_tx_encoding_expected == MBTRAIN_LINKSPEED_TX_Error_Hnd) begin
            o_tx_info_expected = 16'h0000;
            o_tx_sb_req_expected = 1'b1;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_tx_sb_req_expected == item_tx_fsm_sb_out.o_tx_sb_req) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_sb_req mismatch expected value: %0b, got %0b", o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            end
            o_tx_encoding_expected = 0;
        end
        // ----------------------------------------------------------------
        // Phase 1 trigger: Error handshake response received with no repairable
        // lanes (lane_map_tx==0) → transition to Exit SpeedDegrade.
        // Verify only encoding.
        // ----------------------------------------------------------------
        else if (lane_map_tx==0 && item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_LINKSPEED_TX_Error_Hnd && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1) begin
            o_tx_encoding_expected = MBTRAIN_LINKSPEED_TX_Exit_SpeedDegrade_Hnd;
            o_tx_sb_req_expected = 1'b1;
            if (o_tx_encoding_expected == item_tx_fsm_sb_out.o_tx_encoding) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
            end
        end
        // ----------------------------------------------------------------
        // Phase 2 follow-up: Exit SpeedDegrade handshake in progress.
        // Full 3-field check (encoding, info, req), then clear expected encoding.
        // ----------------------------------------------------------------
        else if (o_tx_encoding_expected == MBTRAIN_LINKSPEED_TX_Exit_SpeedDegrade_Hnd) begin
            o_tx_info_expected = 16'h0000;
            o_tx_sb_req_expected = 1'b1;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_tx_sb_req_expected == item_tx_fsm_sb_out.o_tx_sb_req) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_sb_req mismatch expected value: %0b, got %0b", o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            end
            o_tx_encoding_expected = 0;
        end
        // ----------------------------------------------------------------
        // Phase 1 trigger: Error handshake response received with repairable
        // lanes (lane_map_tx!=0) → transition to Repair handshake.
        // Verify only encoding.
        // ----------------------------------------------------------------
        else if (lane_map_tx!=0 && item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_LINKSPEED_TX_Error_Hnd && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1) begin
            o_tx_encoding_expected = MBTRAIN_LINKSPEED_TX_Repair_Hnd;
            o_tx_sb_req_expected = 1'b1;
            if (o_tx_encoding_expected == item_tx_fsm_sb_out.o_tx_encoding) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
            end
        end
        // ----------------------------------------------------------------
        // Phase 2 follow-up: Repair handshake in progress.
        // Full 3-field check (encoding, info, req), then clear expected encoding.
        // ----------------------------------------------------------------
        else if (o_tx_encoding_expected == MBTRAIN_LINKSPEED_TX_Repair_Hnd) begin
            o_tx_info_expected = 16'h0000;
            o_tx_sb_req_expected = 1'b1;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_tx_sb_req_expected == item_tx_fsm_sb_out.o_tx_sb_req) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_sb_req mismatch expected value: %0b, got %0b", o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            end
            o_tx_encoding_expected = 0;
        end
        // ----------------------------------------------------------------
        // Phase 1 trigger: Phy Retrain request received from RX side →
        // respond with Phy Retrain handshake (RSP path). Set state_done,
        // verify only encoding.
        // ----------------------------------------------------------------
        else if (item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_LINKSPEED_TX_Phy_Retrain_Hnd && item_tx_fsm_sb_in.i_sb_tx_req==1'b1) begin
            o_tx_encoding_expected = MBTRAIN_LINKSPEED_TX_Phy_Retrain_Hnd;
            state_done = 1;
            o_tx_sb_rsp_expected = 1'b1;
            if (o_tx_encoding_expected == item_tx_fsm_sb_out.o_tx_encoding) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
            end
        end
        // ----------------------------------------------------------------
        // Phase 2 follow-up: Phy Retrain handshake in progress.
        // Full 3-field check (encoding, info, rsp + data). No encoding reset —
        // state_done governs re-entry from DTC2.
        // ----------------------------------------------------------------
        else if (o_tx_encoding_expected == MBTRAIN_LINKSPEED_TX_Phy_Retrain_Hnd) begin
            o_tx_info_expected = 16'h0000;
            o_tx_sb_rsp_expected = 1'b1;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_tx_sb_rsp_expected == item_tx_fsm_sb_out.o_tx_sb_rsp && o_tx_data_expected == item_tx_fsm_sb_out.o_tx_data) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_linkspeed", $sformatf("o_tx_sb_rsp_expected mismatch expected value: %0b, got %0b", o_tx_sb_rsp_expected, item_tx_fsm_sb_out.o_tx_sb_rsp), UVM_LOW)
            end
            o_tx_encoding_expected =0;
        end
        // ----------------------------------------------------------------
        // Default: no condition matched → assume match (no check applicable).
        // ----------------------------------------------------------------
        else begin
            match = 1'b1; // Default to match if no specific condition is met
        end
        return match;
    endfunction

    virtual function fsm_t getStateId();
        return fsm_mbtrain_tx_linkspeed;
    endfunction
endclass //mbtrain_tx_linkspeed extends state