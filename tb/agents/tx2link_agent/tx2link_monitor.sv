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

class tx2link_monitor extends uvm_monitor;

  `uvm_component_utils(tx2link_monitor)

  // Virtual interface handle (fast clock domain)
  virtual tx2link_if tx2link_vif;

  // Analysis port — broadcasts assembled tx2link transactions
  uvm_analysis_port #(tx2link_item) ap;

  // TLM FIFO for receiving LTSM state updates (connected by env)
  uvm_tlm_analysis_fifo #(ltsm_seq_item) ltsm_state_fifo;

  // Current LTSM state (updated from FIFO)
  ltsm_encoding_e current_state;

  // Environment configuration
  tx_env_cfg cfg;

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

    if (!uvm_config_db#(tx_env_cfg)::get(this, "", "tx_env_cfg", cfg))
      `uvm_fatal("EGR_MON", "Failed to get tx_env_cfg from config_db")
  endfunction

  // -------------------------------------------------------------------------
  //  Run Phase — fork state tracker and sampling loop
  // -------------------------------------------------------------------------

  task run_phase(uvm_phase phase);
    // Wait for reset de-assertion
    @(posedge tx2link_vif.rst_n);

    fork
      track_ltsm_state();
      sample_loop();
    join
  endtask

  // -------------------------------------------------------------------------
  //  LTSM State Tracker — continuously reads FIFO for state updates
  // -------------------------------------------------------------------------

  task track_ltsm_state();
    ltsm_seq_item state_txn;

    forever begin
      ltsm_state_fifo.get(state_txn);
      current_state = state_txn.encoding;
      `uvm_info("EGR_MON", $sformatf("LTSM state updated: %s", current_state.name()), UVM_HIGH)
    end
  endtask

  // -------------------------------------------------------------------------
  //  Sample Loop — assemble chunks based on current LTSM state
  // -------------------------------------------------------------------------

  task sample_loop();
    tx2link_item txn;
    int unsigned chunk_size;

    forever begin
      // Determine chunk size based on current state
      chunk_size = get_chunk_size(current_state);

      if (chunk_size == 0) begin
        // For states with no defined output (e.g., handshake-only),
        // sample a small window and check for silence
        @(posedge tx2link_vif.ui_clk);
        continue;
      end

      // Create and initialize the transaction
      txn = tx2link_item::type_id::create("egr_mon_txn");
      txn.captured_state = current_state;
      txn.init_arrays(chunk_size);

      // Blind sampling loop: sample ALL pins for chunk_size fast-clock cycles
      for (int i = 0; i < chunk_size; i++) begin
        @(posedge tx2link_vif.ui_clk);
        txn.data_lanes[i]  = tx2link_vif.tx_data;
      end

      `uvm_info("EGR_MON", $sformatf("Chunk assembled: state=%s, ui_count=%0d",
                txn.captured_state.name(), txn.ui_count), UVM_HIGH)

      // Broadcast to scoreboard
      ap.write(txn);
    end
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
