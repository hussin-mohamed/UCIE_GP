class MbInitRepairMbState_rx extends LtsmState_rx;

   static MbInitRepairMbState_rx inst;

   protected function new(); endfunction

   static function MbInitRepairMbState_rx Instance();
      if(inst == null)
         inst = new();
      return inst;
   endfunction

   function void do_seq(UcieLtsmContext_rx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);
      // Lane repair negotiation
   endfunction

   function void do_comb(UcieLtsmContext_rx ctx,
                        tx_fsm_sb_sequence_item fsm_tx_items,
                        rx_fsm_sb_sequence_item fsm_rx_items,
                        ltsm_rdi_sequence_item rdi_items,
                        LTSM_controllers_seq_item controllers_items);

         // Init handshake: when sb indicates a done and decoding shows REPAIRMB init
         if(fsm_rx_items.i_sb_rx_done == 1'b1 && controllers_items.i_rx_decoding == REPAIRMB_INIT) begin
            controllers_items.o_rx_encoding_exp = 'h39; // Data to Clock Point Test

         end

         // When the internal RX procedure completes, enter "wait for apply degrade req"
         else if (controllers_items.i_rx_done) begin
            controllers_items.o_rx_encoding_exp = 'h3A; // Wait for Apply Degrade REQ

         end

         // If a sideband request arrives asking for a degrade response, send it
         else if (fsm_rx_items.i_sb_rx_req == 1'b1 && fsm_rx_items.i_rx_data == TX_LANE_MAP) begin
            controllers_items.o_rx_encoding_exp = 'h3C; // Send Degrade RESP
            fsm_rx_items.o_rx_data_exp = ALL_CURRENT_LANES_GOOD;

         end

         // If the received data indicates lanes are not all good, indicate degrade
         else if (fsm_rx_items.i_sb_rx_done == 1'b1 && fsm_rx_items.i_rx_data == NOT_ALL_CURRENT_LANES_GOOD) begin
            controllers_items.o_rx_encoding_exp = 'h3B; // Degrade
            if(controllers_items.i_rx_done == 1'b1)
                controllers_items.o_rx_encoding_exp = 'h3C; // Send Degrade RESP

         end

         // If the received data indicates all lanes good, finish
         else if (fsm_rx_items.i_sb_rx_done == 1'b1 && fsm_rx_items.i_rx_data == ALL_CURRENT_LANES_GOOD) begin
            controllers_items.o_rx_encoding_exp = 'h3D; // Done Handshake

         end

         else
            controllers_items.o_rx_encoding_exp = 'h38; // Init Handshake

   endfunction

   function ltsm_state_e get_id();
      return LTSM_MBINIT_REPAIRMB_RX;
   endfunction

endclass
