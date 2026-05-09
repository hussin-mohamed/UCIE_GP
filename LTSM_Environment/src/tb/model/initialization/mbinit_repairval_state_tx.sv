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
class MbInitRepairValState_tx extends State;

   static MbInitRepairValState_tx inst;
   logic o_tx_sb_req_exp;
   logic [15:0] o_tx_info_exp;

   logic [8:0] o_tx_encoding_exp;
   bit match;

   protected function new(); endfunction

   static function MbInitRepairValState_tx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
      // Value lane repair negotiation

      if(cntxt.currentstate_tx == MbInitRepairClkState_tx::Instance() && item_tx_fsm_sb_in.i_tx_decoding == MBINIT_REPAIRCLK_TX_Done_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1) begin
         o_tx_encoding_exp = 'h28;
         o_tx_sb_req_exp = 1;
         o_tx_info_exp = 0;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairValState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_tx_sb_req: %0b, Actual o_tx_sb_req: %0b, Expected o_tx_info: %0h, Actual o_tx_info: %0h", o_tx_encoding_exp, item_controllers_out.o_tx_encoding, o_tx_sb_req_exp, item_tx_fsm_sb_out.o_tx_sb_req, o_tx_info_exp, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
            match = 0;

         end
      end
      else if(item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_tx_fsm_sb_in.i_tx_decoding == 'h28) begin
         o_tx_encoding_exp = 'h29;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairValState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h", o_tx_encoding_exp, item_controllers_out.o_tx_encoding), UVM_LOW)
            match = 0;

         end
      end
      else if(item_controllers_in.i_tx_done && item_tx_fsm_sb_in.i_tx_decoding == 'h29) begin
         o_tx_encoding_exp = 'h2A;
         o_tx_sb_req_exp = 1'b1;
         o_tx_info_exp = 0;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairValState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_tx_sb_req: %0b, Actual o_tx_sb_req: %0b, Expected o_tx_info: %0h, Actual o_tx_info: %0h", o_tx_encoding_exp, item_controllers_out.o_tx_encoding, o_tx_sb_req_exp, item_tx_fsm_sb_out.o_tx_sb_req, o_tx_info_exp, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
            match = 0;

         end
      end

      // valid lane is functional go the the done the handshake
      else if(item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_tx_fsm_sb_in.i_tx_decoding == 'h2A && item_tx_fsm_sb_in.i_tx_info[0] == 1'b1) begin // needs to know the data field
         o_tx_encoding_exp = 'h2B;
         o_tx_sb_req_exp = 1;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp)
            match = 1;
         else  begin

            `uvm_info("MbInitRepairValState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_tx_sb_req: %0b, Actual o_tx_sb_req: %0b", o_tx_encoding_exp, item_controllers_out.o_tx_encoding, o_tx_sb_req_exp, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            match = 0;

         end
      end

      // faild valid lane -> train error hs  
      else if(item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_tx_fsm_sb_in.i_tx_decoding == 'h2A && item_tx_fsm_sb_in.i_tx_info[0] == 1'b0) begin // needs to know the data field
      // train error hs
         o_tx_encoding_exp = 'h40;
         o_tx_sb_req_exp = 1;
         o_tx_info_exp = 0;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
            match = 1;
         else  begin
            `uvm_info("MbInitRepairValState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_tx_sb_req: %0b, Actual o_tx_sb_req: %0b, Expected o_tx_info: %0h, Actual o_tx_info: %0h", o_tx_encoding_exp, item_controllers_out.o_tx_encoding, o_tx_sb_req_exp, item_tx_fsm_sb_out.o_tx_sb_req, o_tx_info_exp, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
            match = 0;

         end
      end
      else
         match = 1'b1;
      return match;
   endfunction

   function fsm_t getStateId();
      return fsm_mbinit_tx_repairval;
   endfunction

endclass
