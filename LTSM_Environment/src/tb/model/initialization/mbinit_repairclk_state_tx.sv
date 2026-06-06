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
class MbInitRepairClkState_tx extends State;
  

   static MbInitRepairClkState_tx inst;
   logic o_tx_sb_req_exp;
   logic [15:0] o_tx_info_exp;

   logic [8:0] o_tx_encoding_exp;
   bit match;

   protected function new(); endfunction

   static function MbInitRepairClkState_tx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
      tx_done = 0;
      if(cntxt.currentstate_tx == MbInitCalState_tx::Instance() && item_tx_fsm_sb_in.i_tx_decoding == MBINIT_CAL_TX_Done_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1) begin
         o_tx_encoding_exp = 'h20;
         // init req 
         o_tx_sb_req_exp = 1;
         o_tx_info_exp = 0;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairClkState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_tx_sb_req: %0b, Actual o_tx_sb_req: %0b, Expected o_tx_info: %0h, Actual o_tx_info: %0h", o_tx_encoding_exp, item_controllers_out.o_tx_encoding, o_tx_sb_req_exp, item_tx_fsm_sb_out.o_tx_sb_req, o_tx_info_exp, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
            match = 0;

         end
      end
      // Clock lane repair negotiation
      else if(item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_tx_fsm_sb_in.i_tx_decoding == MBINIT_REPAIRCLK_TX_Init_Handshake ) begin
         o_tx_encoding_exp = 'h21;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairClkState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h", o_tx_encoding_exp, item_controllers_out.o_tx_encoding), UVM_LOW)
            match = 0;
         end
      end
      else if(item_controllers_in.i_tx_done && item_tx_fsm_sb_in.i_tx_decoding == 'h21) begin
         o_tx_encoding_exp = 'h22;
         // result req
         o_tx_sb_req_exp = 1; 
         o_tx_info_exp = 0;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairClkState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_tx_sb_req: %0b, Actual o_tx_sb_req: %0b, Expected o_tx_info: %0h, Actual o_tx_info: %0h", o_tx_encoding_exp, item_controllers_out.o_tx_encoding, o_tx_sb_req_exp, item_tx_fsm_sb_out.o_tx_sb_req, o_tx_info_exp, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
            match = 0;

         end
      end
      // failed clk lanes -> trainerror hs
      else if(item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_tx_fsm_sb_in.i_tx_decoding == 'h22 && &item_tx_fsm_sb_in.i_tx_info[2:0] == 0) begin
         o_tx_encoding_exp = 'h40;
         o_tx_sb_req_exp = 1;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairClkState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_tx_sb_req: %0b, Actual o_tx_sb_req: %0b", o_tx_encoding_exp, item_controllers_out.o_tx_encoding, o_tx_sb_req_exp, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            match = 0;

         end
      end
      // successful clk lanes
      else if(item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_tx_fsm_sb_in.i_tx_decoding == 'h22 && &item_tx_fsm_sb_in.i_tx_info[2:0]  == 1) begin
         o_tx_encoding_exp = 'h23;
         // done handshake req
         o_tx_sb_req_exp = 1;
         o_tx_info_exp = 0;
         tx_done = 1;

         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairClkState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_tx_sb_req: %0b, Actual o_tx_sb_req: %0b", o_tx_encoding_exp, item_controllers_out.o_tx_encoding, o_tx_sb_req_exp, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            match = 0;

         end
      end

/*
      else if(item_tx_fsm_sb_in.i_tx_decoding == MBINIT_REPAIRCLK_TX_Done_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1
      && rx_done == 1'b0) begin
         o_tx_encoding_exp = 'h23;
         // done handshake req
         //o_tx_sb_req_exp = 1;
         //o_tx_info_exp = 0;
         tx_done = 1;


         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairClkState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_tx_sb_req: %0b, Actual o_tx_sb_req: %0b", o_tx_encoding_exp, item_controllers_out.o_tx_encoding, o_tx_sb_req_exp, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            match = 0;

         end
      end
*/     
   else
         match = 1'b1;
      return match;
   endfunction

   function fsm_t getStateId();
      return fsm_mbinit_tx_repairclk;
   endfunction

endclass
