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
class mbtrain_tx_datavref extends State;
    local static mbtrain_tx_datavref inst = null;
    logic [8:0] o_tx_encoding_expected;
    logic [15:0] o_tx_info_expected;
    logic o_tx_sb_req_expected;
    logic o_tx_sb_rsp_expected;
    logic[63:0] o_tx_data_expected;
    bit match;
    bit first;       // Guards the End Handshake trigger so it fires only once
    bit first_time;  // Set after the RX INIT follow-up phase; enables the tx_done→LFSR CLEAR trigger
    bit firstt;      // Guards the error-retry branch so it fires only once per result
    protected function new(); endfunction

    static function mbtrain_tx_datavref Instance();
        if (inst == null)
        inst = new();
        return inst;
    endfunction

    virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);

        // ----------------------------------------------------------------
        // Phase 1 trigger: valvref End Handshake completes with sideband
        // response → transition into datavref Start Handshake.
        // Arm retry, clear train/state_done flags, verify only o_tx_encoding.
        // ----------------------------------------------------------------
        if(item_tx_fsm_sb_in.i_tx_decoding == MBTRAIN_VALVREF_TX_End_Handshake && state_done && item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1 && cntxt.currentstate_tx == mbtrain_tx_valvref::Instance()) begin
            o_tx_encoding_expected = MBTRAIN_DATAVREF_TX_Start_Handshake;
            state_done = 1'b0;
            retry = 1;
            train = 0;
            first =1;
            if (o_tx_encoding_expected == item_tx_fsm_sb_out.o_tx_encoding) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_datavref", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
            end
        end
        // ----------------------------------------------------------------
        // Phase 2 follow-up: datavref Start Handshake in progress.
        // Assert o_tx_sb_req, do full 3-field check, then clear expected encoding.
        // ----------------------------------------------------------------
        else if (o_tx_encoding_expected == MBTRAIN_DATAVREF_TX_Start_Handshake) begin
            o_tx_sb_req_expected = 1'b1;
            o_tx_info_expected   = 16'h0000;
            if (o_tx_encoding_expected == item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected == item_tx_fsm_sb_out.o_tx_info && o_tx_sb_req_expected == item_tx_fsm_sb_out.o_tx_sb_req) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_datavref", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_sb_req mismatch expected value: %0b, got %0b", o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            end
            o_tx_encoding_expected = 0;
        end
       // ----------------------------------------------------------------
        // Phase 1 trigger: TX side receives RX INIT handshake request.
        // Arm training, set expected response fields, reset error counter
        // and first_time flag, verify only o_tx_encoding this cycle.
        // ----------------------------------------------------------------
        else if((item_tx_fsm_sb_in.i_tx_decoding == DATA_TO_CLOCK_RX_RX_INIT_HANDSHAKE && item_tx_fsm_sb_in.i_sb_tx_req==1'b1 ) ) begin
            o_tx_encoding_expected = DATA_TO_CLOCK_RX_RX_INIT_HANDSHAKE;
            train = 1;
            o_tx_info_expected = 16'h0000 ;
            //o_error_threshhold_expected=item_tx_fsm_sb_in.i_tx_info;
            o_tx_sb_rsp_expected = 1'b1;
            error_count = 0;
            first_time=0;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding ) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_datavref", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                //`uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                //`uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_sb_req mismatch expected value: %0b, got %0b", o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            end
           
        end
        // ----------------------------------------------------------------
        // Phase 2 follow-up: RX INIT handshake still in progress.
        // Full 3-field check (encoding, info, rsp). Set first_time=1 to
        // enable the subsequent tx_done → LFSR CLEAR trigger, then clear
        // the expected encoding.
        // ----------------------------------------------------------------
        else if (o_tx_encoding_expected == DATA_TO_CLOCK_RX_RX_INIT_HANDSHAKE) begin
            o_tx_sb_rsp_expected = 1'b1;
            o_tx_info_expected = 16'h0000;
             if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_tx_sb_rsp_expected == item_tx_fsm_sb_out.o_tx_sb_rsp /*&&  o_error_threshhold_expected==item_controllers_out.o_error_threshhold*/) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_datavref", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_sb_rsp_expected mismatch expected value: %0b, got %0b", o_tx_sb_rsp_expected, item_tx_fsm_sb_out.o_tx_sb_rsp), UVM_LOW)
                //`uvm_info("mbtrain_tx_datavref", $sformatf("o_error_threshhold_expected mismatch expected value: %0d, got %0d", o_error_threshhold_expected, item_controllers_out.o_error_threshhold), UVM_LOW)
            end
            o_tx_encoding_expected =0;
            first_time=1;
        end
        // ----------------------------------------------------------------
        // Phase 1 trigger: TX done while training and first_time is set →
        // transition to LFSR CLEAR handshake. Deassert train and first_time,
        // verify only o_tx_encoding this cycle.
        // ----------------------------------------------------------------
        else if (item_tx_fsm_sb_in.i_sb_tx_done && train && first_time  ) begin
            // $display("o_tx_encoding_expected = %0h, first_time = %0b, train = %0b", o_tx_encoding_expected, first_time, train);
            // $display("i_sb_tx_done =%0b", item_tx_fsm_sb_in.i_sb_tx_done);
            // $display("time = %0t",$time);
            o_tx_encoding_expected = DATA_TO_CLOCK_RX_RX_LFSR_CLEAR_HANDSHAKE;
            //o_tx_info_expected = 16'h0000;
            first_time=0;
            //o_tx_sb_req_expected = item_tx_fsm_sb_out.o_tx_sb_req;
            //o_tx_sb_req_expected = 1'b1;
            train=0;
            
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding ) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_datavref", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                // `uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                // `uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_sb_req mismatch expected value: %0b, got %0b", o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            end
        end
        // ----------------------------------------------------------------
        // Phase 2 follow-up: LFSR CLEAR handshake in progress.
        // Assert o_tx_sb_req, do full 3-field check, then clear expected encoding.
        // ----------------------------------------------------------------
        else if (o_tx_encoding_expected == DATA_TO_CLOCK_RX_RX_LFSR_CLEAR_HANDSHAKE) begin
            o_tx_sb_req_expected =1'b1;;
            o_tx_info_expected = 16'h0000;
           if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_tx_sb_req_expected == item_tx_fsm_sb_out.o_tx_sb_req) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_datavref", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_sb_req mismatch expected value: %0b, got %0b", o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            end
            o_tx_encoding_expected =0;
        end
        // ----------------------------------------------------------------
        // Error-retry branch: Result handshake response received but training
        // failed (bits [4] or [5] not set). Increment error counter and
        // loop back to LFSR CLEAR. If error_count reaches 4, escalate to
        // RX_TRAINERROR. firstt guards this branch to fire only once per result.
        // ----------------------------------------------------------------
        else if (item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1 && item_tx_fsm_sb_in.i_tx_decoding == DATA_TO_CLOCK_RX_RX_RESULT_HANDSHAKE && retry && (!item_tx_fsm_sb_in.i_tx_info[4] || !item_tx_fsm_sb_in.i_tx_info[5] )&& !firstt) begin
            o_tx_encoding_expected = DATA_TO_CLOCK_RX_RX_LFSR_CLEAR_HANDSHAKE;
            o_tx_info_expected = 16'h0000;
            firstt=1;
            // o_tx_sb_req_expected = item_tx_fsm_sb_out.o_tx_sb_req;
            //o_tx_sb_req_expected = 1'b1;
            train=0;
            error_count++;
            ////$display("error_count = %0d at time = %0t",error_count,$time);
            if (error_count == 4) begin
                o_tx_encoding_expected = RX_TRAINERROR_Handshake;
                o_tx_info_expected = 16'h0000;
                o_tx_sb_req_expected = 1'b1;
            end
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding ) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_datavref", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                // `uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                // `uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_sb_req mismatch expected value: %0b, got %0b", o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            end
        end
        // ----------------------------------------------------------------
        // LFSR CLEAR response received → begin PATTERN GENERATION.
        // Re-arm training and clear firstt to allow the next result check.
        // ----------------------------------------------------------------
        else if (item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1 && item_tx_fsm_sb_in.i_tx_decoding == DATA_TO_CLOCK_RX_RX_LFSR_CLEAR_HANDSHAKE ) begin
            o_tx_encoding_expected = DATA_TO_CLOCK_RX_RX_PATTERN_GENERATION;
            train =1;
            firstt=0;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_datavref", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
            end
        end
        // ----------------------------------------------------------------
        // Phase 1 trigger: TX training done while in PATTERN GENERATION state →
        // transition to RESULT handshake. Deassert train, verify only encoding.
        // ----------------------------------------------------------------
        else if (item_controllers_in.i_tx_done && o_tx_encoding_expected == DATA_TO_CLOCK_RX_RX_PATTERN_GENERATION  )begin
            // $display("da5lna hena at %0t",$time);
            o_tx_encoding_expected = DATA_TO_CLOCK_RX_RX_RESULT_HANDSHAKE;
            //o_tx_info_expected = 16'h0000;
            first_time=0;
            train =0;
            //o_tx_sb_req_expected = 1'b1;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding ) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_datavref", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                //`uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                //`uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_sb_req mismatch expected value: %0b, got %0b", o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            end
        end
        // ----------------------------------------------------------------
        // Phase 2 follow-up: RESULT handshake in progress.
        // Assert o_tx_sb_req, do full 3-field check, then clear expected encoding.
        // ----------------------------------------------------------------
        else if (o_tx_encoding_expected == DATA_TO_CLOCK_RX_RX_RESULT_HANDSHAKE) begin
            o_tx_info_expected = 16'h0000;
            o_tx_sb_req_expected = 1'b1;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_tx_sb_req_expected == item_tx_fsm_sb_out.o_tx_sb_req) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_datavref", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_sb_req mismatch expected value: %0b, got %0b", o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            end
            o_tx_encoding_expected =0;
        end
        // ----------------------------------------------------------------
        // Success path: Result handshake response received with no retry needed
        // or result bit[4] indicates pass → advance to SWEEP RESULT handshake.
        // ----------------------------------------------------------------
        else if ((item_tx_fsm_sb_in.i_sb_tx_rsp==1'b1 && item_tx_fsm_sb_in.i_tx_decoding == DATA_TO_CLOCK_RX_RX_RESULT_HANDSHAKE && (!retry || item_tx_fsm_sb_in.i_tx_info[4]) )  ) begin
            o_tx_encoding_expected = DATA_TO_CLOCK_RX_RX_SWEEP_RESULT_HANDSHAKE;
            //$display("retry =%0b", retry);
            //$display ("item_tx_fsm_sb_in.i_tx_info[4] =%0b", item_tx_fsm_sb_in.i_tx_info[4]);
            o_tx_info_expected = 16'h0000;
            o_tx_sb_req_expected = 1'b1;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding ) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_datavref", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
            end
        end
        // ----------------------------------------------------------------
        // Phase 2 follow-up: SWEEP RESULT handshake in progress.
        // Full 3-field check then clear expected encoding.
        // ----------------------------------------------------------------
        else if (o_tx_encoding_expected == DATA_TO_CLOCK_RX_RX_SWEEP_RESULT_HANDSHAKE) begin
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_tx_sb_req_expected == item_tx_fsm_sb_out.o_tx_sb_req) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_datavref", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_sb_req mismatch expected value: %0b, got %0b", o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            end
            o_tx_encoding_expected=0;
        end
        // ----------------------------------------------------------------
        // Phase 1 trigger: RX side signals END INIT handshake with sideband request.
        // Deassert train, set expected response fields, verify only encoding.
        // ----------------------------------------------------------------
        else if (item_tx_fsm_sb_in.i_tx_decoding == DATA_TO_CLOCK_RX_RX_END_INIT_HANDSHAKE && item_tx_fsm_sb_in.i_sb_tx_req==1'b1  ) begin
            o_tx_encoding_expected = DATA_TO_CLOCK_RX_RX_END_INIT_HANDSHAKE;
            o_tx_info_expected = 16'h0000;
            o_tx_sb_rsp_expected = 1'b1;
            train=0;
            if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding ) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_datavref", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                // `uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                // `uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_sb_rsp mismatch expected value: %0b, got %0b", o_tx_sb_rsp_expected, item_tx_fsm_sb_out.o_tx_sb_rsp), UVM_LOW)
            end
        end
        // ----------------------------------------------------------------
        // Phase 2 follow-up: END INIT handshake in progress.
        // Full 3-field check (encoding, info, rsp), then clear expected encoding.
        // ----------------------------------------------------------------
        else if (o_tx_encoding_expected == DATA_TO_CLOCK_RX_RX_END_INIT_HANDSHAKE) begin
             if (o_tx_encoding_expected==item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected==item_tx_fsm_sb_out.o_tx_info && o_tx_sb_rsp_expected == item_tx_fsm_sb_out.o_tx_sb_rsp /*&&  o_error_threshhold_expected==item_controllers_out.o_error_threshhold*/) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_datavref", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_sb_rsp_expected mismatch expected value: %0b, got %0b", o_tx_sb_rsp_expected, item_tx_fsm_sb_out.o_tx_sb_rsp), UVM_LOW)
                //`uvm_info("mbtrain_tx_datavref", $sformatf("o_error_threshhold_expected mismatch expected value: %0d, got %0d", o_error_threshhold_expected, item_controllers_out.o_error_threshhold), UVM_LOW)
            end
            o_tx_encoding_expected =0;
            first=0;
        end
        // ----------------------------------------------------------------
        // Phase 1 trigger: TX done after END INIT (not training, first not yet set)
        // → transition to valvref End Handshake. Sets first=1 to prevent re-entry,
        // asserts o_tx_sb_req, verifies only encoding this cycle.
        // ----------------------------------------------------------------
        else if (!train && item_tx_fsm_sb_in.i_sb_tx_done && !first ) begin
            o_tx_encoding_expected = MBTRAIN_DATAVREF_TX_End_Handshake;
            o_tx_info_expected     = 16'h0000;
            first                  = 1;
            o_tx_sb_req_expected =1'b1;
            if (o_tx_encoding_expected == item_tx_fsm_sb_out.o_tx_encoding) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_datavref", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
            end
        end
        // ----------------------------------------------------------------
        // Phase 2 follow-up: datavref End Handshake in progress.
        // Full 3-field check. No encoding reset here — state machine
        // will transition out via an external mechanism.
        // ----------------------------------------------------------------
        else if (o_tx_encoding_expected == MBTRAIN_DATAVREF_TX_End_Handshake) begin
            o_tx_sb_req_expected =1'b1;
            if (o_tx_encoding_expected == item_tx_fsm_sb_out.o_tx_encoding && o_tx_info_expected == item_tx_fsm_sb_out.o_tx_info && o_tx_sb_req_expected == item_tx_fsm_sb_out.o_tx_sb_req) begin
                match = 1;
            end else begin
                match = 0;
                `uvm_info("mbtrain_tx_datavref", $sformatf("Mismatch in o_tx_encoding: expected %0h, got %0h", o_tx_encoding_expected, item_tx_fsm_sb_out.o_tx_encoding), UVM_LOW)
                `uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_info mismatch expected value: %0h, got %0h", o_tx_info_expected, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
                `uvm_info("mbtrain_tx_datavref", $sformatf("o_tx_sb_req mismatch expected value: %0b, got %0b", o_tx_sb_req_expected, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
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
        return fsm_mbtrain_tx_datavref;
    endfunction


endclass //mbtrain_tx_datavref extends state