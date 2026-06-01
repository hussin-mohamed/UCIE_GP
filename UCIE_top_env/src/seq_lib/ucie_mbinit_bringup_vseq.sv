//=============================================================================
// File       : ucie_mbinit_bringup_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_mbinit_bringup_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_mbinit_bringup_vseq)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_mbinit_bringup_vseq");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();
    `uvm_info("UCIE_VSEQ", "Starting system-level sanity virtual sequence", UVM_LOW)

    sbinit_phylink_seq.start(sb_phylink_seqr);

    // Get out of reset
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("VSEQ", $sformatf("GOOOOOOOOOOOOOOT111\n %s", sb_ltsm_item.sprint()), UVM_LOW)


    // send out of reset
    sb_ltsm_item.data        = 64'h0;
    sb_ltsm_item.info        = 16'h0;
    sb_ltsm_item.msgtype     = REQ_MSG;
    sb_ltsm_item.wait_cycles = 30;
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::SBINIT_TX_Out_Of_Reset_MSG);
    send_sb_msg(sb_ltsm_item);

    // get sbinit done req
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("VSEQ", $sformatf("GOOOOOOOOOOOOOOT222\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send sbinit done req
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::SBINIT_TX_Done_Handshake);
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

    // get mbinit repairclk init req
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("VSEQ", $sformatf("GOOOOOOOOOOOOOOT777\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit repairclk init req
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_TX_Init_Handshake);
    send_sb_msg(sb_ltsm_item);

    // get mbinit repairclk init resp
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    `uvm_info("VSEQ", $sformatf("GOOOOOOOOOOOOOOT888\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit repairclk init resp
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_RX_Init_Handshake);
    send_sb_msg(sb_ltsm_item);

    // send RMBLink Clock Pattern Sequence
    `uvm_info("UCIE_VSEQ", "Starting rmblink_clk_seq on rp_rmblink_seqr", UVM_LOW)
    rmblink_clk_seq.test_mode = TEST_CLK_IDEAL_ALL;
    rmblink_clk_seq.start(rp_rmblink_seqr);
    `uvm_info("UCIE_VSEQ", "rmblink_clk_seq completed", UVM_LOW)

    // get mbinit repairclk result req
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("VSEQ", $sformatf("GOOOOOOOOOOOOOOT999\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit repairclk result req
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_TX_Result_Handshake);
    send_sb_msg(sb_ltsm_item);

    // get mbinit repairclk result resp
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    `uvm_info("VSEQ", $sformatf("GOOOOOOOOOOOOOOT1000\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit repairclk result resp
    sb_ltsm_item.data        = 64'hFFFFFFFFFFFFFFFF;
    sb_ltsm_item.info        = 16'hFFFF;
    sb_ltsm_item.msgtype     = RSP_MSG;
    sb_ltsm_item.wait_cycles = 30;
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_RX_Send_RESP);
    send_sb_msg(sb_ltsm_item);

    // get mbinit repairclk done req
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("VSEQ", $sformatf("GOOOOOOOOOOOOOOT1111\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit repairclk done req
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_TX_Done_Handshake);
    send_sb_msg(sb_ltsm_item);

    // get mbinit repairclk done resp
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    `uvm_info("VSEQ", $sformatf("GOOOOOOOOOOOOOOT1212\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit repairclk done resp
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_RX_Done_Handshake);
    send_sb_msg(sb_ltsm_item);

    `uvm_info("UCIE_VSEQ", "System-level sanity virtual sequence finished", UVM_LOW)
  endtask
endclass : ucie_mbinit_bringup_vseq
