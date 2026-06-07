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
package shared_ltsm_pkg;
  
  parameter logic [63:0] data_DATA_FIELD = {
    4'b0000,       // [63:60] Reserved
    1'b0,          // [59]    Comparison Mode (Per Lane)
    16'd1,         // [58:43] Iteration Count
    16'd0,         // [42:27] Idle Count
    16'd4000,      // [26:11] Burst Count
    1'b0,          // [10]    Pattern Mode (Continuous)
    4'h0,          // [9:6]   Clock Phase (Clock PI Center)
    3'h0,          // [5:3]   Valid Pattern (Functional)
    3'h0           // [2:0]   Data Pattern (LFSR)
};
  parameter logic [63:0] valid_DATA_FIELD = {
    4'b0000,       // [63:60] Reserved
    1'b0,          // [59]    Comparison Mode (Per Lane)
    16'd1,         // [58:43] Iteration Count
    16'd0,         // [42:27] Idle Count
    16'd128,       // [26:11] Burst Count
    1'b0,          // [10]    Pattern Mode (Continuous)
    4'h0,          // [9:6]   Clock Phase (Clock PI Center)
    3'h0,          // [5:3]   Valid Pattern (Functional)
    3'h0           // [2:0]   Data Pattern (LFSR)
};
  parameter timeout = 1000; // number of cycles to wait for a response before declaring a timeout will be provided by design team in the future
  
  `define RESULT_THRESHOLD 16'b0000000111111111
`define LANE_MAP_CODE 3'b011 // all lanes are functional    

