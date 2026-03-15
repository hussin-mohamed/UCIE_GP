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
   `uvm_object_utils(MbInitRepairValState_tx)
   import shared_ltsm_pkg::*;

   static MbInitRepairValState_tx inst;
   logic o_tx_sb_req_exp;
   logic [15:0] o_tx_info_exp;

   logic [8:0] o_tx_encoding_exp;
   bit match;

   protected function new(string name = "MbInitRepairValState_tx");
      super.new(name);
   endfunction

   static function MbInitRepairValState_tx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_sequence_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_sequence_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
      // Value lane repair negotiation

      if(cntxt.current_state_tx == MbInitRepairClkState_tx::Instance() && item_controllers_in.i_tx_decoding == MBINIT_REPAIRCLK_TX_Done_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1) begin
         o_tx_encoding_exp = 'h28;
         o_tx_sb_req_exp = 1;
         o_tx_info_exp = 0;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
            match = 1;
         else
            match = 0;
      end
      else if(item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_controllers_in.i_tx_decoding == 'h28) begin
         o_tx_encoding_exp = 'h29;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp)
            match = 1;
         else
            match = 0;
      end
      else if(item_controllers_in.i_tx_done && item_controllers_in.i_tx_decoding == 'h29) begin
         o_tx_encoding_exp = 'h2A;
         o_tx_sb_req_exp = 1'b1;
         o_tx_info_exp = 0;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
            match = 1;
         else
            match = 0;
      end

      // valid lane is functional go the the done the handshake
      else if(item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_controllers_in.i_tx_decoding == 'h2A && item_tx_fsm_sb_in.i_tx_info[0] == 1'b1) begin // needs to know the data field
         o_tx_encoding_exp = 'h2B;
         o_tx_sb_req_exp = 1;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp)
            match = 1;
         else
            match = 0;
      end

      // faild valid lane -> train error hs  
      else if(item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_controllers_in.i_tx_decoding == 'h2A && item_tx_fsm_sb_in.i_tx_info[0] == 1'b0) begin // needs to know the data field
      // train error hs
         o_tx_encoding_exp = 'hE0;
         o_tx_sb_req_exp = 1;
         o_tx_info_exp = 0;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
            match = 1;
         else
            match = 0;
      end
      
      return match;
   endfunction

   function fsm_t getStateId();
      return fsm_mbinit_tx_repairval;
   endfunction

endclass
