//=============================================================================
// File       : ucie_sbinit_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_sbinit_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_sbinit_vseq)

  event out_of_rst_msg_received;
  int sbinit_fail_cnt;

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
    trainerror_rdi_exit_vseq.start(ltsm_rdi_seqr);
    
    if (sbinit_fail_cnt == 0 || sbinit_fail_cnt == 1) begin
      `uvm_info(get_type_name(), $sformatf("Executing Attempt 1: sbinit_fail_cnt = %0d. Configuring RAND_TILL_TIMEOUT.", sbinit_fail_cnt), UVM_MEDIUM)
      sbinit_fail_cnt++;
      sbinit_phylink_random_seq.configure(._sbinit_seq_mode(RAND_TILL_TIMEOUT));
      sbinit_phylink_random_seq.start(sb_phylink_seqr);
    end else if (sbinit_fail_cnt == 2) begin
      `uvm_info(get_type_name(), $sformatf("Executing Attempt 2: sbinit_fail_cnt = %0d. Configuring RAND_TILL_DETECTION and DROP_OUT_OF_RESET.", sbinit_fail_cnt), UVM_MEDIUM)
      sbinit_fail_cnt++;
      sbinit_phylink_random_seq.configure(._sbinit_seq_mode(RAND_TILL_DETECTION));
      sbinit_phylink_random_seq.start(sb_phylink_seqr);
      sbinit_bringup_vseq.configure(._msg_drop_mode(DROP_OUT_OF_RESET));
      sbinit_bringup_vseq.start(p_sequencer);
    end else if (sbinit_fail_cnt == 3) begin
      `uvm_info(get_type_name(), $sformatf("Executing Attempt 3: sbinit_fail_cnt = %0d. Configuring RAND_TILL_DETECTION and DROP_DONE_REQ.", sbinit_fail_cnt), UVM_MEDIUM)
      sbinit_fail_cnt++;
      sbinit_phylink_random_seq.configure(._sbinit_seq_mode(RAND_TILL_DETECTION));
      sbinit_phylink_random_seq.start(sb_phylink_seqr);
      sbinit_bringup_vseq.configure(._msg_drop_mode(DROP_DONE_REQ));
      sbinit_bringup_vseq.start(p_sequencer);
    end else if (sbinit_fail_cnt == 4) begin
      `uvm_info(get_type_name(), $sformatf("Executing Attempt 4: sbinit_fail_cnt = %0d. Configuring RAND_TILL_DETECTION and NO_DROP.", sbinit_fail_cnt), UVM_MEDIUM)
      sbinit_fail_cnt++;
      sbinit_phylink_random_seq.configure(._sbinit_seq_mode(RAND_TILL_DETECTION));
      sbinit_phylink_random_seq.start(sb_phylink_seqr);
      sbinit_bringup_vseq.configure(._msg_drop_mode(NO_DROP));
      sbinit_bringup_vseq.start(p_sequencer);
    end
  endtask
  
endclass : ucie_sbinit_vseq


/*
fork
  begin // TX Thread
    // ===============================
    // SBINIT
    // ===============================
    sbinit_bringup_tx_vseq.start(p_sequencer);

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
    // ===============================
    // SBINIT
    // ===============================
    sbinit_bringup_rx_vseq.start(p_sequencer);

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
*/