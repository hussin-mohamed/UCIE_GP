function bit is_monitored_state(rx_encoding_t _rx_enc);
  if (
    _rx_enc == MBINIT_REPAIRCLK_RX_Pattern_Detection              ||
    _rx_enc == MBINIT_REPAIRVAL_RX_Valid_Pattern_Det              ||
    _rx_enc == MBINIT_REVERSAL_RX_Per_Lane_ID_Det                 ||
    _rx_enc == MBINIT_REPAIRMB_RX_Degrade                         ||
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
