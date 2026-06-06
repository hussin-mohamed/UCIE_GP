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
class SbInitState_tx extends State;

   static SbInitState_tx inst;

   logic [8:0] o_tx_encoding_exp;
   logic o_sbinit_start_exp;
   logic o_tx_sb_req_exp;
   logic [15:0] o_tx_info_exp;
   bit match;
   protected function new(); endfunction

   static function SbInitState_tx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
      // predict combinational outputs in sbinit state
      if(cntxt.currentstate_tx == ResetState_tx::Instance() && item_controllers_in.i_supply_stable && item_controllers_in.i_pll_stable) begin

         o_tx_encoding_exp = 'h8;
         o_sbinit_start_exp = 1;

         if(item_tx_fsm_sb_out.o_tx_encoding == o_tx_encoding_exp && item_controllers_out.o_sbinit_start == o_sbinit_start_exp)begin
            match = 1;

         end
            
         else begin
            `uvm_info("SbInitState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_sbinit_start: %0b, Actual o_sbinit_start: %0b", o_tx_encoding_exp, item_tx_fsm_sb_out.o_tx_encoding, o_sbinit_start_exp, item_controllers_out.o_sbinit_start), UVM_LOW)
            match = 0;

         end
      end
      else if(item_controllers_in.i_sb_ready && item_tx_fsm_sb_in.i_tx_decoding == 'h8) begin
         o_tx_encoding_exp = 'h9;
         o_sbinit_start_exp = 0;
         if(item_tx_fsm_sb_out.o_tx_encoding == o_tx_encoding_exp && item_controllers_out.o_sbinit_start == o_sbinit_start_exp)
            match = 1;
         else begin
            `uvm_info("SbInitState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_sbinit_start: %0b, Actual o_sbinit_start: %0b", o_tx_encoding_exp, item_controllers_out.o_tx_encoding, o_sbinit_start_exp, item_controllers_out.o_sbinit_start), UVM_LOW)
            match = 0;
         end
      end

      else if(item_tx_fsm_sb_in.i_tx_decoding == SBINIT_TX_Out_Of_Reset_MSG && o_tx_encoding_exp == 'h9) begin
         o_tx_encoding_exp = 'hA;
         o_sbinit_start_exp = 0;
         o_tx_sb_req_exp = 1;
         o_tx_info_exp = 0;
         tx_done = 1;
      
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_controllers_out.o_sbinit_start == o_sbinit_start_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
           begin
               match = 1;
           end
            
         else begin
            `uvm_info("SbInitState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_sbinit_start: %0b, Actual o_sbinit_start: %0b, Expected o_tx_sb_req: %0b, Actual o_tx_sb_req: %0b, Expected o_tx_info: %0h, Actual o_tx_info: %0h", o_tx_encoding_exp, item_controllers_out.o_tx_encoding, o_sbinit_start_exp, item_controllers_out.o_sbinit_start, o_tx_sb_req_exp, item_tx_fsm_sb_out.o_tx_sb_req, o_tx_info_exp, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
            match = 0;
         end
      end
/*
      else if(item_tx_fsm_sb_in.i_tx_decoding == 'ha && item_tx_fsm_sb_in.i_sb_tx_rsp == 1'b1 && rx_done == 1'b0) begin
         o_tx_encoding_exp = 'hA;
         o_sbinit_start_exp = 0;
         o_tx_sb_req_exp = 1;
         o_tx_info_exp = 0;
         tx_done = 1;
      
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_controllers_out.o_sbinit_start == o_sbinit_start_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp && item_tx_fsm_sb_out.o_tx_info == o_tx_info_exp)
           begin
               match = 1;
           end
            
         else begin
            `uvm_info("SbInitState_tx", $sformatf("Expected o_tx_encoding: %0h, Actual o_tx_encoding: %0h, Expected o_sbinit_start: %0b, Actual o_sbinit_start: %0b, Expected o_tx_sb_req: %0b, Actual o_tx_sb_req: %0b, Expected o_tx_info: %0h, Actual o_tx_info: %0h", o_tx_encoding_exp, item_controllers_out.o_tx_encoding, o_sbinit_start_exp, item_controllers_out.o_sbinit_start, o_tx_sb_req_exp, item_tx_fsm_sb_out.o_tx_sb_req, o_tx_info_exp, item_tx_fsm_sb_out.o_tx_info), UVM_LOW)
            match = 0;
         end
      end

*/
      else
         match = 1'b1;
      return match;
   endfunction

   function fsm_t getStateId();
      return fsm_tx_sbinit;
   endfunction

endclass
