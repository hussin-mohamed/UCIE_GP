class SbInitState_rx extends LtsmState_rx;

   static SbInitState_rx inst;

   protected function new(); endfunction

   static function SbInitState_rx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   function void do_seq(UcieLtsmContext_rx ctx,
                        LtsmInputs inputs);

      // Sideband link training
      // Wait for sb_ready handshake
   endfunction

   function void do_comb(UcieLtsmContext_rx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);

        // predict combinational outputs in sbinit state
        if(controllers_items.i_power || controllers_items.i_pll_stable) begin
            controllers_items.o_rx_encoding_exp = 'h8; 
        end
    
        else if(fsm_rx_items.i_rx_decoding == OUF_OF_REST_MSG) begin
            controllers_items.o_rx_encoding_exp = 'h9;
        end


   endfunction

   function ltsm_state_e get_id();
      return LTSM_SBINIT_RX;
   endfunction

endclass