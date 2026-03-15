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
class MbInitRepairMbState_tx extends State;
   
   `uvm_object_utils(MbInitRepairMbState_tx)

   static MbInitRepairMbState_tx inst;
   logic o_tx_sb_req_exp;
   logic [15:0] o_tx_info_exp;

   logic [8:0] o_tx_encoding_exp;
   bit match;

   protected function new(string name = "MbInitRepairMbState_tx");
      super.new(name);
   endfunction

   static function MbInitRepairMbState_tx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_sequence_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_sequence_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
      // Lane repair negotiation

      // start the lane repair
      if(item_controllers_in.i_tx_decoding == MBINIT_REVERSAL_TX_Done_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1) begin
         o_tx_encoding_exp = 'h38;
         o_tx_sb_req_exp = 1;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp)
            match = 1;
         else
            match = 0;
      end

      // point test 
      else if(item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_controllers_in.i_tx_decoding == 'h38) begin
         o_tx_encoding_exp = 'h39;
         item_tx_sb_req_exp = 1;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp)
            match = 1;
         else
            match = 0;
      end

      //point test fsm
      // ************************************************************************************
      // start point test
      else if(item_controllers_in.i_tx_rsp && item_controllers_in.i_tx_decoding == 'h39) begin
         o_tx_encoding_exp = 'h180;
         o_tx_sb_req_exp = 1;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp)
            match = 1;
         else
            match = 0;
      end

      // lfsr clear hs
      else if(item_controllers_in.i_tx_decoding == 'h180  && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1) begin
         o_tx_encoding_exp = 'h181;
         o_tx_sb_req_exp = 1;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp)
            match = 1;
         else
            match = 0;
      end

      //pattern generation
      else if (item_controllers_in.i_tx_decoding == 'h181 && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1) begin
         o_tx_encoding_exp = 'h182;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp)
            match = 1;
         else
            match = 0;
      end

      //result handshake
      else if (item_controllers_in.i_tx_done && item_controllers_in.i_tx_decoding == 'h182) begin
         o_tx_encoding_exp = 'h183;
         o_tx_sb_req_exp = 1;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp)
            match = 1;
         else
            match = 0;
      end

      // end handshake + // need to check the retry state
      else if(item_controllers_in.i_tx_decoding == 'h183 && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_tx_fsm_sb_in.i_tx_info[4] == 'h1) begin
         o_tx_encoding_exp = 'h184;
         o_tx_sb_req_exp = 1;
         o_tx_info_exp = 15'h0;
         
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
            match = 1;
         else
            match = 0;
      end

      // rerty the point test if failure,  need to check the retry state as the encoding is the same as end handshake
      else if(item_controllers_in.i_tx_decoding == 'h183 && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_tx_fsm_sb_in.i_tx_info[4] == 'h0) begin
         o_tx_encoding_exp = 'h181;
         o_tx_sb_req_exp = 1;
         o_tx_info_exp = 15'h0;
         
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
            match = 1;
         else
            match = 0;
      end




      // *********************************************************************************************
      // apply degarding
      else if(item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_controllers_in.i_tx_decoding == 'h183) begin
         o_tx_encoding_exp = 'h3A;
         o_tx_sb_req_exp = 1;
         // lane map code assigned in the info field
         o_tx_info_exp[2:0] = `LANE_MAP_CODE
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp)
            match = 1;
         else
            match = 0;
      end

      //degradeing result (FAIL)
      else if(item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_controllers_in.i_tx_decoding == 'h3A && item_tx_fsm_sb_in.i_tx_data <= `RESULT_THRESHOLD) begin
         o_tx_encoding_exp = 'h39;
         o_tx_sb_req_exp = 1;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp)
            match = 1;
         else
            match = 0;
      end

      // degareing result (PASS)
      else if(item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_controllers_in.i_tx_decoding == 'h3A && item_tx_fsm_sb_in.i_tx_data > `RESULT_THRESHOLD) begin
         o_tx_encoding_exp = 'h3B;
         // done handshake req
         o_tx_sb_req_exp = 1;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp)
            match = 1;
         else
            match = 0;
      end


      return match;
   endfunction

   function fsm_t getStateId();
      return fsm_mbinit_tx_repairmb;
   endfunction

endclass
