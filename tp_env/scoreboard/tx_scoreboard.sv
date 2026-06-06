//=============================================================================
// File       : tx_scoreboard.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: Data scoreboard — compares golden predictions from the
//              predictor against actual egress monitor observations.
//              Uses two TLM analysis FIFOs for event-based, latency-agnostic
//              comparison of complete transactions.
//=============================================================================

import tx_controller_modelling_pkg::*;

class tx_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(tx_scoreboard)

  // TLM FIFOs — fed by predictor (golden) and egress monitor (actual)
  uvm_tlm_analysis_fifo #(tx2link_item) actual_fifo;
  uvm_tlm_analysis_fifo #(rdi_seq_item) rdi_fifo;
  uvm_tlm_analysis_fifo #(ltsm_seq_item) ltsm_fifo;

  // Statistics
  int unsigned match_count;
  int unsigned mismatch_count;
  int unsigned total_count;

    parameter NBYTES = 256;
    parameter DATA_WIDTH = 64;         //It defines the width of the data input & output ports
    parameter LANES_NUMBER = 16;

  logic [DATA_WIDTH-1:0] golden_o_lane [0:LANES_NUMBER-1];
  logic [DATA_WIDTH-1:0] actual_o_lane [0:LANES_NUMBER-1];

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------

  function new(string name = "tx_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    match_count    = 0;
    mismatch_count = 0;
    total_count    = 0;
  endfunction

  // -------------------------------------------------------------------------
  //  Build Phase
  // -------------------------------------------------------------------------

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    actual_fifo = new("actual_fifo", this);
    rdi_fifo = new("rdi_fifo", this);
    ltsm_fifo = new("ltsm_fifo", this);

    // Initialize controller state instances
    tx_controller_state_init(controller_state_ltsm);
    tx_controller_state_init(controller_state_cmp);
  endfunction

  // Internal state tracking for context
  ltsm_encoding_e latest_state;
  logic [2:0]     latest_lane_map;

  // Controller state instances for isolated FSM state
  tx_controller_state_t controller_state_ltsm;  // For LTSSM tracking thread
  tx_controller_state_t controller_state_cmp;   // For comparison thread

  // -------------------------------------------------------------------------
  //  Run Phase — decoupled comparison loop
  // -------------------------------------------------------------------------

  task run_phase(uvm_phase phase);
    tx2link_item  actual;
    rdi_seq_item  rdi;
    ltsm_seq_item ltsm;

    fork
      // Thread 1: Continuously update the local state knowledge
      // This ensures we always know the latest configuration (like lane_map)
      forever begin
        ltsm_fifo.get(ltsm);
        latest_state    = ltsm.encoding;
        latest_lane_map = ltsm.lane_map;

        tx_predictor::predict(
          controller_state_ltsm,
          1,
          0,
          0,
          0,
          latest_state,
          latest_lane_map,
          1,
          {default:0},
          golden_o_lane
        );

      end

      // Thread 2: Main comparison loop driven by egress (actual) data
      forever begin
        // 1. Wait for a chunk from the pins (TX2LINK)
        actual_fifo.get(actual);
        total_count++;


        // 2. Decide if we need RDI data based on the state captured by the monitor
        if (actual.captured_state == ACTIVE) begin
          // Only block on RDI if the monitor tagged this chunk as ACTIVE
          rdi_fifo.get(rdi);
        end else begin
          // For non-ACTIVE states, RDI data is irrelevant for the predictor
          rdi = rdi_seq_item::type_id::create("dummy_rdi");
          rdi.data = new[NBYTES]; // Prevent "Assignment of 0 elems" fatal error
        end

        `uvm_info("SCB", $sformatf("Comparing chunk: state=%s, ui_count=%0d",
                  actual.captured_state.name(), actual.ui_count), UVM_MEDIUM)

        // Sync state from tracking thread before comparison
        tx_controller_state_copy(controller_state_cmp, controller_state_ltsm);

        // 3. Run the predictor using the state CAPTURED by the monitor
        tx_predictor::predict(
          controller_state_cmp,
          1,
          rdi.lp_valid,
          rdi.lp_irdy,
          rdi.pl_trdy,
          actual.captured_state,
          latest_lane_map,
          0,
          rdi.data,
          golden_o_lane
        );

        // 4. Compare directly
        compare_items(golden_o_lane, actual);
        actual_o_lane = actual.data_lanes;
      end
    join
  endtask

  function void compare_items(logic [DATA_WIDTH-1:0] golden [0:LANES_NUMBER-1], tx2link_item actual);
    bit is_match;

    // Element-wise comparison (=== for Hi-Z support)
    // Only compare up to actual.ui_count
    is_match = 1;
    foreach (golden[i]) begin
      for (int j = 0; j < actual.ui_count; j++) begin
        if (golden[i][j] !== actual.data_lanes[i][j]) begin
          is_match = 0;
          break;
        end
      end
      if (!is_match) break;
    end

    if (is_match) begin
      match_count++;
      `uvm_info("SCB", $sformatf("MATCH [%0d]: ui_count=%0d",
                total_count, actual.ui_count), UVM_HIGH)
    end else begin
      mismatch_count++;
      `uvm_error("SCB", $sformatf(
        "MISMATCH [%0d]:\nActual: %s",
        total_count, actual.convert2string()))
    end
  endfunction

  // -------------------------------------------------------------------------
  //  Report Phase — final summary
  // -------------------------------------------------------------------------

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCB", $sformatf(
      {"\n============================================\n",
      "  SCOREBOARD SUMMARY\n",
      "  Total:      %0d\n",
      "  Matches:    %0d\n",
      "  Mismatches: %0d\n",
      "============================================"},
      total_count, match_count, mismatch_count), UVM_LOW)

    if (mismatch_count > 0)
      `uvm_error("SCB", $sformatf("TEST FAILED: %0d mismatches detected", mismatch_count))
    else
      `uvm_info("SCB", "TEST PASSED: All comparisons matched", UVM_LOW)
  endfunction

endclass : tx_scoreboard
