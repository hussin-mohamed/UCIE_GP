//=============================================================================
// File       : ucie_env.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: System-level environment instantiating all sub-environments.
//=============================================================================

class ucie_env extends uvm_env;

  `uvm_component_utils(ucie_env)

  // -------------------------------------------------------------------------
  //  Environment Configuration
  // -------------------------------------------------------------------------
  ucie_env_cfg m_cfg;

  // -------------------------------------------------------------------------
  //  Virtual Sequencer
  // -------------------------------------------------------------------------
  ucie_vseqr vseqr;

  // -------------------------------------------------------------------------
  //  Sub-Environments
  // -------------------------------------------------------------------------
  LTSM_pkg::LTSM_env ltsm_env_i;
  sb_pkg::sb_env sb_env_i;
  rp_pkg::rp_env rp_env_i;
  tx_tb_pkg::tx_env tx_env_i;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  //  Build Phase
  // -------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(ucie_env_cfg)::get(this, "", "ucie_env_cfg", m_cfg)) begin
      `uvm_fatal("NO_CFG", "No ucie_env_cfg found in config_db")
    end

    vseqr                                     = ucie_vseqr::type_id::create("vseqr", this);

    // --- Configure LTSM Environment ---
    // Active: ltsm_rdi_agent
    // Passive: tx_fsm_sb_agent, rx_fsm_sb_agent, LTSM_controllers_agent
    m_cfg.ltsm_cfg.is_active_rdi              = UVM_ACTIVE;
    m_cfg.ltsm_cfg.is_active_LTSM_controllers = UVM_PASSIVE;
    m_cfg.ltsm_cfg.is_active_tx_fsm_sb        = UVM_PASSIVE;
    m_cfg.ltsm_cfg.is_active_rx_fsm_sb        = UVM_PASSIVE;
    uvm_config_db#(LTSM_pkg::env_config)::set(this, "ltsm_env_i", "ENV_CFG", m_cfg.ltsm_cfg);
    ltsm_env_i                       = LTSM_pkg::LTSM_env::type_id::create("ltsm_env_i", this);

    // --- Configure Sideband Environment ---
    // Active: phylink_agent
    // Passive: ltsm_ctrl_agent, tx_agent, rx_agent, rdi_agent
    m_cfg.sb_cfg.is_active_phylink   = UVM_ACTIVE;
    m_cfg.sb_cfg.is_active_ltsm_ctrl = UVM_PASSIVE;
    m_cfg.sb_cfg.is_active_tx        = UVM_PASSIVE;
    m_cfg.sb_cfg.is_active_rx        = UVM_PASSIVE;
    m_cfg.sb_cfg.is_active_rdi       = UVM_PASSIVE;
    uvm_config_db#(sb_pkg::env_config)::set(this, "sb_env_i", "ENV_CFG", m_cfg.sb_cfg);
    sb_env_i                       = sb_pkg::sb_env::type_id::create("sb_env_i", this);

    // --- Configure RX-Path Environment ---
    // Active: rmblink_agent
    // Passive: rdi_agent, ltsmc_agent
    m_cfg.rp_cfg.is_active_rmblink = UVM_ACTIVE;
    m_cfg.rp_cfg.is_active_rdi     = UVM_PASSIVE;
    m_cfg.rp_cfg.is_active_ltsmc   = UVM_PASSIVE;
    uvm_config_db#(rp_pkg::env_config)::set(this, "rp_env_i", "ENV_CFG", m_cfg.rp_cfg);
    rp_env_i = rp_pkg::rp_env::type_id::create("rp_env_i", this);

    // --- Configure TX-Path Environment ---
    // Active: rdi_agent
    // Passive: ltsm_agent
    m_cfg.tx_cfg.rdi_agent_mode = UVM_ACTIVE;
    m_cfg.tx_cfg.ltsm_agent_mode = UVM_PASSIVE;
    uvm_config_db#(tx_tb_pkg::tx_env_cfg)::set(this, "tx_env_i", "tx_env_cfg", m_cfg.tx_cfg);
    tx_env_i = tx_tb_pkg::tx_env::type_id::create("tx_env_i", this);

  endfunction

  // -------------------------------------------------------------------------
  //  Connect Phase
  // -------------------------------------------------------------------------
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Connect child sequencers to virtual sequencer
    vseqr.ltsm_rdi_seqr   = ltsm_env_i.rdi_agt.seqr;
    vseqr.sb_phylink_seqr = sb_env_i.phylink_agt.seqr;
    vseqr.rp_rmblink_seqr = rp_env_i.rmblink_agt.seqr;

    // For tx_rdi_seqr, we can get it from the tx_env's rdi agent
    if (!$cast(vseqr.tx_rdi_seqr, tx_env_i.rdi_agt.get_sequencer()))
      `uvm_fatal("CAST", "Failed to cast rdi sequencer")

    // Any system-level scoreboard or cross-environment TLM connections would go here.
    // Currently relying on existing sub-environment scoreboards.
    sb_env_i.phylink_agt.out_ap.connect(vseqr.axp_in);
  endfunction

endclass : ucie_env
