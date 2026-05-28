//=============================================================================
// File       : tx2link_monitor.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: State-aware tx2link assembler monitor. Operates on the fast
//              ui_clk. Receives LTSM state via a TLM analysis FIFO to
//              determine chunk sizes. Samples ALL physical pins (data, clk,
//              valid, track) for the chunk duration, then broadcasts the
//              assembled tx2link_item to the scoreboard.
//
//              This monitor is "blind" — it samples everything regardless
//              of state and tags the chunk with captured_state. The
//              scoreboard is responsible for interpreting which lanes
//              carry valid data vs. expected silence.
//=============================================================================

import tx_controller_modelling_pkg::*;

class tx2link_monitor extends uvm_monitor;

  `uvm_component_utils(tx2link_monitor)

  // Virtual interface handle (fast clock domain)
  virtual tx2link_if tx2link_vif;

  // LTSM interface for state tracking
  virtual ltsm_if ltsm_vif;

  // Analysis port — broadcasts assembled tx2link transactions
  uvm_analysis_port #(tx2link_item) ap;

  // TLM FIFO for receiving LTSM state updates (kept for compatibility)
  uvm_tlm_analysis_fifo #(ltsm_seq_item) ltsm_state_fifo;

  // Current LTSM state (updated from FIFO - kept for compatibility)
  ltsm_encoding_e current_state;

  // Environment configuration
  tx_env_cfg cfg;

  logic [63:0] data_lanes [0:15];

  // tx_valid edge detection
  logic tx_valid_q;
  int counter;
  logic start;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------

  function new(string name = "tx2link_monitor", uvm_component parent = null);
    super.new(name, parent);
    current_state = RESET;
  endfunction

  // -------------------------------------------------------------------------
  //  Build Phase
  // -------------------------------------------------------------------------

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap              = new("ap", this);
    ltsm_state_fifo = new("ltsm_state_fifo", this);

    if (!uvm_config_db#(virtual tx2link_if)::get(this, "", "tx2link_vif", tx2link_vif))
      `uvm_fatal("EGR_MON", "Failed to get tx2link_vif from config_db")

    if (!uvm_config_db#(virtual ltsm_if)::get(this, "", "ltsm_vif", ltsm_vif))
      `uvm_fatal("EGR_MON", "Failed to get ltsm_vif from config_db")

    if (!uvm_config_db#(tx_env_cfg)::get(this, "", "tx_env_cfg", cfg))
      `uvm_fatal("EGR_MON", "Failed to get tx_env_cfg from config_db")

    // Initialize edge detection
    tx_valid_q = 1'b0;
  endfunction

  // -------------------------------------------------------------------------
  //  Run Phase — monitor tx_valid to detect serializer activity
  // -------------------------------------------------------------------------

  task run_phase(uvm_phase phase);
    // Wait for reset de-assertion
    @(negedge tx2link_vif.rst);

    fork
      // LTSM state tracker (keep for compatibility/record keeping)
      forever begin
        ltsm_seq_item state_txn;
        ltsm_state_fifo.get(state_txn);
        current_state = state_txn.encoding;
        `uvm_info("EGR_MON", $sformatf("LTSM state updated: %s", current_state.name()), UVM_HIGH)
      end

      // Sampler - detect tx_valid rising edge (serializer active)
      forever begin

        // Detect rising edge of tx_valid
        if (tx2link_vif.tx_valid) begin
          start = 1;
        end

        sample_and_write();
      end
    join
  endtask

  // -------------------------------------------------------------------------
  //  Sample and Write — sample data when FIFO has data and write to scoreboard
  // -------------------------------------------------------------------------

  task sample_and_write();
    tx2link_item txn;
    int unsigned chunk_size;

    // Use direct encoding from LTSM interface (no TLM FIFO latency)
    chunk_size = get_chunk_size(ltsm_vif.tx_encoding);

    if (chunk_size == 0) begin
      start = 0;
      @(posedge tx2link_vif.ui_clk);
      return;
    end

    if (!start) begin
      @(posedge tx2link_vif.ui_clk);
      return;
    end

    $display("[Monitor] Starting sampling - state=%s (0x%h), chunk_size=%0d",
             ltsm_vif.tx_encoding.name(), ltsm_vif.tx_encoding, chunk_size);

    txn = tx2link_item::type_id::create("egr_mon_txn");
    txn.captured_state = ltsm_vif.tx_encoding;  // Direct from interface
    txn.init_arrays(chunk_size);

    // Sample data
    for (int i = 0; i < chunk_size; i++) begin
      foreach (tx2link_vif.tx_data[j]) begin
        txn.data_lanes[j][i] = tx2link_vif.tx_data[j];
        data_lanes = txn.data_lanes;
      end
      @(posedge tx2link_vif.ui_clk);
      if (!tx2link_vif.tx_valid) begin
         counter++;
         if (counter >= 5) begin
          start = 0;
          return;
         end
      end else counter = 0;
    end

    $display($sformatf("Chunk assembled: state=%s, ui_count=%0d",
              txn.captured_state.name(), txn.ui_count));
    `uvm_info("EGR_MON", $sformatf("Chunk assembled: state=%s, ui_count=%0d",
              txn.captured_state.name(), txn.ui_count), UVM_HIGH)

    // Write to scoreboard
    ap.write(txn);
  endtask

  // -------------------------------------------------------------------------
  //  Get Chunk Size — state-dependent UI count for assembly
  // -------------------------------------------------------------------------
  //
  //  Returns the number of fast-clock cycles to sample for one chunk.
  //  Half-rate: 1 fast clk = 2 UI.
  //
  //  This function will be refined as more state behaviors are defined.

  function int unsigned get_chunk_size(ltsm_encoding_e state);
    case (state)

      // Per-lane ID generation
      REVERSAL_PER_LANE_ID_GEN:
        return 64;

      // Data-to-Clock test pattern generation
      D2C_TX_PATTERN_GEN,
      D2C_RX_PATTERN_GEN:
        return 64;

      // ACTIVE: one flit = NBYTES * 4 fast clocks (8 UI per byte, half-rate)
      ACTIVE:
        return 64;

      // Handshake-only states: no significant tx2link output
      default:
        return 0;

    endcase
  endfunction

endclass : tx2link_monitor
