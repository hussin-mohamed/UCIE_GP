class MbInitRepairClkState_rx extends LtsmState_rx;

   static MbInitRepairClkState_rx inst;

   protected function new(); endfunction

   static function MbInitRepairClkState_rx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   function void do_seq(UcieLtsmContext_rx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);
      // Clock lane repair negotiation
   endfunction

   function void do_comb(UcieLtsmContext_rx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);

        if(fsm_rx_items.i_sb_rx_done == 1'b1) begin
            controllers_items.o_rx_encoding_exp = 'h21;

        end
        
        else if (controllers_items.i_rx_done) begin
            controllers_items.o_rx_encoding_exp = 'h22;

            if(fsm_rx_items.i_sb_rx_req == 1'b1 && controllers_items.i_rx_decoding == REPAIRCLK_RESULT_RESP)
                controllers_items.o_rx_encoding_exp = 'h23;
        end

        else if(fsm_rx_items.i_sb_rx_req == 1'b1 
                && controllers_items.i_rx_decoding == REPAIRCLK_RESULT_RESP) begin
            controllers_items.o_rx_encoding_exp = 'h23;
        end

        else if(fsm_rx_items.i_sb_rx_done == 1'b1) begin
            controllers_items.o_rx_encoding_exp = 'h24;
        end

        else
            controllers_items.o_rx_encoding_exp = 'h20;

   endfunction

   function ltsm_state_e get_id();
      return LTSM_MBINIT_REPAIRCLK_RX;
   endfunction

endclass