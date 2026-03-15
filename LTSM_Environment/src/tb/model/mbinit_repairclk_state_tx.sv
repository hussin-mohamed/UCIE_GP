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
class MbInitRepairClkState_tx extends State;
  
   `uvm_object_utils(MbInitRepairClkState_tx)

   static MbInitRepairClkState_tx inst;
   logic o_tx_sb_req_exp;
   logic [15:0] o_tx_info_exp;

   logic [8:0] o_tx_encoding_exp;
   bit match;

   protected function new(string name = "MbInitRepairClkState_tx");
      super.new(name);
   endfunction

   static function MbInitRepairClkState_tx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_sequence_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_sequence_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
      if(cntxt.current_state_tx == MbInitCalState_tx::Instance() && item_controllers_in.i_tx_decoding == MBINIT_CAL_TX_Done_Handshake && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1) begin
         o_tx_encoding_exp = 'h20;
         // init req 
         o_tx_sb_req_exp = 1;
         o_tx_info_exp = 0;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
            match = 1;
         else
            match = 0;
      end
      // Clock lane repair negotiation
      else if(item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_controllers_in.i_tx_decoding == MBINIT_REPAIRCLK_TX_Init_Handshake ) begin
         o_tx_encoding_exp = 'h21;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp)
            match = 1;
         else
            match = 0;
      end
      else if(item_controllers_in.i_tx_done && item_controllers_in.i_tx_encoding == 'h21) begin
         o_tx_encoding_exp = 'h22;
         // result req
         o_tx_sb_req_exp = 1; 
         o_tx_info_exp = 0;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
            match = 1;
         else
            match = 0;
      end
      // failed clk lanes -> trainerror hs
      else if(item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_controllers_in.i_tx_decoding == 'h22 && &item_tx_fsm_sb_in.i_tx_info[2:0] == 3'b000) begin
         o_tx_encoding_exp = 'hE0;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp)
            match = 1;
         else
            match = 0;
      end
      // successful clk lanes
      else if(item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && item_controllers_in.i_tx_decoding == 'h22 && &item_tx_fsm_sb_in.i_tx_info[2:0]  == 3'b111) begin
         o_tx_encoding_exp = 'h23;
         // done handshake req
         o_tx_sb_req_exp = 1;
         o_tx_info_exp = 0;

         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp)
            match = 1;
         else
            match = 0;
      end
      
      return match;
   endfunction

   function fsm_t getStateId();
      return fsm_mbinit_tx_repairclk;
   endfunction

endclass
