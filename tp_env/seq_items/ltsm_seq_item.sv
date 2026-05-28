//=============================================================================
// File       : ltsm_seq_item.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: LTSM sequence item with per-group state definitions.
//              Each group has:
//                - A static ordered state queue (for sequential traversal)
//                - A constraint (for random selection within the group)
//              The sequence selects a group via set_group() and controls
//              sequential vs random via is_random flag.
//=============================================================================

class ltsm_seq_item extends uvm_sequence_item;

  // -------------------------------------------------------------------------
  //  Request Fields
  // -------------------------------------------------------------------------

  // Target LTSM encoding — what the driver will put on the interface
  rand ltsm_encoding_e encoding;

  // Lane map configuration (only relevant for REPAIRMB/REPAIR states)
  rand logic [2:0] lane_map;

  // Inter-state delay in clock cycles (used by driver for non-handshake states)
  rand int unsigned delay;

  // -------------------------------------------------------------------------
  //  Group Control (non-rand — set by sequence)
  // -------------------------------------------------------------------------

  ltsm_state_group_e active_group = GROUP_HAPPY_PATH;

  // -------------------------------------------------------------------------
  //  UVM Registration
  // -------------------------------------------------------------------------

  `uvm_object_utils(ltsm_seq_item)

  // -------------------------------------------------------------------------
  //  Static Ordered State Queues — one per group
  //  These define the sequential walk order. Duplicates allowed (e.g. D2C_TX_INIT_HND).
  // -------------------------------------------------------------------------

  static ltsm_encoding_e happy_path_states[$] = '{
    // Init phase
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
    REPAIRMB_INIT_HND, D2C_TX_INIT_HND,
    D2C_TX_LFSR_CLEAR_HND, D2C_TX_PATTERN_GEN,
    D2C_TX_RESULT_HND, D2C_TX_END_INIT_HND,
    REPAIRMB_APPLY_DEGRADE_HND, REPAIRMB_DONE_HND,
    // Train phase
    VALVREF_START_HND,
    D2C_RX_INIT_HND, D2C_RX_LFSR_CLEAR_HND, D2C_RX_PATTERN_GEN,
    D2C_RX_RESULT_HND, D2C_RX_SWEEP_RESULT_HND, D2C_RX_END_INIT_HND,
    VALVREF_END_HND,
    DATAVREF_START_HND,
    D2C_RX_INIT_HND, D2C_RX_LFSR_CLEAR_HND, D2C_RX_PATTERN_GEN,
    D2C_RX_RESULT_HND, D2C_RX_SWEEP_RESULT_HND, D2C_RX_END_INIT_HND,
    DATAVREF_END_HND,
    DTC1_START_HND,
    D2C_TX_INIT_HND, D2C_TX_LFSR_CLEAR_HND, D2C_TX_PATTERN_GEN,
    D2C_TX_RESULT_HND, D2C_TX_END_INIT_HND,
    DTC1_END_HND,
    RXCLKCAL_START_HND, RXCLKCAL_CLK_SHIFT_OP, RXCLKCAL_END_HND,
    VALTRAINCENTER_START_HND,
    D2C_TX_INIT_HND, D2C_TX_LFSR_CLEAR_HND, D2C_TX_PATTERN_GEN,
    D2C_TX_RESULT_HND, D2C_TX_END_INIT_HND,
    VALTRAINCENTER_END_HND,
    VALTRAINVREF_START_HND,
    D2C_RX_INIT_HND, D2C_RX_LFSR_CLEAR_HND, D2C_RX_PATTERN_GEN,
    D2C_RX_RESULT_HND, D2C_RX_SWEEP_RESULT_HND, D2C_RX_END_INIT_HND,
    VALTRAINVREF_END_HND,
    RXDESKEW_START_HND, RXDESKEW_EQ_PRESET_HND,
    RXDESKEW_DESKEW_OP, RXDESKEW_END_HND,
    DTC2_START_HND,
    D2C_TX_INIT_HND, D2C_TX_LFSR_CLEAR_HND, D2C_TX_PATTERN_GEN,
    D2C_TX_RESULT_HND, D2C_TX_END_INIT_HND,
    DTC2_END_HND,
    DATATRAINVREF_START_HND,
    D2C_RX_INIT_HND, D2C_RX_LFSR_CLEAR_HND, D2C_RX_PATTERN_GEN,
    D2C_RX_RESULT_HND, D2C_RX_SWEEP_RESULT_HND, D2C_RX_END_INIT_HND,
    DATATRAINVREF_END_HND,
    LINKSPEED_START_HND, D2C_TX_INIT_HND, LINKSPEED_DONE_HND,
    // Active phase
    LINKINIT_PL_CLK_REQ_HND, LINKINIT_LP_WAKE_REQ_HND,
    LINKINIT_STATE_REQ_HND,
    ACTIVE
  };

  static ltsm_encoding_e pattern_gen_states[$] = '{
    REPAIRCLK_CLK_PATTERN_GEN,
    REPAIRVAL_VALID_PATTERN_GEN,
    REVERSAL_PER_LANE_ID_GEN,
    D2C_TX_PATTERN_GEN,
    D2C_RX_PATTERN_GEN
  };

  static ltsm_encoding_e train_error_states[$] = '{
    TRAINERROR_HND,
    TRAINERROR_WAIT
  };

  static ltsm_encoding_e tristate_states[$] = '{
    RESET,
    SBINIT_PATTERN_GEN, SBINIT_OUT_OF_RESET, SBINIT_DONE_HND,
    PARAM_CONFIG_HND,
    CAL_DONE_HND
  };

  static ltsm_encoding_e active_states[$] = '{
    LINKINIT_PL_CLK_REQ_HND, LINKINIT_LP_WAKE_REQ_HND,
    LINKINIT_STATE_REQ_HND,
    ACTIVE,
    L1_HND, L1_STATE, EXIT_HS_HND
  };

  // -------------------------------------------------------------------------
  //  Constraints
  // -------------------------------------------------------------------------

  // Lane map: only meaningful for REPAIRMB and REPAIR states
  constraint c_lane_map_valid {
    if (!(encoding inside {
      REPAIRMB_INIT_HND, REPAIRMB_APPLY_DEGRADE_HND, REPAIRMB_DONE_HND,
      REPAIR_START_HND, REPAIR_APPLY_DEGRADE_HND, REPAIR_END_HND
    })) {
      soft lane_map == LANE_MAP_ALL_FUNCTIONAL;
    }

    soft lane_map inside {
      LANE_MAP_DEGRADE_NOT_POSSIBLE,
      LANE_MAP_LANES_0_TO_7,
      LANE_MAP_LANES_8_TO_15,
      LANE_MAP_ALL_FUNCTIONAL
    };
  }

  static rand bit repair;
  static bit repair_old;
  constraint c_lane_map_all_func {
    solve repair before lane_map;
    if (encoding == REPAIRMB_APPLY_DEGRADE_HND) {
      repair == 1;
    } else {
      repair == repair_old;
    }

    if (repair) {
      lane_map == LANE_MAP_LANES_8_TO_15;
    } else {
      lane_map == LANE_MAP_ALL_FUNCTIONAL;
    }
  }

  function void post_randomize();
    repair_old = repair;
  endfunction

  // Reasonable inter-state delay
  constraint c_delay {
    delay inside {[1:20]};
  }

  // ---- Group constraints (only one active at a time via set_group) ----

  constraint c_grp_happy_path {
    encoding inside {
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
      REPAIRMB_INIT_HND, REPAIRMB_APPLY_DEGRADE_HND, REPAIRMB_DONE_HND,
      D2C_TX_INIT_HND, D2C_TX_LFSR_CLEAR_HND, D2C_TX_PATTERN_GEN,
      D2C_TX_RESULT_HND, D2C_TX_END_INIT_HND,
      D2C_RX_INIT_HND, D2C_RX_LFSR_CLEAR_HND, D2C_RX_PATTERN_GEN,
      D2C_RX_RESULT_HND, D2C_RX_SWEEP_RESULT_HND, D2C_RX_END_INIT_HND,
      VALVREF_START_HND, VALVREF_END_HND,
      DATAVREF_START_HND, DATAVREF_END_HND,
      DTC1_START_HND, DTC1_END_HND,
      RXCLKCAL_START_HND, RXCLKCAL_CLK_SHIFT_OP, RXCLKCAL_END_HND,
      VALTRAINCENTER_START_HND, VALTRAINCENTER_END_HND,
      VALTRAINVREF_START_HND, VALTRAINVREF_END_HND,
      RXDESKEW_START_HND, RXDESKEW_EQ_PRESET_HND,
      RXDESKEW_DESKEW_OP, RXDESKEW_DATACENTER_HND, RXDESKEW_END_HND,
      DTC2_START_HND, DTC2_END_HND,
      DATATRAINVREF_START_HND, DATATRAINVREF_END_HND,
      LINKSPEED_START_HND, LINKSPEED_DONE_HND,
      LINKINIT_PL_CLK_REQ_HND, LINKINIT_LP_WAKE_REQ_HND,
      LINKINIT_STATE_REQ_HND,
      ACTIVE
    };
  }

  constraint c_grp_pattern_gen {
    encoding inside {
      REPAIRCLK_CLK_PATTERN_GEN,
      REPAIRVAL_VALID_PATTERN_GEN,
      REVERSAL_PER_LANE_ID_GEN,
      D2C_TX_PATTERN_GEN,
      D2C_RX_PATTERN_GEN
    };
  }

  constraint c_grp_train_error {
    encoding inside {
      TRAINERROR_HND,
      TRAINERROR_WAIT
    };
  }

  constraint c_grp_tristate {
    encoding inside {
      RESET,
      SBINIT_PATTERN_GEN, SBINIT_OUT_OF_RESET, SBINIT_DONE_HND,
      PARAM_CONFIG_HND,
      CAL_DONE_HND
    };
  }

  constraint c_grp_active {
    encoding inside {
      LINKINIT_PL_CLK_REQ_HND, LINKINIT_LP_WAKE_REQ_HND,
      LINKINIT_STATE_REQ_HND,
      ACTIVE,
      L1_HND, L1_STATE, EXIT_HS_HND
    };
  }

  // -------------------------------------------------------------------------
  //  Constructor — all group constraints start OFF
  // -------------------------------------------------------------------------

  function new(string name = "ltsm_seq_item");
    super.new(name);
    c_grp_happy_path.constraint_mode(0);
    c_grp_pattern_gen.constraint_mode(0);
    c_grp_train_error.constraint_mode(0);
    c_grp_tristate.constraint_mode(0);
    c_grp_active.constraint_mode(0);
  endfunction

  // -------------------------------------------------------------------------
  //  set_group — enables exactly one group constraint
  // -------------------------------------------------------------------------

  function void set_group(ltsm_state_group_e grp);
    active_group = grp;
    c_grp_happy_path.constraint_mode(grp == GROUP_HAPPY_PATH);
    c_grp_pattern_gen.constraint_mode(grp == GROUP_PATTERN_GEN);
    c_grp_train_error.constraint_mode(grp == GROUP_TRAIN_ERROR);
    c_grp_tristate.constraint_mode(grp == GROUP_TRISTATE);
    c_grp_active.constraint_mode(grp == GROUP_ACTIVE);
  endfunction

  // -------------------------------------------------------------------------
  //  get_group_states — returns the ordered state queue for a group
  // -------------------------------------------------------------------------

  static function void get_group_states(ltsm_state_group_e grp,
                                        ref ltsm_encoding_e states[$]);
    case (grp)
      GROUP_HAPPY_PATH:  states = happy_path_states;
      GROUP_PATTERN_GEN: states = pattern_gen_states;
      GROUP_TRAIN_ERROR: states = train_error_states;
      GROUP_TRISTATE:    states = tristate_states;
      GROUP_ACTIVE:      states = active_states;
    endcase
  endfunction

  // -------------------------------------------------------------------------
  //  Custom Methods
  // -------------------------------------------------------------------------

  function string convert2string();
    return $sformatf("LTSM_SEQ_ITEM: encoding=%0s (9'h%03h), lane_map=3'b%03b, delay=%0d, group=%0s",
                     encoding.name(), encoding, lane_map, delay, active_group.name());
  endfunction

  function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_string("summary", convert2string());
  endfunction

endclass : ltsm_seq_item
