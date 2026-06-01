//=============================================================================
// File       : ucie_mbtrain_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_mbtrain_vseq extends ucie_vseq_base;



  `uvm_object_utils(ucie_mbtrain_vseq)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_mbtrain_vseq");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();
    `uvm_info("UCIE_VSEQ", "Starting system-level sanity virtual sequence", UVM_LOW)

    sbinit_phylink_seq.start(sb_phylink_seqr);

    // Valverif__TX_LTSM
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("VSEQ", $sformatf("Valverif__TX_LTSM_req\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBTRAIN_VALVREF_TX_Start_Handshake);
    send_sb_msg(sb_ltsm_item);

    // Valverif__RX_LTSM
    `uvm_info("VSEQ", $sformatf("Valverif__RX_LTSM_req\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::RX_MBTRAIN_VALVREF_Start_Handshake);
    send_sb_msg(sb_ltsm_item);

    // get sbinit done resp
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    `uvm_info("VSEQ", $sformatf("GOOOOOOOOOOOOOOT333\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    
    // send sbinit done resp
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::SBINIT_RX_Done_Handshake);
    send_sb_msg(sb_ltsm_item);

    // get mbinit param req
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("VSEQ", $sformatf("GOOOOOOOOOOOOOOT444\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    
    // send mbinit param req
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_PARAM_TX_Config_Handshake);
    send_sb_msg(sb_ltsm_item);

    // get mbinit param resp
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    `uvm_info("VSEQ", $sformatf("GOOOOOOOOOOOOOOT555\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit param resp
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_PARAM_RX_Send_RESP);
    send_sb_msg(sb_ltsm_item);

    // get mbinit cal req
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("VSEQ", $sformatf("GOOOOOOOOOOOOOOT666\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit cal req
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_CAL_TX_Done_Handshake);
    send_sb_msg(sb_ltsm_item);

    // get mbinit cal resp
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    `uvm_info("VSEQ", $sformatf("GOOOOOOOOOOOOOOT666\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit param resp
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_CAL_RX_Done_Handshake);
    send_sb_msg(sb_ltsm_item);
    
    `uvm_info("UCIE_VSEQ", "System-level sanity virtual sequence finished", UVM_LOW)
  endtask

  task D2C_RX_initiated ();
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
    
    rmblink_clk_seq.start(rp_rmblink_seqr);

    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::Data_To_Clock_test_RX_RX_INIT_Result_Handshake);
    send_sb_msg(sb_ltsm_item);

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

    // D2C_RX_initiated__TX_LTSM
    `uvm_info("VSEQ", $sformatf("D2C_RX_initiated__TX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    p_sequencer.rx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.msgtype     = RSP_MSG;
    sb_ltsm_item.wait_cycles = 30;
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::DATA_TO_CLOCK_RX_RX_INIT_HANDSHAKE);
    send_sb_msg(sb_ltsm_item);

    // D2C_RX_initiated__RX_LTSM
    `uvm_info("VSEQ", $sformatf("D2C_RX_initiated__RX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.msgtype     = REQ_MSG;
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::DATA_TO_CLOCK_RX_RX_INIT_HANDSHAKE);
    send_sb_msg(sb_ltsm_item);
  endtask 
endclass : ucie_mbtrain_vseq
