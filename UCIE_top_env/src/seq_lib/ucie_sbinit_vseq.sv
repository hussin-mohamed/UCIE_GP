//=============================================================================
// File       : ucie_sbinit_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_sbinit_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_sbinit_vseq)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_sbinit_vseq");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();
    sbinit_phylink_rand_sequence.start(sb_phylink_seqr);

    // send out of reset
    sb_ltsm_item.data        = 64'h0;
    sb_ltsm_item.info        = 16'h0;
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::SBINIT_TX_Out_Of_Reset_MSG);
    send_sb_msg_blocking(sb_ltsm_item);

    // Get out of reset
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ_RX", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    fork
      begin // TX Thread
        // ===============================
        // SBINIT
        // ===============================
        // send sbinit done req
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::SBINIT_TX_Done_Handshake);
        send_sb_msg_blocking(sb_ltsm_item);

        // get sbinit done resp
        p_sequencer.tx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ_tx", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

        // ===============================
        // MBINIT.PARAM
        // ===============================
        // send mbinit param req
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_PARAM_TX_Config_Handshake);
        send_sb_msg_blocking(sb_ltsm_item);
        
        // get mbinit param resp
        p_sequencer.tx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

        // ===============================
        // MBINIT.CAL
        // ===============================
        // send mbinit cal req
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_CAL_TX_Done_Handshake);
        send_sb_msg_blocking(sb_ltsm_item);

        // get mbinit cal resp
        p_sequencer.tx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)
      end

      begin // RX Thread
        // get sbinit done req
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ_RX", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

        // send sbinit done resp
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::SBINIT_RX_Done_Handshake);
        send_sb_msg_blocking(sb_ltsm_item);

        // ===============================
        // MBINIT.PARAM
        // ===============================
        // get mbinit param req
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

        // send mbinit param resp
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_PARAM_RX_Send_RESP);
        send_sb_msg_blocking(sb_ltsm_item);

        // ===============================
        // MBINIT.CAL
        // ===============================
        // get mbinit cal req
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

        // send mbinit cal resp
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_CAL_RX_Done_Handshake);
        send_sb_msg_blocking(sb_ltsm_item);
      end
    join

    
  endtask
endclass : ucie_sbinit_vseq
