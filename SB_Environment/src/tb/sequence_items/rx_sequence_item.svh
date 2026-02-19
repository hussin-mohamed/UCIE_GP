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

//------------------------------------------------------------------------------
//
// CLASS: tx_sequence_item
//
// Description: Sequence item class for tx sequences, containing all necessary
//              fields for controlling and monitoring the tx behavior.
//------------------------------------------------------------------------------
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
  RX_MBTRAIN_RXDESKEW_Train_Error_Handshake   = 9'b01_0101_100,
  RX_MBTRAIN_RXDESKEW_End_Handshake           = 9'b01_0101_101,

  // 7. MBTRAIN DATATRAINCENTER2
  RX_MBTRAIN_DTC2_Start_Handshake             = 9'b01_0110_000,
  RX_MBTRAIN_DTC2_Pattern_Detection           = 9'b01_0110_001,
  RX_MBTRAIN_DTC2_End_Handshake               = 9'b01_0110_010,

  // 8. MBTRAIN LINKSPEED
  RX_MBTRAIN_LINKSPEED_Start_Handshake        = 9'b01_0111_000,
  RX_MBTRAIN_LINKSPEED_Data_Clock_Test_Det    = 9'b01_0111_001,
  RX_MBTRAIN_LINKSPEED_Wait_REQ               = 9'b01_0111_010,
  RX_MBTRAIN_LINKSPEED_Send_SpeedDegrade_RESP = 9'b01_0111_011,
  RX_MBTRAIN_LINKSPEED_Send_PhyRetrain_RESP   = 9'b01_0111_100,
  RX_MBTRAIN_LINKSPEED_Send_Repair_RESP       = 9'b01_0111_101,
  RX_MBTRAIN_LINKSPEED_Send_Done_RESP         = 9'b01_0111_110,
  RX_MBTRAIN_LINKSPEED_Send_Error_RESP        = 9'b01_0111_111,

  // 9. MBTRAIN REPAIR
  RX_MBTRAIN_REPAIR_Start_Handshake           = 9'b01_1000_000,
  RX_MBTRAIN_REPAIR_Wait_Apply_Degrade_REQ    = 9'b01_1000_001,
  RX_MBTRAIN_REPAIR_Apply_Degrade             = 9'b01_1000_010,
  RX_MBTRAIN_REPAIR_Send_Apply_Degrade_RESP   = 9'b01_1000_011,
  RX_MBTRAIN_REPAIR_End_Handshake             = 9'b01_1000_100,

  // 10. MBTRAIN SPEEDIDLE
  RX_MBTRAIN_SPEEDIDLE_Speed_Transition       = 9'b01_1001_000,
  RX_MBTRAIN_SPEEDIDLE_TrainError_Handshake   = 9'b01_1001_001,
  RX_MBTRAIN_SPEEDIDLE_End_Handshake          = 9'b01_1001_010,

  // 11. MBTRAIN TXSELFCAL
  RX_MBTRAIN_TXSELFCAL_End_Handshake          = 9'b01_1010_000,

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
  Data_To_Clock_sweep_RX_INIT_Handshake	    = 9'b11_0000_000,
  Data_To_Clock_sweep_RX_LFSR_Clear_Handshake	= 9'b11_0000_001,
  Data_To_Clock_sweep_RX_Pattern_Generation	= 9'b11_0000_010,
  Data_To_Clock_sweep_RX_Result_Handshake	= 9'b11_0000_011,
  Data_To_Clock_sweep_RX_End_Init_Handshake	= 9'b11_0000_100
} encoding_t;
import uvm_pkg::*;
`include "uvm_macros.svh"
class rx_sequence_item extends ltsm_sequence_item_base;
    encoding_t encoding;
    `uvm_object_utils_begin(rx_sequence_item)
        `uvm_field_enum(encoding, encoding_t, UVM_NORECORD)
    `uvm_object_utils_end

    // Function: new
    //
    // Creates a new rx_sequence_item instance with the given name.
    extern function new(string name = "rx_sequence_item");
endclass : rx_sequence_item

function rx_sequence_item::new(string name = "rx_sequence_item");
    super.new(name);
endfunction