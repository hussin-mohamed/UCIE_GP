//=============================================================================
// File       : ucie_sanity_test.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Sanity test that runs the master virtual sequence.
//=============================================================================

class ucie_sanity_test extends ucie_base_test;

  `uvm_component_utils(ucie_sanity_test)
  
  ucie_mbinit_bringup_vseq vseq;
  ucie_mbtrain_vseq train_vseq;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_sanity_test", uvm_component parent = null);
    super.new(name, parent);
    uvm_top.set_timeout(100ms, 0);
  endfunction

  // -------------------------------------------------------------------------
  //  Run Phase
  // -------------------------------------------------------------------------
  virtual task main_phase(uvm_phase phase);
    phase.raise_objection(this);

    // Wait for reset to deassert before starting (handled in vseq or here)
    // Assume TB logic handles reset duration and sequence can just start.

    vseq = ucie_mbinit_bringup_vseq::type_id::create("vseq");
    train_vseq = ucie_mbtrain_vseq::type_id::create("train_vseq");
    vseq.start(env.vseqr);
    train_vseq.start(env.vseqr);

    train_vseq.wait_for_msg_ser_end();

    // Wait a bit to let things settle after sequence finishes
    #1000ns;

    phase.drop_objection(this);
  endtask

endclass : ucie_sanity_test
