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

class MbInitReversalMbState_rx extends State;
   `uvm_object_utils(MbInitReversalMbState_rx)

   static MbInitReversalMbState_rx inst;

   logic [8:0] o_rx_encoding_exp;
   logic o_rx_sb_rsp_exp;
   bit match;

   protected function new(string name = "MbInitReversalMbState_rx");
      super.new(name);
   endfunction

   static function MbInitReversalMbState_rx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_sequence_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_sequence_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
      // Lane reversal negotiation

      if(cntxt.current_state_tx == MbInitRepairValState_rx::Instance() && item_controllers_in.i_rx_decoding == 'h2C && item_rx_fsm_sb_in.i_sb_rx_req == 1'b1) begin
         o_rx_encoding_exp = 'h30;
         o_rx_sb_rsp_exp = 1;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp)
            match = 1;
         else
            match = 0;
      end
      else if(item_rx_fsm_sb_in.i_sb_rx_done == 1'b1 && item_rx_fsm_sb_in.o_rx_data == MAJORITY_LANES_SUCCESS && item_controllers_in.i_rx_decoding == 'h33) begin
         o_rx_encoding_exp = 'h34;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else
            match = 0;
      end

      // result fail - > return back to the clear log 
      else if(item_rx_fsm_sb_in.i_sb_rx_done == 1'b1 && item_rx_fsm_sb_in.o_rx_data == MAJORITY_LANES_FAIL && item_controllers_in.i_rx_decoding == 'h33) begin
         o_rx_encoding_exp = 'h31;
         // clear log rsp
         o_rx_sb_rsp_exp = 1;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp)
            match = 1;
         else
            match = 0;
      end


      else if(item_controllers_in.i_rx_done && item_controllers_in.i_rx_decoding == 'h32) begin
         o_rx_encoding_exp = 'h33;
         o_rx_sb_rsp_exp = 1;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp   )
            match = 1;
         else
            match = 0;
      end

      // clear log 
      else if(item_rx_fsm_sb_in.i_sb_rx_done == 1'b1 && item_controllers_in.i_rx_decoding == 'h30) begin
         o_rx_encoding_exp = 'h31;
         //clear log rsp
         o_rx_sb_rsp_exp = 1;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp)
            match = 1;
         else
            match = 0;
      end

      // per-lane detection
      else if(item_rx_fsm_sb_in.i_sb_rx_done == 1'b1 && item_controllers_in.i_rx_decoding == 'h31) begin
         o_rx_encoding_exp = 'h32;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else
            match = 0;
      end
      
      return match;
   endfunction

   function fsm_t getStateId();
      return fsm_mbinit_rx_reversal;
   endfunction

endclass
