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

class MbInitReversalMbState_tx extends State;
   `uvm_object_utils(MbInitReversalMbState_tx)

   static MbInitReversalMbState_tx inst;

   logic [8:0] o_tx_encoding_exp;
   logic o_tx_sb_req_exp;
   logic[15:0] o_tx_info_exp;
   bit match;

   protected function new(string name = "MbInitReversalMbState_tx");
      super.new(name);
   endfunction

   static function MbInitReversalMbState_tx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_sequence_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_sequence_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
      // Lane reversal negotiation

      if(cntxt.current_state_rx == MbInitRepairValState_tx::Instance() && item_controllers_in.i_tx_decoding == MBINIT_REPAIRVAL_TX_Done_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1) begin
         o_tx_encoding_exp = 'h30;
         o_tx_sb_req_exp = 1;
         o_tx_info_exp = 0;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
            match = 1;
         else
            match = 0;
      end


      else if(item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_controllers_in.i_tx_decoding == 'h30) begin
         o_tx_encoding_exp = 'h31;
         // clearl log req
         o_tx_sb_req_exp = 1;
         o_tx_info_exp = 0;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
            match = 1;
         else
            match = 0;
      end

      else if(item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_controllers_in.i_tx_decoding == 'h33 && item_tx_fsm_sb_in.i_tx_data > `RESULT_THRESHOLD) begin
         o_tx_encoding_exp = 'h35;
         // done handshake req
         o_tx_sb_req_exp = 1;
         o_tx_info_exp = 0;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
            match = 1;
         else
            match = 0;
      end
      // apply the reversal request
      else if(item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_tx_fsm_sb_in.i_tx_data <= `RESULT_THRESHOLD && item_controllers_in.i_tx_decoding == 'h33 ) begin
         o_tx_encoding_exp = 'h34;
         o_tx_sb_req_exp = 1;
         o_tx_info_exp = 0;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
            match = 1;
         else
            match = 0;
      end

       else if(item_controllers_in.i_tx_done && item_controllers_in.i_tx_decoding == 'h34) begin
         o_tx_encoding_exp = 'h31;
         //loop back to clear log req
         o_tx_sb_req_exp = 1;
         o_tx_info_exp = 0;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
            match = 1;
         else
            match = 0;
      end

      else if(item_controllers_in.i_tx_done && item_controllers_in.i_tx_decoding == 'h32) begin
         o_tx_encoding_exp = 'h33;
         // result req
         o_tx_sb_req_exp = 1;
         o_tx_info_exp = 0;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
            match = 1;
         else
            match = 0;
      end
      else if(item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_controllers_in.i_tx_decoding == 'h31) begin
         o_tx_encoding_exp = 'h32;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp)
            match = 1;
         else
            match = 0;
      end
      
      return match;
   endfunction

   function fsm_t getStateId();
      return fsm_mbinit_tx_reversal;
   endfunction

endclass
