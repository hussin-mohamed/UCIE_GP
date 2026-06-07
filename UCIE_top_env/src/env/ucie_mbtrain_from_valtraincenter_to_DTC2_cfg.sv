//=============================================================================
// File       : ucie_mbtrain_from_valtraincenter_to_DTC2_cfg.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Configuration object for the system-level environment.
//              Holds handles to the sub-environment configurations.
//=============================================================================

class ucie_mbtrain_from_valtraincenter_to_DTC2_cfg extends uvm_object;

  `uvm_object_utils(ucie_mbtrain_from_valtraincenter_to_DTC2_cfg)

  static int trainerror_cnt;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_mbtrain_from_valtraincenter_to_DTC2_cfg");
    super.new(name);
  endfunction

endclass : ucie_mbtrain_from_valtraincenter_to_DTC2_cfg
