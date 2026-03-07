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

class SbInitState_rx extends State;
   `uvm_object_utils(SbInitState_rx)

   static SbInitState_rx inst;

   logic [8:0] o_rx_encoding_exp;
   bit match;

   protected function new(string name = "SbInitState_rx");
      super.new(name);
   endfunction

   static function SbInitState_rx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_sequence_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_sequence_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
      // predict combinational outputs in sbinit state
      if(cntxt.current_state_rx == ResetState_rx::instance() && item_controllers_in.i_power && item_controllers_in.i_pll_stable) begin
         o_rx_encoding_exp = 'h8;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else
            match = 0;
      end
      else if(item_rx_fsm_sb_in.i_rx_decoding == SBINIT_TX_Out_Of_Reset_MSG ) begin
         o_rx_encoding_exp = 'h9;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else
            match = 0;
      end
      
      return match;
   endfunction

   function fsm_t getStateId();
      return fsm_rx_sbinit;
   endfunction

endclass