class MbInitRepairValState_rx extends LtsmState_rx;

   static MbInitRepairValState_rx inst;

   protected function new(); endfunction

   static function MbInitRepairValState_rx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   function void do_seq(UcieLtsmContext_rx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);
      // Value lane repair negotiation
   endfunction

   function void do_comb(UcieLtsmContext_rx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);

        if(fsm_rx_items.i_sb_rx_done == 1'b1 && controllers_items.i_rx_done) begin
            controllers_items.o_rx_encoding_exp = 'h2C;
        end

        else if(fsm_rx_items.i_sb_rx_req == 1'b1 
                && controllers_items.i_rx_decoding == REPAIRVAL_RESULT_REQ) begin
            controllers_items.o_rx_encoding_exp = 'h2B;
            fsm_rx_items.o_rx_data_exp = RESULTS;
        end

        else if (controllers_items.i_rx_done) begin
            controllers_items.o_rx_encoding_exp = 'h2A;
        end

        else if(fsm_rx_items.i_sb_rx_done == 1'b1) begin
            controllers_items.o_rx_encoding_exp = 'h29;
        end

        else
            controllers_items.o_rx_encoding_exp = 'h28;

   endfunction

   function ltsm_state_e get_id();
      return LTSM_MBINIT_REPAIRVAL_RX;
   endfunction

endclass
