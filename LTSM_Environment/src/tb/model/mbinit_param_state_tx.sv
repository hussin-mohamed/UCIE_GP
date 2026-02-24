class MbInitParamState_tx extends LtsmState_tx;

   static MbInitParamState_tx inst;

   protected function new(); endfunction

   static function MbInitParamState_tx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   function void do_seq(UcieLtsmContext_tx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);


   endfunction

   function void do_comb(UcieLtsmContext_tx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);

      controllers_items.o_tx_encoding_exp = 'h10; 

   endfunction

   function ltsm_state_e get_id();
      return LTSM_MBINIT_PARAM_TX;
   endfunction

endclass