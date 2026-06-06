//=============================================================================
// File       : tx_env_cfg.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: Centralized environment configuration object. Holds virtual
//              interface handles, test knobs, and plusarg parsing.
//              Passed down via uvm_config_db to all components.
//=============================================================================

class tx_env_cfg extends uvm_object;

  `uvm_object_utils(tx_env_cfg)

  // -------------------------------------------------------------------------
  //  Virtual Interface Handles
  // -------------------------------------------------------------------------

  virtual rdi_if    rdi_vif;
  virtual rdi_if    rdi_vif_drive;
  virtual ltsm_if   ltsm_vif;
  virtual tx2link_if  tx2link_vif;

  // -------------------------------------------------------------------------
  //  Agent Configuration
  // -------------------------------------------------------------------------

  // Active/passive mode for each agent
  uvm_active_passive_enum rdi_agent_mode   = UVM_ACTIVE;
  uvm_active_passive_enum ltsm_agent_mode  = UVM_ACTIVE;
  // tx2link agent is always passive — no config needed



  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------

  function new(string name = "tx_env_cfg");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  Plusarg Parsing
  // -------------------------------------------------------------------------
  //  Call this in the base test's build_phase after construction.
  //
  //  Note: +FLIT_SIZE is parsed by rdi_seq_item (static, per-run).
  //        +ITER is parsed by rdi_base_seq / ltsm_base_seq (per-sequence).

  function void parse_plusargs();
    // Reserved for future test knobs
  endfunction

  // -------------------------------------------------------------------------
  //  Debug Print
  // -------------------------------------------------------------------------

  function string convert2string();
    return $sformatf("TX_ENV_CFG: rdi=%0s, ltsm=%0s",
                     rdi_agent_mode.name(), ltsm_agent_mode.name());
  endfunction

endclass : tx_env_cfg
