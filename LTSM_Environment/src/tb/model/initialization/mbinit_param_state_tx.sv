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

class MbInitParamState_tx extends State;

   static MbInitParamState_tx inst;

   logic [8:0] o_tx_encoding_exp;
   logic o_tx_sb_req_exp;
   logic [15:0] o_tx_info_exp;
   bit match;

   protected function new(); endfunction

   static function MbInitParamState_tx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
      tx_done = 0;
      if(item_tx_fsm_sb_in.i_tx_decoding == SBINIT_TX_Done_Handshake && cntxt.currentstate_tx == SbInitState_tx::Instance() && item_tx_fsm_sb_in.i_sb_tx_rsp) begin
         o_tx_encoding_exp = 'h10;
         o_tx_sb_req_exp = 1;
         o_tx_info_exp = 0;
         tx_done = 1;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
         begin
            match = 1;

         end
         else begin
            `uvm_info("MbInitParamState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_tx_sb_req: %0b, Actual o_tx_sb_req: %0b, Expected o_tx_info: %0h, Actual o_tx_info: %0h", o_tx_encoding_exp, item_controllers_out.o_tx_encoding, o_tx_sb_req_exp, item_tx_fsm_sb_out.o_tx_sb_req, o_tx_info_exp, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
            match = 0;
         end
            

      end
/*
      else if(item_tx_fsm_sb_in.i_sb_tx_rsp && item_tx_fsm_sb_in.i_tx_decoding == 'h10 && rx_done == 1'b0)begin
         o_tx_encoding_exp = 'h10;
         //o_tx_sb_req_exp = 1;
         //o_tx_info_exp = 0;
         tx_done = 1;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp)
         begin
            match = 1;

         end
         else begin
            `uvm_info("MbInitParamState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_tx_sb_req: %0b, Actual o_tx_sb_req: %0b, Expected o_tx_info: %0h, Actual o_tx_info: %0h", o_tx_encoding_exp, item_controllers_out.o_tx_encoding, o_tx_sb_req_exp, item_tx_fsm_sb_out.o_tx_sb_req, o_tx_info_exp, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
            match = 0;
         end
            
      end
*/   
      else
         match = 1'b1;
      return match;
   endfunction

   function fsm_t getStateId();
      return fsm_mbinit_tx_param;
   endfunction

endclass
