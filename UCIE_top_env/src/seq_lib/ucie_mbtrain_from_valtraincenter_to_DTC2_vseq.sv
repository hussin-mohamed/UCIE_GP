//=============================================================================
// File       : ucie_mbtrain_from_valtraincenter_to_DTC2_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_mbtrain_from_valtraincenter_to_DTC2_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_mbtrain_from_valtraincenter_to_DTC2_vseq)

  reset_seq reset;
  ucie_mbtrain_from_valtraincenter_to_DTC2_cfg vseq_cfg;
  ucie_mbtrain_till_valtraincenter_vseq ucie_mbtrain_till_valtraincenter;
  ucie_mbtrain_till_valtrainvref_vseq ucie_mbtrain_till_valtrainvref;

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
  ucie_mbtrain_till_valtrainvref = ucie_mbtrain_till_valtrainvref_vseq::type_id::create("ucie_mbtrain_till_valtrainvref");
  reset = reset_seq::type_id::create("reset");
  
  ucie_mbtrain_till_valtraincenter.vseq_cfg = this.vseq_cfg;
  ucie_mbtrain_till_valtrainvref.vseq_cfg = this.vseq_cfg;

  if (reset.reset_counter == 0) begin
    ucie_mbtrain_till_valtraincenter.start(p_sequencer);
    reset.reset_counter++;
    reset.start(tx_rdi_seqr);
  end else if(reset.reset_counter == 1) begin
    $display("ucie_mbtrain_till_valtrainvref seq begin");
    ucie_mbtrain_till_valtrainvref.start(p_sequencer);
    reset.reset_counter++;
    reset.start(tx_rdi_seqr);
  end
  endtask
endclass : ucie_mbtrain_from_valtraincenter_to_DTC2_vseq
