//=============================================================================
// File       : ucie_sanity_test.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Sanity test that runs the master virtual sequence.
//=============================================================================

class ucie_sanity_test extends ucie_base_test;

  `uvm_component_utils(ucie_sanity_test)

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
    ucie_mbinit_bringup_vseq vseq;

    phase.raise_objection(this);

    // Wait for reset to deassert before starting (handled in vseq or here)
    // Assume TB logic handles reset duration and sequence can just start.

    vseq = ucie_mbinit_bringup_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);

    wait (env.sb_env_i.phylink_agt.mntr.txn_in_cnt == vseq.ltsm2link_msg_cnt);

    // Wait a bit to let things settle after sequence finishes
    #100ms;

    phase.drop_objection(this);
  endtask

endclass : ucie_sanity_test
