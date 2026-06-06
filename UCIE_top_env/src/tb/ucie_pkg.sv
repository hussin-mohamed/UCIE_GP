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

  `include "ucie_mbtrain_from_valtraincenter_to_DTC2_cfg.sv"
  `include "ucie_env_cfg.sv"
  `include "ucie_vseqr.sv"
  `include "ucie_env.sv"
  typedef class ucie_RX_D2C_vseq;
  typedef class ucie_TX_D2C_vseq;
  // -------------------------------------------------------------------------
  //  System-Level Sequences
  // -------------------------------------------------------------------------
  `include "sb_sequences/active_phylink_sequence.sv"
  `include "ucie_vseq_base.sv"
  `include "ucie_mbinit_bringup_vseq.sv"
  `include "ucie_mbtrain_states/ucie_TX_D2C_vseq.sv"
  `include "ucie_mbtrain_states/ucie_RX_D2C_vseq.sv"
  `include "ucie_mbtrain_states/ucie_mbtrain_valverf_vseq.sv"
  `include "ucie_mbtrain_states/ucie_mbtrain_valtrainverf_vseq.sv"
  `include "ucie_mbtrain_states/ucie_mbtrain_dataverf_vseq.sv"
  `include "ucie_mbtrain_states/ucie_mbtrain_speedidle_vseq.sv"
  `include "ucie_mbtrain_states/ucie_mbtrain_valtraincenter_vseq.sv"
  `include "ucie_mbtrain_states/ucie_mbtrain_txselfcal_vseq.sv"
  `include "ucie_mbtrain_states/ucie_mbtrain_rxclkcal_vseq.sv"
  `include "ucie_mbtrain_states/ucie_mbtrain_DTC1_vseq.sv"
  `include "ucie_mbtrain_states/ucie_mbtrain_datatrainvref_vseq.sv"
  `include "ucie_mbtrain_states/ucie_mbtrain_rxdskew_vseq.sv"
  `include "ucie_mbtrain_states/ucie_mbtrain_DTC2_vseq.sv"
  `include "ucie_mbtrain_states/ucie_mbtrain_linkspeed_vseq.sv"
  `include "ucie_mbtrain_linkspeed_cases_vseq.sv"
  `include "ucie_mbinit_fail_vseq.sv"
  `include "ucie_trainerror_vseq.sv"
  `include "ucie_mbtrain_vseq.sv"
  `include "ucie_mbtrain_till_valtraincenter_vseq.sv"
  `include "ucie_mbtrain_from_valtraincenter_to_DTC2_vseq.sv"
  `include "ucie_vvref_till_rxcal_vseq.sv"
  `include "ucie_sbinit_vseq.sv"
  `include "ucie_sbinit_virtual_sequences/ucie_sbinit_bringup_tx_vseq.sv"
  `include "ucie_sbinit_virtual_sequences/ucie_sbinit_bringup_rx_vseq.sv"
  `include "ucie_sbinit_virtual_sequences/ucie_sbinit_bringup_vseq.sv"

  // -------------------------------------------------------------------------
  //  System-Level Tests
  // -------------------------------------------------------------------------
  `include "ucie_base_test.sv"
  `include "ucie_sanity_test.sv"
  `include "ucie_mbtrain_from_valtraincenter_to_DTC2_test.sv"
  `include "ucie_vvref_till_rxcal_vseq_test.sv"
  `include "ucie_mbinit_fail_test.sv"
  `include "ucie_mbtrain_linkspeed_test.sv"
  `include "ucie_sbinit_test.sv"

endpackage : ucie_pkg
