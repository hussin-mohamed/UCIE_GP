//=============================================================================
// File       : ucie_mbinit_fail_repair_tx_test.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Test setting up the system environment and starting
//              ucie_mbinit_fail_vseq configured for FAIL_REPAIR on FAIL_SIDE_TX.
//=============================================================================

class ucie_mbinit_fail_repair_tx_test extends ucie_base_test;

  `uvm_component_utils(ucie_mbinit_fail_repair_tx_test)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_mbinit_fail_repair_tx_test", uvm_component parent = null);
    super.new(name, parent);
    uvm_top.set_timeout(1000ms, 0);
  endfunction

  function void build_phase(uvm_phase phase);
    // Override the base vseq by your vseq
    ucie_vseq_base::type_id::set_type_override(ucie_mbinit_fail_vseq::get_type());

    super.build_phase(phase);
  endfunction : build_phase

  virtual function void start_of_simulation_phase(uvm_phase phase);
    ucie_mbinit_fail_vseq fail_vseq;
    super.start_of_simulation_phase(phase);
    // Set the drain time to be waited before exiting the main phase
    set_main_phase_drain_time(3000000ns);
    if ($cast(fail_vseq, vseq)) begin
      fail_vseq.configure(FAIL_REPAIR, FAIL_SIDE_TX);
    end else begin
      `uvm_fatal("TEST_CFG_ERR", "Failed to cast vseq to ucie_mbinit_fail_vseq")
    end
  endfunction : start_of_simulation_phase

endclass : ucie_mbinit_fail_repair_tx_test
