// ****************************************************************************
// *                                                                          *
// * Copyright (c) 2014-2015 Synopsys Inc. All rights reserved.               *
// *                                                                          *
// * Synopsys Proprietary and Confidential. This file contains confidential   *
// * information and the trade secrets of Synopsys Inc. Use, disclosure, or   *
// * reproduction is prohibited without the prior express written permission  *
// * of Synopsys, Inc.                                                        *
// *                                                                          *
// * Synopsys, Inc.                                                           *
// * 700 East Middlefield Road                                                *
// * Mountain View, California 94043                                          *
// * (800) 541-7737                                                           *
// *                                                                          *
// ****************************************************************************

package shared_pkg;
  
  parameter TX_FIFO_SIZE  = 2;
  parameter RX_FIFO_SIZE  = 2;
  parameter RDI_FIFO_SIZE = 8;

  typedef enum logic [1:0] { 
    START,
    T1MS,
    WAIT_FOR_READY
  } sbinit_mode_t;

  typedef enum logic[1:0] {
    REQ_MSG,
    RSP_MSG,
    NO_TYPE
  } msgtype_t;
  
  typedef enum logic { 
    SBINIT,
    ACTIVE
  } operation_t;

  typedef enum logic {
    MSG_FROM_TX  = 1'b0,
    MSG_FROM_RX  = 1'b1
  } msg_dir_t;

  typedef enum logic [8:0] {
  // ==========================================
  // 00: INITIALIZATION PHASE
  // ==========================================
  
  // 1. RESET
  RESET_Reset_TX                                = 9'b00_0000_000, // PLL/Power Stabilization
  
  // 2. SBINIT
  SBINIT_TX_Pattern_Generation                  = 9'b00_0001_000, // Send Clock Pattern
  SBINIT_TX_Out_Of_Reset_MSG                    = 9'b00_0001_001, // Send Out of Reset
  SBINIT_TX_Done_Handshake                      = 9'b00_0001_010, // Send Done REQ & Wait for RSP
  
  // 3. MBINIT PARAM
  MBINIT_PARAM_TX_Config_Handshake              = 9'b00_0010_000, // Send Config REQ
  
  // 4. MBINIT CAL
  MBINIT_CAL_TX_Done_Handshake                  = 9'b00_0011_000, // Send Cal Done REQ
  
  // 5. MBINIT REPAIRCLK
  MBINIT_REPAIRCLK_TX_Init_Handshake            = 9'b00_0100_000, // Send Init REQ
  MBINIT_REPAIRCLK_TX_Clk_Pattern_Gen           = 9'b00_0100_001, // Send 128 iterations
  MBINIT_REPAIRCLK_TX_Result_Handshake          = 9'b00_0100_010, // Send Result REQ
  MBINIT_REPAIRCLK_TX_Done_Handshake            = 9'b00_0100_011, // Send Done REQ
  
  // 6. MBINIT REPAIRVAL
  MBINIT_REPAIRVAL_TX_Init_Handshake            = 9'b00_0101_000, // Send Init REQ
  MBINIT_REPAIRVAL_TX_Valid_Pattern_Gen         = 9'b00_0101_001, // Send VALTRAIN pattern
  MBINIT_REPAIRVAL_TX_Result_Handshake          = 9'b00_0101_010, // Send Result REQ
  MBINIT_REPAIRVAL_TX_Done_Handshake            = 9'b00_0101_011, // Send Done REQ
  
  // 7. MBINIT REVERSAL
  MBINIT_REVERSAL_TX_Init_Handshake             = 9'b00_0110_000, // Send Init REQ
  MBINIT_REVERSAL_TX_Clear_Log_Handshake        = 9'b00_0110_001, // Send Clear Error REQ
  MBINIT_REVERSAL_TX_Per_Lane_ID_Gen            = 9'b00_0110_010, // Send ID Pattern
  MBINIT_REVERSAL_TX_Result_Handshake           = 9'b00_0110_011, // Check majority success
  MBINIT_REVERSAL_TX_Apply_Reversal             = 9'b00_0110_100, // Flip Mux (Loop back)
  MBINIT_REVERSAL_TX_Done_Handshake             = 9'b00_0110_101, // Send Done REQ
  
  // 8. MBINIT REPAIRMB
  MBINIT_REPAIRMB_TX_Init_Handshake             = 9'b00_0111_000, // Send Start REQ
  MBINIT_REPAIRMB_TX_Data_to_Clock_Point        = 9'b00_0111_001, // Send ID Pattern
  MBINIT_REPAIRMB_TX_Apply_Degrade_Hnd          = 9'b00_0111_010, // Negotiate Width
  MBINIT_REPAIRMB_TX_Done_Handshake             = 9'b00_0111_011, // Send End REQ
  
  // 9. TRAINERROR
  TRAINERROR_TX_Handshake                       = 9'b00_1000_000, // Send Error REQ
  TRAINERROR_TX_TrainError                      = 9'b00_1000_001, // Wait 8ms Timeout
  TRAINERROR_TX_Reset                           = 9'b00_1000_010, // Go to RESET

  // ==========================================
  // 01: TRAIN PHASE
  // ==========================================
  
  // 1. MBTRAIN VALVREF
  MBTRAIN_VALVREF_TX_Start_Handshake            = 9'b01_0000_000, // Send Vref Start REQ
  MBTRAIN_VALVREF_TX_Pattern_Generation         = 9'b01_0000_001, // Send Pattern
  MBTRAIN_VALVREF_TX_End_Handshake              = 9'b01_0000_010, // Send End REQ
  
  // 2. MBTRAIN DATAVREF
  MBTRAIN_DATAVREF_TX_Start_Handshake           = 9'b01_0001_000, // Send Start REQ
  MBTRAIN_DATAVREF_TX_Pattern_Generation        = 9'b01_0001_001, // Send Pattern
  MBTRAIN_DATAVREF_TX_End_Handshake             = 9'b01_0001_010, // Send End REQ
  
  // 3. MBTRAIN DATATRAINCENTER1
  MBTRAIN_DTC1_TX_Start_Handshake               = 9'b01_0010_000, // Send Start REQ
  MBTRAIN_DTC1_TX_Pattern_Generation            = 9'b01_0010_001, // Send 4K UI Pattern
  MBTRAIN_DTC1_TX_End_Handshake                 = 9'b01_0010_010, // Send End REQ
  
  // 4. MBTRAIN RXCLKCAL
  MBTRAIN_RXCLKCAL_TX_Start_Handshake           = 9'b01_0011_000, // Send Start REQ
  MBTRAIN_RXCLKCAL_TX_Clock_Shifting_Op         = 9'b01_0011_001, // Wait for RX shift
  MBTRAIN_RXCLKCAL_TX_End_Handshake             = 9'b01_0011_010, // Send End REQ
  
  // 5. MBTRAIN VALTRAINVREF
  MBTRAIN_VALTRAINVREF_TX_Start_Handshake       = 9'b01_0100_000, // Send Start REQ
  MBTRAIN_VALTRAINVREF_TX_Pattern_Generation    = 9'b01_0100_001, // Send Pattern
  MBTRAIN_VALTRAINVREF_TX_End_Handshake         = 9'b01_0100_010, // Send End REQ
  
  // 6. MBTRAIN RXDESKEW
  MBTRAIN_RXDESKEW_TX_Start_Handshake           = 9'b01_0101_000, // Send Start REQ
  MBTRAIN_RXDESKEW_TX_EQ_Preset_Handshake       = 9'b01_0101_001, // Send EQ Preset REQ
  MBTRAIN_RXDESKEW_TX_Deskew_Operation          = 9'b01_0101_010, // Wait for Deskew
  MBTRAIN_RXDESKEW_TX_Datacenter_Handshake      = 9'b01_0101_011, // Exit to DTC2
  MBTRAIN_RXDESKEW_TX_End_Handshake             = 9'b01_0101_100, // Exit to LinkSpeed
  MBTRAIN_RXDESKEW_TX_Train_Error_Handshake     = 9'b01_0101_101, // Exit to Error
  
  // 7. MBTRAIN DATATRAINCENTER2
  MBTRAIN_DTC2_TX_Start_Handshake               = 9'b01_0110_000, // Send Start REQ
  MBTRAIN_DTC2_TX_Pattern_Generation            = 9'b01_0110_001, // Send 4K UI Pattern
  MBTRAIN_DTC2_TX_End_Handshake                 = 9'b01_0110_010, // Send End REQ
  
  // 8. MBTRAIN LINKSPEED
  MBTRAIN_LINKSPEED_TX_Start_Handshake          = 9'b01_0111_000, // Send Start REQ
  MBTRAIN_LINKSPEED_TX_Data_Clock_Test          = 9'b01_0111_001, // Send LFSR Pattern
  MBTRAIN_LINKSPEED_TX_LinksSpeed_Done_Hnd      = 9'b01_0111_010, // Success -> LinkInit
  MBTRAIN_LINKSPEED_TX_Error_REQ                = 9'b01_0111_011, // Fail -> Eval Error
  MBTRAIN_LINKSPEED_TX_Phy_Retrain_Hnd          = 9'b01_0111_100, // Critical Fail -> Retrain
  MBTRAIN_LINKSPEED_TX_Exit_Repair_Hnd          = 9'b01_0111_101, // Exit to Repair
  MBTRAIN_LINKSPEED_TX_Exit_SpeedDegrade_Hnd    = 9'b01_0111_110, // Exit to Speed Degrade
  
  // 9. MBTRAIN REPAIR
  MBTRAIN_REPAIR_TX_Start_Handshake             = 9'b01_1000_000, // Send Init REQ
  MBTRAIN_REPAIR_TX_Apply_Degrade_Handshake     = 9'b01_1000_001, // Negotiate Width
  MBTRAIN_REPAIR_TX_End_Handshake               = 9'b01_1000_010, // Send End REQ
  
  // 10. MBTRAIN SPEEDIDLE
  MBTRAIN_SPEEDIDLE_TX_Speed_Transition         = 9'b01_1001_000, // Change Clock Div
  MBTRAIN_SPEEDIDLE_TX_End_Handshake            = 9'b01_1001_001, // Success -> Retrain
  MBTRAIN_SPEEDIDLE_TX_TrainError_Handshake     = 9'b01_1001_010, // Fail -> Error
  
  // 11. MBTRAIN TXSELFCAL
  MBTRAIN_TXSELFCAL_TX_Calibration              = 9'b01_1010_000, // Run Internal Cal
  MBTRAIN_TXSELFCAL_TX_End_Handshake            = 9'b01_1010_001, // Send End REQ
  
  // 12. PHYRETRAIN
  PHYRETRAIN_TX_PL_StallReq_Handshake           = 9'b01_1011_000, // Ask Adapter to Stall
  PHYRETRAIN_TX_Retrain_Handshake               = 9'b01_1011_001, // Sync with Partner
  PHYRETRAIN_TX_Start_Req_Handshake             = 9'b01_1011_010, // Choose next state
  
  // 14. VALTRAINCENTER
  MBTRAIN_VALTRAINCENTER_TX_Start_Handshake     = 9'b01_1101_000, 
  MBTRAIN_VALTRAINCENTER_TX_Pattern_Generation  = 9'b01_1101_001, 
  MBTRAIN_VALTRAINCENTER_TX_End_Handshake       = 9'b01_1101_010, 
  
  // 15. DATATRAINVREF
  MBTRAIN_DATATRAINVREF_TX_Start_Handshake      = 9'b01_1110_000, 
  MBTRAIN_DATATRAINVREF_TX_Pattern_Generation   = 9'b01_1110_001, 
  MBTRAIN_DATATRAINVREF_TX_End_Handshake        = 9'b01_1110_010, 

  // ==========================================
  // 10: ACTIVE PHASE
  // ==========================================
  
  // 1. LINKINIT
  LINKINIT_TX_PL_Clk_Req_Handshake              = 9'b10_0000_000, // Req Adapter Clock
  LINKINIT_TX_LP_Wake_Req_Handshake             = 9'b10_0000_001, // Wake Adapter
  LINKINIT_TX_State_Req_Handshake               = 9'b10_0000_010, // RDI State Exchange
  
  // 2. ACTIVE
  ACTIVE_TX_Active                              = 9'b10_0001_000, // Data Flowing
  
  // 3. L1 / Exit HS
  L1_TX_handshake                               = 9'b10_0010_000, 
  L1_TX_L1_State                                = 9'b10_0010_001, // Low Power State
  EXIT_HS_TX_Exit_Handshake                     = 9'b10_0011_010, // Wakeup from L1

  Send_Start_Rx_Init_D_to_C_eye_sweep_resp      = 9'b11_0000_000,
  Send_Rx_Init_D_to_C_sweep_done_with_results   = 9'b11_0000_001,

  
  NOP_TX                                       = 9'b11_1111_111   // No Operation

  } tx_encoding_t;

  typedef enum logic [8:0] {
  // ==========================================
  // 00: INITIALIZATION PHASE
  // ==========================================
  
  // 1. RESET
  RESET_Reset_RX                                = 9'b00_0000_000, // PLL/Power Stabilization
  
  // 2. SBINIT
  SBINIT_RX_Wait_Out_Of_Reset                   = 9'b00_0001_000, // Wait for MSG
  SBINIT_RX_Done_Handshake                      = 9'b00_0001_001, // Send Done REQ/RESP
  
  // 3. MBINIT PARAM
  MBINIT_PARAM_RX_Wait_Config_REQ               = 9'b00_0010_000, // Idle
  MBINIT_PARAM_RX_Check_Parameters              = 9'b00_0010_001, // Resolve Capabilities
  MBINIT_PARAM_RX_Send_RESP                     = 9'b00_0010_010, // Send Config RESP
  
  // 4. MBINIT CAL
  MBINIT_CAL_RX_Done_Handshake                  = 9'b00_0011_000, // Send Cal Done RESP
  
  // 5. MBINIT REPAIRCLK
  MBINIT_REPAIRCLK_RX_Init_Handshake            = 9'b00_0100_000, // Send Init RESP
  MBINIT_REPAIRCLK_RX_Pattern_Detection         = 9'b00_0100_001, // Check Clock/Track
  MBINIT_REPAIRCLK_RX_Wait_Result_REQ           = 9'b00_0100_010, // Wait for Log Request
  MBINIT_REPAIRCLK_RX_Send_RESP                 = 9'b00_0100_011, // Send Result Log
  MBINIT_REPAIRCLK_RX_Done_Handshake            = 9'b00_0100_100, // Send Done RESP
  
  // 6. MBINIT REPAIRVAL
  MBINIT_REPAIRVAL_RX_Init_Handshake            = 9'b00_0101_000, // Send Init RESP
  MBINIT_REPAIRVAL_RX_Valid_Pattern_Det         = 9'b00_0101_001, // Check VALTRAIN
  MBINIT_REPAIRVAL_RX_Wait_Result_REQ           = 9'b00_0101_010, // Wait for Log Request
  MBINIT_REPAIRVAL_RX_Send_Result_RESP          = 9'b00_0101_011, // Send Result Log
  MBINIT_REPAIRVAL_RX_Done_Handshake            = 9'b00_0101_100, // Send Done RESP
  
  // 7. MBINIT REVERSAL
  MBINIT_REVERSAL_RX_Init_Handshake             = 9'b00_0110_000, // Send Init RESP
  MBINIT_REVERSAL_RX_Clear_Log_Hnd              = 9'b00_0110_001, // Reset Error Counters
  MBINIT_REVERSAL_RX_Per_Lane_ID_Det            = 9'b00_0110_010, // Identify Lanes
  MBINIT_REVERSAL_RX_Result_Handshake           = 9'b00_0110_011, // Send Result RESP
  MBINIT_REVERSAL_RX_Done_Handshake             = 9'b00_0110_100, // Send Done RESP
  
  // 8. MBINIT REPAIRMB
  MBINIT_REPAIRMB_RX_Init_Handshake             = 9'b00_0111_000, // Send Start RESP
  MBINIT_REPAIRMB_RX_Data_to_Clock              = 9'b00_0111_001, // Detect Faults
  MBINIT_REPAIRMB_RX_Wait_Apply_Degrade         = 9'b00_0111_010, // Wait for TX Map
  MBINIT_REPAIRMB_RX_Degrade                    = 9'b00_0111_011, // Update Hardware
  MBINIT_REPAIRMB_RX_Send_Degrade_Resp          = 9'b00_0111_100, // Confirm Degrade
  MBINIT_REPAIRMB_RX_Done_Handshake             = 9'b00_0111_101, // Send End RESP
  
  // 9. TRAINERROR
  TRAINERROR_RX_Handshake                       = 9'b00_1000_000, // Send Error RESP
  TRAINERROR_RX_TrainError                      = 9'b00_1000_001, // Wait 8ms Timeout
  TRAINERROR_RX_Reset                           = 9'b00_1000_010, // Go to RESET

  // ==========================================
  // 01: TRAIN PHASE
  // ==========================================
  
  // 1. MBTRAIN VALVREF
  MBTRAIN_VALVREF_RX_Start_Handshake            = 9'b01_0000_000, // Send Start RESP
  MBTRAIN_VALVREF_RX_Data_to_Clock_Test         = 9'b01_0000_001, // Eye Width Sweep
  MBTRAIN_VALVREF_RX_End_Handshake              = 9'b01_0000_010, // Send End RESP
  
  // 2. MBTRAIN DATAVREF
  MBTRAIN_DATAVREF_RX_Start_Handshake           = 9'b01_0001_000, // Send Start RESP
  MBTRAIN_DATAVREF_RX_Data_to_Clock_Test        = 9'b01_0001_001, // Eye Width Sweep
  MBTRAIN_DATAVREF_RX_End_Handshake             = 9'b01_0001_010, // Send End RESP
  
  // 3. MBTRAIN DATATRAINCENTER1
  MBTRAIN_DTC1_RX_Start_Handshake               = 9'b01_0010_000, // Send Start RESP
  MBTRAIN_DTC1_RX_Pattern_Detection             = 9'b01_0010_001, // Check 4K UI Pattern
  MBTRAIN_DTC1_RX_End_Handshake                 = 9'b01_0010_010, // Send End RESP
  
  // 4. MBTRAIN RXCLKCAL
  MBTRAIN_RXCLKCAL_RX_Start_Handshake           = 9'b01_0011_000, // Send Start RESP
  MBTRAIN_RXCLKCAL_RX_Adjust_TX_Clock           = 9'b01_0011_001, // Shift Clock Phase
  MBTRAIN_RXCLKCAL_RX_End_Handshake             = 9'b01_0011_010, // Send End RESP
  
  // 5. MBTRAIN VALTRAINCENTER
  MBTRAIN_VALTRAINCENTER_RX_Start_Handshake     = 9'b01_0100_000, // Send Start RESP
  MBTRAIN_VALTRAINCENTER_RX_Pattern_Detection   = 9'b01_0100_001, // Check Pattern
  MBTRAIN_VALTRAINCENTER_RX_End_Handshake       = 9'b01_0100_010, // Send End RESP
  
  // 6. MBTRAIN RXDESKEW
  MBTRAIN_RXDESKEW_RX_Start_Handshake           = 9'b01_0101_000, // Send Start RESP
  MBTRAIN_RXDESKEW_RX_TX_EQ_Preset_Handshake    = 9'b01_0101_001, // Set Equalization
  MBTRAIN_RXDESKEW_RX_Deskew_Operation          = 9'b01_0101_010, // Align Lanes
  MBTRAIN_RXDESKEW_RX_Datacenter_Handshake      = 9'b01_0101_011, // Exit to DTC2
  MBTRAIN_RXDESKEW_RX_Train_Error_Handshake     = 9'b01_0101_100, // Exit to Error
  MBTRAIN_RXDESKEW_RX_End_Handshake             = 9'b01_0101_101, // Exit to LinkSpeed
  
  // 7. MBTRAIN DATATRAINCENTER2
  MBTRAIN_DTC2_RX_Start_Handshake               = 9'b01_0110_000, // Send Start RESP
  MBTRAIN_DTC2_RX_Pattern_Detection             = 9'b01_0110_001, // Check 4K UI Pattern
  MBTRAIN_DTC2_RX_End_Handshake                 = 9'b01_0110_010, // Send End RESP
  
  // 8. MBTRAIN LINKSPEED
  MBTRAIN_LINKSPEED_RX_Start_Handshake          = 9'b01_0111_000, // Send Start RESP
  MBTRAIN_LINKSPEED_RX_Data_Clock_Test_Det      = 9'b01_0111_001, // Check LFSR
  MBTRAIN_LINKSPEED_RX_Wait_REQ                 = 9'b01_0111_010, // Wait for Decision
  MBTRAIN_LINKSPEED_RX_Send_SpeedDegrade_RESP   = 9'b01_0111_011, // Ack Speed Drop
  MBTRAIN_LINKSPEED_RX_Send_PhyRetrain_RESP     = 9'b01_0111_100, // Ack Retrain
  MBTRAIN_LINKSPEED_RX_Send_Repair_RESP         = 9'b01_0111_101, // Ack Repair
  MBTRAIN_LINKSPEED_RX_Send_Done_RESP           = 9'b01_0111_110, // Ack Success
  MBTRAIN_LINKSPEED_RX_Send_Error_RESP          = 9'b01_0111_111, // Send Error resp
  
  // 9. MBTRAIN REPAIR
  MBTRAIN_REPAIR_RX_Start_Handshake             = 9'b01_1000_000, // Send Init RESP
  MBTRAIN_REPAIR_RX_Wait_Apply_Degrade_REQ      = 9'b01_1000_001, // Receive Map
  MBTRAIN_REPAIR_RX_Apply_Degrade               = 9'b01_1000_010, // Update Hardware
  MBTRAIN_REPAIR_RX_Send_Apply_Degrade_RESP     = 9'b01_1000_011, // Confirm Degrade
  MBTRAIN_REPAIR_RX_End_Handshake               = 9'b01_1000_100, // Send End RESP
  
  // 10. MBTRAIN SPEEDIDLE
  MBTRAIN_SPEEDIDLE_RX_Speed_Transition         = 9'b01_1001_000, // Change Clock Div
  MBTRAIN_SPEEDIDLE_RX_TrainError_Handshake     = 9'b01_1001_001, // Fail -> Error
  MBTRAIN_SPEEDIDLE_RX_End_Handshake            = 9'b01_1001_010, // Success -> Retrain
  
  // 11. MBTRAIN TXSELFCAL
  MBTRAIN_TXSELFCAL_RX_End_Handshake            = 9'b01_1010_000, // Wait for TX done
  
  // 12. PHYRETRAIN
  PHYRETRAIN_RX_Retrain_Handshake               = 9'b01_1011_000, // Sync with Partner
  PHYRETRAIN_RX_PL_StallReq_Handshake           = 9'b01_1011_001, // Ask Adapter to Stall
  PHYRETRAIN_RX_Start_RSP_Handshake             = 9'b01_1011_010, // Ack Start
  
  // 14. VALTRAINVREF
  MBTRAIN_VALTRAINVREF_RX_Start_Handshake       = 9'b01_1101_000, // Send Start RESP
  MBTRAIN_VALTRAINVREF_RX_Data_to_Clock_Test    = 9'b01_1101_001, // Eye Width Sweep
  MBTRAIN_VALTRAINVREF_RX_End_Handshake         = 9'b01_1101_010, // Send End RESP
  
  // 15. DATATRAINVREF
  MBTRAIN_DATATRAINVREF_RX_Start_Handshake      = 9'b01_1110_000, // Send Start RESP
  MBTRAIN_DATATRAINVREF_RX_Data_to_Clock_Test   = 9'b01_1110_001, // Eye Width Sweep
  MBTRAIN_DATATRAINVREF_RX_End_Handshake        = 9'b01_1110_010, // Send End RESP

  // ==========================================
  // 10: ACTIVE PHASE
  // ==========================================
  
  // 1. LINKINIT
  LINKINIT_RX_PL_Clk_Req_Handshake              = 9'b10_0000_000, // Req Adapter Clock
  LINKINIT_RX_LP_Wake_Req_Handshake             = 9'b10_0000_001, // Wake Adapter
  LINKINIT_RX_State_Rsp_Handshake               = 9'b10_0000_010, // Ack State Exch
  
  // 2. ACTIVE
  ACTIVE_RX_Active                              = 9'b10_0001_000, // Data Flowing
  
  // 3. L1 / Exit HS
  L1_RX_Start_HS                                = 9'b10_0010_000, // Entering Sleep
  L1_RX_L1_State                                = 9'b10_0010_001, // Low Power State
  L1_RX_Wait1us                                 = 9'b10_0011_010, // Wait for RDI
  L1_RX_Refuse                                  = 9'b10_0011_011, // Refuse L1
  EXIT_HS_RX_Exit_Handshake                     = 9'b10_0011_100, // Wakeup from L1

  Send_Start_Rx_Init_D_to_C_eye_sweep_req       = 9'b11_0000_000,

  NOP_RX                                        = 9'b11_1111_111   // No Operation

} rx_encoding_t;

