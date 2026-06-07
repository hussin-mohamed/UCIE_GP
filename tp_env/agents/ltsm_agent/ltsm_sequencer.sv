//=============================================================================
// File       : ltsm_sequencer.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: LTSM sequencer — standard single-parameter sequencer.
//              Handshake logic is handled directly by the driver.
//=============================================================================

class ltsm_sequencer extends uvm_sequencer #(ltsm_seq_item);

  `uvm_component_utils(ltsm_sequencer)

  function new(string name = "ltsm_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass : ltsm_sequencer
