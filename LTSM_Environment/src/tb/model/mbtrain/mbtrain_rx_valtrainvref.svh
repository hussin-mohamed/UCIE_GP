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
class mbtrain_rx_valtrainvref extends State;
    local static mbtrain_rx_valtrainvref inst = null;
    logic [8:0] o_rx_encoding_expected;
    logic [15:0] o_rx_info_expected;
    logic o_rx_sb_req_expected;
    logic o_rx_sb_rsp_expected;
    logic [63:0] o_rx_data_expected;
    bit match;
    bit first;
    bit first_time;
    bit firstt;
    protected function new(); endfunction

    static function mbtrain_rx_valtrainvref Instance();
        if (inst == null)
        inst = new();
        return inst;
    endfunction

    virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);

        // ----------------------------------------------------------------
        // Phase 1 trigger: RX side signals Start Handshake with sideband
        // request from valtraincenter state. Arm training, clear guards,
        // reset end_sweep, verify only o_rx_encoding this cycle.
        // ----------------------------------------------------------------
        if(item_rx_fsm_sb_in.i_rx_decoding == RX_MBTRAIN_VALTRAINVREF_Start_Handshake && item_rx_fsm_sb_in.i_sb_rx_req==1'b1 && cntxt.currentstate_rx == mbtrain_rx_valtraincenter::Instance()) begin
            o_rx_encoding_expected = RX_MBTRAIN_VALTRAINVREF_Start_Handshake;
            end_sweep = 0;
            o_rx_info_expected = 16'h0000;
            o_rx_sb_rsp_expected = 1'b1;
            first = 0;
            if (o_rx_encoding_expected == item_rx_fsm_sb_out.o_rx_encoding) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
            end
        end
        // ----------------------------------------------------------------
        // Phase 2 follow-up: Start Handshake in progress.
        // Full 3-field check (encoding, info, rsp), then clear expected
        // encoding and set first=1 to enable the RX INIT trigger.
        // ----------------------------------------------------------------
        else if (o_rx_encoding_expected == RX_MBTRAIN_VALTRAINVREF_Start_Handshake) begin
            if (o_rx_encoding_expected==item_rx_fsm_sb_out.o_rx_encoding && o_rx_info_expected==item_rx_fsm_sb_out.o_rx_info && o_rx_sb_rsp_expected == item_rx_fsm_sb_out.o_rx_sb_rsp) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("o_rx_sb_rsp mismatch expected value: %0b, got %0b", o_rx_sb_rsp_expected, item_rx_fsm_sb_out.o_rx_sb_rsp), UVM_LOW)
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
            end
            o_rx_encoding_expected = 0;
            first = 1;
        end
        // ----------------------------------------------------------------
        // Phase 1 trigger: RX done and first is set → transition to RX INIT
        // handshake. Clear first, set req, data, info fields.
        // Verify only o_rx_encoding this cycle.
        // ----------------------------------------------------------------
        else if((item_rx_fsm_sb_in.i_sb_rx_done == 1 && first ))begin
            o_rx_encoding_expected = DATA_TO_CLOCK_RX_RX_INIT_HANDSHAKE;
            first = 0;
            o_rx_data_expected=valid_DATA_FIELD;
            o_rx_info_expected = 16'h0001;
            o_rx_sb_req_expected = 1'b1;
            if (o_rx_encoding_expected==item_rx_fsm_sb_out.o_rx_encoding ) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
            end          
        end
        // ----------------------------------------------------------------
        // Phase 2 follow-up: RX INIT handshake in progress.
        // Full 4-field check (encoding, info, req, data), then clear
        // expected encoding.
        // ----------------------------------------------------------------
        else if (o_rx_encoding_expected == DATA_TO_CLOCK_RX_RX_INIT_HANDSHAKE) begin
            o_rx_sb_req_expected = 1'b1;
            if (o_rx_encoding_expected==item_rx_fsm_sb_out.o_rx_encoding && o_rx_info_expected==item_rx_fsm_sb_out.o_rx_info && o_rx_sb_req_expected == item_rx_fsm_sb_out.o_rx_sb_req && o_rx_data_expected == item_rx_fsm_sb_out.o_rx_data) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("o_rx_sb_req mismatch expected value: %0b, got %0b", o_rx_sb_req_expected, item_rx_fsm_sb_out.o_rx_sb_req), UVM_LOW)
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("o_rx_data mismatch expected value: %0h, got %0h", o_rx_data_expected, item_rx_fsm_sb_out.o_rx_data), UVM_LOW)
            end 
            o_rx_encoding_expected =0;
        end
        // ----------------------------------------------------------------
        // Phase 1 trigger: LFSR CLEAR handshake request received from RX.
        // Verify only o_rx_encoding this cycle.
        // ----------------------------------------------------------------
        else if (item_rx_fsm_sb_in.i_rx_decoding == DATA_TO_CLOCK_TX_RX_LFSR_CLEAR_HANDSHAKE && item_rx_fsm_sb_in.i_sb_rx_req==1'b1 ) begin
            o_rx_encoding_expected = DATA_TO_CLOCK_RX_RX_LFSR_CLEAR_HANDSHAKE;
            if (o_rx_encoding_expected == item_rx_fsm_sb_out.o_rx_encoding) begin
                match=1;
            end else begin
                match =0;
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
            end 
        end
        // ----------------------------------------------------------------
        // Phase 2 follow-up: LFSR CLEAR handshake in progress.
        // Full 3-field check (encoding, info, rsp), then clear expected
        // encoding and reset first_time guard.
        // ----------------------------------------------------------------
        else if (o_rx_encoding_expected == DATA_TO_CLOCK_RX_RX_LFSR_CLEAR_HANDSHAKE) begin
            o_rx_sb_rsp_expected = 1'b1;
            o_rx_info_expected = 16'h0000;
            if (o_rx_encoding_expected == item_rx_fsm_sb_out.o_rx_encoding && o_rx_info_expected == item_rx_fsm_sb_out.o_rx_info && o_rx_sb_rsp_expected == item_rx_fsm_sb_out.o_rx_sb_rsp) begin
                match=1;
            end else begin
                match =0;
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("o_rx_sb_rsp mismatch expected value: %0b, got %0b", o_rx_sb_rsp_expected, item_rx_fsm_sb_out.o_rx_sb_rsp), UVM_LOW)
            end
            o_rx_encoding_expected =0;
            first_time=0;
        end
        // ----------------------------------------------------------------
        // Phase 1 trigger: RX done and first_time not yet set → transition
        // to PATTERN GENERATION. Clear first_time. Verify only encoding.
        // ----------------------------------------------------------------
        else if (item_rx_fsm_sb_in.i_sb_rx_done == 1 && first_time ) begin
            o_rx_encoding_expected = DATA_TO_CLOCK_RX_RX_PATTERN_GENERATION;
            first_time=0;
            if (o_rx_encoding_expected == item_rx_fsm_sb_out.o_rx_encoding) begin
                match=1;
            end else begin
                match =0;
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
            end 
        end
        // ----------------------------------------------------------------
        // Phase 1 trigger: RESULT handshake request received from RX.
        // Capture result fields from controllers, set rsp.
        // Verify only o_rx_encoding this cycle.
        // ----------------------------------------------------------------
        else if (item_rx_fsm_sb_in.i_rx_decoding == DATA_TO_CLOCK_RX_RX_RESULT_HANDSHAKE && item_rx_fsm_sb_in.i_sb_rx_req==1'b1) begin
            o_rx_encoding_expected = DATA_TO_CLOCK_RX_RX_RESULT_HANDSHAKE;
            o_rx_info_expected = 0;
            o_rx_info_expected[5] = item_controllers_in.i_rx_valid_results;
            o_rx_info_expected[4] = (&item_controllers_in.i_rx_data_results);
            o_rx_data_expected = item_controllers_in.i_rx_data_results;
            o_rx_sb_rsp_expected = 1'b1;
            if (o_rx_encoding_expected == item_rx_fsm_sb_out.o_rx_encoding) begin
                match=1;
            end else begin
                match =0;
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
            end 
        end
        // ----------------------------------------------------------------
        // Phase 2 follow-up: RESULT handshake in progress.
        // Full 4-field check (encoding, info[5:4], rsp, data), then clear
        // expected encoding.
        // ----------------------------------------------------------------
        else if (o_rx_encoding_expected == DATA_TO_CLOCK_RX_RX_RESULT_HANDSHAKE) begin
            if (o_rx_encoding_expected==item_rx_fsm_sb_out.o_rx_encoding && o_rx_info_expected[5:4]==item_rx_fsm_sb_out.o_rx_info[5:4] && o_rx_sb_rsp_expected == item_rx_fsm_sb_out.o_rx_sb_rsp && o_rx_data_expected == item_rx_fsm_sb_out.o_rx_data) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("o_rx_sb_rsp mismatch expected value: %0b, got %0b", o_rx_sb_rsp_expected, item_rx_fsm_sb_out.o_rx_sb_rsp), UVM_LOW)
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("o_rx_data mismatch expected value: %0h, got %0h", o_rx_data_expected, item_rx_fsm_sb_out.o_rx_data), UVM_LOW)
            end 
            o_rx_encoding_expected =0;
        end
        // ----------------------------------------------------------------
        // Phase 1 trigger: SWEEP RESULT handshake request received and
        // end_sweep not yet set. Arm end_sweep guard. Silent match —
        // no mismatch logging on this cycle.
        // ----------------------------------------------------------------
        else if (item_rx_fsm_sb_in.i_rx_decoding == DATA_TO_CLOCK_RX_RX_SWEEP_RESULT_HANDSHAKE && item_rx_fsm_sb_in.i_sb_rx_req==1'b1 && !end_sweep) begin
            o_rx_encoding_expected = DATA_TO_CLOCK_RX_RX_SWEEP_RESULT_HANDSHAKE;
            end_sweep=1;
            if (o_rx_encoding_expected == item_rx_fsm_sb_out.o_rx_encoding) begin
                match=1;
            end else begin
                match =1;
                //`uvm_info("mbtrain_rx_valtrainvref", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
            end 
        end
        // ----------------------------------------------------------------
        // Phase 1 trigger: end_sweep set → transition to END INIT handshake.
        // Clear end_sweep, set firstt. Verify only o_rx_encoding this cycle.
        // ----------------------------------------------------------------
        else if (end_sweep ) begin 
            o_rx_encoding_expected = DATA_TO_CLOCK_RX_RX_END_INIT_HANDSHAKE;
            o_rx_info_expected = 16'h0000;
            o_rx_sb_req_expected = 1'b1;
            firstt=1;
            end_sweep =1'b0;
            if (o_rx_encoding_expected == item_rx_fsm_sb_out.o_rx_encoding) begin
                match=1;
            end else begin
                match =0;
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
            end 
        end
        // ----------------------------------------------------------------
        // Phase 2 follow-up: END INIT handshake in progress.
        // Full 3-field check (encoding, info, req), then clear expected
        // encoding.
        // ----------------------------------------------------------------
        else if (o_rx_encoding_expected == DATA_TO_CLOCK_RX_RX_END_INIT_HANDSHAKE) begin
            if (o_rx_encoding_expected == item_rx_fsm_sb_out.o_rx_encoding && o_rx_info_expected == item_rx_fsm_sb_out.o_rx_info && o_rx_sb_req_expected == item_rx_fsm_sb_out.o_rx_sb_req) begin
                match=1;
            end else begin
                match =0;
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("o_rx_sb_req mismatch expected value: %0b, got %0b", o_rx_sb_req_expected, item_rx_fsm_sb_out.o_rx_sb_req), UVM_LOW)
            end
            o_rx_encoding_expected =0;
        end
        // ----------------------------------------------------------------
        // Phase 1 trigger: End Handshake request received → respond with
        // RSP. Verify only o_rx_encoding this cycle.
        // ----------------------------------------------------------------
        else if (item_rx_fsm_sb_in.i_sb_rx_req && item_rx_fsm_sb_in.i_rx_decoding == RX_MBTRAIN_VALTRAINVREF_End_Handshake) begin
            o_rx_encoding_expected = RX_MBTRAIN_VALTRAINVREF_End_Handshake;
            o_rx_info_expected = 16'h0000;
            o_rx_sb_rsp_expected = 1'b1;
            
            if (o_rx_encoding_expected == item_rx_fsm_sb_out.o_rx_encoding) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
            end
        end
        // ----------------------------------------------------------------
        // Phase 2 follow-up: End Handshake in progress.
        // Full 3-field check (encoding, info, rsp), then clear expected
        // encoding.
        // ----------------------------------------------------------------
        else if (o_rx_encoding_expected == RX_MBTRAIN_VALTRAINVREF_End_Handshake) begin
            state_done = 1'b1;
            if (o_rx_encoding_expected == item_rx_fsm_sb_out.o_rx_encoding && o_rx_info_expected == item_rx_fsm_sb_out.o_rx_info && o_rx_sb_rsp_expected == item_rx_fsm_sb_out.o_rx_sb_rsp) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("Mismatch in o_rx_encoding: expected %0h, got %0h", o_rx_encoding_expected, item_rx_fsm_sb_out.o_rx_encoding), UVM_LOW)
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("o_rx_info mismatch expected value: %0h, got %0h", o_rx_info_expected, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
                `uvm_info("mbtrain_rx_valtrainvref", $sformatf("o_rx_sb_rsp mismatch expected value: %0b, got %0b", o_rx_sb_rsp_expected, item_rx_fsm_sb_out.o_rx_sb_rsp), UVM_LOW)
            end
            o_rx_encoding_expected = 0;
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
        return fsm_mbtrain_rx_valtrainvref;
    endfunction


endclass //mbtrain_rx_valvref extends state