typedef enum logic [15:0] {
    // ==========================================
    // Messages Without Data
    // ==========================================
    
    // --- Sheet 1 ---
    Start_Tx_Init_D_to_C_point_test_resp               = 16'h8A01,
    LFSR_clear_error_req                               = 16'h8502,
    LFSR_clear_error_resp                              = 16'h8A02,
    Tx_Init_D_to_C_results_req                         = 16'h8503,
    End_Tx_Init_D_to_C_point_test_req                  = 16'h8504,
    End_Tx_Init_D_to_C_point_test_resp                 = 16'h8A04,
    Start_Tx_Init_D_to_C_eye_sweep_resp                = 16'h8A05,
    End_Tx_Init_D_to_C_eye_sweep_req                   = 16'h8506,
    End_Tx_Init_D_to_C_eye_sweep_resp                  = 16'h8A06,
    Start_Rx_Init_D_to_C_point_test_resp               = 16'h8A07,
    Rx_Init_D_to_C_Tx_Count_Done_req                   = 16'h8508,
    Rx_Init_D_to_C_Tx_Count_Done_resp                  = 16'h8A08,
    End_Rx_Init_D_to_C_point_test_req                  = 16'h8509,
    End_Rx_Init_D_to_C_point_test_resp                 = 16'h8A09,
    Start_Rx_Init_D_to_C_eye_sweep_resp                = 16'h8A0A,
    Rx_Init_D_to_C_results_req                         = 16'h850B,
    End_Rx_Init_D_to_C_eye_sweep_req                   = 16'h850D,
    End_Rx_Init_D_to_C_eye_sweep_resp                  = 16'h8A0D,
    SBINIT_out_of_Reset                                = 16'h9100,
    SBINIT_done_req                                    = 16'h9501,
    SBINIT_done_resp                                   = 16'h9A01,
    MBINIT_CAL_Done_req                                = 16'hA502,
    MBINIT_CAL_Done_resp                               = 16'hAA02,
    MBINIT_REPAIRCLK_init_req                          = 16'hA503,
    MBINIT_REPAIRCLK_init_resp                         = 16'hAA03,
    MBINIT_REPAIRCLK_result_req                        = 16'hA504,
    MBINIT_REPAIRCLK_result_resp                       = 16'hAA04,
    MBINIT_REPAIRCLK_apply_repair_req                  = 16'hA505,
    MBINIT_REPAIRCLK_apply_repair_resp                 = 16'hAA05,

    // --- Sheet 2 ---
    MBINIT_REPAIRCLK_check_repair_init_req             = 16'hA506,
    MBINIT_REPAIRCLK_check_repair_init_resp            = 16'hAA06,
    MBINIT_REPAIRCLK_check_results_req                 = 16'hA507,
    MBINIT_REPAIRCLK_check_results_resp                = 16'hAA07,
    MBINIT_REPAIRCLK_done_req                          = 16'hA508,
    MBINIT_REPAIRCLK_done_resp                         = 16'hAA08,
    MBINIT_REPAIRVAL_init_req                          = 16'hA509,
    MBINIT_REPAIRVAL_init_resp                         = 16'hAA09,
    MBINIT_REPAIRVAL_result_req                        = 16'hA50A,
    MBINIT_REPAIRVAL_result_resp                       = 16'hAA0A,
    MBINIT_REPAIRVAL_apply_repair_req                  = 16'hA50B,
    MBINIT_REPAIRVAL_apply_repair_resp                 = 16'hAA0B,
    MBINIT_REPAIRVAL_done_req                          = 16'hA50C,
    MBINIT_REPAIRVAL_done_resp                         = 16'hAA0C,
    MBINIT_REVERSALMB_init_req                         = 16'hA50D,
    MBINIT_REVERSALMB_init_resp                        = 16'hAA0D,
    MBINIT_REVERSALMB_clear_error_req                  = 16'hA50E,
    MBINIT_REVERSALMB_clear_error_resp                 = 16'hAA0E,
    MBINIT_REVERSALMB_result_req                       = 16'hA50F,
    MBINIT_REVERSALMB_done_req                         = 16'hA510,
    MBINIT_REVERSALMB_done_resp                        = 16'hAA10,
    MBINIT_REPAIRMB_start_req                          = 16'hA511,
    MBINIT_REPAIRMB_start_resp                         = 16'hAA11,
    MBINIT_REPAIRMB_Apply_repair_resp                  = 16'hAA12,
    MBINIT_REPAIRMB_end_req                            = 16'hA513,
    MBINIT_REPAIRMB_end_resp                           = 16'hAA13,
    MBINIT_REPAIRMB_apply_degrade_req                  = 16'hA514,
    MBINIT_REPAIRMB_apply_degrade_resp                 = 16'hAA14,

    // --- Sheet 3 ---
    MBTRAIN_VALVREF_start_req                          = 16'hB500,
    MBTRAIN_VALVREF_start_resp                         = 16'hBA00,
    MBTRAIN_VALVREF_end_req                            = 16'hB501,
    MBTRAIN_VALVREF_end_resp                           = 16'hBA01,
    MBTRAIN_DATAVREF_start_req                         = 16'hB502,
    MBTRAIN_DATAVREF_start_resp                        = 16'hBA02,
    MBTRAIN_DATAVREF_end_req                           = 16'hB503,
    MBTRAIN_DATAVREF_end_resp                          = 16'hBA03,
    MBTRAIN_SPEEDIDLE_done_req                         = 16'hB504,
    MBTRAIN_SPEEDIDLE_done_resp                        = 16'hBA04,
    MBTRAIN_TXSELFCAL_Done_req                         = 16'hB505,
    MBTRAIN_TXSELFCAL_Done_resp                        = 16'hBA05,
    MBTRAIN_RXCLKCAL_start_req                         = 16'hB506,
    MBTRAIN_RXCLKCAL_start_resp                        = 16'hBA06,
    MBTRAIN_RXCLKCAL_done_req                          = 16'hB507,
    MBTRAIN_RXCLKCAL_done_resp                         = 16'hBA07,
    MBTRAIN_VALTRAINCENTER_start_req                   = 16'hB508,
    MBTRAIN_VALTRAINCENTER_start_resp                  = 16'hBA08,
    MBTRAIN_VALTRAINCENTER_done_req                    = 16'hB509,
    MBTRAIN_VALTRAINCENTER_done_resp                   = 16'hBA09,
    MBTRAIN_VALTRAINVREF_start_req                     = 16'hB50A,
    MBTRAIN_VALTRAINVREF_start_resp                    = 16'hBA0A,
    MBTRAIN_VALTRAINVREF_done_req                      = 16'hB50B,
    MBTRAIN_VALTRAINVREF_done_resp                     = 16'hBA0B,
    MBTRAIN_DATATRAINCENTER1_start_req                 = 16'hB50C,
    MBTRAIN_DATATRAINCENTER1_start_resp                = 16'hBA0C,
    MBTRAIN_DATATRAINCENTER1_end_req                   = 16'hB50D,
    MBTRAIN_DATATRAINCENTER1_end_resp                  = 16'hBA0D,
    MBTRAIN_DATATRAINVREF_start_req                    = 16'hB50E,
    MBTRAIN_DATATRAINVREF_start_resp                   = 16'hBA0E,
    MBTRAIN_DATATRAINVREF_end_req                      = 16'hB510,
    MBTRAIN_DATATRAINVREF_end_resp                     = 16'hBA10,
    MBTRAIN_RXDESKEW_start_req                         = 16'hB511,
    MBTRAIN_RXDESKEW_start_resp                        = 16'hBA11,
    MBTRAIN_RXDESKEW_end_req                           = 16'hB512,
    MBTRAIN_RXDESKEW_end_resp                          = 16'hBA12,
    MBTRAIN_DATATRAINCENTER2_start_req                 = 16'hB513,
    MBTRAIN_DATATRAINCENTER2_start_resp                = 16'hBA13,
    MBTRAIN_DATATRAINCENTER2_end_req                   = 16'hB514,
    MBTRAIN_DATATRAINCENTER2_end_resp                  = 16'hBA14,

    // --- Sheet 4 ---
    MBTRAIN_LINKSPEED_start_req                        = 16'hB515,
    MBTRAIN_LINKSPEED_start_resp                       = 16'hBA15,
    MBTRAIN_LINKSPEED_error_req                        = 16'hB516,
    MBTRAIN_LINKSPEED_error_resp                       = 16'hBA16,
    MBTRAIN_LINKSPEED_exit_to_repair_req               = 16'hB517,
    MBTRAIN_LINKSPEED_exit_to_repair_resp              = 16'hBA17,
    MBTRAIN_LINKSPEED_exit_to_speed_degrade_req        = 16'hB518,
    MBTRAIN_LINKSPEED_exit_to_speed_degrade_resp       = 16'hBA18,
    MBTRAIN_LINKSPEED_done_req                         = 16'hB519,
    MBTRAIN_LINKSPEED_done_resp                        = 16'hBA19,
    MBTRAIN_LINKSPEED_multi_module_disable_module_resp = 16'hBA1A,
    MBTRAIN_LINKSPEED_exit_to_phy_retrain_req          = 16'hB51F, // Note: Collides with EQ_Preset_req value in spec
    MBTRAIN_LINKSPEED_exit_to_phy_retrain_resp         = 16'hBA1F, // Note: Collides with EQ_Preset_resp value in spec
    MBTRAIN_REPAIR_init_req                            = 16'hB51B,
    MBTRAIN_REPAIR_init_resp                           = 16'hBA1B,
    MBTRAIN_REPAIR_Apply_repair_resp                   = 16'hBA1C,
    MBTRAIN_REPAIR_end_req                             = 16'hB51D,
    MBTRAIN_REPAIR_end_resp                            = 16'hBA1D,
    MBTRAIN_REPAIR_Apply_degrade_req                   = 16'hB51E,
    MBTRAIN_REPAIR_Apply_degrade_resp                  = 16'hBA1E,
    MBTRAIN_RXDESKEW_exit_to_DATATRAINCENTER1_req      = 16'hB520,
    MBTRAIN_RXDESKEW_exit_to_DATATRAINCENTER1_resp     = 16'hBA20,

    // --- Sheet 5 ---
    MBTRAIN_RXCLKCAL_TCKN_L_shift_req                  = 16'hB521,
    MBTRAIN_RXCLKCAL_TCKN_L_shift_resp                 = 16'hBA21,
    PHYRETRAIN_retrain_start_req                       = 16'hC501,
    PHYRETRAIN_retrain_start_resp                      = 16'hCA01,
    TRAINERROR_Entry_req                               = 16'hE500,
    TRAINERROR_Entry_resp                              = 16'hEA00,
    RECAL_track_pattern_init_req                       = 16'hD500,
    RECAL_track_pattern_init_resp                      = 16'hDA00,
    RECAL_track_pattern_done_req                       = 16'hD501,
    RECAL_track_pattern_done_resp                      = 16'hDA01,
    RECAL_track_tx_adjust_req                          = 16'hB522,
    RECAL_track_tx_adjust_resp                         = 16'hBA22,

    // ==========================================
    // Messages With Data Payloads
    // ==========================================
    Start_Tx_Init_D_to_C_point_test_req        = 16'h8501,
    Tx_Init_D_to_C_results_resp                = 16'h8A03,
    Start_Tx_Init_D_to_C_eye_sweep_req         = 16'h8505,
    Start_Rx_Init_D_to_C_point_test_req        = 16'h8507,
    Start_Rx_Init_D_to_C_eye_sweep_req         = 16'h850A,
    Rx_Init_D_to_C_results_resp                = 16'h8A0B,
    Rx_Init_D_to_C_sweep_done_with_results     = 16'h810C,
    MBINIT_PARAM_configuration_req             = 16'hA500,
    MBINIT_PARAM_configuration_resp            = 16'hAA00,
    MBINIT_PARAM_SBFE_req                      = 16'hA501,
    MBINIT_PARAM_SBFE_resp                     = 16'hAA01,
    MBINIT_REVERSAL_MB_result_resp             = 16'hAA0F,
    MBINIT_REPAIRMB_Apply_repair_req           = 16'hA512,
    MBTRAIN_REPAIR_Apply_repair_req            = 16'hB51C
} fullcode_t;

