//=============================================================================
// File       : rdi_sequencer.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: RDI sequencer — standard single-parameter sequencer.
//              Backpressure (pl_trdy) is handled directly by the driver.
//=============================================================================

class rdi_sequencer extends uvm_sequencer #(rdi_seq_item);

  `uvm_component_utils(rdi_sequencer)

  function new(string name = "rdi_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass : rdi_sequencer
