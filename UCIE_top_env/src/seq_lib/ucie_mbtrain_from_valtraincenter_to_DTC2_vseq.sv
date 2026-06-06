//=============================================================================
// File       : ucie_mbtrain_from_valtraincenter_to_DTC2_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_mbtrain_from_valtraincenter_to_DTC2_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_mbtrain_from_valtraincenter_to_DTC2_vseq)

  ucie_mbtrain_from_valtraincenter_to_DTC2_cfg vseq_cfg;
  ucie_mbtrain_till_valtraincenter_vseq ucie_mbtrain_till_valtraincenter;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_mbtrain_from_valtraincenter_to_DTC2_vseq");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();
  ucie_mbtrain_till_valtraincenter = ucie_mbtrain_till_valtraincenter_vseq::type_id::create("ucie_mbtrain_till_valtraincenter");
  ucie_mbtrain_till_valtraincenter.vseq_cfg = this.vseq_cfg;

  ucie_mbtrain_till_valtraincenter.start(p_sequencer);
  endtask
endclass : ucie_mbtrain_from_valtraincenter_to_DTC2_vseq
