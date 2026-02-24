class MbInitCalState_rx extends LtsmState_rx;

   static MbInitCalState_rx inst;

   protected function new(); endfunction

   static function MbInitCalState_rx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   function void do_seq(UcieLtsmContext_rx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);


      // Lane deskew
      // Equalization
      // Clock alignment

   endfunction

   function void do_comb(UcieLtsmContext_rx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);

        controllers_items.o_rx_encoding_exp = 'h18;

   endfunction

   function ltsm_state_e get_id();
      return LTSM_MBINIT_CAL_RX;
   endfunction

endclass