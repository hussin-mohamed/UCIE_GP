//=============================================================================
// File       : ucie_mbinit_fail_all_test.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Test that runs all MBINIT failure scenarios in one run.
//=============================================================================

class ucie_mbinit_fail_all_test extends ucie_base_test;

  `uvm_component_utils(ucie_mbinit_fail_all_test)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_mbinit_fail_all_test", uvm_component parent = null);
    super.new(name, parent);
    // Set a much larger timeout since we are running 50+ phase iterations
    uvm_top.set_timeout(3500ms, 0);
  endfunction

  function void build_phase(uvm_phase phase);
    // Override the base vseq by our mega fail_all vseq
    ucie_vseq_base::type_id::set_type_override(ucie_mbinit_fail_all_vseq::get_type());
    
    // Override the PerLaneID sequence by our custom PerLaneID mega sequence
    rmblink_sanity_PerLaneID_sequence::type_id::set_type_override(ucie_rmblink_PerLaneID_mega_seq::get_type());

    super.build_phase(phase);
  endfunction : build_phase

  virtual function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    // Set the drain time to be waited before exiting the main phase
    set_main_phase_drain_time(10000000000ns);
  endfunction : start_of_simulation_phase

endclass : ucie_mbinit_fail_all_test
