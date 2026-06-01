//=============================================================================
// File       : ucie_pkg.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Top-level package importing all sub-environment packages
//              and including system-level environment, sequences, and tests.
//=============================================================================

package ucie_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // -------------------------------------------------------------------------
  //  Import Sub-Environment Packages
  // -------------------------------------------------------------------------

  // LTSM Environment
  import shared_ltsm_pkg::*;
  import LTSM_pkg::*;

  // Sideband Environment
  import sb_shared_pkg::*;
  import sb_pkg::*;

  // RX-Path Environment
  import rp_shared_pkg::*;
  import rp_pkg::*;

  // TX-Path Environment
  import tx_defs_pkg::*;
  import B2L_modelling_pkg::*;
  import LFSR_modelling_pkg::*;
  import tx_controller_modelling_pkg::*;
  import per_lane_id_modelling_pkg::*;
  import tx_tb_pkg::*;

  // -------------------------------------------------------------------------
  //  System-Level Components
  // -------------------------------------------------------------------------
  
  `include "ucie_env_cfg.sv"
  `include "ucie_vseqr.sv"
  `include "ucie_env.sv"

  // -------------------------------------------------------------------------
  //  System-Level Sequences
  // -------------------------------------------------------------------------
  `include "sb_sequences/active_phylink_sequence.sv"
  `include "ucie_sanity_vseq.sv"
  `include "ucie_vseq_base.sv"
  `include "ucie_mbinit_bringup_vseq.sv"

  // -------------------------------------------------------------------------
  //  System-Level Tests
  // -------------------------------------------------------------------------
  `include "ucie_base_test.sv"
  `include "ucie_sanity_test.sv"

endpackage : ucie_pkg
