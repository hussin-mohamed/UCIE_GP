 //=============================================================================
// File       : tx_env.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: Top-level UVM environment — instantiates all agents,
//              predictor, scoreboard, coverage, and TLM analysis FIFOs.
//              Wires everything together including cross-agent reactive
//              paths via TLM FIFOs and the sqr_pool sequencer container.
//=============================================================================

class tx_env extends uvm_env;

  `uvm_component_utils(tx_env)

  // -------------------------------------------------------------------------
  //  Sub-components
  // -------------------------------------------------------------------------

  // Agents
  rdi_agent     rdi_agt;
  ltsm_agent    ltsm_agt;
  tx2link_agent  tx2link_agt;

  // Reference model & checking
  tx_scoreboard  scoreboard;
  tx_coverage    coverage;

  // Configuration
  tx_env_cfg     cfg;

  // TLM Analysis FIFOs for cross-agent reactivity
  // FIFO 1: LTSM state → RDI sequence (gates flit generation on ACTIVE)
  uvm_tlm_analysis_fifo #(ltsm_seq_item) ltsm_to_rdi_fifo;

  // FIFO 2: LTSM state → tx2link monitor (determines chunk sizes)
  // Note: tx2link_monitor has its own internal FIFO — we connect LTSM ap to it

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------

  function new(string name = "tx_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  //  Build Phase
  // -------------------------------------------------------------------------

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Retrieve environment config
    if (!uvm_config_db#(tx_env_cfg)::get(this, "", "tx_env_cfg", cfg))
      `uvm_fatal("TX_ENV", "Failed to get tx_env_cfg from config_db")

    // Propagate config to all children
    uvm_config_db#(tx_env_cfg)::set(this, "*", "tx_env_cfg", cfg);

    // Propagate virtual interfaces to agents
    uvm_config_db#(virtual rdi_if)::set(this, "rdi_agt.*", "rdi_vif", cfg.rdi_vif);
    uvm_config_db#(virtual ltsm_if)::set(this, "ltsm_agt.*", "ltsm_vif", cfg.ltsm_vif);
    uvm_config_db#(virtual tx2link_if)::set(this, "tx2link_agt.*", "tx2link_vif", cfg.tx2link_vif);

    // Instantiate agents
    rdi_agt    = rdi_agent::type_id::create("rdi_agt", this);
    ltsm_agt   = ltsm_agent::type_id::create("ltsm_agt", this);
    tx2link_agt = tx2link_agent::type_id::create("tx2link_agt", this);

    // Instantiate reference model & checking
    scoreboard = tx_scoreboard::type_id::create("scoreboard", this);
    coverage   = tx_coverage::type_id::create("coverage", this);

    // Instantiate TLM FIFOs
    ltsm_to_rdi_fifo = new("ltsm_to_rdi_fifo", this);
  endfunction

  // -------------------------------------------------------------------------
  //  Connect Phase — wire all TLM connections
  // -------------------------------------------------------------------------

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // ---- LTSM Monitor Analysis Port Connections ----

    // 1. LTSM Monitor → RDI Sequence FIFO (cross-agent reactivity)
    ltsm_agt.mon.ap.connect(ltsm_to_rdi_fifo.analysis_export);

    // 2. LTSM Monitor → tx2link Monitor's internal FIFO
    ltsm_agt.mon.ap.connect(tx2link_agt.mon.ltsm_state_fifo.analysis_export);

    // 4. LTSM Monitor → Coverage
    ltsm_agt.mon.ap.connect(coverage.ltsm_imp);

    // 6. RDI Monitor → Coverage
    rdi_agt.mon.ap.connect(coverage.rdi_imp);

    // ---- tx2link Monitor → Scoreboard ----

    // 8. tx2link Monitor actual output → Scoreboard actual FIFO
    tx2link_agt.mon.ap.connect(scoreboard.actual_fifo.analysis_export);
    rdi_agt.mon.ap.connect(scoreboard.rdi_fifo.analysis_export);
    ltsm_agt.mon.ap.connect(scoreboard.ltsm_fifo.analysis_export);

    // ---- Sequencer Container Registration ----

    // Register sequencers in the global sqr_pool
    if (cfg.rdi_agent_mode == UVM_ACTIVE)
      sqr_pool::get_global_pool().add("rdi_sqr", rdi_agt.get_sequencer());

    if (cfg.ltsm_agent_mode == UVM_ACTIVE)
      sqr_pool::get_global_pool().add("ltsm_sqr", ltsm_agt.get_sequencer());

    `uvm_info("TX_ENV", "All TLM connections and sqr_pool registrations complete", UVM_MEDIUM)
  endfunction

endclass : tx_env