typedef enum logic [4:0] {
  // 32-bit Operations
  MEM_RD_32B        = 5'b00000, // 32b Memory Read
  MEM_WR_32B        = 5'b00001, // 32b Memory Write
  DMS_REG_RD_32B    = 5'b00010, // 32b DMS Register Read
  DMS_REG_WR_32B    = 5'b00011, // 32b DMS Register Write
  CFG_RD_32B        = 5'b00100, // 32b Configuration Read
  CFG_WR_32B        = 5'b00101, // 32b Configuration Write

  // 64-bit Operations
  MEM_RD_64B        = 5'b01000, // 64b Memory Read
  MEM_WR_64B        = 5'b01001, // 64b Memory Write
  DMS_REG_RD_64B    = 5'b01010, // 64b DMS Register Read
  DMS_REG_WR_64B    = 5'b01011, // 64b DMS Register Write
  CFG_RD_64B        = 5'b01100, // 64b Configuration Read
  CFG_WR_64B        = 5'b01101, // 64b Configuration Write

  // Completions & Messages
  CPL_WO_DATA       = 5'b10000, // Completion without Data
  CPL_W_32B_DATA    = 5'b10001, // Completion with 32b Data
  MSG_WO_DATA       = 5'b10010, // Message without Data

  // Management Port & 64-bit Completions/Messages
  MGT_MSG_WO_DATA   = 5'b10111, // Management Port Messages without Data
  MGT_MSG_W_DATA    = 5'b11000, // Management Port Message with Data
  CPL_W_64B_DATA    = 5'b11001, // Completion with 64b Data
  MSG_W_64B_DATA    = 5'b11011, // Message with 64b Data

  // Priority Packets (Two distinct encodings provided)
  PRIORITY_PKT_0    = 5'b11110, // Priority Packet 
  PRIORITY_PKT_1    = 5'b11111  // Priority Packet 
  
  // Note: Any unlisted value acts as "Reserved" per the specification table
} opcode_t;

