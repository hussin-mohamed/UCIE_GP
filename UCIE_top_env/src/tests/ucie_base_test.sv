//=============================================================================
// File       : ucie_base_test.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Base test setting up the system environment and passing 
//              virtual interfaces to the sub-environments.
//=============================================================================

class ucie_base_test extends uvm_test;

  `uvm_component_utils(ucie_base_test)

  ucie_env      env;
  ucie_env_cfg  m_cfg;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name="ucie_base_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  //  Build Phase
  // -------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    m_cfg = ucie_env_cfg::type_id::create("m_cfg");
    m_cfg.ltsm_cfg = LTSM_pkg::env_config::type_id::create("ltsm_cfg");
    m_cfg.sb_cfg   = sb_pkg::env_config::type_id::create("sb_cfg");
    m_cfg.rp_cfg   = rp_pkg::env_config::type_id::create("rp_cfg");
    m_cfg.tx_cfg   = tx_tb_pkg::tx_env_cfg::type_id::create("tx_cfg");

    // -----------------------------------------------------------------------
    // Retrieve Virtual Interfaces
    // -----------------------------------------------------------------------

    // LTSM Env VIFs
    if (!uvm_config_db#(virtual ltsm_rdi_if)::get(this, "", "ltsm_rdi_vif", m_cfg.ltsm_cfg.ltsm_rdi_vif))
      `uvm_fatal("NO_VIF", "ltsm_rdi_vif not set")
    if (!uvm_config_db#(virtual TX_FSM_SB)::get(this, "", "tx_fsm_sb_vif", m_cfg.ltsm_cfg.tx_fsm_sb_if))
      `uvm_fatal("NO_VIF", "tx_fsm_sb_vif not set")
    if (!uvm_config_db#(virtual RX_FSM_SB)::get(this, "", "rx_fsm_sb_vif", m_cfg.ltsm_cfg.rx_fsm_sb_if))
      `uvm_fatal("NO_VIF", "rx_fsm_sb_vif not set")
    if (!uvm_config_db#(virtual LTSM_controllers_if)::get(this, "", "ltsm_ctrl_vif", m_cfg.ltsm_cfg.vif))
      `uvm_fatal("NO_VIF", "LTSM_controllers_if not set")

    // Sideband Env VIFs
    if (!uvm_config_db#(virtual sb_reset_intf)::get(this, "", "sb_reset_vif", m_cfg.sb_cfg.reset_intf))
      `uvm_fatal("NO_VIF", "sb_reset_vif not set")
    if (!uvm_config_db#(virtual sb_ltsm_ctrl_bfm)::get(this, "", "sb_ltsm_ctrl_bfm", m_cfg.sb_cfg.ltsm_ctrl_bfm))
      `uvm_fatal("NO_VIF", "sb_ltsm_ctrl_bfm not set")
    if (!uvm_config_db#(virtual sb_tx_bfm)::get(this, "", "sb_tx_bfm", m_cfg.sb_cfg.tx_bfm))
      `uvm_fatal("NO_VIF", "sb_tx_bfm not set")
    if (!uvm_config_db#(virtual sb_rx_bfm)::get(this, "", "sb_rx_bfm", m_cfg.sb_cfg.rx_bfm))
      `uvm_fatal("NO_VIF", "sb_rx_bfm not set")
    if (!uvm_config_db#(virtual sb_phylink_bfm)::get(this, "", "sb_phylink_bfm", m_cfg.sb_cfg.phylink_bfm))
      `uvm_fatal("NO_VIF", "sb_phylink_bfm not set")

    // RX-Path Env VIFs
    if (!uvm_config_db#(virtual rp_reset_intf)::get(this, "", "rp_reset_vif", m_cfg.rp_cfg.reset_intf))
      `uvm_fatal("NO_VIF", "rp_reset_vif not set")
    if (!uvm_config_db#(virtual rp_rdi_bfm)::get(this, "", "rp_rdi_bfm", m_cfg.rp_cfg.rdi_bfm))
      `uvm_fatal("NO_VIF", "rp_rdi_bfm not set")
    if (!uvm_config_db#(virtual rp_ltsmc_bfm)::get(this, "", "rp_ltsmc_bfm", m_cfg.rp_cfg.ltsmc_bfm))
      `uvm_fatal("NO_VIF", "rp_ltsmc_bfm not set")
    if (!uvm_config_db#(virtual rp_rmblink_bfm)::get(this, "", "rp_rmblink_bfm", m_cfg.rp_cfg.rmblink_bfm))
      `uvm_fatal("NO_VIF", "rp_rmblink_bfm not set")

    // TX-Path Env VIFs
    if (!uvm_config_db#(virtual rdi_if)::get(this, "", "tx_rdi_vif", m_cfg.tx_cfg.rdi_vif))
      `uvm_fatal("NO_VIF", "tx_rdi_vif not set")
    if (!uvm_config_db#(virtual ltsm_if)::get(this, "", "tx_ltsm_vif", m_cfg.tx_cfg.ltsm_vif))
      `uvm_fatal("NO_VIF", "tx_ltsm_vif not set")
    if (!uvm_config_db#(virtual tx2link_if)::get(this, "", "tx2link_vif", m_cfg.tx_cfg.tx2link_vif))
      `uvm_fatal("NO_VIF", "tx2link_vif not set")

    uvm_config_db#(ucie_env_cfg)::set(this, "env", "ucie_env_cfg", m_cfg);
    env = ucie_env::type_id::create("env", this);
  endfunction

  // -------------------------------------------------------------------------
  //  End of Elaboration Phase
  // -------------------------------------------------------------------------
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info(get_type_name(), "Printing UVM System Topology:", UVM_NONE)
    uvm_top.print_topology();
  endfunction

endclass : ucie_base_test
