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

  function configure (D2c_mode_e D2c_mode, pattern_mode_e pattern_mode,
                      data_mode_e data_mode, info_mode_e info_mode, message_mode_e message_mode, valid_mode_e valid_mode);
    this.D2c_mode = D2c_mode;
    this.pattern_mode = pattern_mode;
    this.data_mode = data_mode;
    this.info_mode = info_mode;
    this.message_mode = message_mode;
    this.valid_mode = valid_mode;
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

    ucie_RX_D2C_vseq.configure(
      D2c_mode,
      pattern_mode,
      data_mode,
      info_mode,
      message_mode,
      valid_mode
    );

    ucie_RX_D2C_vseq.start(p_sequencer);

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
