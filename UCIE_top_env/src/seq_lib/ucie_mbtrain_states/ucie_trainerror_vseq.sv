//=============================================================================
// File       : ucie_trainerror_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_trainerror_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_trainerror_vseq)

  static int trainerr_cnt;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_trainerror_vseq");
    super.new(name);
    trainerr_cnt = 0;
  endfunction


  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();
    `uvm_info("UCIE_VSEQ", "Starting system-level sanity virtual sequence", UVM_LOW)


    // Trainerror_Start_TX_LTSM
    `uvm_info("VSEQ", $sformatf("Trainerror_Start_TX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    p_sequencer.rx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::TRAINERROR_TX_Handshake);
    send_sb_msg(sb_ltsm_item);

    // Trainerror_Start_RX_LTSM
    `uvm_info("VSEQ", $sformatf("Trainerror_Start_RX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::TRAINERROR_RX_Handshake);
    send_sb_msg(sb_ltsm_item);

    trainerr_cnt++;

    `uvm_info("UCIE_VSEQ", "System-level sanity virtual sequence finished", UVM_LOW)
  endtask
endclass : ucie_trainerror_vseq
