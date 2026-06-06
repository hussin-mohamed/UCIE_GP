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
class MbInitRepairValState_rx extends State;
  

   static MbInitRepairValState_rx inst;

   logic [8:0] o_rx_encoding_exp;
   logic [63:0] o_rx_data_exp;
   logic o_rx_sb_rsp_exp;
   logic [15:0] o_rx_info_exp;
   bit match;

   protected function new(); endfunction

   static function MbInitRepairValState_rx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
      // Value lane repair negotiation

       if(cntxt.currentstate_rx == MbInitRepairClkState_rx::Instance() && item_rx_fsm_sb_in.i_rx_decoding == 'h24 && item_rx_fsm_sb_in.i_sb_rx_req == 1'b1) begin
         o_rx_encoding_exp = 'h28;

         o_rx_sb_rsp_exp = 1;
         o_rx_info_exp = 0;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp && item_rx_fsm_sb_out.o_rx_info == o_rx_info_exp) begin
            match = 1;
         end
            

         else begin
            `uvm_info("MbInitRepairValState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h, Expected o_rx_sb_rsp: %0b, Actual o_rx_sb_rsp: %0b, Expected o_rx_info: %0h, Actual o_rx_info: %0h", o_rx_encoding_exp, item_controllers_out.o_rx_encoding, o_rx_sb_rsp_exp, item_rx_fsm_sb_out.o_rx_sb_rsp, o_rx_info_exp, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
             match = 0;
         end
            
      end

      else if(item_rx_fsm_sb_in.i_sb_rx_done == 1'b1 && item_rx_fsm_sb_in.i_rx_decoding == 'h2B) begin
         o_rx_encoding_exp = 'h2C;
         //o_rx_sb_rsp_exp = 1;
         o_rx_info_exp = 0;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp  && item_rx_fsm_sb_out.o_rx_info == o_rx_info_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairValState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h, Expected o_rx_info: %0h, Actual o_rx_info: %0h", o_rx_encoding_exp, item_controllers_out.o_rx_encoding, o_rx_info_exp, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
            match = 0;

         end
      end
      else if(item_rx_fsm_sb_in.i_sb_rx_req == 1'b1 && item_rx_fsm_sb_in.i_rx_decoding == 'h29) begin
         o_rx_encoding_exp = 'h2B;
         o_rx_info_exp[0] = 1; // no errors
         o_rx_sb_rsp_exp = 1;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_info == o_rx_info_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairValState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h, Expected o_rx_sb_rsp: %0b, Actual o_rx_sb_rsp: %0b, Expected o_rx_info: %0h, Actual o_rx_info: %0h", o_rx_encoding_exp, item_controllers_out.o_rx_encoding, o_rx_sb_rsp_exp, item_rx_fsm_sb_out.o_rx_sb_rsp, o_rx_info_exp, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
            match = 0;

         end
      end

      else if(item_rx_fsm_sb_in.i_sb_rx_req == 1'b1 && item_rx_fsm_sb_in.i_rx_decoding == 'h2A) begin
         o_rx_encoding_exp = 'h2B;
         // send result resp msg
         o_rx_sb_rsp_exp = 1;
         o_rx_info_exp[0] = item_controllers_in.i_rx_valid_results;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_info == o_rx_info_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairValState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h, Expected o_rx_sb_rsp: %0b, Actual o_rx_sb_rsp: %0b, Expected o_rx_info: %0b, Actual o_rx_info: %0b", o_rx_encoding_exp, item_controllers_out.o_rx_encoding, o_rx_sb_rsp_exp, item_rx_fsm_sb_out.o_rx_sb_rsp, o_rx_info_exp[0], item_rx_fsm_sb_out.o_rx_info[0]), UVM_LOW)
            match = 0;

         end
      end
      else if(item_controllers_in.i_rx_done && item_rx_fsm_sb_in.i_rx_decoding == 'h29) begin
         o_rx_encoding_exp = 'h2A;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairValState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h", o_rx_encoding_exp, item_controllers_out.o_rx_encoding), UVM_LOW)
            match = 0;

         end
      end
      else if(item_rx_fsm_sb_in.i_sb_rx_req == 1'b1 && item_rx_fsm_sb_in.i_rx_decoding == 'h28) begin
         o_rx_encoding_exp = 'h28;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairValState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h", o_rx_encoding_exp, item_controllers_out.o_rx_encoding), UVM_LOW)
            match = 0;

         end
      end
      else
         match = 1'b1;
      return match;
   endfunction

   function fsm_t getStateId();
      return fsm_mbinit_rx_repairval;
   endfunction

endclass
