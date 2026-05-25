function bit is_monitored_state(rx_encoding_t _rx_enc);
  if (
    _rx_enc == MBINIT_REVERSAL_RX_Per_Lane_ID_Det                 ||
    _rx_enc == MBINIT_REPAIRMB_RX_Degrade                         ||  // What should the predictor do with this state?
    _rx_enc == ACTIVE_RX_Active                                   ||
    _rx_enc == Data_To_Clock_test_RX_LFSR_Clear_Handshake_TX_Init ||
    _rx_enc == Data_To_Clock_test_RX_Pattern_Detection_TX_Init    ||
    _rx_enc == Data_To_Clock_test_RX_LFSR_Clear_Handshake_RX_Init ||
    _rx_enc == Data_To_Clock_test_RX_Pattern_Detection_RX_Init
  ) begin
    return 1;
  end else begin
    return 0;
  end
endfunction : is_monitored_state

function bit is_control_state(rx_encoding_t enc);
  // Returns 1 if state does NOT rely on physical link data
  if (enc == ACTIVE_RX_Active ||
      enc == MBINIT_REVERSAL_RX_Per_Lane_ID_Det ||
      enc == Data_To_Clock_test_RX_Pattern_Detection_TX_Init ||
      enc == Data_To_Clock_test_RX_Pattern_Detection_RX_Init) begin
    return 1'b0;
  end
  return 1'b1;
endfunction : is_control_state