//=============================================================================
// File       : ucie_sbinit_test.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Sanity test that runs the master virtual sequence.
//=============================================================================

class ucie_sbinit_test extends ucie_base_test;

  `uvm_component_utils(ucie_sbinit_test)
  
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_sbinit_test", uvm_component parent = null);
    super.new(name, parent);
    uvm_top.set_timeout(100ms, 0);
  endfunction

  function void build_phase(uvm_phase phase);
    // Override the base vseq by your vseq
    ucie_vseq_base::type_id::set_type_override(ucie_sbinit_vseq::get_type());
    
    super.build_phase(phase);
  endfunction : build_phase

  virtual function void start_of_simulation_phase(uvm_phase phase);
    // Set the drain time to be waited before exiting the main phase
    set_main_phase_drain_time(100000ns);
  endfunction : start_of_simulation_phase

endclass : ucie_sbinit_test
