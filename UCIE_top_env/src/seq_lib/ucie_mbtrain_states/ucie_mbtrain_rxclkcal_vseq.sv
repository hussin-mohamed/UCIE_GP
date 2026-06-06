//=============================================================================
// File       : ucie_mbtrain_rxclkcal_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_mbtrain_rxclkcal_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_mbtrain_rxclkcal_vseq)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_mbtrain_rxclkcal_vseq");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();
    `uvm_info("UCIE_VSEQ", "Starting system-level sanity virtual sequence", UVM_LOW)

    // Rxclkcal_Start_TX_LTSM
    `uvm_info("VSEQ", $sformatf("Rxclkcal_Start_TX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    p_sequencer.rx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBTRAIN_RXCLKCAL_TX_Start_Handshake);
    send_sb_msg(sb_ltsm_item);

    // Rxclkcal_Start_RX_LTSM
    `uvm_info("VSEQ", $sformatf("Rxclkcal_Start_RX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBTRAIN_RXCLKCAL_RX_Start_Handshake);
    send_sb_msg(sb_ltsm_item);
    
    // Rxclkcal_End_TX_LTSM
    `uvm_info("VSEQ", $sformatf("Rxclkcal_End_TX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    p_sequencer.rx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBTRAIN_RXCLKCAL_TX_End_Handshake);
    send_sb_msg(sb_ltsm_item);

    // Rxclkcal_End_RX_LTSM
    `uvm_info("VSEQ", $sformatf("Rxclkcal_End_RX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBTRAIN_RXCLKCAL_RX_End_Handshake);
    send_sb_msg(sb_ltsm_item);
    
    `uvm_info("UCIE_VSEQ", "System-level sanity virtual sequence finished", UVM_LOW)
  endtask

  task D2C_RX_initiated ();
    
  endtask 
endclass : ucie_mbtrain_rxclkcal_vseq
