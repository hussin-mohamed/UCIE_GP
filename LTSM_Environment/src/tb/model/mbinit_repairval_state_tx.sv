class MbInitRepairValState_tx extends LtsmState_tx;

   static MbInitRepairValState_tx inst;

   protected function new(); endfunction

   static function MbInitRepairValState_tx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   function void do_seq(UcieLtsmContext_tx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);
      // Value lane repair negotiation
   endfunction

   function void do_comb(UcieLtsmContext_tx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);

        if(fsm_tx_items.i_sb_tx_rsp == 1'b1) begin
            controllers_items.o_tx_encoding_exp = 'h29;
        end

        else if (controllers_items.i_tx_done) begin
            controllers_items.o_tx_encoding_exp = 'h2A;
        end

        else if(fsm_tx_items.i_sb_tx_rsp == 1'b1 
                && controllers_items.i_tx_decoding == REPAIRVAL_RESULT_RESP 
                && fsm_tx_items.i_tx_data == NO_ERRORS) begin
            controllers_items.o_tx_encoding_exp = 'h2B;
        end

        else
            controllers_items.o_tx_encoding_exp = 'h28;
   endfunction

   function ltsm_state_e get_id();
      return LTSM_MBINIT_REPAIRVAL_TX;
   endfunction

endclass
