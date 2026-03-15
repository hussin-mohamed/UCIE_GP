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
class MbInitRepairMbState_rx extends State;
   import shared_ltsm_pkg::*;
   `uvm_object_utils(MbInitRepairMbState_rx)

   static MbInitRepairMbState_rx inst;

   logic [8:0] o_rx_encoding_exp;
   logic [63:0] o_rx_data_exp;
   logic o_rx_sb_rsp_exp;
   logic [15:0] o_rx_info_exp;
   static logic[2:0] lane_map_code_rx;
   bit match;

   protected function new(string name = "MbInitRepairMbState_rx");
      super.new(name);
   endfunction

   static function MbInitRepairMbState_rx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_sequence_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_sequence_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
      // Lane repair negotiation
      //init-handshake
       if(cntxt.current_state_rx == MbInitReversalMbState_rx::Instance() && item_controllers_in.i_rx_decoding == MBINIT_REVERSAL_RX_Done_Handshake && item_rx_fsm_sb_in.i_sb_rx_req == 1'b1) begin
         o_rx_encoding_exp = 'h38;
         o_rx_sb_rsp_exp = 1;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp)
            match = 1;
         else
            match = 0;
      end
      

      else if(item_rx_fsm_sb_in.i_sb_rx_done == 1'b1 && item_controllers_in.i_rx_decoding == 'h38) begin
         o_rx_encoding_exp = 'h39;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else
            match = 0;
      end
      // rx point test fsm
      //**********************************************************
      else if(item_rx_fsm_sb_in.i_sb_rx_req == 1'b1 && item_controllers_in.i_rx_decoding == 'h39) begin
         o_rx_encoding_exp = 'h180;
         o_rx_sb_rsp_exp = 1;
         o_rx_info_exp = 15'h0;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp && item_rx_fsm_sb_out.o_rx_info == o_rx_info_exp)
            match = 1;
         else
            match = 0;
      end

      // lfsr clear hs
      else if(item_controllers_in.i_rx_decoding == 'h181 && item_rx_fsm_sb_in.i_sb_rx_req == 1'b1) begin
         o_rx_encoding_exp = 'h181;
         o_rx_sb_rsp_exp = 1;
         o_rx_info_exp = 15'h0;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp && item_rx_fsm_sb_out.o_rx_info == o_rx_info_exp)
            match = 1;
         else
            match = 0;
      end

      // pattern detection
      else if(item_controllers_in.i_rx_decoding == 'h182 && item_rx_fsm_sb_in.i_sb_rx_done == 1'b1) begin
         o_rx_encoding_exp = 'h182;
         // must be randomized as this flow is created for valid detection only
         o_rx_info_exp[4] = 1'h1;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_info == o_rx_info_exp)
            match = 1;
         else
            match = 0;
      end

      // result hs
      else if(item_controllers_in.i_rx_decoding == 'h183 && item_rx_fsm_sb_in.i_sb_rx_req == 1'b1) begin
         o_rx_encoding_exp = 'h183;
         o_rx_sb_rsp_exp = 1;
         // filling the info field with the pattern detection result
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp)
            match = 1;
         else
            match = 0;
      end

      // end handshake + retry state check
      else if(item_controllers_in.i_rx_decoding == 'h184 && item_rx_fsm_sb_in.i_sb_rx_req == 1'b1) begin
         o_rx_encoding_exp = 'h184;
         o_rx_sb_rsp_exp = 1;
         o_rx_data_exp = item_controllers_in.i_lane_error;
         // calc the rx_lane_map 
         if(item_controllers_in.i_lane_error[7:0] = 8'b11111111) begin
            lane_map_code_rx = 3'b001;
         end
         else if(item_controllers_in.i_lane_error[15:8] = 8'b11111111)begin
            lane_map_code_rx = 3'b010;
         end
         else if(item_controllers_in.i_lane_error[15:0] = 16'b1111111111111111)begin
            lane_map_code_rx = 3'b011;
         end
         else if(item_controllers_in.i_lane_error[3:0] = 4'b1111)begin
            lane_map_code_rx = 3'b100;
         end
         else if(item_controllers_in.i_lane_error[7:4] = 4'b1111)begin
            lane_map_code_rx = 3'b101;
         end

         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp && item_rx_fsm_sb_out.o_rx_info == o_rx_info_exp)
            match = 1;
         else
            match = 0;
      end

      //***********************************************************

      //wait the result req
      else if( item_controllers_in.i_rx_decoding == 'h184) begin
         o_rx_encoding_exp = 'h3A;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else
            match = 0;
      end


      else if(item_rx_fsm_sb_in.i_sb_rx_req == 1'b1 && item_rx_fsm_sb_in.i_rx_info[2:0] == lane_map_code_rx && item_controllers_in.i_rx_decoding == 'h3A) begin
         o_rx_encoding_exp = 'h3C;
         //send degrade response
         o_rx_sb_rsp_exp = 1;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp)
            match = 1;
         else
            match = 0;
      end

      else if(item_rx_fsm_sb_in.i_sb_rx_req == 1'b1 && item_rx_fsm_sb_in.i_rx_info[2:0] == 3'b000 && item_controllers_in.i_rx_decoding == 'h3A) begin
         o_rx_encoding_exp = 'hE0;
         // degrade isnot possible -> train error
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else
            match = 0;
      end

      // done handshake
      else if(item_rx_fsm_sb_in.i_sb_rx_done == 1'b1 && item_controllers_in.i_rx_decoding == 'h3C) begin
         o_rx_encoding_exp = 'h3D;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else
            match = 0;
      end
      else if(item_rx_fsm_sb_in.i_sb_req == 1'b1 && item_controllers_in.i_rx_decoding == 'h3A && item_rx_fsm_sb_in.i_rx_info[2:0] != lane_map_code_rx) begin
         o_rx_encoding_exp = 'h3B;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else
            match = 0;
      end

      else if (item_controllers_in.i_rx_decoding == 'h3B && item_controllers_in.i_rx_done == 1'b1) begin
         o_rx_encoding_exp = 'h3C;
         o_rx_sb_rsp_exp = 1;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else
            match = 0;  
      end
      return match;
   endfunction

   function fsm_t getStateId();
      return fsm_mbinit_rx_repairmb;
   endfunction

endclass
