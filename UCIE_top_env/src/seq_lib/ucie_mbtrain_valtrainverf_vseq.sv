//=============================================================================
// File       : ucie_mbtrain_valtrainverf_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_mbtrain_valtrainverf_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_mbtrain_valtrainverf_vseq)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_mbtrain_valtrainverf_vseq");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();
    `uvm_info("UCIE_VSEQ", "Starting system-level sanity virtual sequence", UVM_LOW)

    // Valtrainverf_Start_TX_LTSM
    `uvm_info("VSEQ", $sformatf("Valtrainverf_Start_TX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    p_sequencer.rx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBTRAIN_VALTRAINVREF_TX_Start_Handshake);
    send_sb_msg(sb_ltsm_item);

    // Valtrainverf_Start_RX_LTSM
    `uvm_info("VSEQ", $sformatf("Valtrainverf_Start_RX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBTRAIN_VALTRAINVREF_RX_Start_Handshake);
    send_sb_msg(sb_ltsm_item);

    // Valtrainverf_D2C_RX_LTSM
    `uvm_info("VSEQ", $sformatf("Valtrainverf_D2C_RX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    ucie_D2C_vseq.configure(0,'hFFFF_FFFF_FFFF_FFFF, 0);
    ucie_D2C_vseq.start();

    // Valtrainverf_End_TX_LTSM
    `uvm_info("VSEQ", $sformatf("Valtrainverf_End_TX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    p_sequencer.rx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBTRAIN_VALTRAINVREF_TX_End_Handshake);
    send_sb_msg(sb_ltsm_item);

    // Valtrainverf_End_RX_LTSM
    `uvm_info("VSEQ", $sformatf("Valtrainverf_End_RX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBTRAIN_VALTRAINVREF_RX_End_Handshake);
    send_sb_msg(sb_ltsm_item);

    `uvm_info("UCIE_VSEQ", "System-level sanity virtual sequence finished", UVM_LOW)
  endtask
endclass : ucie_mbtrain_valtrainverf_vseq
