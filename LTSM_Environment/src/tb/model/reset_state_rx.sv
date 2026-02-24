class ResetState_rx extends LtsmState_rx;

   static ResetState_rx inst;

   protected function new(); endfunction

   static function ResetState_rx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   function void do_seq(UcieLtsmContext_rx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);

      // Wait for reset deassert
      // Clear training flags
   endfunction

   function void do_comb(UcieLtsmContext_rx ctx,
                         tx_fsm_sb_sequence_item fsm_tx_items,
                         rx_fsm_sb_sequence_item fsm_rx_items,
                         ltsm_rdi_sequence_item rdi_items,
                         LTSM_controllers_seq_item controllers_items);


      // predict combinational outputs in reset state
      controllers_items.o_rx_encoding_exp = 0;

   endfunction

   function ltsm_state_e get_id();
      return LTSM_RESET_RX;
   endfunction

endclass