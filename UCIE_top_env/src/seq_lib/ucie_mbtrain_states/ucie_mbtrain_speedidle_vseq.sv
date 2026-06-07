//=============================================================================
// File       : ucie_mbtrain_speedidle_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_mbtrain_speedidle_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_mbtrain_speedidle_vseq)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_mbtrain_speedidle_vseq");
    super.new(name);
  endfunction

  function configure (missing_msg_e missing_msg = NORMAL);
    this.missing_msg = missing_msg;
endfunction

  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();
    `uvm_info("UCIE_VSEQ", "Starting system-level sanity virtual sequence", UVM_LOW)


    // Speedidle_End_TX_LTSM
    `uvm_info("VSEQ", $sformatf("Speedidle_End_TX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    p_sequencer.rx_fifo.get(sb_ltsm_item);

    if ((missing_msg == MISS) && (TRAINERROR_vseq.trainerr_cnt == 8)) begin
    TRAINERROR_vseq.configure(.missing_msg_2get(NORMAL));
    TRAINERROR_vseq.start(p_sequencer);
    return;
    end

    else begin
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBTRAIN_SPEEDIDLE_TX_TrainError_Handshake);
    send_sb_msg(sb_ltsm_item);
    end



    // Speedidle_End_RX_LTSM
    `uvm_info("VSEQ", $sformatf("Speedidle_End_RX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    
    p_sequencer.tx_fifo.get(sb_ltsm_item);

    if ((missing_msg == MISS) && (TRAINERROR_vseq.trainerr_cnt == 9)) begin
    TRAINERROR_vseq.configure(.missing_msg_2get(NORMAL));
    TRAINERROR_vseq.start(p_sequencer);
    return;
    end

    else begin
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBTRAIN_SPEEDIDLE_RX_End_Handshake);
    send_sb_msg(sb_ltsm_item);
    end

    `uvm_info("UCIE_VSEQ", "System-level sanity virtual sequence finished", UVM_LOW)
  endtask

endclass : ucie_mbtrain_speedidle_vseq
