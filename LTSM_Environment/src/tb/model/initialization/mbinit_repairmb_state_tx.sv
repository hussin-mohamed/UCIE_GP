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
   

   static MbInitRepairMbState_tx inst;
   logic o_tx_sb_req_exp;
   logic [15:0] o_tx_info_exp;
   logic [64:0] o_tx_data_exp;

   logic [8:0] o_tx_encoding_exp;
   bit match;
   static logic[15:0]  lane_res;
   static bit error;
   

   protected function new(); endfunction

   static function MbInitRepairMbState_tx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
      // Lane repair negotiation

      // start the lane repair
      if(item_tx_fsm_sb_in.i_tx_decoding == MBINIT_REVERSAL_TX_Done_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1) begin
         o_tx_encoding_exp = 'h38;
         o_tx_sb_req_exp = 1;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairMbState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_tx_sb_req: %0b, Actual o_tx_sb_req: %0b", o_tx_encoding_exp, item_controllers_out.o_tx_encoding, o_tx_sb_req_exp, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            match = 0;

         end
      end

      //point test fsm
      // ************************************************************************************
      // start point test
      else if(item_tx_fsm_sb_in.i_sb_tx_rsp && item_tx_fsm_sb_in.i_tx_decoding == 'h38) begin
         o_tx_encoding_exp = 'h180;
         o_tx_sb_req_exp = 1;
         
         // Maximum comparison error threshold (info field)

         // (data field)
         /*
               [63:60]: Reserved
               [59]: Comparison Mode (0: Per Lane; 1: 
               Aggregate)
               [58:43]: Iteration Count Settings
               [42:27]: Idle Count settings
               [26:11]: Burst Count settings
               [10]: Pattern Mode (0: continuous mode, 1: 
               Burst Mode)
               [9:6]: Clock Phase control at Tx Device (0h: 
               Clock PI Center, 1h: Left Edge, 2h: Right 
               Edge)
               [5:3]: Valid Pattern (0h: Functional pattern)
               [2:0]: Data pattern (0h: LFSR, 1h: Per Lane ID)
         */
         o_tx_data_exp[2:0] = 1'h1;
         o_tx_data_exp[10] = 1'b0; // per lane id pattern
         
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp &&  o_tx_data_exp[2:0]==item_tx_fsm_sb_out.o_tx_data[2:0] )
            begin
            match = 1;
            end
         else begin
            `uvm_info("MbInitRepairMbState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_tx_sb_req: %0b, Actual o_tx_sb_req: %0b, Expected o_tx_data: %0h, Actual o_tx_data: %0h", o_tx_encoding_exp, item_controllers_out.o_tx_encoding, o_tx_sb_req_exp, item_tx_fsm_sb_out.o_tx_sb_req, o_tx_data_exp[2:0], item_tx_fsm_sb_out.o_tx_data[2:0]), UVM_LOW)
            match = 0;

         end
      end

      // lfsr clear hs
      else if(item_tx_fsm_sb_in.i_tx_decoding == 'h180  && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1) begin
         o_tx_encoding_exp = 'h181;
         o_tx_sb_req_exp = 1;
         o_tx_info_exp = 0;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairMbState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_tx_sb_req: %0b, Actual o_tx_sb_req: %0b, Expected o_tx_info: %0h, Actual o_tx_info: %0h", o_tx_encoding_exp, item_controllers_out.o_tx_encoding, o_tx_sb_req_exp, item_tx_fsm_sb_out.o_tx_sb_req, o_tx_info_exp, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
            match = 0;

         end
      end

      //pattern generation
      else if (item_tx_fsm_sb_in.i_tx_decoding == 'h181 && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1) begin
         o_tx_encoding_exp = 'h182;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp) begin
            match = 1;
         end
         else begin
            `uvm_info("MbInitRepairMbState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h", o_tx_encoding_exp, item_controllers_out.o_tx_encoding), UVM_LOW)
            match = 0;

         end
      end

      //result handshake
      else if (item_controllers_in.i_tx_done && item_tx_fsm_sb_in.i_tx_decoding == 'h182) begin
         o_tx_encoding_exp = 'h183;

         o_tx_sb_req_exp = 1;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp) 
         begin
            match = 1;
         end
         else begin
            `uvm_info("MbInitRepairMbState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_tx_sb_req: %0b, Actual o_tx_sb_req: %0b", o_tx_encoding_exp, item_controllers_out.o_tx_encoding, o_tx_sb_req_exp, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            match = 0;

         end
      end

      // end handshake + // need to check the retry state
      else if(item_tx_fsm_sb_in.i_tx_decoding == 'h183 && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1) begin
         lane_res = item_tx_fsm_sb_in.i_tx_data[15:0];
         if(lane_res[7:0] == 8'b11111111 && lane_res[17:8] == 8'b00000000) begin
            lane_map_code_tx = 3'b001;
         end
         else if(lane_res[15:8] == 8'b11111111 && lane_res[7:0] == 8'b00000000)begin
            lane_map_code_tx = 3'b010;
         end
         else if(lane_res[15:0] == 16'hFFFF)begin
            lane_map_code_tx = 3'b011;
         end
         else if(lane_res[3:0] == 4'b1111 && lane_res[7:4] == 4'b0000)begin
            lane_map_code_tx = 3'b100;
         end
         else if(lane_res[7:4] == 4'b1111 && lane_res[3:0] == 4'b0000)begin
            lane_map_code_tx = 3'b101;
         end
         else begin
            lane_map_code_tx = 3'b000;
         end

         o_tx_encoding_exp = 'h184;
         o_tx_sb_req_exp = 1;
         o_tx_info_exp = 15'h0;
         `uvm_info("183 state" , $sformatf("tx_lane_map = %b" , lane_map_code_tx) , UVM_LOW)
         
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
            begin
               match = 1;
            end
         else begin
            `uvm_info("MbInitRepairMbState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_tx_sb_req: %0b, Actual o_tx_sb_req: %0b, Expected o_tx_info: %0h, Actual o_tx_info: %0h", o_tx_encoding_exp, item_controllers_out.o_tx_encoding, o_tx_sb_req_exp, item_tx_fsm_sb_out.o_tx_sb_req, o_tx_info_exp, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
            match = 0;

         end
      end

      // apply degarding
      else if(item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_tx_fsm_sb_in.i_tx_decoding == 'h184) begin
         o_tx_encoding_exp = 'h3A;
         o_tx_sb_req_exp = 1;
         
         // lane map code assigned in the info field
         o_tx_info_exp[2:0] = lane_map_code_tx;

         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info[2:0] == o_tx_info_exp[2:0])
            match = 1;
         else  begin
            `uvm_info("MbInitRepairMbState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_tx_sb_req: %0b, Actual o_tx_sb_req: %0b, Expected o_tx_info: %0b, Actual o_tx_info: %0b", o_tx_encoding_exp, item_controllers_out.o_tx_encoding, o_tx_sb_req_exp, item_tx_fsm_sb_out.o_tx_sb_req, o_tx_info_exp[2:0], item_tx_fsm_sb_out.o_tx_info[2:0]), UVM_LOW)
            match = 0;

         end
      end

       else if(lane_map_code_tx === 3'b000 && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_tx_fsm_sb_in.i_tx_decoding == 'h184 ) begin
         o_tx_encoding_exp = 'h40;
         error = 1;
         o_tx_sb_req_exp = 1;
         o_tx_info_exp = 0;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
            match = 1;
         else  begin
            `uvm_info("MbInitRepairmbState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_tx_sb_req: %0b, Actual o_tx_sb_req: %0b, Expected o_tx_info: %0h, Actual o_tx_info: %0h", o_tx_encoding_exp, item_controllers_out.o_tx_encoding, o_tx_sb_req_exp, item_tx_fsm_sb_out.o_tx_sb_req, o_tx_info_exp, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
            match = 0;

         end
      end


      // *********************************************************************************************
      

     

      //degradeing result (FAIL)
      
      else if(item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_tx_fsm_sb_in.i_tx_decoding == 'h3A  &&  lane_map_code_tx != 3'b000 &&  lane_map_code_tx != 3'b011 ) begin
         o_tx_encoding_exp = 'h180;

         o_tx_sb_req_exp = 1;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairMbState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_tx_sb_req: %0b, Actual o_tx_sb_req: %0b", o_tx_encoding_exp, item_controllers_out.o_tx_encoding, o_tx_sb_req_exp, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            match = 0;

         end
      end

      // degareing result (PASS)
      else if(item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_tx_fsm_sb_in.i_tx_decoding == 'h3A && lane_map_code_tx == 3'b011) begin
         o_tx_encoding_exp = 'h3B;

         // done handshake req
         o_tx_sb_req_exp = 1;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairMbState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_tx_sb_req: %0b, Actual o_tx_sb_req: %0b", o_tx_encoding_exp, item_controllers_out.o_tx_encoding, o_tx_sb_req_exp, item_tx_fsm_sb_out.o_tx_sb_req), UVM_LOW)
            match = 0;

         end
      end

      else
         match = 1'b1;
      return match;
   endfunction

   function fsm_t getStateId();
      return fsm_mbinit_tx_repairmb;
   endfunction

endclass
