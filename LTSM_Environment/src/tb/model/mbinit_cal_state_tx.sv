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
class MbInitCalState_tx extends State;
   `uvm_object_utils(MbInitCalState_tx)

   static MbInitCalState_tx inst;

   logic [8:0] o_tx_encoding_exp;
   logic o_tx_sb_req_exp;
   bit match;

   protected function new(string name = "MbInitCalState_tx");
      super.new(name);
   endfunction

   static function MbInitCalState_tx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_sequence_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_sequence_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
      // Lane deskew, Equalization, Clock alignment

      if(cntxt.current_state_tx == MbInitParamState_tx::Instance() && item_tx_fsm_sb_in.i_sb_tx_done && item_controllers_in.tx_decoding == MBINIT_CAL_TX_Done_Handshake) begin
         o_tx_encoding_exp = 'h18;
         o_tx_sb_req_exp = 1;
      
         if(item_controllers_out.o_tx_encoding == o_tx_encoding_exp && item_tx_fsm_sb_out.o_tx_sb_req == o_tx_sb_req_exp)
            match = 1;
         else
            match = 0;
      
      end
      
      return match;
   endfunction

   function fsm_t getStateId();
      return fsm_mbinit_tx_cal;
   endfunction

endclass