typedef enum logic [2:0] {PASS = 3'b111 , FAIL_RTRK_L = 3'b011 , FAIL_RCKN_L = 3'b101,
FAIL_RCKP_L = 3'b110} clk_result_t; 

typedef enum logic  {PASS_VAL = 1'b1, FAIL_VAL = 1'b0} val_result_t;

typedef enum logic[15:0] {
  NO_LANES_FUNCTIONAL    = 16'h0000, // None (Degrade not possible)
  LANES_0_TO_7           = 16'h00FF, // Logical lanes 0 to 7
  LANES_8_TO_15          = 16'hFF00, // Logical lanes 8 to 15
  ALL_LANES_FUNCTIONAL   = 16'hFFFF, // 0 to 15
  LANES_0_TO_3           = 16'h000F, // Logical lanes 0 to 3
  LANES_4_TO_7           = 16'h00F0  // Logical lanes 4 to 7
} lane_results_t;
  bit enter_speeddegrade;
 bit state_done;
typedef enum logic [2:0] { NOT_POSSIBLE = 3'b0 , MATCHED = `LANE_MAP_CODE } degrade_t;
typedef enum logic [8:0] {
 // =========================================================
  // 00: INITIALIZATION PHASE
  // =========================================================

  // 1. RESET
  RX_RESET_Reset                              = 9'b00_0000_000,

  // 2. SBINIT
  RX_SBINIT_Wait_Out_Of_Reset                 = 9'b00_0001_000,
  RX_SBINIT_Done_Handshake                    = 9'b00_0001_001,

  // 3. MBINIT PARAM
  RX_MBINIT_PARAM_Wait_Config_REQ             = 9'b00_0010_000,
  RX_MBINIT_PARAM_Check_Parameters            = 9'b00_0010_001,
  RX_MBINIT_PARAM_Send_RESP                   = 9'b00_0010_010,

  // 4. MBINIT CAL
  RX_MBINIT_CAL_Done_Handshake                = 9'b00_0011_000,

  // 5. MBINIT REPAIRCLK
  RX_MBINIT_REPAIRCLK_Init_Handshake          = 9'b00_0100_000,
  RX_MBINIT_REPAIRCLK_Pattern_Detection       = 9'b00_0100_001,
  RX_MBINIT_REPAIRCLK_Wait_Result_REQ         = 9'b00_0100_010,
  RX_MBINIT_REPAIRCLK_Send_RESP               = 9'b00_0100_011,
  RX_MBINIT_REPAIRCLK_Done_Handshake          = 9'b00_0100_100,

  // 6. MBINIT REPAIRVAL
  RX_MBINIT_REPAIRVAL_Init_Handshake          = 9'b00_0101_000,
  RX_MBINIT_REPAIRVAL_Valid_Pattern_Det       = 9'b00_0101_001,
  RX_MBINIT_REPAIRVAL_Wait_Result_REQ         = 9'b00_0101_010,
  RX_MBINIT_REPAIRVAL_Send_Result_RESP        = 9'b00_0101_011,
  RX_MBINIT_REPAIRVAL_Done_Handshake          = 9'b00_0101_100,

  // 7. MBINIT REVERSAL
  RX_MBINIT_REVERSAL_Init_Handshake           = 9'b00_0110_000,
  RX_MBINIT_REVERSAL_Clear_Log_Hnd            = 9'b00_0110_001,
  RX_MBINIT_REVERSAL_Per_Lane_ID_Det          = 9'b00_0110_010,
  RX_MBINIT_REVERSAL_Result_Handshake         = 9'b00_0110_011,
  RX_MBINIT_REVERSAL_Done_Handshake           = 9'b00_0110_100,

  // 8. MBINIT REPAIRMB
  RX_MBINIT_REPAIRMB_Init_Handshake           = 9'b00_0111_000,
  RX_MBINIT_REPAIRMB_Data_to_Clock            = 9'b00_0111_001,
  RX_MBINIT_REPAIRMB_Wait_Apply_Degrade       = 9'b00_0111_010,
  RX_MBINIT_REPAIRMB_Degrade                  = 9'b00_0111_011,
  RX_MBINIT_REPAIRMB_Send_Degrade_Resp        = 9'b00_0111_100,
  RX_MBINIT_REPAIRMB_Done_Handshake           = 9'b00_0111_101,

  // 9. TRAINERROR
  RX_TRAINERROR_Handshake                     = 9'b00_1000_000,
  RX_TRAINERROR_TrainError                    = 9'b00_1000_001,
  RX_TRAINERROR_Reset                         = 9'b00_1000_010,

  // =========================================================
  // 01: TRAIN PHASE
  // =========================================================

  // 1. MBTRAIN VALVREF
  RX_MBTRAIN_VALVREF_Start_Handshake          = 9'b01_0000_000,
  RX_MBTRAIN_VALVREF_Data_to_Clock_Test       = 9'b01_0000_001,
  RX_MBTRAIN_VALVREF_End_Handshake            = 9'b01_0000_010,

  // 2. MBTRAIN DATAVREF
  RX_MBTRAIN_DATAVREF_Start_Handshake         = 9'b01_0001_000,
  RX_MBTRAIN_DATAVREF_Data_to_Clock_Test      = 9'b01_0001_001,
  RX_MBTRAIN_DATAVREF_End_Handshake           = 9'b01_0001_010,

  // 3. MBTRAIN DATATRAINCENTER1
  RX_MBTRAIN_DTC1_Start_Handshake             = 9'b01_0010_000,
  RX_MBTRAIN_DTC1_Pattern_Detection           = 9'b01_0010_001,
  RX_MBTRAIN_DTC1_End_Handshake               = 9'b01_0010_010,

  // 4. MBTRAIN RXCLKCAL
  RX_MBTRAIN_RXCLKCAL_Start_Handshake         = 9'b01_0011_000,
  RX_MBTRAIN_RXCLKCAL_Adjust_TX_Clock         = 9'b01_0011_001,
  RX_MBTRAIN_RXCLKCAL_End_Handshake           = 9'b01_0011_010,

  // 5. MBTRAIN VALTRAINCENTER
  RX_MBTRAIN_VALTRAINCENTER_Start_Handshake   = 9'b01_0100_000,
  RX_MBTRAIN_VALTRAINCENTER_Pattern_Detection = 9'b01_0100_001,
  RX_MBTRAIN_VALTRAINCENTER_End_Handshake     = 9'b01_0100_010,

  // 6. MBTRAIN RXDESKEW
  RX_MBTRAIN_RXDESKEW_Start_Handshake         = 9'b01_0101_000,
  RX_MBTRAIN_RXDESKEW_TX_EQ_Preset_Handshake  = 9'b01_0101_001,
  RX_MBTRAIN_RXDESKEW_Deskew_Operation        = 9'b01_0101_010,
  RX_MBTRAIN_RXDESKEW_Datacenter_Handshake    = 9'b01_0101_011,
  RX_MBTRAIN_RXDESKEW_Train_Error_Handshake   = 9'b01_0101_101,
  RX_MBTRAIN_RXDESKEW_End_Handshake           = 9'b01_0101_100,

  // 7. MBTRAIN DATATRAINCENTER2
  RX_MBTRAIN_DTC2_Start_Handshake             = 9'b01_0110_000,
  RX_MBTRAIN_DTC2_Pattern_Detection           = 9'b01_0110_001,
  RX_MBTRAIN_DTC2_End_Handshake               = 9'b01_0110_010,

  // 8. MBTRAIN LINKSPEED
  RX_MBTRAIN_LINKSPEED_Start_Handshake        = 9'b01_0111_000,
  RX_MBTRAIN_LINKSPEED_Data_Clock_Test_Det    = 9'b01_0111_001,
  RX_MBTRAIN_LINKSPEED_Send_SpeedDegrade_RESP = 9'b01_0111_110,
  RX_MBTRAIN_LINKSPEED_Send_PhyRetrain_RESP   = 9'b01_0111_100,
  RX_MBTRAIN_LINKSPEED_Send_Repair_RESP       = 9'b01_0111_101,
  RX_MBTRAIN_LINKSPEED_Send_Done_RESP         = 9'b01_0111_010,
  RX_MBTRAIN_LINKSPEED_Send_Error_RESP        = 9'b01_0111_111,

  // 9. MBTRAIN REPAIR
  RX_MBTRAIN_REPAIR_Start_Handshake           = 9'b01_1000_000,
  RX_MBTRAIN_REPAIR_Send_Apply_Degrade_RESP    = 9'b01_1000_001,
  RX_MBTRAIN_REPAIR_Wait_Trainerror_REQ   = 9'b01_1000_011,
  RX_MBTRAIN_REPAIR_End_Handshake             = 9'b01_1000_010,

  // 10. MBTRAIN SPEEDIDLE
  RX_MBTRAIN_SPEEDIDLE_Speed_Transition       = 9'b01_1001_000,
  RX_MBTRAIN_SPEEDIDLE_TrainError_Handshake   = 9'b01_1001_001,
  RX_MBTRAIN_SPEEDIDLE_End_Handshake          = 9'b01_1001_010,

  // 11. MBTRAIN TXSELFCAL
  RX_MBTRAIN_TXSELFCAL_End_Handshake           = 9'b01_1010_001,

  // 12. PHYRETRAIN
  RX_PHYRETRAIN_Retrain_Handshake             = 9'b01_1011_000,
  RX_PHYRETRAIN_PL_StallReq_Handshake         = 9'b01_1011_001,
  RX_PHYRETRAIN_Start_RSP_Handshake           = 9'b01_1011_010,

  // 14. VALTRAINVREF
  RX_MBTRAIN_VALTRAINVREF_Start_Handshake     = 9'b01_1101_000,
  RX_MBTRAIN_VALTRAINVREF_Data_to_Clock_Test  = 9'b01_1101_001,
  RX_MBTRAIN_VALTRAINVREF_End_Handshake       = 9'b01_1101_010,

  // 15. DATATRAINVREF
  RX_MBTRAIN_DATATRAINVREF_Start_Handshake    = 9'b01_1110_000,
  RX_MBTRAIN_DATATRAINVREF_Data_to_Clock_Test = 9'b01_1110_001,
  RX_MBTRAIN_DATATRAINVREF_End_Handshake      = 9'b01_1110_010,

  // =========================================================
  // 10: ACTIVE PHASE
  // =========================================================

  // 1. LINKINIT
  RX_ACTIVE_LINKINIT_PL_Clk_Req_Handshake    = 9'b10_0000_000,
  RX_ACTIVE_LINKINIT_LP_Wake_Req_Handshake    = 9'b10_0000_001,
  RX_ACTIVE_LINKINIT_State_Rsp_Handshake      = 9'b10_0000_010,

  // 2. ACTIVE
  RX_ACTIVE_Active                            = 9'b10_0001_000,

  // 3. L1 / Exit HS
  RX_ACTIVE_L1_Start_HS                       = 9'b10_0010_000,
  RX_ACTIVE_L1_L1_State                       = 9'b10_0010_001,
  RX_ACTIVE_L1_Wait1us                        = 9'b10_0010_010,
  RX_ACTIVE_L1_Refuse                         = 9'b10_0010_011,
  RX_ACTIVE_EXIT_HS_Exit_Handshake            = 9'b10_0011_100,
  // =========================================================
  // 11: DATA_SWEEP PHASE
  // =========================================================	
  DATA_TO_CLOCK_TX_RX_INIT_HANDSHAKE         = 9'b110000000,  // 11 0000 000
  DATA_TO_CLOCK_TX_RX_LFSR_CLEAR_HANDSHAKE   = 9'b110000001,  // 11 0000 001
  DATA_TO_CLOCK_TX_RX_PATTERN_GENERATION     = 9'b110000010,  // 11 0000 010
  DATA_TO_CLOCK_TX_RX_RESULT_HANDSHAKE       = 9'b110000011,  // 11 0000 011
  DATA_TO_CLOCK_TX_RX_END_INIT_HANDSHAKE     = 9'b110000100,  // 11 0000 100

    // RX Initiated
  DATA_TO_CLOCK_RX_RX_INIT_HANDSHAKE         = 9'b110001000,  // 11 0001 000
  DATA_TO_CLOCK_RX_RX_LFSR_CLEAR_HANDSHAKE   = 9'b110001001,  // 11 0001 001
  DATA_TO_CLOCK_RX_RX_PATTERN_GENERATION     = 9'b110001010,  // 11 0001 010
  DATA_TO_CLOCK_RX_RX_RESULT_HANDSHAKE       = 9'b110001011,  // 11 0001 011
  DATA_TO_CLOCK_RX_RX_SWEEP_RESULT_HANDSHAKE = 9'b110001100,  // 11 0001 100
  DATA_TO_CLOCK_RX_RX_END_INIT_HANDSHAKE     = 9'b110001101
    } encoding_rx_t;

    typedef enum logic [8:0] {

  // =========================================================
  // 00: INITIALIZATION PHASE
  // =========================================================

  // 1. RESET
  RESET                                    = 9'b00_0000_000,

  // 2. SBINIT
  SBINIT_TX_Pattern_Generation             = 9'b00_0001_000,
  SBINIT_TX_Out_Of_Reset_MSG               = 9'b00_0001_001,
  SBINIT_TX_Done_Handshake                 = 9'b00_0001_010,

  // 3. MBINIT PARAM
  MBINIT_PARAM_TX_Config_Handshake         = 9'b00_0010_000,

  // 4. MBINIT CAL
  MBINIT_CAL_TX_Done_Handshake             = 9'b00_0011_000,

  // 5. MBINIT REPAIRCLK
  MBINIT_REPAIRCLK_TX_Init_Handshake       = 9'b00_0100_000,
  MBINIT_REPAIRCLK_TX_Clk_Pattern_Gen      = 9'b00_0100_001,
  MBINIT_REPAIRCLK_TX_Result_Handshake     = 9'b00_0100_010,
  MBINIT_REPAIRCLK_TX_Done_Handshake       = 9'b00_0100_011,

  // 6. MBINIT REPAIRVAL
  MBINIT_REPAIRVAL_TX_Init_Handshake       = 9'b00_0101_000,
  MBINIT_REPAIRVAL_TX_Valid_Pattern_Gen    = 9'b00_0101_001,
  MBINIT_REPAIRVAL_TX_Result_Handshake     = 9'b00_0101_010,
  MBINIT_REPAIRVAL_TX_Done_Handshake       = 9'b00_0101_011,

  // 7. MBINIT REVERSAL
  MBINIT_REVERSAL_TX_Init_Handshake        = 9'b00_0110_000,
  MBINIT_REVERSAL_TX_Clear_Log_Handshake   = 9'b00_0110_001,
  MBINIT_REVERSAL_TX_Per_Lane_ID_Gen       = 9'b00_0110_010,
  MBINIT_REVERSAL_TX_Result_Handshake      = 9'b00_0110_011,
  MBINIT_REVERSAL_TX_Apply_Reversal        = 9'b00_0110_100,
  MBINIT_REVERSAL_TX_Done_Handshake        = 9'b00_0110_101,

  // 8. MBINIT REPAIRMB
  MBINIT_REPAIRMB_TX_Init_Handshake        = 9'b00_0111_000,
  MBINIT_REPAIRMB_TX_Data_to_Clock_Point   = 9'b00_0111_001,
  MBINIT_REPAIRMB_TX_Apply_Degrade_Hnd    = 9'b00_0111_010,
  MBINIT_REPAIRMB_TX_Done_Handshake        = 9'b00_0111_011,

  // =========================================================
  // 01: TRAIN PHASE
  // =========================================================

  // TRAINERROR
  TRAINERROR_TX_Handshake                  = 9'b00_1000_000,
  TRAINERROR_TX_TrainError                 = 9'b00_1000_001,
  TRAINERROR_TX_Reset                      = 9'b00_1000_010,

  // 1. MBTRAIN VALVREF
  MBTRAIN_VALVREF_TX_Start_Handshake       = 9'b01_0000_000,
  MBTRAIN_VALVREF_TX_Pattern_Generation    = 9'b01_0000_001,
  MBTRAIN_VALVREF_TX_End_Handshake         = 9'b01_0000_010,

  // 2. MBTRAIN DATAVREF
  MBTRAIN_DATAVREF_TX_Start_Handshake      = 9'b01_0001_000,
  MBTRAIN_DATAVREF_TX_Pattern_Generation   = 9'b01_0001_001,
  MBTRAIN_DATAVREF_TX_End_Handshake        = 9'b01_0001_010,

  // 3. MBTRAIN DATATRAINCENTER1
  MBTRAIN_DTC1_TX_Start_Handshake          = 9'b01_0010_000,
  MBTRAIN_DTC1_TX_Pattern_Generation       = 9'b01_0010_001,
  MBTRAIN_DTC1_TX_End_Handshake            = 9'b01_0010_010,

  // 4. MBTRAIN RXCLKCAL
  MBTRAIN_RXCLKCAL_TX_Start_Handshake      = 9'b01_0011_000,
  MBTRAIN_RXCLKCAL_TX_Clock_Shifting_Op    = 9'b01_0011_001,
  MBTRAIN_RXCLKCAL_TX_End_Handshake        = 9'b01_0011_010,

  // 5. MBTRAIN VALTRAINVREF
  MBTRAIN_VALTRAINCENTER_TX_Start_Handshake  = 9'b01_0100_000,
  MBTRAIN_VALTRAINCENTER_TX_Pattern_Generation = 9'b01_0100_001,
  MBTRAIN_VALTRAINCENTER_TX_End_Handshake    = 9'b01_0100_010,

  // 6. MBTRAIN RXDESKEW
  MBTRAIN_RXDESKEW_TX_Start_Handshake      = 9'b01_0101_000,
  MBTRAIN_RXDESKEW_TX_EQ_Preset_Handshake  = 9'b01_0101_001,
  MBTRAIN_RXDESKEW_TX_Deskew_Operation     = 9'b01_0101_010,
  MBTRAIN_RXDESKEW_TX_Datacenter_Handshake = 9'b01_0101_011,
  MBTRAIN_RXDESKEW_TX_End_Handshake        = 9'b01_0101_100,
  MBTRAIN_RXDESKEW_TX_Train_Error_Handshake = 9'b01_0101_101,

  // 7. MBTRAIN DATATRAINCENTER2
  MBTRAIN_DTC2_TX_Start_Handshake          = 9'b01_0110_000,
  MBTRAIN_DTC2_TX_Pattern_Generation       = 9'b01_0110_001,
  MBTRAIN_DTC2_TX_End_Handshake            = 9'b01_0110_010,

  // 8. MBTRAIN LINKSPEED
  MBTRAIN_LINKSPEED_TX_Start_Handshake     = 9'b01_0111_000,
  MBTRAIN_LINKSPEED_TX_Data_Clock_Test     = 9'b01_0111_001,
  MBTRAIN_LINKSPEED_TX_LinkSpeed_Done_Hnd  = 9'b01_0111_010,
  MBTRAIN_LINKSPEED_TX_Error_Hnd           = 9'b01_0111_011,
  MBTRAIN_LINKSPEED_TX_Phy_Retrain_Hnd     = 9'b01_0111_100,
  MBTRAIN_LINKSPEED_TX_Repair_Hnd          = 9'b01_0111_101,
  MBTRAIN_LINKSPEED_TX_Exit_SpeedDegrade_Hnd = 9'b01_0111_110,

  // 9. MBTRAIN REPAIR
  MBTRAIN_REPAIR_TX_Start_Handshake        = 9'b01_1000_000,
  MBTRAIN_REPAIR_TX_Apply_Degrade_Handshake = 9'b01_1000_001,
  MBTRAIN_REPAIR_TX_End_Handshake          = 9'b01_1000_010,

  // 10. MBTRAIN SPEEDIDLE
  MBTRAIN_SPEEDIDLE_TX_Speed_Transition    = 9'b01_1001_000,
  MBTRAIN_SPEEDIDLE_TX_End_Handshake       = 9'b01_1001_010,
  MBTRAIN_SPEEDIDLE_TX_TrainError_Handshake = 9'b01_1001_001,

  // 11. MBTRAIN TXSELFCAL
  MBTRAIN_TXSELFCAL_TX_Calibration         = 9'b01_1010_000,
  MBTRAIN_TXSELFCAL_TX_End_Handshake       = 9'b01_1010_001,

  // 12. PHYRETRAIN
  PHYRETRAIN_TX_PL_StallReq_Handshake      = 9'b01_1011_000,
  PHYRETRAIN_TX_Retrain_Handshake          = 9'b01_1011_001,
  PHYRETRAIN_TX_Start_Req_Handshake        = 9'b01_1011_010,

  // 14. VALTRAINCENTER
  MBTRAIN_VALTRAINVREF_TX_Start_Handshake     = 9'b01_1101_000,
  MBTRAIN_VALTRAINVREF_TX_Pattern_Generation  = 9'b01_1101_001,
  MBTRAIN_VALTRAINVREF_TX_End_Handshake       = 9'b01_1101_010,

  // 15. DATATRAINVREF
  MBTRAIN_DATATRAINVREF_TX_Start_Handshake      = 9'b01_1110_000,
  MBTRAIN_DATATRAINVREF_TX_Pattern_Generation   = 9'b01_1110_001,
  MBTRAIN_DATATRAINVREF_TX_End_Handshake        = 9'b01_1110_010,

  // =========================================================
  // 10: ACTIVE PHASE
  // =========================================================

  // 1. LINKINIT
  ACTIVE_LINKINIT_TX_PL_Clk_Req_Handshake  = 9'b10_0000_000,
  ACTIVE_LINKINIT_TX_LP_Wake_Req_Handshake  = 9'b10_0000_001,
  ACTIVE_LINKINIT_TX_State_Req_Handshake    = 9'b10_0000_010,

  // 2. ACTIVE
  ACTIVE_TX_Active                          = 9'b10_0001_000,

  // 3. L1 / Exit HS
  ACTIVE_L1_TX_handshake                    = 9'b10_0010_000,
  ACTIVE_L1_TX_L1_State                     = 9'b10_0010_001,
  ACTIVE_EXIT_HS_TX_Exit_Handshake          = 9'b10_0011_000
  
} encoding_tx_t;
typedef enum logic [5:0] { 
  fsm_tx_reset,
  fsm_tx_sbinit,
  fsm_mbinit_tx_param,
  fsm_mbinit_tx_cal,
  fsm_mbinit_tx_repairclk,
  fsm_mbinit_tx_repairval,
  fsm_mbinit_tx_reversal,
  fsm_mbinit_tx_repairmb,
  fsm_tx_trainerror,
  fsm_mbtrain_tx_valvref,
  fsm_mbtrain_tx_datavref,
  fsm_mbtrain_tx_dtc1,
  fsm_mbtrain_tx_rxclkcal,
  fsm_mbtrain_tx_valtraincenter,
  fsm_mbtrain_tx_valtrainvref,
  fsm_mbtrain_tx_rxdeskew,
  fsm_mbtrain_tx_dtc2,
  fsm_mbtrain_tx_datatrainvref,
  fsm_mbtrain_tx_linkspeed,
  fsm_mbtrain_tx_repair,
  fsm_mbtrain_tx_speedidle,
  fsm_mbtrain_tx_txselfcal,
  fsm_tx_phyretrain,
  fsm_tx_linkinit,
  fsm_tx_active,
  fsm_tx_l1,
  fsm_rx_reset,
  fsm_rx_sbinit,
  fsm_mbinit_rx_param,
  fsm_mbinit_rx_cal,
  fsm_mbinit_rx_repairclk,
  fsm_mbinit_rx_repairval,
  fsm_mbinit_rx_reversal,
  fsm_mbinit_rx_repairmb,
  fsm_rx_trainerror,
  fsm_mbtrain_rx_valvref,
  fsm_mbtrain_rx_datavref,
  fsm_mbtrain_rx_dtc1,
  fsm_mbtrain_rx_rxclkcal,
  fsm_mbtrain_rx_valtraincenter,
  fsm_mbtrain_rx_valtrainvref,
  fsm_mbtrain_rx_rxdeskew,
  fsm_mbtrain_rx_dtc2,
  fsm_mbtrain_rx_datatrainvref,
  fsm_mbtrain_rx_linkspeed,
  fsm_mbtrain_rx_repair,
  fsm_mbtrain_rx_speedidle,
  fsm_mbtrain_rx_txselfcal,
  fsm_rx_phyretrain,
  fsm_rx_linkinit,
  fsm_rx_active,
  fsm_rx_l1
 } fsm_t;
 typedef enum logic[3:0]{
    state_req_NOP       =     4'b0000  ,
    state_req_active    =     4'b0001  ,
    state_req_l1        =     4'b0100  ,
    state_req_linkReset =     4'b1001  ,
    state_req_retrain   =     4'b1011  ,
    state_req_disabled  =     4'b1100  
  } lp_state_req_t;
endpackage : shared_ltsm_pkg