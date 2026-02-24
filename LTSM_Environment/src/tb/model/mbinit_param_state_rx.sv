class MbInitParamState_rx extends LtsmState_rx;

   static MbInitParamState_rx inst;

   protected function new(); endfunction

   static function MbInitParamState_rx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   function void do_seq(UcieLtsmContext_rx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);


   endfunction

   function void do_comb(UcieLtsmContext_rx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);

    if(controller_items.i_rx_decoding == CONFIG_REQ)
        controllers_items.o_rx_encoding_exp = 'h11;

    else if(controller_items.i_par_check_done) begin
        controllers_items.o_rx_encoding_exp = 'h12;
        fsm_rx_items.o_rx_data_exp = CHECKING_RESULTS;
    end

    else begin
        controllers_items.o_rx_encoding_exp = 'h10; 
    end
    

   endfunction

   function ltsm_state_e get_id();
      return LTSM_MBINIT_PARAM_RX;
   endfunction

endclass    