//=============================================================================
// File       : ucie_D2C_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_D2C_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_D2C_vseq)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_D2C_vseq");
    super.new(name);
  endfunction

  protected logic [63:0] data;
  protected logic [15:0] info;
  protected logic pattern_type;

  protected bit is_configured;

  function configure (logic [63:0] data, logic [15:0] info, logic pattern_type);
    this.data = data;
    this.info = info;
    this.pattern_type = pattern_type;
    this.is_configured = 1;
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

    // D2C_RX_initiated_INIT_TX_LTSM
    `uvm_info("VSEQ", $sformatf("D2C_RX_initiated__TX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    p_sequencer.rx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::Data_To_Clock_test_RX_RX_INIT_Handshake);
    send_sb_msg(sb_ltsm_item);

    // D2C_RX_initiated_INIT_RX_LTSM
    `uvm_info("VSEQ", $sformatf("D2C_RX_initiated__RX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::Data_To_Clock_test_RX_RX_INIT_Handshake);
    send_sb_msg(sb_ltsm_item);

    // D2C_RX_initiated_LFSR_CLEAR_TX_LTSM
    `uvm_info("VSEQ", $sformatf("D2C_RX_initiated_LFSR_CLEAR_TX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    p_sequencer.rx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::Data_To_Clock_test_RX_RX_INIT_LFSR_Clear_Handshake);
    send_sb_msg(sb_ltsm_item);

    // D2C_RX_initiated_LFSR_CLEAR_RX_LTSM
    `uvm_info("VSEQ", $sformatf("D2C_RX_initiated_LFSR_CLEAR_RX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::Data_To_Clock_test_RX_RX_INIT_LFSR_Clear_Handshake);
    send_sb_msg(sb_ltsm_item);

    // D2C_RX_initiated_Pattern_detection_RX_LTSM
    `uvm_info("VSEQ", $sformatf("D2C_RX_initiated_Pattern_detection_RX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    
    if (pattern_type) begin
      rmblink_lfsr_seq.start(rp_rmblink_seqr);
      rmblink_valid_seq.test_mode = SCENARIO_EXACT_MATCH;
    end else begin
      rmblink_valid_seq.start(rp_rmblink_seqr);
      rmblink_valid_seq.test_mode = TEST_IDEAL_ALL_0F;
    end

    `uvm_info("VSEQ", $sformatf("End Pattern Detection\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // D2C_RX_initiated_Result_handshake_TX_LTSM
    `uvm_info("VSEQ", $sformatf("D2C_RX_initiated_Result_handshake_TX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    p_sequencer.rx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::Data_To_Clock_test_RX_RX_INIT_Result_Handshake);
    send_sb_msg(sb_ltsm_item);

    // D2C_RX_initiated_Result_handshake_RX_LTSM
    `uvm_info("VSEQ", $sformatf("D2C_RX_initiated_Result_handshake_RX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::Data_To_Clock_test_RX_RX_INIT_Result_Handshake);
    send_sb_msg(sb_ltsm_item);

    // Data_To_Clock_test_RX_Sweep_Result_Handshake_TX_LTSM
    `uvm_info("VSEQ", $sformatf("Data_To_Clock_test_RX_Sweep_Result_Handshake_TX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    p_sequencer.rx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::Data_To_Clock_test_RX_Sweep_Result_Handshake);
    send_sb_msg(sb_ltsm_item);

    // Data_To_Clock_test_RX_Sweep_Result_Handshake_RX_LTSM
    `uvm_info("VSEQ", $sformatf("Data_To_Clock_test_RX_Sweep_Result_Handshake_RX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::Data_To_Clock_test_RX_Sweep_Result_Handshake);
    send_sb_msg(sb_ltsm_item);

    // Data_To_Clock_test_RX_RX_INIT_End_Init_Handshake_TX_LTSM
    `uvm_info("VSEQ", $sformatf("Data_To_Clock_test_RX_RX_INIT_End_Init_Handshake_TX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    p_sequencer.rx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::Data_To_Clock_test_RX_RX_INIT_End_Init_Handshake);
    send_sb_msg(sb_ltsm_item);

    // Data_To_Clock_test_RX_RX_INIT_End_Init_Handshake_RX_LTSM
    `uvm_info("VSEQ", $sformatf("Data_To_Clock_test_RX_RX_INIT_End_Init_Handshake_RX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::Data_To_Clock_test_RX_RX_INIT_End_Init_Handshake);
    send_sb_msg(sb_ltsm_item);
  endtask 
endclass : ucie_D2C_vseq
