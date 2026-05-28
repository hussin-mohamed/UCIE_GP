//=============================================================================
// File       : tx_coverage.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: Coverage collector — subscribes to RDI and LTSM monitor
//              analysis ports. Collects functional coverage for LTSM
//              state transitions, lane_map usage, flit sizes, and
//              backpressure events.
//=============================================================================

class tx_coverage extends uvm_component;

  `uvm_component_utils(tx_coverage)

  // Analysis imports
  `uvm_analysis_imp_decl(_rdi_cov)
  `uvm_analysis_imp_decl(_ltsm_cov)

  uvm_analysis_imp_rdi_cov  #(rdi_seq_item, tx_coverage)  rdi_imp;
  uvm_analysis_imp_ltsm_cov #(ltsm_seq_item, tx_coverage) ltsm_imp;

  // Internal state tracking
  ltsm_encoding_e prev_encoding;
  ltsm_encoding_e curr_encoding;
  logic [2:0]     curr_lane_map;


  // -------------------------------------------------------------------------
  //  LTSM Covergroup
  // -------------------------------------------------------------------------

  covergroup cg_ltsm;

    // All encoding values
    cp_encoding: coverpoint curr_encoding {
      // Phase 00: Initialization
      bins reset           = {RESET};
      bins sbinit[]        = {SBINIT_PATTERN_GEN, SBINIT_OUT_OF_RESET, SBINIT_DONE_HND};
      bins param           = {PARAM_CONFIG_HND};
      bins cal             = {CAL_DONE_HND};
      bins repairclk[]     = {REPAIRCLK_INIT_HND, REPAIRCLK_CLK_PATTERN_GEN,
                              REPAIRCLK_RESULT_HND, REPAIRCLK_DONE_HND};
      bins repairval[]     = {REPAIRVAL_INIT_HND, REPAIRVAL_VALID_PATTERN_GEN,
                              REPAIRVAL_RESULT_HND, REPAIRVAL_DONE_HND};
      bins reversal[]      = {REVERSAL_INIT_HND, REVERSAL_CLEAR_LOG_HND,
                              REVERSAL_PER_LANE_ID_GEN, REVERSAL_RESULT_HND,
                              REVERSAL_APPLY, REVERSAL_DONE_HND};
      bins repairmb[]      = {REPAIRMB_INIT_HND, REPAIRMB_APPLY_DEGRADE_HND,
                              REPAIRMB_DONE_HND};
      bins trainerror[]    = {TRAINERROR_HND, TRAINERROR_WAIT};

      // Phase 01: Training
      bins valvref[]       = {VALVREF_START_HND, VALVREF_END_HND};
      bins datavref[]      = {DATAVREF_START_HND, DATAVREF_END_HND};
      bins dtc1[]          = {DTC1_START_HND, DTC1_END_HND};
      bins rxclkcal[]      = {RXCLKCAL_START_HND, RXCLKCAL_CLK_SHIFT_OP, RXCLKCAL_END_HND};
      bins valtrainctr[]   = {VALTRAINCENTER_START_HND, VALTRAINCENTER_END_HND};
      bins rxdeskew[]      = {RXDESKEW_START_HND, RXDESKEW_EQ_PRESET_HND,
                              RXDESKEW_DESKEW_OP, RXDESKEW_DATACENTER_HND,
                              RXDESKEW_END_HND, RXDESKEW_TRAIN_ERROR_HND};
      bins dtc2[]          = {DTC2_START_HND, DTC2_END_HND};
      bins linkspeed[]     = {LINKSPEED_START_HND, LINKSPEED_DONE_HND,
                              LINKSPEED_ERROR_REQ, LINKSPEED_PHY_RETRAIN_HND,
                              LINKSPEED_EXIT_REPAIR_HND, LINKSPEED_EXIT_SPEED_DEGRADE};
      bins repair[]        = {REPAIR_START_HND, REPAIR_APPLY_DEGRADE_HND, REPAIR_END_HND};
      bins speedidle[]     = {SPEEDIDLE_SPEED_TRANSITION, SPEEDIDLE_END_HND};
      bins txselfcal[]     = {TXSELFCAL_CALIBRATION, TXSELFCAL_END_HND};
      bins phyretrain[]    = {PHYRETRAIN_STALL_REQ_HND, PHYRETRAIN_RETRAIN_HND,
                              PHYRETRAIN_START_REQ_HND};
      bins valtrainvref[]  = {VALTRAINVREF_START_HND, VALTRAINVREF_END_HND};
      bins datatrainvref[] = {DATATRAINVREF_START_HND, DATATRAINVREF_END_HND};

      // Phase 10: Active
      bins linkinit[]      = {LINKINIT_PL_CLK_REQ_HND, LINKINIT_LP_WAKE_REQ_HND,
                              LINKINIT_STATE_REQ_HND};
      bins active          = {ACTIVE};
      bins l1[]            = {L1_HND, L1_STATE};
      bins exit_hs         = {EXIT_HS_HND};

      // Phase 11: D2C Test
      bins d2c_tx[]        = {D2C_TX_INIT_HND, D2C_TX_LFSR_CLEAR_HND,
                              D2C_TX_PATTERN_GEN, D2C_TX_RESULT_HND, D2C_TX_END_INIT_HND};
      bins d2c_rx[]        = {D2C_RX_INIT_HND, D2C_RX_LFSR_CLEAR_HND,
                              D2C_RX_PATTERN_GEN, D2C_RX_RESULT_HND,
                              D2C_RX_SWEEP_RESULT_HND, D2C_RX_END_INIT_HND};
    }

    // Lane map values
    cp_lane_map: coverpoint curr_lane_map {
      bins no_degrade  = {LANE_MAP_DEGRADE_NOT_POSSIBLE};
      bins lanes_0_7   = {LANE_MAP_LANES_0_TO_7};
      bins lanes_8_15  = {LANE_MAP_LANES_8_TO_15};
      bins all_func    = {LANE_MAP_ALL_FUNCTIONAL};
    }

    // Cross: lane_map × encoding for states that use lane_map
    cx_encoding_x_lane_map: cross cp_encoding, cp_lane_map {
      // Ignore all states that don't use lane_map — only REPAIRMB and REPAIR are meaningful
      ignore_bins ignore_non_degrade =
        binsof(cp_encoding) intersect {
          // Init: non-degradation states
          RESET,
          SBINIT_PATTERN_GEN, SBINIT_OUT_OF_RESET, SBINIT_DONE_HND,
          PARAM_CONFIG_HND,
          CAL_DONE_HND,
          REPAIRCLK_INIT_HND, REPAIRCLK_CLK_PATTERN_GEN,
          REPAIRCLK_RESULT_HND, REPAIRCLK_DONE_HND,
          REPAIRVAL_INIT_HND, REPAIRVAL_VALID_PATTERN_GEN,
          REPAIRVAL_RESULT_HND, REPAIRVAL_DONE_HND,
          REVERSAL_INIT_HND, REVERSAL_CLEAR_LOG_HND,
          REVERSAL_PER_LANE_ID_GEN, REVERSAL_RESULT_HND,
          REVERSAL_APPLY, REVERSAL_DONE_HND,
          TRAINERROR_HND, TRAINERROR_WAIT,
          // Training
          VALVREF_START_HND, VALVREF_END_HND,
          DATAVREF_START_HND, DATAVREF_END_HND,
          DTC1_START_HND, DTC1_END_HND,
          RXCLKCAL_START_HND, RXCLKCAL_CLK_SHIFT_OP, RXCLKCAL_END_HND,
          VALTRAINCENTER_START_HND, VALTRAINCENTER_END_HND,
          RXDESKEW_START_HND, RXDESKEW_EQ_PRESET_HND,
          RXDESKEW_DESKEW_OP, RXDESKEW_DATACENTER_HND,
          RXDESKEW_END_HND, RXDESKEW_TRAIN_ERROR_HND,
          DTC2_START_HND, DTC2_END_HND,
          LINKSPEED_START_HND, LINKSPEED_DONE_HND,
          LINKSPEED_ERROR_REQ, LINKSPEED_PHY_RETRAIN_HND,
          LINKSPEED_EXIT_REPAIR_HND, LINKSPEED_EXIT_SPEED_DEGRADE,
          SPEEDIDLE_SPEED_TRANSITION, SPEEDIDLE_END_HND,
          TXSELFCAL_CALIBRATION, TXSELFCAL_END_HND,
          PHYRETRAIN_STALL_REQ_HND, PHYRETRAIN_RETRAIN_HND,
          PHYRETRAIN_START_REQ_HND,
          VALTRAINVREF_START_HND, VALTRAINVREF_END_HND,
          DATATRAINVREF_START_HND, DATATRAINVREF_END_HND,
          // Active
          LINKINIT_PL_CLK_REQ_HND, LINKINIT_LP_WAKE_REQ_HND,
          LINKINIT_STATE_REQ_HND,
          ACTIVE,
          L1_HND, L1_STATE, EXIT_HS_HND,
          // D2C
          D2C_TX_INIT_HND, D2C_TX_LFSR_CLEAR_HND,
          D2C_TX_PATTERN_GEN, D2C_TX_RESULT_HND, D2C_TX_END_INIT_HND,
          D2C_RX_INIT_HND, D2C_RX_LFSR_CLEAR_HND,
          D2C_RX_PATTERN_GEN, D2C_RX_RESULT_HND,
          D2C_RX_SWEEP_RESULT_HND, D2C_RX_END_INIT_HND
        };
    }

    // Key state transitions
    cp_transitions: coverpoint curr_encoding {
      // Any state → TRAINERROR
      bins to_trainerror[] = (
        RESET, SBINIT_PATTERN_GEN, SBINIT_OUT_OF_RESET, SBINIT_DONE_HND,
        PARAM_CONFIG_HND, CAL_DONE_HND, REPAIRCLK_INIT_HND,
        REPAIRCLK_CLK_PATTERN_GEN, REPAIRCLK_RESULT_HND, REPAIRCLK_DONE_HND,
        REPAIRVAL_INIT_HND, REPAIRVAL_VALID_PATTERN_GEN, REPAIRVAL_RESULT_HND,
        REPAIRVAL_DONE_HND, REVERSAL_INIT_HND, REVERSAL_CLEAR_LOG_HND,
        REVERSAL_PER_LANE_ID_GEN, REVERSAL_RESULT_HND, REVERSAL_APPLY,
        REVERSAL_DONE_HND, REPAIRMB_INIT_HND, REPAIRMB_APPLY_DEGRADE_HND,
        REPAIRMB_DONE_HND, VALVREF_START_HND, VALVREF_END_HND,
        DATAVREF_START_HND, DATAVREF_END_HND, DTC1_START_HND, DTC1_END_HND,
        RXCLKCAL_START_HND, RXCLKCAL_CLK_SHIFT_OP, RXCLKCAL_END_HND,
        VALTRAINCENTER_START_HND, VALTRAINCENTER_END_HND, RXDESKEW_START_HND,
        RXDESKEW_EQ_PRESET_HND, RXDESKEW_DESKEW_OP, RXDESKEW_DATACENTER_HND,
        RXDESKEW_END_HND, DTC2_START_HND, DTC2_END_HND, LINKSPEED_START_HND,
        LINKSPEED_DONE_HND, SPEEDIDLE_SPEED_TRANSITION, SPEEDIDLE_END_HND,
        TXSELFCAL_CALIBRATION, TXSELFCAL_END_HND, PHYRETRAIN_STALL_REQ_HND,
        PHYRETRAIN_RETRAIN_HND, PHYRETRAIN_START_REQ_HND, VALTRAINVREF_START_HND,
        VALTRAINVREF_END_HND, DATATRAINVREF_START_HND, DATATRAINVREF_END_HND,
        REPAIR_START_HND, REPAIR_APPLY_DEGRADE_HND, REPAIR_END_HND,
        D2C_TX_INIT_HND, D2C_TX_LFSR_CLEAR_HND, D2C_TX_PATTERN_GEN,
        D2C_TX_RESULT_HND, D2C_TX_END_INIT_HND, D2C_RX_INIT_HND,
        D2C_RX_LFSR_CLEAR_HND, D2C_RX_PATTERN_GEN, D2C_RX_RESULT_HND,
        D2C_RX_SWEEP_RESULT_HND, D2C_RX_END_INIT_HND
        => TRAINERROR_HND
      );
      // TRAINERROR → RESET
      bins trainerror_to_reset = (TRAINERROR_WAIT => RESET);
      // LINKINIT → ACTIVE
      bins linkinit_to_active = (LINKINIT_STATE_REQ_HND => ACTIVE);
      // ACTIVE → L1
      bins active_to_l1 = (ACTIVE => L1_HND);
    }


  endgroup

  // -------------------------------------------------------------------------
  //  RDI Covergroup
  // -------------------------------------------------------------------------

  covergroup cg_rdi;
    // Empty for now
  endgroup

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------

  function new(string name = "tx_coverage", uvm_component parent = null);
    super.new(name, parent);
    cg_ltsm = new();
    cg_rdi  = new();
    prev_encoding = RESET;
    curr_encoding = RESET;
  endfunction

  // -------------------------------------------------------------------------
  //  Build Phase
  // -------------------------------------------------------------------------

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    rdi_imp  = new("rdi_imp", this);
    ltsm_imp = new("ltsm_imp", this);
  endfunction

  // -------------------------------------------------------------------------
  //  Analysis Writes
  // -------------------------------------------------------------------------

  function void write_ltsm_cov(ltsm_seq_item txn);
    prev_encoding = curr_encoding;
    curr_encoding = txn.encoding;
    curr_lane_map = txn.lane_map;
    cg_ltsm.sample();
  endfunction

  function void write_rdi_cov(rdi_seq_item txn);
    // cg_rdi is currently empty
    // cg_rdi.sample();
  endfunction

  // -------------------------------------------------------------------------
  //  Report Phase
  // -------------------------------------------------------------------------

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("COVERAGE", $sformatf(
      {"\n============================================\n",
      "  COVERAGE SUMMARY\n",
      "  LTSM: %.1f%%\n",
      "  RDI:  %.1f%%\n",
      "============================================"},
      cg_ltsm.get_coverage(), cg_rdi.get_coverage()), UVM_LOW)
  endfunction

endclass : tx_coverage
