//=============================================================================
// File       : tx_smoke_test.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: Smoke test — runs the virtual sequence for a full
//              RESET → init → ACTIVE → 10 flits scenario. Validates
//              the complete TB infrastructure end-to-end.
//=============================================================================

class tx_smoke_test extends tx_base_test;

  `uvm_component_utils(tx_smoke_test)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------

  function new(string name = "tx_smoke_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  //  Run Phase — start virtual sequence
  // -------------------------------------------------------------------------

  task run_phase(uvm_phase phase);
    tx_virtual_seq vseq;

    phase.raise_objection(this, "tx_smoke_test running");

    vseq = tx_virtual_seq::type_id::create("vseq");

    // Pass the LTSM-to-RDI FIFO handle to the virtual sequence
    vseq.ltsm_state_fifo = env.ltsm_to_rdi_fifo;

    `uvm_info("SMOKE_TEST", "Starting virtual sequence: RESET -> ACTIVE -> 10 flits", UVM_LOW)

    // Start the virtual sequence (no sequencer needed — it uses sqr_pool)
    vseq.start(null);

    // Allow some drain time for scoreboard to process remaining items
    #1000;

    `uvm_info("SMOKE_TEST", "Virtual sequence complete", UVM_LOW)

    phase.drop_objection(this, "tx_smoke_test done");
  endtask

endclass : tx_smoke_test
