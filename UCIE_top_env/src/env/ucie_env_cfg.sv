//=============================================================================
// File       : ucie_env_cfg.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Configuration object for the system-level environment.
//              Holds handles to the sub-environment configurations.
//=============================================================================

class ucie_env_cfg extends uvm_object;

  `uvm_object_utils(ucie_env_cfg)

  // -------------------------------------------------------------------------
  //  Sub-Environment Configurations
  // -------------------------------------------------------------------------
  LTSM_pkg::env_config  ltsm_cfg;
  sb_pkg::env_config    sb_cfg;
  rp_pkg::env_config    rp_cfg;
  tx_tb_pkg::tx_env_cfg tx_cfg;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_env_cfg");
    super.new(name);
  endfunction

endclass : ucie_env_cfg
