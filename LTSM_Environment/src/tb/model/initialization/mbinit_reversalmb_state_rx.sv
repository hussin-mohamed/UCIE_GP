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

class MbInitReversalMbState_rx extends State;
   

   static MbInitReversalMbState_rx inst;

   logic [8:0] o_rx_encoding_exp;
   logic o_rx_sb_rsp_exp;
   logic [15:0] o_rx_info_exp;
   logic [63:0] o_rx_data_exp;
   static logic[15:0] data_res;

   bit match;

   protected function new(); endfunction

   static function MbInitReversalMbState_rx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
      // Lane reversal negotiation

      if(cntxt.currentstate_rx == MbInitRepairValState_rx::Instance() && item_rx_fsm_sb_in.i_rx_decoding == 'h2C && item_rx_fsm_sb_in.i_sb_rx_req == 1'b1) begin
         o_rx_encoding_exp = 'h2c;
         o_rx_sb_rsp_exp = 1;
         o_rx_info_exp = 0;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp && item_rx_fsm_sb_out.o_rx_info == o_rx_info_exp)
            match = 1;
         else begin
            `uvm_info("MbInitReversalMbState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h, Expected o_rx_sb_rsp: %0b, Actual o_rx_sb_rsp: %0b, Expected o_rx_info: %0h, Actual o_rx_info: %0h", o_rx_encoding_exp, item_controllers_out.o_rx_encoding, o_rx_sb_rsp_exp, item_rx_fsm_sb_out.o_rx_sb_rsp, o_rx_info_exp, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
            match = 0;

         end
      end
      else if(item_rx_fsm_sb_in.i_sb_rx_done == 1'b1 && $countones(item_controllers_in.i_rx_data_results[15:0]) >= $countones(`RESULT_THRESHOLD ) && item_rx_fsm_sb_in.i_rx_decoding == 'h34) begin
         o_rx_encoding_exp = 'h35;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp) begin
            match = 1;

         end
         else begin
            `uvm_info("MbInitReversalMbState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h", o_rx_encoding_exp, item_controllers_out.o_rx_encoding), UVM_LOW)
            match = 0;

         end
      end

      // result fail - > return back to the clear log 
      else if(item_rx_fsm_sb_in.i_sb_rx_done == 1'b1 && $countones(item_controllers_in.i_rx_data_results[15:0]) < $countones(`RESULT_THRESHOLD ) && item_rx_fsm_sb_in.i_rx_decoding == 'h34) begin
         o_rx_encoding_exp = 'h31;

         // clear log hs
         o_rx_sb_rsp_exp = 1;
         o_rx_info_exp = 0;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp && item_rx_fsm_sb_out.o_rx_info == o_rx_info_exp)
            match = 1;
         else begin
            `uvm_info("MbInitReversalMbState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h, Expected o_rx_sb_rsp: %0b, Actual o_rx_sb_rsp: %0b, Expected o_rx_info: %0h, Actual o_rx_info: %0h", o_rx_encoding_exp, item_controllers_out.o_rx_encoding, o_rx_sb_rsp_exp, item_rx_fsm_sb_out.o_rx_sb_rsp, o_rx_info_exp, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
            match = 0;
         end
      end


     // wait resp
      else if(item_controllers_in.i_rx_done && item_rx_fsm_sb_in.i_rx_decoding == 'h32) begin
         o_rx_encoding_exp = 'h33;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else begin
            `uvm_info("MbInitReversalMbState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h", o_rx_encoding_exp, item_controllers_out.o_rx_encoding), UVM_LOW)
            match = 0;

         end
      end


      // clear log 
      else if(item_rx_fsm_sb_in.i_sb_rx_req == 1'b1 && item_rx_fsm_sb_in.i_rx_decoding == 'h30) begin
         o_rx_encoding_exp = 'h31;
         //clear log rsp
         o_rx_sb_rsp_exp = 1;
         o_rx_info_exp = 0;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp && item_rx_fsm_sb_out.o_rx_info == o_rx_info_exp)
            match = 1;
         else begin
            `uvm_info("MbInitReversalMbState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h, Expected o_rx_sb_rsp: %0b, Actual o_rx_sb_rsp: %0b, Expected o_rx_info: %0h, Actual o_rx_info: %0h", o_rx_encoding_exp, item_controllers_out.o_rx_encoding, o_rx_sb_rsp_exp, item_rx_fsm_sb_out.o_rx_sb_rsp, o_rx_info_exp, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
            match = 0;

         end
      end

      // per-lane detection
      else if(item_rx_fsm_sb_in.i_sb_rx_req == 1'b1 && item_rx_fsm_sb_in.i_rx_decoding == 'h31) begin
         o_rx_encoding_exp = 'h31;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else begin
            `uvm_info("MbInitReversalMbState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h", o_rx_encoding_exp, item_controllers_out.o_rx_encoding), UVM_LOW)
            match = 0;

         end
      end

      else if(item_rx_fsm_sb_in.i_sb_rx_req == 1'b1 && item_rx_fsm_sb_in.i_rx_decoding == 'h33) begin
         o_rx_encoding_exp = 'h33;
         o_rx_data_exp[15:0] = item_controllers_in.i_rx_data_results[15:0];

         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_data[15:0] == o_rx_data_exp[15:0])
            match = 1;
         else begin
            `uvm_info("MbInitReversalMbState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h , Expected o_rx_data: %0h, Actual o_rx_data: %0h", o_rx_encoding_exp, item_controllers_out.o_rx_encoding, o_rx_data_exp[15:0], item_rx_fsm_sb_out.o_rx_data[15:0]), UVM_LOW)
            match = 0;

         end
      end
      else
         match = 1'b1;
      return match;
   endfunction

   function fsm_t getStateId();
      return fsm_mbinit_rx_reversal;
   endfunction

endclass