typedef enum logic [2:0] {
  SRC_D2D = 3'b001, // D2D Adapter
  SRC_PHY = 3'b010, // Physical Layer
  SRC_MGT = 3'b011  // Management Port Gateway

  // Note: All other encodings (3'b000, 3'b100 - 3'b111) are reserved
} srcid_t;

typedef enum logic [2:0] {
  // Assuming dstid[2] = 1 (Remote die terminated request) 
  // combined with the dstid[1:0] targets.
  
  DST_RSD = 3'b100, // Register Access request / Reserved target
  DST_D2D = 3'b101, // D2D Adapter (Completion / Message)
  DST_PHY = 3'b110, // Physical Layer message
  DST_MGT = 3'b111  // Management Port Gateway message
  
  // 3'b0xx encodings are technically reserved per the "dstid[2]" row
} dstid_t;

typedef struct {
  fullcode_t   fullcode;   // Concatenated {MsgCode, MsgSubcode} for Link Training State Machine commands
  opcode_t     opcode;     // Opcode
  srcid_t      srcid;      // Source ID
  dstid_t      dstid;      // Destination ID
  logic [15:0] info;       // Message Information
  logic [63:0] data;       // Message Data
  logic        cp;         // Control Parity
  logic        dp;         // Data Parity
} message_t;


