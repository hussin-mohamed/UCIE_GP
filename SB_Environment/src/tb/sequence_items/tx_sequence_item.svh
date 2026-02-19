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
  MBTRAIN_VALTRAINVREF_TX_Start_Handshake  = 9'b01_0100_000,
  MBTRAIN_VALTRAINVREF_TX_Pattern_Generation = 9'b01_0100_001,
  MBTRAIN_VALTRAINVREF_TX_End_Handshake    = 9'b01_0100_010,

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
  MBTRAIN_SPEEDIDLE_TX_End_Handshake       = 9'b01_1001_001,
  MBTRAIN_SPEEDIDLE_TX_TrainError_Handshake = 9'b01_1001_010,

  // 11. MBTRAIN TXSELFCAL
  MBTRAIN_TXSELFCAL_TX_Calibration         = 9'b01_1010_000,
  MBTRAIN_TXSELFCAL_TX_End_Handshake       = 9'b01_1010_001,

  // 12. PHYRETRAIN
  PHYRETRAIN_TX_PL_StallReq_Handshake      = 9'b01_1011_000,
  PHYRETRAIN_TX_Retrain_Handshake          = 9'b01_1011_001,
  PHYRETRAIN_TX_Start_Req_Handshake        = 9'b01_1011_010,

  // 14. VALTRAINCENTER
  MBTRAIN_VALTRAINCENTER_TX_Start_Handshake     = 9'b01_1101_000,
  MBTRAIN_VALTRAINCENTER_TX_Pattern_Generation  = 9'b01_1101_001,
  MBTRAIN_VALTRAINCENTER_TX_End_Handshake       = 9'b01_1101_010,

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
  ACTIVE_EXIT_HS_TX_Exit_Handshake          = 9'b10_0011_000,
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
class tx_sequence_item extends LTSM_sequence_item_base;
    encoding_t encoding;
    `uvm_object_utils_begin(tx_sequence_item)
        `uvm_field_enum(encoding, encoding_t, UVM_NORECORD)
    `uvm_object_utils_end
    // Function: new
    //
    // Creates a new tx_sequence_item instance with the given name.
    extern function new(string name = "tx_sequence_item");
endclass : tx_sequence_item

function tx_sequence_item::new(string name = "tx_sequence_item");
    super.new(name);
endfunction