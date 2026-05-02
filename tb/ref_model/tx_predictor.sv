//=============================================================================
// File       : tx_predictor.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: Golden predictor — controller model only. Takes LTSM encoding
//              + lane_map and produces expected egress output. Receives
//              transactions from both RDI and LTSM monitors.
//
//              Datapath function stubs (LFSR, B2L, lane repair) define
//              clean interfaces for the collaborator to plug in their
//              implementations.
//=============================================================================

class tx_predictor extends uvm_component;

  `uvm_component_utils(tx_predictor)

  // Analysis imports — receive from RDI and LTSM monitors
  `uvm_analysis_imp_decl(_rdi)
  `uvm_analysis_imp_decl(_ltsm)

  uvm_analysis_imp_rdi  #(rdi_seq_item, tx_predictor)  rdi_imp;
  uvm_analysis_imp_ltsm #(ltsm_seq_item, tx_predictor) ltsm_imp;

  // Analysis port — sends golden egress items to scoreboard
  uvm_analysis_port #(tx2link_item) golden_ap;

  // Internal state
  ltsm_encoding_e current_state;
  logic [2:0]     current_lane_map;

  // Environment config
  tx_env_cfg cfg;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------

  function new(string name = "tx_predictor", uvm_component parent = null);
    super.new(name, parent);
    current_state    = RESET;
    current_lane_map = LANE_MAP_ALL_FUNCTIONAL;
  endfunction

  // -------------------------------------------------------------------------
  //  Build Phase
  // -------------------------------------------------------------------------

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    rdi_imp   = new("rdi_imp", this);
    ltsm_imp  = new("ltsm_imp", this);
    golden_ap = new("golden_ap", this);

    if (!uvm_config_db#(tx_env_cfg)::get(this, "", "tx_env_cfg", cfg))
      `uvm_fatal("PREDICTOR", "Failed to get tx_env_cfg from config_db")
  endfunction

  // -------------------------------------------------------------------------
  //  LTSM Analysis Write — update internal state
  // -------------------------------------------------------------------------

  function void write_ltsm(ltsm_seq_item txn);
    current_state    = txn.encoding;
    current_lane_map = txn.lane_map;
    `uvm_info("PREDICTOR", $sformatf("State updated: %s, lane_map=3'b%03b",
              current_state.name(), current_lane_map), UVM_HIGH)

    // For training/pattern states, generate expected egress output
    if (is_pattern_gen_state(current_state)) begin
      generate_training_pattern();
    end
  endfunction

  // -------------------------------------------------------------------------
  //  RDI Analysis Write — process flit data through pipeline
  // -------------------------------------------------------------------------

  function void write_rdi(rdi_seq_item txn);
    tx2link_item golden;

    // Only process RDI data when in ACTIVE state
    if (current_state != ACTIVE) begin
      `uvm_warning("PREDICTOR", $sformatf(
        "RDI data received in non-ACTIVE state (%s) — ignoring",
        current_state.name()))
      return;
    end

    `uvm_info("PREDICTOR", $sformatf("Processing flit: %s", txn.convert2string()), UVM_HIGH)

    // Create golden egress item
    golden = tx2link_item::type_id::create("golden_egress");
    golden.captured_state = ACTIVE;

    // Run through datapath pipeline stubs
    process_active_flit(txn, golden);

    // Broadcast golden item to scoreboard
    golden_ap.write(golden);
  endfunction

  // -------------------------------------------------------------------------
  //  Datapath Pipeline — Controller Model
  // -------------------------------------------------------------------------
  //
  //  The controller determines which pipeline stages are enabled based
  //  on the current encoding and lane_map. The actual datapath functions
  //  are stubs to be implemented by the collaborator.

  function void process_active_flit(rdi_seq_item rdi_txn, ref tx2link_item golden);
    logic [7:0] byte_data [];
    logic [7:0] scrambled_data [];
    logic [15:0] lane_data [];

    // Stage 1: Get raw byte data from RDI
    byte_data = rdi_txn.data;

    // Stage 2: LFSR Scrambler (stub — collaborator implements)
    scrambled_data = lfsr_scramble(byte_data);

    // Stage 3: Byte-to-Lane Mapping (stub — collaborator implements)
    lane_data = byte_to_lane_map(scrambled_data);

    // Stage 4: Lane Repair Crossbar (stub — collaborator implements)
    lane_data = lane_repair_crossbar(lane_data, current_lane_map);

    // Stage 5: Pack into golden egress item
    // For now, set chunk size based on flit config
    golden.init_arrays(rdi_seq_item::active_flit_size * 4);  // Half-rate: 4 fast clks per byte

    // Placeholder: distribute lane data across UIs
    // The actual serialization logic depends on the collaborator's model
    for (int ui = 0; ui < golden.ui_count; ui++) begin
      if (ui < lane_data.size())
        golden.data_lanes[ui] = lane_data[ui];
      else
        golden.data_lanes[ui] = '0;
    end
  endfunction

  // -------------------------------------------------------------------------
  //  Training Pattern Generator
  // -------------------------------------------------------------------------

  function void generate_training_pattern();
    tx2link_item golden;

    golden = tx2link_item::type_id::create("golden_training");
    golden.captured_state = current_state;

    // Chunk size depends on the state
    case (current_state)
      REPAIRCLK_CLK_PATTERN_GEN:   golden.init_arrays(128);
      REPAIRVAL_VALID_PATTERN_GEN: golden.init_arrays(128);
      REVERSAL_PER_LANE_ID_GEN:    golden.init_arrays(128);
      D2C_TX_PATTERN_GEN:          golden.init_arrays(128);
      D2C_RX_PATTERN_GEN:          golden.init_arrays(128);
      default:                     golden.init_arrays(32);
    endcase

    // Stub: populate expected patterns (collaborator implements)
    populate_training_data(golden);

    golden_ap.write(golden);
  endfunction

  // =========================================================================
  //  DATAPATH FUNCTION STUBS — To be implemented by collaborator
  // =========================================================================
  typedef logic [7:0]  byte_da_t [];
  typedef logic [15:0] word_da_t [];

  // LFSR Scrambler: scramble byte stream
  // Input:  raw bytes from RDI
  // Output: scrambled bytes
  virtual function byte_da_t lfsr_scramble(byte_da_t data);
    // STUB — pass through for now
    return data;
  endfunction

  // Byte-to-Lane Mapping: stripe bytes across 16 lanes
  // Input:  scrambled byte stream
  // Output: lane-mapped data (one entry per lane per UI)
  virtual function word_da_t byte_to_lane_map(byte_da_t data);
    word_da_t result;
    result = new[data.size()];
    // STUB — simple pass-through mapping
    foreach (data[i])
      result[i] = {8'h00, data[i]};
    return result;
  endfunction

  // Lane Repair Crossbar: reroute lanes based on lane_map
  // Input:  lane data + lane_map configuration
  // Output: repaired/degraded lane data
  virtual function word_da_t lane_repair_crossbar(
    word_da_t data,
    logic [2:0] lane_map
  );
    // STUB — pass through for now
    return data;
  endfunction

  // Populate Training Data: fill expected patterns for training states
  virtual function void populate_training_data(ref tx2link_item golden);
    // STUB — fill with zeros for now
    foreach (golden.data_lanes[i])
      golden.data_lanes[i] = '0;
  endfunction

endclass : tx_predictor
