//=============================================================================
// File       : ucie_trainerror_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_trainerror_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_trainerror_vseq)

  protected static int trainerr_cnt;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_trainerror_vseq");
    super.new(name);
  endfunction

   function configure (missing_msg_2get_e missing_msg_2get);

    this.missing_msg_2get = missing_msg_2get;

    is_configured = 1;
  endfunction


  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();
    `uvm_info("UCIE_VSEQ", "Starting system-level sanity virtual sequence", UVM_LOW)

    if (!is_configured) begin
      `uvm_fatal("SEQ_CFG_ERR", "Sequence must be configured via configure() before starting!")
    end

    is_configured = 0;

    trainerr_cnt++;

    // Trainerror_Start_TX_LTSM
    `uvm_info("VSEQ", $sformatf("Trainerror_Start_TX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    if (missing_msg_2get == MISS2RX) begin
        p_sequencer.tx_fifo.get(sb_ltsm_item);
        p_sequencer.rx_fifo.get(sb_ltsm_item);
    end
    else if (missing_msg_2get == NORMAL) begin
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    end

    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::TRAINERROR_TX_Handshake);
    send_sb_msg(sb_ltsm_item);

    // Trainerror_Start_RX_LTSM
    `uvm_info("VSEQ", $sformatf("Trainerror_Start_RX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::TRAINERROR_RX_Handshake);
    send_sb_msg(sb_ltsm_item);



    `uvm_info("UCIE_VSEQ", "System-level sanity virtual sequence finished", UVM_LOW)
  endtask

  function void reset_trainerr_cnt();
    trainerr_cnt = 0;
  endfunction : reset_trainerr_cnt
endclass : ucie_trainerror_vseq