// Messages transmitted by TX FSM to the partner's RX FSM
message_t tx_messages [tx_encoding_t] = '{
  SBINIT_TX_Out_Of_Reset_MSG: '{
    fullcode: SBINIT_out_of_Reset,
    opcode:   MSG_WO_DATA,
    srcid:    SRC_PHY,
    dstid:    DST_PHY,
    info:     '0,            // Unspecified, defaulting to 0
    data:     '0,            // Unspecified, defaulting to 0
    cp:       '0,            // Control Parity
    dp:       '0             // Data Parity
  },

  SBINIT_TX_Done_Handshake: '{
    fullcode: SBINIT_done_req,
    opcode:   MSG_WO_DATA,
    srcid:    SRC_PHY,
    dstid:    DST_PHY,
    info:     '0,            // Unspecified, defaulting to 0
    data:     '0,            // Unspecified, defaulting to 0
    cp:       '0,            // Control Parity
    dp:       '0             // Data Parity
  },

  MBINIT_PARAM_TX_Config_Handshake: '{
    fullcode: MBINIT_PARAM_configuration_req,
    opcode:   MSG_W_64B_DATA,
    srcid:    SRC_PHY,
    dstid:    DST_PHY,
    info:     '0,            // Unspecified, defaulting to 0
    data:     '0,            // Unspecified, defaulting to 0
    cp:       '0,            // Control Parity
    dp:       '0             // Data Parity
  },

  Send_Start_Rx_Init_D_to_C_eye_sweep_resp: '{
    fullcode: Start_Rx_Init_D_to_C_eye_sweep_resp,
    opcode:   MSG_WO_DATA,
    srcid:    SRC_PHY,
    dstid:    DST_PHY,
    info:     '0,            // Unspecified, defaulting to 0
    data:     '0,            // Unspecified, defaulting to 0
    cp:       '0,            // Control Parity
    dp:       '0             // Data Parity
  },

  Send_Rx_Init_D_to_C_sweep_done_with_results: '{
    fullcode: Rx_Init_D_to_C_sweep_done_with_results,
    opcode:   MSG_W_64B_DATA,
    srcid:    SRC_PHY,
    dstid:    DST_PHY,
    info:     '0,            // Unspecified, defaulting to 0
    data:     '0,            // Unspecified, defaulting to 0
    cp:       '0,            // Control Parity
    dp:       '0             // Data Parity
  }
};

