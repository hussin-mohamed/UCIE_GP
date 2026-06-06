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

class ResetState_rx extends State;
   
   static ResetState_rx inst= null;

   logic [8:0] o_rx_encoding_exp;
   bit match;

   // function new();
   // `uvm_info("ResetState_rx", "entered the new function", UVM_LOW)
   // endfunction

   static function ResetState_rx Instance();

   //`uvm_info("ResetState_rx", "Accessing instance of ResetState_rx", UVM_LOW)
      if(inst == null) begin
         //`uvm_info("ResetState_rx", "entered the if condition", UVM_LOW) 
          inst = new();
         //`uvm_info("ResetState_rx", "Creating instance of ResetState_rx", UVM_LOW)
      end
        
      return inst;
   endfunction

   virtual function bit doSpecificCombAction(FSMContext cntxt,LTSM_controllers_seq_item item_controllers_in,ltsm_rdi_sequence_item item_rdi_in,rx_fsm_sb_sequence_item item_rx_fsm_sb_in,tx_fsm_sb_sequence_item item_tx_fsm_sb_in,
                                              LTSM_controllers_seq_item item_controllers_out,ltsm_rdi_sequence_item item_rdi_out,rx_fsm_sb_sequence_item item_rx_fsm_sb_out,tx_fsm_sb_sequence_item item_tx_fsm_sb_out);
      // predict combinational outputs in reset state
         o_rx_encoding_exp = 0;
         
         if(item_controllers_out.o_rx_encoding == o_rx_encoding_exp) begin
            match = 1;

         end
            
         else begin
            `uvm_info("ResetState_rx", $sformatf("Expected o_rx_encoding: %0h, Actual o_rx_encoding: %0h", o_rx_encoding_exp, item_controllers_out.o_rx_encoding), UVM_LOW)
            match = 0;

         end

      return match;
   endfunction

   function fsm_t getStateId();
      return fsm_rx_reset;
   endfunction

endclass
