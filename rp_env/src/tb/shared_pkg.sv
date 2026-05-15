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

  // --- RTL Paramters ---
  parameter pNUM_LANES  = 16;
  parameter pDATA_WIDTH = 64;
  parameter pNBYTES = 256;

  parameter T_CLK = 32ns;
  parameter UI    = 4ns;

  parameter LINK2LTSM_RTL_LATENCY = 11 * T_CLK;
  parameter LTSM2LINK_RTL_LATENCY = (8 * T_CLK) + (0.5 * UI);
  parameter HEADER_SER_LATENCY    = 64 * UI;
  parameter DATA_SER_LATENCY      = 64 * UI;
  parameter IDLE_LATENCY          = 32 * UI;

  parameter DATA_MAX = 64'hFFFF_FFFF_FFFF_FFFF;
  parameter INFO_MAX = 16'hFFFF;

  parameter VALID_CLK_PATTERN_STREAM_LEN = 128;
  parameter CLK_STREAM_LEN_CLK_PAT = 4096;  
  parameter CLK_STREAM_LEN_VALID_PAT = 1024;
  parameter CLK_STROBE_VALID_PAT = 8;
  parameter CLK_STROBE_CLK_PAT = 32;



  // --- Type Definitions ---
  typedef enum bit { 
     QR
    ,HR
  } rate_mode_t;

  typedef enum bit [1:0] { 
     CLK_PATTERN
    ,VAL_PATTERN
    ,DATA_PATTERN
  } pattern_type_t;

  typedef enum bit [2:0] { 
     X8_LOWER_MODE = 3'b001
    ,X8_UPPER_MODE = 3'b010
    ,X16_MODE      = 3'b011
    ,X4_LOWER_MODE = 3'b100
    ,X4_UPPER_MODE = 3'b101
  } lane_map_code_t;
  //-----------------------------------------------------------------------------
  // RX State Encoding Typedef Enum
  // Source: LTSM Specifications Document
  // Encoding [8:0]: [8:7] = Module (2b) | [6:3] = State (4b) | [2:0] = Substate (3b)
  //-----------------------------------------------------------------------------

  typedef enum logic [8:0] {

    // =========================================================================
    // 00: INITIALIZATION PHASE
    // =========================================================================

    // --- 1. RESET ---
    RESET_Reset                                    = 9'b00_0000_000, // Hex: 9'h000 (PLL/Power Stabilization)

    // --- 2. SBINIT ---
    SBINIT_RX_Wait_Out_Of_Reset                    = 9'b00_0001_000, // Hex: 9'h008 (Wait for MSG)
    SBINIT_RX_Done_Handshake                       = 9'b00_0001_001, // Hex: 9'h009 (Send Done REQ/RESP)

    // --- 3. MBINIT PARAM ---
    MBINIT_PARAM_RX_Wait_Config_REQ                = 9'b00_0010_000, // Hex: 9'h010 (Idle)
    MBINIT_PARAM_RX_Check_Parameters               = 9'b00_0010_001, // Hex: 9'h011 (Resolve Capabilities)
    MBINIT_PARAM_RX_Send_RESP                      = 9'b00_0010_010, // Hex: 9'h012 (Send Config RESP)

    // --- 4. MBINIT CAL ---
    MBINIT_CAL_RX_Done_Handshake                   = 9'b00_0011_000, // Hex: 9'h018 (Send Cal Done RESP)

    // --- 5. MBINIT REPAIRCLK ---
    MBINIT_REPAIRCLK_RX_Init_Handshake             = 9'b00_0100_000, // Hex: 9'h020 (Send Init RESP)
    MBINIT_REPAIRCLK_RX_Pattern_Detection          = 9'b00_0100_001, // Hex: 9'h021 (Check Clock/Track)
    MBINIT_REPAIRCLK_RX_Wait_Result_REQ            = 9'b00_0100_010, // Hex: 9'h022 (Wait for Log Request)
    MBINIT_REPAIRCLK_RX_Send_RESP                  = 9'b00_0100_011, // Hex: 9'h023 (Send Result Log)
    MBINIT_REPAIRCLK_RX_Done_Handshake             = 9'b00_0100_100, // Hex: 9'h024 (Send Done RESP)

    // --- 6. MBINIT REPAIRVAL ---
    MBINIT_REPAIRVAL_RX_Init_Handshake             = 9'b00_0101_000, // Hex: 9'h028 (Send Init RESP)
    MBINIT_REPAIRVAL_RX_Valid_Pattern_Det          = 9'b00_0101_001, // Hex: 9'h029 (Check VALTRAIN)
    MBINIT_REPAIRVAL_RX_Wait_Result_REQ            = 9'b00_0101_010, // Hex: 9'h02A (Wait for Log Request)
    MBINIT_REPAIRVAL_RX_Send_Result_RESP           = 9'b00_0101_011, // Hex: 9'h02B (Send Result Log)
    MBINIT_REPAIRVAL_RX_Done_Handshake             = 9'b00_0101_100, // Hex: 9'h02C (Send Done RESP)

    // --- 7. MBINIT REVERSAL ---
    MBINIT_REVERSAL_RX_Init_Handshake              = 9'b00_0110_000, // Hex: 9'h030 (Send Init RESP)
    MBINIT_REVERSAL_RX_Clear_Log_Hnd               = 9'b00_0110_001, // Hex: 9'h031 (Reset Error Counters)
    MBINIT_REVERSAL_RX_Per_Lane_ID_Det             = 9'b00_0110_010, // Hex: 9'h032 (Identify Lanes)
    MBINIT_REVERSAL_RX_Result_Handshake            = 9'b00_0110_011, // Hex: 9'h033 (Send Result RESP)
    MBINIT_REVERSAL_RX_Done_Handshake              = 9'b00_0110_100, // Hex: 9'h034 (Send Done RESP)

    // --- 8. MBINIT REPAIRMB ---
    MBINIT_REPAIRMB_RX_Init_Handshake             = 9'b00_0111_000, // Hex: 9'h038 (Send Start RESP)
    MBINIT_REPAIRMB_RX_Wait_Apply_Degrade         = 9'b00_0111_010, // Hex: 9'h03A (Wait for TX Map)
    MBINIT_REPAIRMB_RX_Degrade                    = 9'b00_0111_011, // Hex: 9'h03B (Update Hardware)
    MBINIT_REPAIRMB_RX_Send_Degrade_Resp          = 9'b00_0111_100, // Hex: 9'h03C (Confirm Degrade)
    MBINIT_REPAIRMB_RX_Done_Handshake             = 9'b00_0111_101, // Hex: 9'h03D (Send End RESP)

    // --- 9. TRAINERROR ---
    TRAINERROR_RX_Handshake                        = 9'b00_1000_000, // Hex: 9'h040 (Send Error RESP)
    TRAINERROR_RX_TrainError                       = 9'b00_1000_001, // Hex: 9'h041 (Wait 8ms Timeout)
    TRAINERROR_RX_Reset                            = 9'b00_1000_010, // Hex: 9'h042 (Go to RESET)

    // =========================================================================
    // 01: TRAIN PHASE
    // =========================================================================

    // --- 1. MBTRAIN VALVREF ---
    MBTRAIN_VALVREF_RX_Start_Handshake             = 9'b01_0000_000, // Hex: 9'h080 (Send Vref Start REQ)
    MBTRAIN_VALVREF_RX_End_Handshake               = 9'b01_0000_010, // Hex: 9'h082 (Send End REQ)

    // --- 2. MBTRAIN DATAVREF ---
    MBTRAIN_DATAVREF_RX_Start_Handshake            = 9'b01_0001_000, // Hex: 9'h088 (Send Start REQ)
    MBTRAIN_DATAVREF_RX_End_Handshake              = 9'b01_0001_010, // Hex: 9'h08A (Send End REQ)

    // --- 3. MBTRAIN SPEEDIDLE ---
    MBTRAIN_SPEEDIDLE_RX_Speed_Transition          = 9'b01_1001_000, // Hex: 9'h0C8 (Change Clock Div)
    MBTRAIN_SPEEDIDLE_RX_End_Handshake             = 9'b01_1001_001, // Hex: 9'h0C9 (Success -> Retrain)

    // --- 4. MBTRAIN TXSELFCAL ---
    MBTRAIN_TXSELFCAL_RX_End_Handshake             = 9'b01_1010_000, // Hex: 9'h0D0 (Send End REQ)

    // --- 4. MBTRAIN RXCLKCAL ---
    MBTRAIN_RXCLKCAL_RX_Start_Handshake            = 9'b01_0011_000, // Hex: 9'h098 (Send Start REQ)
    MBTRAIN_RXCLKCAL_RX_Clock_Shifting_Op          = 9'b01_0011_001, // Hex: 9'h099 (Wait for RX shift)
    MBTRAIN_RXCLKCAL_RX_End_Handshake              = 9'b01_0011_010, // Hex: 9'h09A (Send End REQ)

    // --- 5. MBTRAIN VALTRAINCENTER ---
    MBTRAIN_VALTRAINCENTER_RX_Start_Handshake      = 9'b01_0100_000, // Hex: 9'h0A0 (Send Start REQ)
    MBTRAIN_VALTRAINCENTER_RX_End_Handshake        = 9'b01_0100_010, // Hex: 9'h0A2 (Send End REQ)

    // --- 6. MBTRAIN VALTRAINVREF ---
    MBTRAIN_VALTRAINVREF_RX_Start_Handshake        = 9'b01_1101_000, // Hex: 9'h0E8 (Send Start REQ)
    MBTRAIN_VALTRAINVREF_RX_End_Handshake          = 9'b01_1101_010, // Hex: 9'h0EA (Send End REQ)

    // --- 7. MBTRAIN DATATRAINCENTER1 ---
    MBTRAIN_DTC1_RX_Start_Handshake                = 9'b01_0010_000, // Hex: 9'h090 (Send Start REQ)
    MBTRAIN_DTC1_RX_End_Handshake                  = 9'b01_0010_010, // Hex: 9'h092 (Send End REQ)

    // --- 8. MBTRAIN DATATRAINVREF ---
    MBTRAIN_DATATRAINVREF_RX_Start_Handshake       = 9'b01_1110_000, // Hex: 9'h0F0 (Send Start REQ)
    MBTRAIN_DATATRAINVREF_RX_End_Handshake         = 9'b01_1110_010, // Hex: 9'h0F2 (Send End REQ)

    // --- 9. MBTRAIN RXDESKEW ---
    MBTRAIN_RXDESKEW_RX_Start_Handshake            = 9'b01_0101_000, // Hex: 9'h0A8 (Send Start REQ)
    MBTRAIN_RXDESKEW_RX_EQ_Preset_Handshake        = 9'b01_0101_001, // Hex: 9'h0A9 (Send EQ Preset REQ)
    MBTRAIN_RXDESKEW_RX_Deskew_Operation           = 9'b01_0101_010, // Hex: 9'h0AA (Wait for Deskew)
    MBTRAIN_RXDESKEW_RX_Datacenter_Handshake       = 9'b01_0101_011, // Hex: 9'h0AB (Exit to DTC2)
    MBTRAIN_RXDESKEW_RX_End_Handshake              = 9'b01_0101_100, // Hex: 9'h0AC (Exit to LinkSpeed)
    MBTRAIN_RXDESKEW_RX_Train_Error_Handshake      = 9'b01_0101_101, // Hex: 9'h0AD (Exit to Error)

    // --- 10. MBTRAIN DATATRAINCENTER2 ---
    MBTRAIN_DTC2_RX_Start_Handshake                = 9'b01_0110_000, // Hex: 9'h0B0 (Send Start REQ)
    MBTRAIN_DTC2_RX_End_Handshake                  = 9'b01_0110_010, // Hex: 9'h0B2 (Send End REQ)

    // --- 11. MBTRAIN LINKSPEED ---
    MBTRAIN_LINKSPEED_RX_Start_Handshake           = 9'b01_0111_000, // Hex: 9'h0B8 (Send Start REQ)
    MBTRAIN_LINKSPEED_RX_LinksSpeed_Done_Hnd       = 9'b01_0111_010, // Hex: 9'h0BA (Success -> LinkInit)
    MBTRAIN_LINKSPEED_RX_Error_REQ                 = 9'b01_0111_011, // Hex: 9'h0BB (Fail -> Eval Error)
    MBTRAIN_LINKSPEED_RX_Phy_Retrain_Hnd           = 9'b01_0111_100, // Hex: 9'h0BC (Critical Fail -> Retrain)
    MBTRAIN_LINKSPEED_RX_Exit_Repair_Hnd           = 9'b01_0111_101, // Hex: 9'h0BD (Exit to Repair)
    MBTRAIN_LINKSPEED_RX_Exit_SpeedDegrade_Hnd     = 9'b01_0111_110, // Hex: 9'h0BE (Exit to Speed Degrade)

    // --- 12. MBTRAIN REPAIR ---
    MBTRAIN_REPAIR_RX_Start_Handshake              = 9'b01_1000_000, // Hex: 9'h0C0 (Send Init REQ)
    MBTRAIN_REPAIR_RX_Apply_Degrade_Handshake      = 9'b01_1000_001, // Hex: 9'h0C1 (Negotiate Width)
    MBTRAIN_REPAIR_RX_End_Handshake                = 9'b01_1000_010, // Hex: 9'h0C2 (Send End REQ)

    // --- 13. PHYRETRAIN ---
    PHYRETRAIN_RX_PL_StallReq_Handshake            = 9'b01_1011_000, // Hex: 9'h0D8 (Ask Adapter to Stall)
    PHYRETRAIN_RX_Retrain_Handshake                = 9'b01_1011_001, // Hex: 9'h0D9 (Sync with Partner)
    PHYRETRAIN_RX_Start_Req_Handshake              = 9'b01_1011_010, // Hex: 9'h0DA (Choose next state)

    // =========================================================================
    // 10: ACTIVE PHASE
    // =========================================================================

    // --- 1. LINKINIT ---
    LINKINIT_RX_PL_Clk_Req_Handshake              = 9'b10_0000_000, // Hex: 9'h100 (Req Adapter Clock)
    LINKINIT_RX_LP_Wake_Req_Handshake             = 9'b10_0000_001, // Hex: 9'h101 (Wake Adapter)
    LINKINIT_RX_State_Rsp_Handshake               = 9'b10_0000_010, // Hex: 9'h102 (Ack State Exch)

    // --- 2. ACTIVE ---
    ACTIVE_RX_Active                               = 9'b10_0001_000, // Hex: 9'h108 (Data Flowing)

    // --- 3. L1 / Exit HS ---
    L1_RX_Start_HS                                 = 9'b10_0010_000, // Hex: 9'h110 (Entering Sleep)
    L1_RX_L1_State                                 = 9'b10_0010_001, // Hex: 9'h111 (Low Power State)
    L1_RX_Wait1us                                  = 9'b10_0011_010, // Hex: 9'h11A (Wait for RDI)
    L1_RX_Refuse                                   = 9'b10_0011_011, // Hex: 9'h11B (Refuse L1)
    EXIT_HS_RX_Exit_Handshake                      = 9'b10_0011_100, // Hex: 9'h11C (Wakeup from L1)

    // =========================================================================
    // 11: DATA-TO-CLOCK EYE SWEEP
    // =========================================================================
    // --- 1. TX Initiated (state = 4'b0000) ---
    Data_To_Clock_test_RX_INIT_Handshake_TX_Init          = 9'b11_0000_000, // Hex: 9'h180
    Data_To_Clock_test_RX_LFSR_Clear_Handshake_TX_Init    = 9'b11_0000_001, // Hex: 9'h181
    Data_To_Clock_test_RX_Pattern_Detection_TX_Init       = 9'b11_0000_010, // Hex: 9'h182
    Data_To_Clock_test_RX_Result_Handshake_TX_Init        = 9'b11_0000_011, // Hex: 9'h183
    Data_To_Clock_test_RX_End_Init_Handshake_TX_Init      = 9'b11_0000_100, // Hex: 9'h184

    // --- 2. RX Initiated (state = 4'b0001) ---
    Data_To_Clock_test_RX_INIT_Handshake_RX_Init          = 9'b11_0001_000, // Hex: 9'h188
    Data_To_Clock_test_RX_LFSR_Clear_Handshake_RX_Init    = 9'b11_0001_001, // Hex: 9'h189
    Data_To_Clock_test_RX_Pattern_Detection_RX_Init       = 9'b11_0001_010, // Hex: 9'h18A
    Data_To_Clock_test_RX_Result_Handshake_RX_Init        = 9'b11_0001_011, // Hex: 9'h18B
    Data_To_Clock_test_RX_Sweep_Result_Handshake          = 9'b11_0001_100, // Hex: 9'h18C
    Data_To_Clock_test_RX_End_Init_Handshake_RX_Init      = 9'b11_0001_101  // Hex: 9'h18D

  } rx_encoding_t;
endpackage : shared_pkg
