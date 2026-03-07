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

class SbInitState_tx extends State;
   `uvm_object_utils(SbInitState_tx)

   static SbInitState_tx inst;

   logic [8:0] o_tx_encoding_exp;
   logic o_sbinit_start_exp;
   logic o_tx_sb_req_exp;
   bit match;

   protected function new(string name = "SbInitState_tx");
      super.new(name);
   endfunction

   static function SbInitState_tx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_sequence_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_sequence_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
      // predict combinational outputs in sbinit state
      if(cntxt.current_state_tx == ResetState_tx::instance() && item_controllers_in.i_power && item_controllers_in.i_pll_stable) begin
         o_tx_encoding_exp = 'h8;
         o_sbinit_start_exp = 1;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_sbinit_start == o_sbinit_start_exp)
            match = 1;
         else
            match = 0;
      end
      else if(item_controllers_in.i_stop && item_controllers_in.i_tx_decoding == 'h8) begin
         o_tx_encoding_exp = 'h9;
         o_sbinit_start_exp = 0;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_sbinit_start == o_sbinit_start_exp)
            match = 1;
         else
            match = 0;
      end
      else if(item_tx_fsm_sb_in.i_tx_decoding == SBINIT_TX_Out_Of_Reset_MSG) begin
         o_tx_encoding_exp = 'hA;
         o_sbinit_start_exp = 0;
         o_tx_sb_req_exp = 1;
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_sbinit_start == o_sbinit_start_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp)
            match = 1;
         else
            match = 0;
      end
      
      return match;
   endfunction

   function fsm_t getStateId();
      return fsm_tx_sbinit;
   endfunction

endclass