//=============================================================================
// File       : ucie_vseqr.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequencer for the system-level environment.
//=============================================================================

class ucie_vseqr extends uvm_sequencer;

  `uvm_component_utils(ucie_vseqr)

  // -------------------------------------------------------------------------
  //  Child Sequencer Handles
  // -------------------------------------------------------------------------
  LTSM_pkg::ltsm_rdi_sequencer ltsm_rdi_seqr;
  sb_pkg::phylink_sequencer    sb_phylink_seqr;
  rp_pkg::rmblink_sequencer    rp_rmblink_seqr;
  tx_tb_pkg::rdi_sequencer     tx_rdi_seqr;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_vseqr", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass : ucie_vseqr
