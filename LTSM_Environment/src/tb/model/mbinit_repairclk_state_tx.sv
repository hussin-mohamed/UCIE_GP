class MbInitRepairClkState_tx extends LtsmState_tx;

   static MbInitRepairClkState_tx inst;

   protected function new(); endfunction

   static function MbInitRepairClkState_tx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   function void do_seq(UcieLtsmContext_tx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);
      // Clock lane repair negotiation
   endfunction

   function void do_comb(UcieLtsmContext_tx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);

        if(fsm_tx_items.i_sb_tx_rsp == 1'b1 && controllers_items.i_tx_decoding == REPAIRCLK_INIT_RESP) begin
            controllers_items.o_tx_encoding_exp = 'h21;

        end
        
        else if (controllers_items.i_tx_done) begin
            controllers_items.o_tx_encoding_exp = 'h22;
        end

        else if(fsm_tx_items.i_sb_tx_rsp == 1'b1 
                && controllers_items.i_tx_decoding == REPAIRCLK_RESULT_RESP 
                && fsm_tx_items.i_tx_data == ERROR_DETECTED) begin
            controllers_items.o_tx_encoding_exp = 'hE0;
        end

        else if(fsm_tx_items.i_sb_tx_rsp == 1'b1 
                && controllers_items.i_tx_decoding == REPAIRCLK_RESULT_RESP 
                && fsm_tx_items.i_tx_data == NO_ERRORS) begin
            controllers_items.o_tx_encoding_exp = 'h23;
        end
        else
            controllers_items.o_tx_encoding_exp = 'h20;
   endfunction

   function ltsm_state_e get_id();
      return LTSM_MBINIT_REPAIRCLK_TX;
   endfunction

endclass