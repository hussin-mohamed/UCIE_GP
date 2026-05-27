function bit is_monitored_state(rx_encoding_t _rx_enc);
  if (
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

//-----------------------------------------------------------------------------
// Function: get_next_rx_state
// Description: Returns the next state encoding. Intercepts non-linear FSM 
// jumps into the Data-to-Clock training/test phases.
//-----------------------------------------------------------------------------
function rx_encoding_t get_next_rx_state(rx_encoding_t current_state);
  case (current_state)
    
    // Jumps to TX Initiated Data-to-Clock
    MBINIT_REPAIRMB_RX_Init_Handshake: 
      return Data_To_Clock_test_RX_INIT_Handshake_TX_Init;
      
    MBTRAIN_LINKSPEED_RX_Start_Handshake: 
      return Data_To_Clock_test_RX_INIT_Handshake_TX_Init;

    // Jumps to RX Initiated Data-to-Clock
    MBTRAIN_VALVREF_RX_Start_Handshake: 
      return Data_To_Clock_test_RX_INIT_Handshake_RX_Init;
      
    MBTRAIN_DATAVREF_RX_Start_Handshake: 
      return Data_To_Clock_test_RX_INIT_Handshake_RX_Init;
      
    MBTRAIN_VALTRAINCENTER_RX_Start_Handshake: 
      return Data_To_Clock_test_RX_INIT_Handshake_RX_Init;
      
    MBTRAIN_VALTRAINVREF_RX_Start_Handshake: 
      return Data_To_Clock_test_RX_INIT_Handshake_RX_Init;
      
    MBTRAIN_DTC1_RX_Start_Handshake: 
      return Data_To_Clock_test_RX_INIT_Handshake_RX_Init;
      
    MBTRAIN_DATATRAINVREF_RX_Start_Handshake: 
      return Data_To_Clock_test_RX_INIT_Handshake_RX_Init;
      
    MBTRAIN_DTC2_RX_Start_Handshake: 
      return Data_To_Clock_test_RX_INIT_Handshake_RX_Init;

    // Default sequential transition for all other states
    default: 
      return current_state.next();
      
  endcase // current_state
endfunction : get_next_rx_state
