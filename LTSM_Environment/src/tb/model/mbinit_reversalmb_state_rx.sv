class MbInitReversalMbState_rx extends LtsmState_rx;

   static MbInitReversalMbState_rx inst;

   protected function new(); endfunction

   static function MbInitReversalMbState_rx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   function void do_seq(UcieLtsmContext_rx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);
      // Lane reversal negotiation
   endfunction

   function void do_comb(UcieLtsmContext_rx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);

        if(fsm_rx_items.i_sb_rx_done == 1'b1 
                && fsm_rx_items.o_rx_data == MAJORITY_LANES_SUCCESS) begin
            controllers_items.o_rx_encoding_exp = 'h34;
        end

        else if(controllers_items.i_rx_done 
                && fsm_rx_items.o_rx_data == MAJORITY_LANES_SUCCESS) begin
            controllers_items.o_rx_encoding_exp = 'h33;
        end


        else if(fsm_rx_items.i_sb_rx_done == 1'b1) begin
            controllers_items.o_rx_encoding_exp = 'h31;

            if(fsm_rx_items.i_sb_rx_done == 1'b1) begin
                controllers_items.o_rx_encoding_exp = 'h32;
            end
        end

        else
            controllers_items.o_rx_encoding_exp = 'h30;

   endfunction

   function ltsm_state_e get_id();
      return LTSM_MBINIT_REVERSALMB_RX;
   endfunction

endclass
