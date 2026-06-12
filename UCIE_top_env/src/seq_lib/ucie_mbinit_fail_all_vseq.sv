//=============================================================================
// File       : ucie_mbinit_fail_all_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: virtual sequence that runs ALL failure scenarios inside the MBINIT
//=============================================================================

// Custom PerLaneID sequence override to support dynamically changing the 
// error injection region (LOWER / UPPER / ALL lanes) during reversal tests
class ucie_rmblink_PerLaneID_mega_seq extends rmblink_sanity_PerLaneID_sequence;
  `uvm_object_utils(ucie_rmblink_PerLaneID_mega_seq)

  static error_inject_region_e override_err_region = ERR_INJECT_ALL_LANES;
  static bit use_override = 0;

  function new(string name = "ucie_rmblink_PerLaneID_mega_seq");
    super.new(name);
  endfunction

  virtual function void configure(
    per_lane_scenario_e   _scenario, 
    int                   _num_iterations,
    lane_map_code_t       _lane_map_code = X16_MODE,
    mixed_lane_mode_e     _mixed_mode    = MIXED_ALTERNATING,
    error_inject_region_e _err_region    = ERR_INJECT_ALL_LANES
  );
    super.configure(_scenario, _num_iterations, _lane_map_code, _mixed_mode, 
                    use_override ? override_err_region : _err_region);
  endfunction
endclass : ucie_rmblink_PerLaneID_mega_seq


class ucie_mbinit_fail_all_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_mbinit_fail_all_vseq)

  // Child failure sequence instance
  ucie_mbinit_fail_vseq fail_vseq;

  // Struct for combinations
  typedef struct {
    mbinit_fail_state_e fail_state;
    mbinit_fail_side_e fail_side;
    clk_fail_select_e clk_fail_select;
    lane_map_fail_select_e tx_lane_map;
    lane_map_fail_select_e rx_lane_map;
    bit use_reversal_err_region_override;
    error_inject_region_e reversal_err_region;
  } fail_combo_s;

  // Array of combinations to execute
  fail_combo_s combos[18];

  // Static tracking variables to persist across phase jumps
  static int combo_idx = 0;
  static bit is_recovery = 0;
  static int fail_all_step = 0;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_mbinit_fail_all_vseq");
    super.new(name);
    initialize_combos();
  endfunction

  // -------------------------------------------------------------------------
  //  Initialize combinations
  // -------------------------------------------------------------------------
  function void initialize_combos();
    // CLK Fail RX Side (3 combos)
    combos[0]  = '{fail_state: FAIL_CLK, fail_side: FAIL_SIDE_RX, clk_fail_select: FAIL_CLK_CLKP,  tx_lane_map: LANE_MAP_ALL, rx_lane_map: LANE_MAP_ALL, use_reversal_err_region_override: 0, reversal_err_region: ERR_INJECT_ALL_LANES};
    combos[1]  = '{fail_state: FAIL_CLK, fail_side: FAIL_SIDE_RX, clk_fail_select: FAIL_CLK_CLKN,  tx_lane_map: LANE_MAP_ALL, rx_lane_map: LANE_MAP_ALL, use_reversal_err_region_override: 0, reversal_err_region: ERR_INJECT_ALL_LANES};
    combos[2]  = '{fail_state: FAIL_CLK, fail_side: FAIL_SIDE_RX, clk_fail_select: FAIL_CLK_TRACK, tx_lane_map: LANE_MAP_ALL, rx_lane_map: LANE_MAP_ALL, use_reversal_err_region_override: 0, reversal_err_region: ERR_INJECT_ALL_LANES};
    
    // CLK Fail TX Side (3 combos)
    combos[3]  = '{fail_state: FAIL_CLK, fail_side: FAIL_SIDE_TX, clk_fail_select: FAIL_CLK_CLKP,  tx_lane_map: LANE_MAP_ALL, rx_lane_map: LANE_MAP_ALL, use_reversal_err_region_override: 0, reversal_err_region: ERR_INJECT_ALL_LANES};
    combos[4]  = '{fail_state: FAIL_CLK, fail_side: FAIL_SIDE_TX, clk_fail_select: FAIL_CLK_CLKN,  tx_lane_map: LANE_MAP_ALL, rx_lane_map: LANE_MAP_ALL, use_reversal_err_region_override: 0, reversal_err_region: ERR_INJECT_ALL_LANES};
    combos[5]  = '{fail_state: FAIL_CLK, fail_side: FAIL_SIDE_TX, clk_fail_select: FAIL_CLK_TRACK, tx_lane_map: LANE_MAP_ALL, rx_lane_map: LANE_MAP_ALL, use_reversal_err_region_override: 0, reversal_err_region: ERR_INJECT_ALL_LANES};
    
    // VAL Fail TX and RX Side (2 combos)
    combos[6]  = '{fail_state: FAIL_VAL, fail_side: FAIL_SIDE_TX, clk_fail_select: FAIL_CLK_ALL,   tx_lane_map: LANE_MAP_ALL, rx_lane_map: LANE_MAP_ALL, use_reversal_err_region_override: 0, reversal_err_region: ERR_INJECT_ALL_LANES};
    combos[7]  = '{fail_state: FAIL_VAL, fail_side: FAIL_SIDE_RX, clk_fail_select: FAIL_CLK_ALL,   tx_lane_map: LANE_MAP_ALL, rx_lane_map: LANE_MAP_ALL, use_reversal_err_region_override: 0, reversal_err_region: ERR_INJECT_ALL_LANES};
    
    // REVERSAL Fail RX Side (3 combos: LOWER, UPPER, ALL)
    combos[8]  = '{fail_state: FAIL_REVERSAL, fail_side: FAIL_SIDE_RX, clk_fail_select: FAIL_CLK_ALL, tx_lane_map: LANE_MAP_ALL, rx_lane_map: LANE_MAP_LOWER, use_reversal_err_region_override: 1, reversal_err_region: ERR_INJECT_LOWER_LANES_ONLY};
    combos[9]  = '{fail_state: FAIL_REVERSAL, fail_side: FAIL_SIDE_RX, clk_fail_select: FAIL_CLK_ALL, tx_lane_map: LANE_MAP_ALL, rx_lane_map: LANE_MAP_UPPER, use_reversal_err_region_override: 1, reversal_err_region: ERR_INJECT_UPPER_LANES_ONLY};
    combos[10] = '{fail_state: FAIL_REVERSAL, fail_side: FAIL_SIDE_RX, clk_fail_select: FAIL_CLK_ALL, tx_lane_map: LANE_MAP_ALL, rx_lane_map: LANE_MAP_ALL,   use_reversal_err_region_override: 1, reversal_err_region: ERR_INJECT_ALL_LANES};
    
    // REPAIR Fail TX Side (3 combos: UPPER, LOWER, ALL)
    combos[11] = '{fail_state: FAIL_REPAIR, fail_side: FAIL_SIDE_TX, clk_fail_select: FAIL_CLK_ALL, tx_lane_map: LANE_MAP_UPPER, rx_lane_map: LANE_MAP_ALL, use_reversal_err_region_override: 0, reversal_err_region: ERR_INJECT_ALL_LANES};
    combos[12] = '{fail_state: FAIL_REPAIR, fail_side: FAIL_SIDE_TX, clk_fail_select: FAIL_CLK_ALL, tx_lane_map: LANE_MAP_LOWER, rx_lane_map: LANE_MAP_ALL, use_reversal_err_region_override: 0, reversal_err_region: ERR_INJECT_ALL_LANES};
    combos[13] = '{fail_state: FAIL_REPAIR, fail_side: FAIL_SIDE_TX, clk_fail_select: FAIL_CLK_ALL, tx_lane_map: LANE_MAP_ALL,   rx_lane_map: LANE_MAP_ALL, use_reversal_err_region_override: 0, reversal_err_region: ERR_INJECT_ALL_LANES};
    
    // REPAIR Fail RX Side (3 combos: UPPER, LOWER, ALL)
    combos[14] = '{fail_state: FAIL_REPAIR, fail_side: FAIL_SIDE_RX, clk_fail_select: FAIL_CLK_ALL, tx_lane_map: LANE_MAP_ALL, rx_lane_map: LANE_MAP_UPPER, use_reversal_err_region_override: 0, reversal_err_region: ERR_INJECT_ALL_LANES};
    combos[15] = '{fail_state: FAIL_REPAIR, fail_side: FAIL_SIDE_RX, clk_fail_select: FAIL_CLK_ALL, tx_lane_map: LANE_MAP_ALL, rx_lane_map: LANE_MAP_LOWER, use_reversal_err_region_override: 0, reversal_err_region: ERR_INJECT_ALL_LANES};
    combos[16] = '{fail_state: FAIL_REPAIR, fail_side: FAIL_SIDE_RX, clk_fail_select: FAIL_CLK_ALL, tx_lane_map: LANE_MAP_ALL, rx_lane_map: LANE_MAP_ALL,   use_reversal_err_region_override: 0, reversal_err_region: ERR_INJECT_ALL_LANES};
    
    // FAIL_ALL exhaustive (1 combo)
    combos[17] = '{fail_state: FAIL_ALL, fail_side: FAIL_SIDE_RX, clk_fail_select: FAIL_CLK_ALL, tx_lane_map: LANE_MAP_ALL, rx_lane_map: LANE_MAP_ALL, use_reversal_err_region_override: 0, reversal_err_region: ERR_INJECT_ALL_LANES};
  endfunction : initialize_combos

  // -------------------------------------------------------------------------
  //  Pre-body Task
  // -------------------------------------------------------------------------
  virtual task pre_body();
    super.pre_body();
    fail_vseq = ucie_mbinit_fail_vseq::type_id::create("fail_vseq");
  endtask : pre_body

  // -------------------------------------------------------------------------
  //  Inject Task
  // -------------------------------------------------------------------------
  task run_inject(fail_combo_s combo);
    `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("=== [INJECT] Combo %0d/17: State=%s, Side=%s, ClkSel=%s, TxMap=%s, RxMap=%s ===", 
              combo_idx, combo.fail_state.name(), combo.fail_side.name(), 
              combo.clk_fail_select.name(), combo.tx_lane_map.name(), combo.rx_lane_map.name()), UVM_LOW)

    // Reversal override handling
    if (combo.use_reversal_err_region_override) begin
      `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Overriding Reversal Err Region to: %s", combo.reversal_err_region.name()), UVM_LOW)
      ucie_rmblink_PerLaneID_mega_seq::override_err_region = combo.reversal_err_region;
      ucie_rmblink_PerLaneID_mega_seq::use_override = 1;
    end else begin
      ucie_rmblink_PerLaneID_mega_seq::use_override = 0;
    end

    // Prepare child's trainerr_cnt to 0 for injection
    TRAINERROR_vseq.reset_trainerr_cnt();
    
    // Configure and start child sequence for injection
    fail_vseq.configure(combo.fail_state, combo.fail_side, combo.clk_fail_select, combo.tx_lane_map, combo.rx_lane_map);
    
    // Set is_recovery to 1 BEFORE starting, since this thread will be aborted by phase jump
    is_recovery = 1;
    
    fail_vseq.start(p_sequencer);
    // Phase jump occurs here (TrainError fired)
  endtask : run_inject

  // -------------------------------------------------------------------------
  //  Start Next Inject Task
  // -------------------------------------------------------------------------
  task start_next_inject();
    fail_combo_s next_combo;
    if (combo_idx >= 18) begin
      `uvm_info("MBINIT_FAIL_ALL_VSEQ", "==================================================", UVM_LOW)
      `uvm_info("MBINIT_FAIL_ALL_VSEQ", "   ALL FAILURE COMBINATIONS PASSED SUCCESSFULLY!  ", UVM_LOW)
      `uvm_info("MBINIT_FAIL_ALL_VSEQ", "==================================================", UVM_LOW)
      return;
    end
    
    next_combo = combos[combo_idx];
    
    if (next_combo.fail_state == FAIL_ALL) begin
      `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("=== [INJECT] FAIL_ALL step %0d/32 ===", fail_all_step), UVM_LOW)
      TRAINERROR_vseq.trainerr_cnt = fail_all_step;
      fail_vseq.configure(next_combo.fail_state, next_combo.fail_side, next_combo.clk_fail_select, next_combo.tx_lane_map, next_combo.rx_lane_map);
      fail_all_step++;
      fail_vseq.start(p_sequencer);
    end else begin
      run_inject(next_combo);
    end
  endtask : start_next_inject

  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();
    fail_combo_s combo;

    // Check if we have executed all combinations
    if (combo_idx >= 18) begin
      `uvm_info("MBINIT_FAIL_ALL_VSEQ", "==================================================", UVM_LOW)
      `uvm_info("MBINIT_FAIL_ALL_VSEQ", "   ALL FAILURE COMBINATIONS PASSED SUCCESSFULLY!  ", UVM_LOW)
      `uvm_info("MBINIT_FAIL_ALL_VSEQ", "==================================================", UVM_LOW)
      return;
    end

    combo = combos[combo_idx];

    // Handle FAIL_ALL state
    if (combo.fail_state == FAIL_ALL) begin
      `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("=== [FAIL_ALL Phase Restart] step %0d/32 ===", fail_all_step), UVM_LOW)
      
      if (fail_all_step < 32) begin
        // Set trainerr_cnt for the child sequence to target this specific step
        TRAINERROR_vseq.trainerr_cnt = fail_all_step;
        
        // Configure and start child sequence for injection
        fail_vseq.configure(combo.fail_state, combo.fail_side, combo.clk_fail_select, combo.tx_lane_map, combo.rx_lane_map);
        
        // Increment step BEFORE starting, since this thread will be killed by phase jump
        fail_all_step++;
        
        fail_vseq.start(p_sequencer);
        // Phase jump occurs here (TrainError fired)
      end else begin
        // Recovery phase of FAIL_ALL
        `uvm_info("MBINIT_FAIL_ALL_VSEQ", "=== [RECOVER] FAIL_ALL Final Recovery (step 32) ===", UVM_LOW)
        TRAINERROR_vseq.trainerr_cnt = 32;
        fail_vseq.configure(combo.fail_state, combo.fail_side, combo.clk_fail_select, combo.tx_lane_map, combo.rx_lane_map);
        fail_vseq.start(p_sequencer);
        
        // Once recovery completes, advance to next combo
        combo_idx++;
        is_recovery = 0;
        fail_all_step = 0;
        
        // Trigger a reset to transition the RTL back to RESET state and cause a UVM phase jump
        begin
          reset_seq rst_seq;
          rst_seq = reset_seq::type_id::create("rst_seq");
          rst_seq.start(tx_rdi_seqr);
        end
      end
    end
    
    // Handle standard failure states
    else begin
      if (!is_recovery) begin
        // First run of the test, start with combo 0 inject
        run_inject(combo);
      end else begin
        // Recovery phase
        `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("=== [RECOVER] Combo %0d/17: State=%s, Side=%s ===", 
                  combo_idx, combo.fail_state.name(), combo.fail_side.name()), UVM_LOW)
        
        // Disable reversal override
        ucie_rmblink_PerLaneID_mega_seq::use_override = 0;
        
        mbinit_vseq.start(p_sequencer);
        
        // Once recovery completes, advance to next combo
        combo_idx++;
        is_recovery = 0;
        
        // Trigger a reset to transition the RTL back to RESET state and cause a UVM phase jump
        begin
          reset_seq rst_seq;
          rst_seq = reset_seq::type_id::create("rst_seq");
          rst_seq.start(tx_rdi_seqr);
        end
      end
    end
  endtask : body

endclass : ucie_mbinit_fail_all_vseq
