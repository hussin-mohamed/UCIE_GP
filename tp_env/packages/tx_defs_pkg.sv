//=============================================================================
// File       : tx_defs_pkg.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: Central definitions package — enums, parameters, and typedefs.
//=============================================================================

package tx_defs_pkg;

  // ===========================================================================
  //  Global Parameters
  // ===========================================================================

  // Physical lane count
  parameter int NUM_LANES     = 16;

  // Default flit size in bytes
  parameter int DEFAULT_NBYTES = 256;

  // ===========================================================================
  //  Flit Size Enum
  // ===========================================================================

  typedef enum int {
    FLIT_64  = 64,
    FLIT_128 = 128,
    FLIT_256 = 256,
    FLIT_512 = 512
  } flit_size_e;

  // ===========================================================================
  //  Lane Map Configuration (localparams per spec)
  // ===========================================================================
  //
  //  Driven alongside REPAIRMB / REPAIR state encodings:
  //   000 = Cannot degrade (no degradation possible)
  //   001 = Lanes 0-7 are functional, lanes 8-15 disabled
  //   010 = Lanes 8-15 are functional, lanes 0-7 disabled
  //   011 = All lanes functional (no degradation applied)
  //
  //  If an unsupported combination occurs, DV drives TRAINERROR.

  localparam logic [2:0] LANE_MAP_DEGRADE_NOT_POSSIBLE  = 3'b000;
  localparam logic [2:0] LANE_MAP_LANES_0_TO_7          = 3'b001;
  localparam logic [2:0] LANE_MAP_LANES_8_TO_15         = 3'b010;
  localparam logic [2:0] LANE_MAP_ALL_FUNCTIONAL        = 3'b011;

  // ===========================================================================
  //  LTSM State Group Enum (TB-level — selects constraint group for seq_item)
  // ===========================================================================

  typedef enum {
    GROUP_HAPPY_PATH,     // Full init → train → active ordered walk
    GROUP_PATTERN_GEN,    // Pattern generation states only
    GROUP_TRAIN_ERROR,    // Error injection states
    GROUP_TRISTATE,       // States with Z output (RESET, SBINIT, PARAM, CAL)
    GROUP_ACTIVE          // LINKINIT + ACTIVE + L1/EXIT_HS
  } ltsm_state_group_e;

  // ===========================================================================
  //  LTSM Encoding Enum — Full TX FSM (9-bit encoding)
  // ===========================================================================
  //
  //  Encoding format: [8:7] = FSM_ID,  [6:3] = State,  [2:0] = Substate
  //
  //  FSM_ID 00 = Initialization
  //  FSM_ID 01 = Training
  //  FSM_ID 10 = Active
  //  FSM_ID 11 = Data-to-Clock Test (shared sub-FSM)
  //
  // ===========================================================================

  typedef enum logic [8:0] {

    // -----------------------------------------------------------------------
    //  FSM 00: INITIALIZATION
    // -----------------------------------------------------------------------

    // 1. RESET
    RESET                          = 9'b00_0000_000,  // 9'h000  PLL/Power stabilization

    // 2. SBINIT
    SBINIT_PATTERN_GEN             = 9'b00_0001_000,  // 9'h008  Send clock pattern
    SBINIT_OUT_OF_RESET            = 9'b00_0001_001,  // 9'h009  Send out-of-reset msg
    SBINIT_DONE_HND                = 9'b00_0001_010,  // 9'h00A  Send Done REQ & wait RSP

    // 3. MBINIT PARAM
    PARAM_CONFIG_HND               = 9'b00_0010_000,  // 9'h010  Send Config REQ

    // 4. MBINIT CAL
    CAL_DONE_HND                   = 9'b00_0011_000,  // 9'h018  Send Cal Done REQ

    // 5. MBINIT REPAIRCLK
    REPAIRCLK_INIT_HND             = 9'b00_0100_000,  // 9'h020  Send Init REQ
    REPAIRCLK_CLK_PATTERN_GEN      = 9'b00_0100_001,  // 9'h021  128 iterations clk pattern
    REPAIRCLK_RESULT_HND           = 9'b00_0100_010,  // 9'h022  Send Result REQ
    REPAIRCLK_DONE_HND             = 9'b00_0100_011,  // 9'h023  Send Done REQ

    // 6. MBINIT REPAIRVAL
    REPAIRVAL_INIT_HND             = 9'b00_0101_000,  // 9'h028  Send Init REQ
    REPAIRVAL_VALID_PATTERN_GEN    = 9'b00_0101_001,  // 9'h029  Send VALTRAIN pattern
    REPAIRVAL_RESULT_HND           = 9'b00_0101_010,  // 9'h02A  Send Result REQ
    REPAIRVAL_DONE_HND             = 9'b00_0101_011,  // 9'h02B  Send Done REQ

    // 7. MBINIT REVERSAL
    REVERSAL_INIT_HND              = 9'b00_0110_000,  // 9'h030  Send Init REQ
    REVERSAL_CLEAR_LOG_HND         = 9'b00_0110_001,  // 9'h031  Send Clear Error REQ
    REVERSAL_PER_LANE_ID_GEN       = 9'b00_0110_010,  // 9'h032  Send ID pattern
    REVERSAL_RESULT_HND            = 9'b00_0110_011,  // 9'h033  Check majority success
    REVERSAL_APPLY                 = 9'b00_0110_100,  // 9'h034  Flip mux (loop back)
    REVERSAL_DONE_HND              = 9'b00_0110_101,  // 9'h035  Send Done REQ

    // 8. MBINIT REPAIRMB
    REPAIRMB_INIT_HND              = 9'b00_0111_000,  // 9'h038  Send Start REQ
    // NOTE: REPAIRMB D2C point uses D2C_TX_INIT_HND (9'h180) — shared FSM
    REPAIRMB_APPLY_DEGRADE_HND     = 9'b00_0111_010,  // 9'h03A  Negotiate width
    REPAIRMB_DONE_HND              = 9'b00_0111_011,  // 9'h03B  Send End REQ

    // 9. TRAINERROR (under init phase encoding but used globally)
    TRAINERROR_HND                 = 9'b00_1000_000,  // 9'h040  Send Error REQ
    // NOTE: Also used by MBTRAIN_SPEEDIDLE.TX_TrainError_Handshake (same encoding)
    TRAINERROR_WAIT                = 9'b00_1000_001,  // 9'h041  Wait 8ms timeout
  

    // -----------------------------------------------------------------------
    //  FSM 01: TRAINING
    // -----------------------------------------------------------------------

    // 1. MBTRAIN VALVREF
    VALVREF_START_HND              = 9'b01_0000_000,  // 9'h080  Send Vref Start REQ
    // NOTE: VALVREF eye sweep uses D2C_RX_EYE_SWEEP (9'h185) — shared FSM
    VALVREF_END_HND                = 9'b01_0000_010,  // 9'h082  Send End REQ

    // 2. MBTRAIN DATAVREF
    DATAVREF_START_HND             = 9'b01_0001_000,  // 9'h088  Send Start REQ
    // NOTE: DATAVREF eye sweep uses D2C_RX_EYE_SWEEP (9'h185) — shared FSM
    DATAVREF_END_HND               = 9'b01_0001_010,  // 9'h08A  Send End REQ

    // 3. MBTRAIN DTC1 (DataTrainCenter1)
    DTC1_START_HND                 = 9'b01_0010_000,  // 9'h090  Send Start REQ
    // NOTE: DTC1 eye sweep uses D2C_TX_INIT_HND (9'h180) — shared FSM
    DTC1_END_HND                   = 9'b01_0010_010,  // 9'h092  Send End REQ

    // 4. MBTRAIN RXCLKCAL
    RXCLKCAL_START_HND             = 9'b01_0011_000,  // 9'h098  Send Start REQ
    RXCLKCAL_CLK_SHIFT_OP          = 9'b01_0011_001,  // 9'h099  Wait for RX shift
    RXCLKCAL_END_HND               = 9'b01_0011_010,  // 9'h09A  Send End REQ

    // 5. MBTRAIN VALTRAINCENTER
    VALTRAINCENTER_START_HND       = 9'b01_0100_000,  // 9'h0A0  Send Start REQ
    // NOTE: eye sweep uses D2C_TX_INIT_HND (9'h180) — shared FSM
    VALTRAINCENTER_END_HND         = 9'b01_0100_010,  // 9'h0A2  Send End REQ

    // 6. MBTRAIN RXDESKEW
    RXDESKEW_START_HND             = 9'b01_0101_000,  // 9'h0A8  Send Start REQ
    RXDESKEW_EQ_PRESET_HND         = 9'b01_0101_001,  // 9'h0A9  Send EQ Preset REQ
    RXDESKEW_DESKEW_OP             = 9'b01_0101_010,  // 9'h0AA  Wait for deskew
    RXDESKEW_DATACENTER_HND        = 9'b01_0101_011,  // 9'h0AB  Exit to DTC2
    RXDESKEW_END_HND               = 9'b01_0101_100,  // 9'h0AC  Exit to LinkSpeed
    RXDESKEW_TRAIN_ERROR_HND       = 9'b01_0101_101,  // 9'h0AD  Exit to Error

    // 7. MBTRAIN DTC2 (DataTrainCenter2)
    DTC2_START_HND                 = 9'b01_0110_000,  // 9'h0B0  Send Start REQ
    // NOTE: eye sweep uses D2C_TX_INIT_HND (9'h180) — shared FSM
    DTC2_END_HND                   = 9'b01_0110_010,  // 9'h0B2  Send End REQ

    // 8. MBTRAIN LINKSPEED
    LINKSPEED_START_HND            = 9'b01_0111_000,  // 9'h0B8  Send Start REQ
    // NOTE: D2C test uses D2C_TX_INIT_HND (9'h180) — shared FSM
    LINKSPEED_DONE_HND             = 9'b01_0111_010,  // 9'h0BA  Success → LinkInit
    LINKSPEED_ERROR_REQ            = 9'b01_0111_011,  // 9'h0BB  Fail → Eval Error
    LINKSPEED_PHY_RETRAIN_HND      = 9'b01_0111_100,  // 9'h0BC  Critical Fail → Retrain
    LINKSPEED_EXIT_REPAIR_HND      = 9'b01_0111_101,  // 9'h0BD  Exit to Repair
    LINKSPEED_EXIT_SPEED_DEGRADE   = 9'b01_0111_110,  // 9'h0BE  Exit to SpeedDegrade

    // 9. MBTRAIN REPAIR
    REPAIR_START_HND               = 9'b01_1000_000,  // 9'h0C0  Send Init REQ
    REPAIR_APPLY_DEGRADE_HND       = 9'b01_1000_001,  // 9'h0C1  Negotiate Width
    REPAIR_END_HND                 = 9'b01_1000_010,  // 9'h0C2  Send End REQ

    // 10. MBTRAIN SPEEDIDLE
    SPEEDIDLE_SPEED_TRANSITION     = 9'b01_1001_000,  // 9'h0C8  Change clock divider
    SPEEDIDLE_END_HND              = 9'b01_1001_010,  // 9'h0CA  Success → Retrain
    // NOTE: SPEEDIDLE fail → TRAINERROR_HND (9'h040) — same encoding, no dup needed

    // 11. MBTRAIN TXSELFCAL
    TXSELFCAL_CALIBRATION          = 9'b01_1010_000,  // 9'h0D0  Run internal cal
    TXSELFCAL_END_HND              = 9'b01_1010_001,  // 9'h0D1  Send End REQ

    // 12. PHYRETRAIN
    PHYRETRAIN_STALL_REQ_HND       = 9'b01_1011_000,  // 9'h0D8  Ask adapter to stall
    PHYRETRAIN_RETRAIN_HND         = 9'b01_1011_001,  // 9'h0D9  Sync with partner
    PHYRETRAIN_START_REQ_HND       = 9'b01_1011_010,  // 9'h0DA  Choose next state

    // 13. MBTRAIN VALTRAINVREF
    VALTRAINVREF_START_HND         = 9'b01_1101_000,  // 9'h0E8  Send Start REQ
    // NOTE: eye sweep uses D2C_TX_INIT_HND (9'h180) — shared FSM
    VALTRAINVREF_END_HND           = 9'b01_1101_010,  // 9'h0EA  Send End REQ

    // 14. MBTRAIN DATATRAINVREF
    DATATRAINVREF_START_HND        = 9'b01_1110_000,  // 9'h0F0  Send Start REQ
    // NOTE: eye sweep uses D2C_TX_INIT_HND (9'h180) — shared FSM
    DATATRAINVREF_END_HND          = 9'b01_1110_010,  // 9'h0F2  Send End REQ

    // -----------------------------------------------------------------------
    //  FSM 10: ACTIVE
    // -----------------------------------------------------------------------

    // 1. LINKINIT
    LINKINIT_PL_CLK_REQ_HND        = 9'b10_0000_000,  // 9'h100  Req adapter clock
    LINKINIT_LP_WAKE_REQ_HND       = 9'b10_0000_001,  // 9'h101  Wake adapter
    LINKINIT_STATE_REQ_HND         = 9'b10_0000_010,  // 9'h102  RDI state exchange

    // 2. ACTIVE
    ACTIVE                         = 9'b10_0001_000,  // 9'h108  Data flowing (flits)

    // 3. L1 / Exit HS
    L1_HND                         = 9'b10_0010_000,  // 9'h110  L1 handshake
    L1_STATE                       = 9'b10_0010_001,  // 9'h111  Low power state
    EXIT_HS_HND                    = 9'b10_0011_010,  // 9'h11A  Wakeup from L1

    // -----------------------------------------------------------------------
    //  FSM 11: Data-to-Clock Test (Shared Sub-FSM)
    // -----------------------------------------------------------------------
    //
    //  This FSM is entered from multiple parent states:
    //    - MBINIT_REPAIRMB.TX_Data_to_Clock_Point → D2C_TX_INIT_HND
    //    - MBTRAIN_VALTRAINCENTER / DTC1 / DTC2 / LINKSPEED / etc. → D2C_TX_INIT_HND
    //    - MBTRAIN_VALVREF / DATAVREF → D2C_RX_EYE_SWEEP
    //    - MBTRAIN_VALTRAINVREF / DATATRAINVREF → D2C_TX_INIT_HND

    // TX-initiated Data-to-Clock test
    D2C_TX_INIT_HND                = 9'b11_0000_000,  // 9'h180  Init handshake
    D2C_TX_LFSR_CLEAR_HND          = 9'b11_0000_001,  // 9'h181  LFSR clear handshake
    D2C_TX_PATTERN_GEN             = 9'b11_0000_010,  // 9'h182  Pattern generation
    D2C_TX_RESULT_HND              = 9'b11_0000_011,  // 9'h183  Result handshake
    D2C_TX_END_INIT_HND            = 9'b11_0000_100,  // 9'h184  End init handshake

    // RX-initiated Data-to-Clock test
    D2C_RX_INIT_HND                = 9'b11_0001_000,  // 9'h188  Init handshake
    D2C_RX_LFSR_CLEAR_HND          = 9'b11_0001_001,  // 9'h189  LFSR clear handshake
    D2C_RX_PATTERN_GEN             = 9'b11_0001_010,  // 9'h18A  Pattern generation
    D2C_RX_RESULT_HND              = 9'b11_0001_011,  // 9'h18B  Result handshake
    D2C_RX_SWEEP_RESULT_HND        = 9'b11_0001_100,  // 9'h18C  Sweep result handshake
    D2C_RX_END_INIT_HND            = 9'b11_0001_101   // 9'h18D  End init handshake

  } ltsm_encoding_e;

  // ===========================================================================
  //  Helper Functions
  // ===========================================================================

  // Extract the 2-bit FSM_ID from a 9-bit encoding
  function automatic logic [1:0] get_fsm_id(ltsm_encoding_e enc);
    return enc[8:7];
  endfunction

  // Check if encoding is in the initialization FSM_ID (00)
  function automatic logic is_init_fsm(ltsm_encoding_e enc);
    return (enc[8:7] == 2'b00);
  endfunction

  // Check if encoding is in the training FSM_ID (01)
  function automatic logic is_train_fsm(ltsm_encoding_e enc);
    return (enc[8:7] == 2'b01);
  endfunction

  // Check if encoding is in the active FSM_ID (10)
  function automatic logic is_active_fsm(ltsm_encoding_e enc);
    return (enc[8:7] == 2'b10);
  endfunction

  // Check if encoding is in the data-to-clock test FSM_ID (11)
  function automatic logic is_d2c_fsm(ltsm_encoding_e enc);
    return (enc[8:7] == 2'b11);
  endfunction

  // Check if encoding indicates outputs should be tri-stated
  // (RESET, all SBINIT, PARAM, CAL substates)
  function automatic logic is_tristate_state(ltsm_encoding_e enc);
    case (enc)
      RESET,
      SBINIT_PATTERN_GEN, SBINIT_OUT_OF_RESET, SBINIT_DONE_HND,
      PARAM_CONFIG_HND,
      CAL_DONE_HND:
        return 1'b1;
      default:
        return 1'b0;
    endcase
  endfunction

  // Check if encoding is the ACTIVE data-flowing state
  function automatic logic is_active_data(ltsm_encoding_e enc);
    return (enc == ACTIVE);
  endfunction

  // Check if encoding involves pattern generation on the egress
  function automatic logic is_pattern_gen_state(ltsm_encoding_e enc);
    case (enc)
      REPAIRCLK_CLK_PATTERN_GEN,
      REPAIRVAL_VALID_PATTERN_GEN,
      REVERSAL_PER_LANE_ID_GEN,
      D2C_TX_PATTERN_GEN,
      D2C_RX_PATTERN_GEN:
        return 1'b1;
      default:
        return 1'b0;
    endcase
  endfunction

  // Check if encoding involves pattern generation on the egress
  function automatic logic is_valid_gen_state(ltsm_encoding_e enc);
    case (enc)
      REPAIRVAL_VALID_PATTERN_GEN,
      VALVREF_START_HND,
      VALTRAINCENTER_START_HND:
        return 1'b1;
      default:
        return 1'b0;
    endcase
  endfunction

  // Check if lane_map is relevant for this encoding
  function automatic logic uses_lane_map(ltsm_encoding_e enc);
    case (enc)
      REPAIRMB_INIT_HND, REPAIRMB_APPLY_DEGRADE_HND, REPAIRMB_DONE_HND,
      REPAIR_START_HND, REPAIR_APPLY_DEGRADE_HND, REPAIR_END_HND:
        return 1'b1;
      default:
        return 1'b0;
    endcase
  endfunction

endpackage : tx_defs_pkg
