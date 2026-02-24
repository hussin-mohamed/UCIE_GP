class MbInitRepairMbState_tx extends LtsmState_t;

   static MbInitRepairMbState_tx inst;

   protected function new(); endfunction

   static function MbInitRepairMbState_tx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   function void do_seq(UcieLtsmContext_tx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);
      // Lane repair negotiation
   endfunction

   function void do_comb(UcieLtsmContext_tx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);

        if(fsm_tx_items.i_sb_tx_rsp == 1'b1 
                && fsm_tx_items.i_tx_data == ALL_CURRENT_LANES_GOOD) begin
            controllers_items.o_tx_encoding_exp = 'h3D;
        end

        else if(fsm_tx_items.i_sb_tx_rsp == 1'b1 
                && fsm_tx_items.i_tx_data == NOT_ALL_CURRENT_LANES_GOOD) begin
            controllers_items.o_tx_encoding_exp = 'h3A;
        end

        else if(fsm_tx_items.i_sb_tx_rsp == 1'b1 
                && controllers_items.i_tx_decoding == REPAIRMB_INIT_RESP) begin
            controllers_items.o_tx_encoding_exp = 'h39;
        end

        else
            controllers_items.o_tx_encoding_exp = 'h38;

   endfunction

   function ltsm_state_e get_id();
      return LTSM_MBINIT_REPAIRMB_TX;
   endfunction

endclass
