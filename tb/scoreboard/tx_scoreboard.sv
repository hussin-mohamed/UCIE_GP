//=============================================================================
// File       : tx_scoreboard.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: Data scoreboard — compares golden predictions from the
//              predictor against actual egress monitor observations.
//              Uses two TLM analysis FIFOs for event-based, latency-agnostic
//              comparison of complete transactions.
//=============================================================================

class tx_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(tx_scoreboard)

  // TLM FIFOs — fed by predictor (golden) and egress monitor (actual)
  uvm_tlm_analysis_fifo #(tx2link_item) golden_fifo;
  uvm_tlm_analysis_fifo #(tx2link_item) actual_fifo;

  // Statistics
  int unsigned match_count;
  int unsigned mismatch_count;
  int unsigned total_count;

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
    golden_fifo = new("golden_fifo", this);
    actual_fifo = new("actual_fifo", this);
  endfunction

  // -------------------------------------------------------------------------
  //  Run Phase — blocking comparison loop
  // -------------------------------------------------------------------------

  task run_phase(uvm_phase phase);
    tx2link_item golden, actual;

    forever begin
      // Block until both FIFOs have items
      golden_fifo.get(golden);
      actual_fifo.get(actual);

      total_count++;

      // Compare
      compare_items(golden, actual);
    end
  endtask

  // -------------------------------------------------------------------------
  //  Compare Items
  // -------------------------------------------------------------------------

  function void compare_items(tx2link_item golden, tx2link_item actual);
    bit pass;

    // State metadata must match
    if (golden.captured_state != actual.captured_state) begin
      `uvm_error("SCB", $sformatf(
        "State mismatch: golden=%s, actual=%s",
        golden.captured_state.name(), actual.captured_state.name()))
      mismatch_count++;
      return;
    end

    // UI count must match
    if (golden.ui_count != actual.ui_count) begin
      `uvm_error("SCB", $sformatf(
        "UI count mismatch for state %s: golden=%0d, actual=%0d",
        golden.captured_state.name(), golden.ui_count, actual.ui_count))
      mismatch_count++;
      return;
    end

    // For tri-state states, check that actual outputs are Hi-Z
    if (is_tristate_state(golden.captured_state)) begin
      check_tristate(actual);
      return;
    end

    // Field-level comparison
    pass = golden.compare(actual);

    if (pass) begin
      match_count++;
      `uvm_info("SCB", $sformatf("MATCH [%0d]: state=%s, ui_count=%0d",
                total_count, golden.captured_state.name(), golden.ui_count), UVM_HIGH)
    end else begin
      mismatch_count++;
      `uvm_error("SCB", $sformatf(
        "MISMATCH [%0d]: state=%s\nGolden: %s\nActual: %s",
        total_count, golden.captured_state.name(),
        golden.convert2string(), actual.convert2string()))
    end
  endfunction

  // -------------------------------------------------------------------------
  //  Check Tri-State — verify all outputs are Hi-Z
  // -------------------------------------------------------------------------

  function void check_tristate(tx2link_item actual);
    bit all_z = 1;

    foreach (actual.data_lanes[i]) begin
      if (actual.data_lanes[i] !== 16'hzzzz) begin
        all_z = 0;
        `uvm_error("SCB", $sformatf(
          "Tri-state violation at UI[%0d]: data_lanes=16'h%04h (expected Hi-Z)",
          i, actual.data_lanes[i]))
      end
    end


    if (all_z) begin
      match_count++;
      `uvm_info("SCB", $sformatf("TRISTATE OK [%0d]: state=%s",
                total_count, actual.captured_state.name()), UVM_HIGH)
    end else begin
      mismatch_count++;
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
