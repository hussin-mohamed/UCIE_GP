//=============================================================================
// File       : ucie_vseq_base.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_vseq_base extends uvm_sequence;

  `uvm_object_utils(ucie_vseq_base)
  `uvm_declare_p_sequencer(ucie_vseqr)

  LTSM_pkg::ltsm_rdi_sequencer ltsm_rdi_seqr;
  sb_pkg::phylink_sequencer    sb_phylink_seqr;
  rp_pkg::rmblink_sequencer    rp_rmblink_seqr;
  tx_tb_pkg::rdi_sequencer     tx_rdi_seqr;
  phylink_seq_item             phylink_item;
  active_phylink_sequence      active_phylink_seq;
  sb_pkg::ltsm_seq_item        sb_ltsm_item;


  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_vseq_base");
    super.new(name);
  endfunction

  virtual task pre_body();
    ltsm_rdi_seqr      = p_sequencer.ltsm_rdi_seqr;
    sb_phylink_seqr    = p_sequencer.sb_phylink_seqr;
    rp_rmblink_seqr    = p_sequencer.rp_rmblink_seqr;
    tx_rdi_seqr        = p_sequencer.tx_rdi_seqr;
    active_phylink_seq = active_phylink_sequence::type_id::create("active_phylink_seq");
    sb_ltsm_item = new("sb_ltsm_item");
  endtask : pre_body

  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();
    `uvm_info("UCIE_VSEQ", "Starting system-level sanity virtual sequence", UVM_LOW)
    fork
      begin
          p_sequencer.link_fifo.get(phylink_item);
          active_phylink_seq.req = phylink_item;
          active_phylink_seq.start(sb_phylink_seqr);
      end

      begin
        sb_ltsm_item.data        = 64'habcd1234abcd1234;
        sb_ltsm_item.info        = 16'h5678;
        sb_ltsm_item.msgtype     = REQ_MSG;
        sb_ltsm_item.wait_cycles = 30;
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_PARAM_TX_Config_Handshake);
    
        send_sb_msg(sb_ltsm_item);
      end
    join

    `uvm_info("UCIE_VSEQ", "System-level sanity virtual sequence finished", UVM_LOW)
  endtask

  function void send_sb_msg(sb_pkg::ltsm_seq_item sb_ltsm_item);
    if (sb_ltsm_item.get_tx_encoding() != NOP_TX) begin
      p_sequencer.prd_ltsm2link.write_tx(sb_ltsm_item);
    end else begin
      p_sequencer.prd_ltsm2link.write_rx(sb_ltsm_item);
    end
  endfunction : send_sb_msg

endclass : ucie_vseq_base
