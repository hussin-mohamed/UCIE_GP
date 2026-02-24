class SbInitState_tx extends LtsmState_tx;

   static SbInitState_tx inst;

   protected function new(); endfunction

   static function SbInitState_tx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   function void do_seq(UcieLtsmContext_tx ctx,
                        LtsmInputs inputs);

      // Sideband link training
      // Wait for sb_ready handshake
   endfunction

   function void do_comb(UcieLtsmContext_tx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);

        // predict combinational outputs in sbinit state
        if(controllers_items.i_power || controllers_items.i_pll_stable) begin
            controllers_items.o_tx_encoding_exp = 'h8; 
            fsm_tx_items.o_sbinit_start_exp = 1;
        end

        else if(controllers_items.i_stop) begin // where stop??
            controllers_items.o_tx_encoding_exp = 'h9;;
        end

        else if(fsm_tx_items.i_tx_decoding == OUF_OF_REST_MSG) begin
            controllers_items.o_tx_encoding_exp = 'hA;
        end


   endfunction

   function ltsm_state_e get_id();
      return LTSM_SBINIT_TX;
   endfunction

endclass