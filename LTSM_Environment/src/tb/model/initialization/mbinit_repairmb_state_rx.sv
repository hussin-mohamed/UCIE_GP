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

   static MbInitRepairMbState_rx inst;

   logic [8:0] o_rx_encoding_exp;
   logic [63:0] o_rx_data_exp;
   logic o_rx_sb_rsp_exp;
   logic [15:0] o_rx_info_exp;
   static logic[2:0] lane_map_code_rx;
   bit match;

   protected function new(); endfunction

   static function MbInitRepairMbState_rx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
      // Lane repair negotiation
      //init-handshake
       if(cntxt.currentstate_rx == MbInitReversalMbState_rx::Instance() && item_rx_fsm_sb_in.i_rx_decoding == MBINIT_REVERSAL_TX_Done_Handshake && item_rx_fsm_sb_in.i_sb_rx_req == 1'b1) begin
         o_rx_encoding_exp = 'h38;
         o_rx_sb_rsp_exp = 1;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairMbState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h, Expected o_rx_sb_rsp: %0b, Actual o_rx_sb_rsp: %0b", o_rx_encoding_exp, item_controllers_out.o_rx_encoding, o_rx_sb_rsp_exp, item_rx_fsm_sb_out.o_rx_sb_rsp), UVM_LOW)
            match = 0;

         end
      end
      

      else if(item_rx_fsm_sb_in.i_sb_rx_done == 1'b1 && item_rx_fsm_sb_in.i_rx_decoding == 'h38) begin
         o_rx_encoding_exp = 'h180;
         o_rx_sb_rsp_exp = 1;

         // must samples the info field of the incoming the req message to know the max_error_threshold

         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairMbState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h, Expected o_rx_sb_rsp: %0b, Actual o_rx_sb_rsp: %0b", o_rx_encoding_exp, item_controllers_out.o_rx_encoding, o_rx_sb_rsp_exp, item_rx_fsm_sb_out.o_rx_sb_rsp), UVM_LOW)
            match = 0;

         end
      end
      // rx point test fsm
      //**********************************************************
      // lfsr clear hs
      else if(item_rx_fsm_sb_in.i_rx_decoding == 'h181 && item_rx_fsm_sb_in.i_sb_rx_req == 1'b1) begin
         o_rx_encoding_exp = 'h181;
         o_rx_sb_rsp_exp = 1;
         o_rx_info_exp = 15'h0;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp && item_rx_fsm_sb_out.o_rx_info == o_rx_info_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairMbState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h, Expected o_rx_sb_rsp: %0b, Actual o_rx_sb_rsp: %0b, Expected o_rx_info: %0h, Actual o_rx_info: %0h", o_rx_encoding_exp, item_controllers_out.o_rx_encoding, o_rx_sb_rsp_exp, item_rx_fsm_sb_out.o_rx_sb_rsp, o_rx_info_exp, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
            match = 0;
         end
      end

      // pattern detection
      else if( item_rx_fsm_sb_in.i_rx_decoding == 'h183 && item_rx_fsm_sb_in.i_sb_rx_req == 1'b1) begin
         o_rx_encoding_exp = 'h183;
         o_rx_info_exp = 15'h20;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_info == o_rx_info_exp)
           begin
            match = 1;
           end
         else begin
            `uvm_info("MbInitRepairMbState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h, Expected o_rx_info: %0h, Actual o_rx_info: %0h", o_rx_encoding_exp, item_controllers_out.o_rx_encoding, o_rx_info_exp, item_rx_fsm_sb_out.o_rx_info), UVM_LOW)
            match = 0;
         end
      end

      // result hs
      else if(item_rx_fsm_sb_in.i_rx_decoding == 'h183 && item_rx_fsm_sb_in.i_sb_rx_req == 1'b1) begin
         o_rx_encoding_exp = 'h183;
         o_rx_sb_rsp_exp = 1;
         // test result indication (pass = if all lanes are functional)
         o_rx_info_exp[4] = &item_controllers_in.i_rx_data_results[15:0];
         // calc the rx_lane_map 
         if(item_controllers_in.i_rx_data_results[7:0] == 8'b11111111 && item_controllers_in.i_rx_data_results[17:8] == 8'b00000000) begin
            lane_map_code_rx = 3'b001;
         end
         else if(item_controllers_in.i_rx_data_results[15:8] == 8'b11111111 && item_controllers_in.i_rx_data_results[7:0] == 8'b00000000)begin
            lane_map_code_rx = 3'b010;
         end
         else if(item_controllers_in.i_rx_data_results[15:0] == 16'hFFFF)begin
            lane_map_code_rx = 3'b011;
         end
         else if(item_controllers_in.i_rx_data_results[3:0] == 4'b1111 && item_controllers_in.i_rx_data_results[7:4] == 4'b0000)begin
            lane_map_code_rx = 3'b100;
         end
         else if(item_controllers_in.i_rx_data_results[7:4] == 4'b1111 && item_controllers_in.i_rx_data_results[3:0] == 4'b0000)begin
            lane_map_code_rx = 3'b101;
         end
         else begin
            lane_map_code_rx = 3'b000;
         end

         // filling the info field with the pattern detection result

         o_rx_data_exp = item_controllers_in.i_rx_data_results;
         

         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp && item_rx_fsm_sb_out.o_rx_sb_rsp == o_rx_sb_rsp_exp)
         begin
            match = 1;

         end
         else begin
            `uvm_info("MbInitRepairMbState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h, Expected o_rx_sb_rsp: %0b, Actual o_rx_sb_rsp: %0b, Expected o_rx_info: %0b, Actual o_rx_info: %0b", o_rx_encoding_exp, item_controllers_out.o_rx_encoding, o_rx_sb_rsp_exp, item_rx_fsm_sb_out.o_rx_sb_rsp, o_rx_info_exp[4], item_rx_fsm_sb_out.o_rx_info[4]), UVM_LOW)
            match = 0;

         end
      end

      // end handshake + retry state check
      else if(item_rx_fsm_sb_in.i_rx_decoding == 'h184 && item_rx_fsm_sb_in.i_sb_rx_req == 1'b1) begin
         o_rx_encoding_exp = 'h184;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp )
         begin
            match = 1;
         end
            
         else begin
            `uvm_info("MbInitRepairMbState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h", o_rx_encoding_exp, item_controllers_out.o_rx_encoding), UVM_LOW)
            match = 0;

         end
      end

      //***********************************************************

      //wait the result req
      else if( item_rx_fsm_sb_in.i_rx_decoding == 'h184 && item_rx_fsm_sb_in.i_sb_rx_done == 1'b1) begin
         o_rx_encoding_exp = 'h3A;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairMbState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h", o_rx_encoding_exp, item_controllers_out.o_rx_encoding), UVM_LOW)
            match = 0;

         end
      end
      
      /*
      else if(item_rx_fsm_sb_in.i_sb_rx_req == 1'b1 && item_rx_fsm_sb_in.i_rx_info[2:0] == 3'b000 && item_rx_fsm_sb_in.i_rx_decoding == 'h3A) begin
         o_rx_encoding_exp = 'h40;

         // degrade isnot possible -> train error
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairMbState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h", o_rx_encoding_exp, item_controllers_out.o_rx_encoding), UVM_LOW)
            match = 0;

         end
      end
*/
      // done handshake
      else if(item_rx_fsm_sb_in.i_sb_rx_done == 1'b1 && item_rx_fsm_sb_in.i_rx_decoding == 'h3C) begin
         o_rx_encoding_exp = 'h3D;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)begin
               //`uvm_info("MbInitRepairMbState_rx_pass", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h", o_rx_encoding_exp, item_controllers_out.o_rx_encoding), UVM_LOW)
               match = 1;
         end
            
         else begin
            `uvm_info("MbInitRepairMbState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h", o_rx_encoding_exp, item_controllers_out.o_rx_encoding), UVM_LOW)
            match = 0;

         end
      end
      else if(item_rx_fsm_sb_in.i_sb_rx_req == 1'b1 && item_rx_fsm_sb_in.i_rx_decoding == 'h3A && item_rx_fsm_sb_in.i_rx_info[2:0] != lane_map_code_rx) begin
         o_rx_encoding_exp = 'h3B;

         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairMbState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h", o_rx_encoding_exp, item_controllers_out.o_rx_encoding), UVM_LOW)
            match = 0;

         end
      end

       else if(item_rx_fsm_sb_in.i_sb_rx_req == 1'b1 && item_rx_fsm_sb_in.i_rx_decoding == 'h3A && item_rx_fsm_sb_in.i_rx_info[2:0] == lane_map_code_rx) begin
         o_rx_encoding_exp = 'h3C;

         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairMbState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h", o_rx_encoding_exp, item_controllers_out.o_rx_encoding), UVM_LOW)
            match = 0;

         end
      end

      else if (item_rx_fsm_sb_in.i_rx_decoding == 'h3B && item_controllers_in.i_rx_done == 1'b1) begin
         o_rx_encoding_exp = 'h3C;

         o_rx_sb_rsp_exp = 1;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else begin
            `uvm_info("MbInitRepairMbState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h", o_rx_encoding_exp, item_controllers_out.o_rx_encoding), UVM_LOW)
            match = 0;

         end  
      end

      else
         match = 1'b1;
      return match;
   endfunction

   function fsm_t getStateId();
      return fsm_mbinit_rx_repairmb;
   endfunction

endclass
