//=============================================================================
// File       : ucie_sbinit_bringup_tx_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_sbinit_bringup_tx_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_sbinit_bringup_tx_vseq)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_sbinit_bringup_tx_vseq");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();
    sb_ltsm_item.data        = 64'h0;
    sb_ltsm_item.info        = 16'h0;
    sb_ltsm_item.wait_cycles = 100;
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::SBINIT_TX_Out_Of_Reset_MSG);
    fork
      begin
        forever begin
          // send out of reset
          send_sb_msg_blocking(sb_ltsm_item);
        end
      end
    join_none
    
    // Wait for the SBINIT_Out_Of_Reset message to be received at the RX side to be able to send the SBINIT_done_req
    @(out_of_rst_msg_received);

    // Stop sending SBINIT_Out_Of_Reset
    disable fork;

    // send sbinit done req
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::SBINIT_TX_Done_Handshake);
    send_sb_msg_blocking(sb_ltsm_item);

    // get sbinit done resp
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)
  endtask
endclass : ucie_sbinit_bringup_tx_vseq
