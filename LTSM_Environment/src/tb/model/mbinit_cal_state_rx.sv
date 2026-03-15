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
class MbInitCalState_rx extends State;
   `uvm_object_utils(MbInitCalState_rx)

   static MbInitCalState_rx inst;

   logic [8:0] o_rx_encoding_exp;
   logic [15:0] o_rx_info_exp;
   bit match;

   protected function new(string name = "MbInitCalState_rx");
      super.new(name);
   endfunction

   static function MbInitCalState_rx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_sequence_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_sequence_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
      // Lane deskew, Equalization, Clock alignment
      if(cntxt.current_state_rx == MbInitParamState_rx::Instance() && item_rx_fsm_sb_in.i_sb_rx_done && item_controllers_in.rx_decoding == RX_MBINIT_PARAM_Send_RESP) begin
         o_rx_encoding_exp = 'h18;
         o_rx_info_exp = 0;
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp)
            match = 1;
         else
            match = 0;
      end
      
      
      return match;
   endfunction

   function fsm_t getStateId();
      return fsm_mbinit_rx_cal;
   endfunction

endclass
