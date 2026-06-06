//=============================================================================
// File       : ucie_sbinit_bringup_rx_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_sbinit_bringup_rx_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_sbinit_bringup_rx_vseq)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_sbinit_bringup_rx_vseq");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();
    // Get out of reset
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    -> out_of_rst_msg_received;

    forever begin
      // get sbinit done req
      p_sequencer.rx_fifo.get(sb_ltsm_item);

      if (sb_ltsm_item.get_rx_encoding() == sb_shared_pkg::SBINIT_RX_Done_Handshake) begin
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)
        break;
      end
    end

    // send sbinit done resp
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::SBINIT_RX_Done_Handshake);
    send_sb_msg_blocking(sb_ltsm_item);
  endtask
endclass : ucie_sbinit_bringup_rx_vseq
