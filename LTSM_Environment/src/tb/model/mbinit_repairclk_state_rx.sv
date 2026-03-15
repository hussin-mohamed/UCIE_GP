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
class MbInitRepairClkState_rx extends State;
   `uvm_object_utils(MbInitRepairClkState_rx)
   
   static MbInitRepairClkState_rx inst;

   logic [8:0] o_rx_encoding_exp;
   logic o_rx_sb_rsp_exp;
   logic [15:0] o_rx_info_exp;
   bit match;

   protected function new(string name = "MbInitRepairClkState_rx");
      super.new(name);
   endfunction

   static function MbInitRepairClkState_rx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_sequence_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_sequence_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
      // Clock lane repair negotiation
      if(cntxt.current_state_rx == MbInitCalState_rx::Instance() && item_controllers_in.i_rx_decoding == MBINIT_CAL_RX_Done_Handshake && item_rx_fsm_sb_in.i_sb_rx_req == 1'b1) begin
         o_rx_encoding_exp = 'h20;
         o_rx_sb_rsp_exp = 1;
         o_rx_info_exp = 0;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp && item_rx_fsm_sb_out.o_rx_info == o_rx_info_exp)
            match = 1;
         else
            match = 0;
      end
      if(item_rx_fsm_sb_in.i_sb_rx_done == 1'b1 && item_controllers_in.i_rx_decoding == 'h20) begin
         o_rx_encoding_exp = 'h21;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else
            match = 0;
      end
      else if(item_controllers_in.i_rx_done && item_controllers_in.i_rx_decoding == 'h21) begin
         o_rx_encoding_exp = 'h22;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else
            match = 0;
      end


      else if(item_rx_fsm_sb_in.i_sb_rx_req == 1'b1 && item_controllers_in.i_rx_decoding == 'h21) begin
            o_rx_encoding_exp = 'h23;
            o_rx_sb_rsp_exp = 1;

            o_rx_info_exp = 0;
            if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp && item_rx_fsm_sb_out.o_rx_info == o_rx_info_exp)
               match = 1;
            else
               match = 0;
      end

      else if(item_controllers_in.i_rx_decoding == 'h22 && item_rx_fsm_sb_in.i_sb_rx_req == 1'b1 ) begin
         o_rx_encoding_exp =='h23;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
               match = 1;
         else
               match = 0;
      end

      else if(item_rx_fsm_sb_in.i_sb_rx_done == 1'b1 && item_controllers_in.i_rx_decoding == 'h23) begin
         o_rx_encoding_exp = 'h24;
         o_rx_sb_rsp_exp = 1;
         o_rx_info_exp = item_controllers_in.i_clk_error;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp && item_rx_fsm_sb_out.o_rx_info == o_rx_info_exp)
            match = 1;
         else
            match = 0;
      end
      
      return match;
   endfunction

   function fsm_t getStateId();
      return fsm_mbinit_rx_repairclk;
   endfunction

endclass
