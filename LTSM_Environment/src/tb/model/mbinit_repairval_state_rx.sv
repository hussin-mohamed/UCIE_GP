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
   `uvm_object_utils(MbInitRepairValState_rx)

   static MbInitRepairValState_rx inst;

   logic [8:0] o_rx_encoding_exp;
   logic [63:0] o_rx_data_exp;
   logic o_rx_sb_rsp_exp;
   bit match;

   protected function new(string name = "MbInitRepairValState_rx");
      super.new(name);
   endfunction

   static function MbInitRepairValState_rx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_sequence_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_sequence_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
      // Value lane repair negotiation

       if(cntxt.current_state_rx == MbInitRepairClkState_rx::Instance() && item_controllers_in.i_rx_decoding == MBINIT_REPAIRCLK_RX_Done_Handshake && item_rx_fsm_sb_in.i_sb_rx_req == 1'b1) begin
         o_rx_encoding_exp = 'h28;
         o_rx_sb_rsp_exp = 1;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp)
            match = 1;
         else
            match = 0;
      end

      else if(item_rx_fsm_sb_in.i_sb_rx_done == 1'b1 && item_controllers_in.i_rx_decoding == 'h2B) begin
         o_rx_encoding_exp = 'h2C;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else
            match = 0;
      end
      else if(item_rx_fsm_sb_in.i_sb_rx_req == 1'b1 && item_controllers_in.i_rx_decoding == 'h29) begin
         o_rx_encoding_exp = 'h2B;
         o_rx_data_exp = RESULTS;
         o_rx_sb_rsp_exp = 1;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_data == o_rx_data_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp)
            match = 1;
         else
            match = 0;
      end

      else if(item_rx_fsm_sb_in.i_sb_rx_req == 1'b1 && item_controllers_in.i_rx_decoding == 'h2A) begin
         o_rx_encoding_exp = 'h2B;
         o_rx_data_exp = RESULTS;
         o_rx_sb_rsp_exp = 1;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_data == o_rx_data_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp)
            match = 1;
         else
            match = 0;
      end
      else if(item_controllers_in.i_rx_done && item_controllers_in.i_rx_decoding == 'h29) begin
         o_rx_encoding_exp = 'h2A;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else
            match = 0;
      end
      else if(item_rx_fsm_sb_in.i_sb_rx_done == 1'b1 && item_controllers_in.i_rx_decoding == 'h28) begin
         o_rx_encoding_exp = 'h29;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else
            match = 0;
      end
      
      return match;
   endfunction

   function fsm_t getStateId();
      return fsm_mbinit_rx_repairval;
   endfunction

endclass
