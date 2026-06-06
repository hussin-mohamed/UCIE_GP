//=============================================================================
// File       : tx_virtual_seq.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: Virtual sequence — orchestrates LTSM and RDI sequences.
//              Uses the sqr_pool sequencer container to retrieve handles
//              (no virtual sequencer component needed).
//=============================================================================

class tx_virtual_seq extends uvm_sequence #(uvm_sequence_item);

  `uvm_object_utils(tx_virtual_seq)

  // Sub-sequences
  ltsm_base_seq  ltsm_seq;
  rdi_base_seq   rdi_seq;

  // LTSM state FIFO handle (set by test/env before starting)
  uvm_tlm_analysis_fifo #(ltsm_seq_item) ltsm_state_fifo;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------

  function new(string name = "tx_virtual_seq");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  Body — fork LTSM and RDI sequences on their respective sequencers
  // -------------------------------------------------------------------------

  task body();
    uvm_sequencer_base rdi_sqr, ltsm_sqr;

    // Retrieve sequencer handles from the global pool
    rdi_sqr  = sqr_pool::get_global_pool().get("rdi_sqr");
    ltsm_sqr = sqr_pool::get_global_pool().get("ltsm_sqr");

    // Create sub-sequences
    ltsm_seq = ltsm_base_seq::type_id::create("ltsm_seq");
    rdi_seq  = rdi_base_seq::type_id::create("rdi_seq");

    // Pass LTSM state FIFO to RDI sequence for cross-agent reactivity
    if (ltsm_state_fifo == null)
      `uvm_fatal("VSEQ", "ltsm_state_fifo handle is null")
    rdi_seq.ltsm_state_fifo = ltsm_state_fifo;

    // Fork both sequences on their respective sequencers
    // LTSM walks through init→active; RDI waits for ACTIVE then sends flits
    fork
      ltsm_seq.start(ltsm_sqr);
      rdi_seq.start(rdi_sqr);
    join

    `uvm_info("VSEQ", "Virtual sequence complete", UVM_LOW)
  endtask

endclass : tx_virtual_seq
