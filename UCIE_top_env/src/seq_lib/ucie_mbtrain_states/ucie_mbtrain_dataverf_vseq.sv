//=============================================================================
// File       : ucie_mbtrain_dataverf_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_mbtrain_dataverf_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_mbtrain_dataverf_vseq)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_mbtrain_dataverf_vseq");
    super.new(name);
  endfunction

  function configure (D2c_mode_e D2c_mode, pattern_mode_e pattern_mode,
                      data_mode_e data_mode, info_mode_e info_mode, message_mode_e message_mode, valid_mode_e valid_mode,missing_msg_e missing_msg);
    this.D2c_mode = D2c_mode;
    this.pattern_mode = pattern_mode;
    this.data_mode = data_mode;
    this.info_mode = info_mode;
    this.message_mode = message_mode;
    this.valid_mode = valid_mode;
    this.missing_msg = missing_msg;

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

    // Dataverf_Start_TX_LTSM
    `uvm_info("VSEQ", $sformatf("Dataverf_Start_TX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    p_sequencer.rx_fifo.get(sb_ltsm_item);

    if ((missing_msg == MISS) && (TRAINERROR_vseq.trainerr_cnt == 6)) begin
    TRAINERROR_vseq.configure(.missing_msg_2get(NORMAL));
    TRAINERROR_vseq.start(p_sequencer);
    return;
    end

    else begin
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBTRAIN_DATAVREF_TX_Start_Handshake);
    send_sb_msg(sb_ltsm_item);
    end

    // Dataverf_Start_RX_LTSM
    `uvm_info("VSEQ", $sformatf("Dataverf_Start_RX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    
    p_sequencer.tx_fifo.get(sb_ltsm_item);

    if ((missing_msg == MISS) && (TRAINERROR_vseq.trainerr_cnt == 7)) begin
    TRAINERROR_vseq.configure(.missing_msg_2get(MISS2RX));
    TRAINERROR_vseq.start(p_sequencer);
    return;
    end

    else begin
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBTRAIN_DATAVREF_RX_Start_Handshake);
    send_sb_msg(sb_ltsm_item);
    end


    // Dataverf_D2C_RX_LTSM
    `uvm_info("VSEQ", $sformatf("Dataverf_D2C_RX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    ucie_RX_D2C.configure(
      D2c_mode,
      pattern_mode,
      data_mode,
      info_mode,
      message_mode,
      valid_mode
    );
    
    ucie_RX_D2C.start(p_sequencer);

    if ((missing_msg == IDEAL) && (TRAINERROR_vseq.trainerr_cnt == 11)) begin
    TRAINERROR_vseq.configure(.missing_msg_2get(NORMAL));
    TRAINERROR_vseq.start(p_sequencer);
    return;
    end

    // Dataverf_End_TX_LTSM
    `uvm_info("VSEQ", $sformatf("Dataverf_End_TX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    p_sequencer.rx_fifo.get(sb_ltsm_item);

    if ((missing_msg == MISS) && (TRAINERROR_vseq.trainerr_cnt == 8)) begin
    TRAINERROR_vseq.configure(.missing_msg_2get(NORMAL));
    TRAINERROR_vseq.start(p_sequencer);
    return;
    end

    else if ((missing_msg == MISS) && (TRAINERROR_vseq.trainerr_cnt == 10)) begin
    TRAINERROR_vseq.configure(.missing_msg_2get(NORMAL), .train_error_dir(SEND_REQ));
    TRAINERROR_vseq.start(p_sequencer);
    return;
    end

    else begin
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBTRAIN_DATAVREF_TX_End_Handshake);
    send_sb_msg(sb_ltsm_item);
    end


    // Dataverf_End_RX_LTSM
    `uvm_info("VSEQ", $sformatf("Dataverf_End_RX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    
    p_sequencer.tx_fifo.get(sb_ltsm_item);

    if ((missing_msg == MISS) && (TRAINERROR_vseq.trainerr_cnt == 9)) begin
    TRAINERROR_vseq.configure(.missing_msg_2get(NORMAL));
    TRAINERROR_vseq.start(p_sequencer);
    return;
    end

    else begin
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBTRAIN_DATAVREF_RX_End_Handshake);
    send_sb_msg(sb_ltsm_item);
    end

    `uvm_info("UCIE_VSEQ", "System-level sanity virtual sequence finished", UVM_LOW)
  endtask

  task D2C_RX_initiated ();
    
  endtask 
endclass : ucie_mbtrain_dataverf_vseq
