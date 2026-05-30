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
  function new(string name="ucie_sanity_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  //  Run Phase
  // -------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    ucie_sanity_vseq vseq;
    
    phase.raise_objection(this);
    
    // Wait for reset to deassert before starting (handled in vseq or here)
    // Assume TB logic handles reset duration and sequence can just start.
    
    vseq = ucie_sanity_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);

    // Wait a bit to let things settle after sequence finishes
    #100ns;
    
    phase.drop_objection(this);
  endtask

endclass : ucie_sanity_test