// Messages transmitted by RX FSM to the partner's TX FSM
message_t rx_messages [rx_encoding_t] = '{
  SBINIT_RX_Done_Handshake: '{
    fullcode: SBINIT_done_resp,
    opcode:   MSG_WO_DATA,
    srcid:    SRC_PHY,
    dstid:    DST_PHY,
    info:     '0,            // Unspecified, defaulting to 0
    data:     '0,            // Unspecified, defaulting to 0
    cp:       '0,            // Control Parity
    dp:       '0             // Data Parity
  },

  MBINIT_PARAM_RX_Send_RESP: '{
    fullcode: MBINIT_PARAM_configuration_resp,
    opcode:   MSG_W_64B_DATA,
    srcid:    SRC_PHY,
    dstid:    DST_PHY,
    info:     '0,            // Unspecified, defaulting to 0
    data:     '0,            // Unspecified, defaulting to 0
    cp:       '0,            // Control Parity
    dp:       '0             // Data Parity
  },

  Send_Start_Rx_Init_D_to_C_eye_sweep_req: '{
    fullcode: Start_Rx_Init_D_to_C_eye_sweep_req,
    opcode:   MSG_W_64B_DATA,
    srcid:    SRC_PHY,
    dstid:    DST_PHY,
    info:     '0,            // Unspecified, defaulting to 0
    data:     '0,            // Unspecified, defaulting to 0
    cp:       '0,            // Control Parity
    dp:       '0             // Data Parity
  }
};
endpackage : shared_pkg
