class MbInitReversalMbState_tx extends LtsmState_tx;

   static MbInitReversalMbState_tx inst;

   protected function new(); endfunction

   static function MbInitReversalMbState_tx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   function void do_seq(UcieLtsmContext_tx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);
      // Lane reversal negotiation
   endfunction

   function void do_comb(UcieLtsmContext_tx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);

        if(fsm_tx_items.i_sb_tx_rsp == 1'b1 
                && controllers_items.i_tx_decoding == REVERSAL_RESULT_RESP 
                && fsm_tx_items.i_tx_data == MAJORITY_LANES_SUCCESS) begin
            controllers_items.o_tx_encoding_exp = 'h35;
        end

        else if(fsm_tx_items.i_sb_tx_rsp == 1'b1 
                && fsm_tx_items.i_tx_data == MAJORITY_LANES_SUCCESS) begin
            controllers_items.o_tx_encoding_exp = 'h34;
        end

        else if(controllers_items.i_tx_done) begin
            controllers_items.o_tx_encoding_exp = 'h33;
        end

        else if(fsm_tx_items.i_sb_tx_rsp == 1'b1) begin
            controllers_items.o_tx_encoding_exp = 'h32;
        end

        else if(fsm_tx_items.i_sb_tx_rsp == 1'b1) begin
            controllers_items.o_tx_encoding_exp = 'h31;
        end

        else
            controllers_items.o_tx_encoding_exp = 'h30;
   endfunction

   function ltsm_state_e get_id();
      return LTSM_MBINIT_REVERSALMB_TX;
   endfunction

endclass
