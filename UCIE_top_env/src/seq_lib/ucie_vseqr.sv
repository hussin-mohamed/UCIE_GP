//=============================================================================
// File       : ucie_vseqr.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequencer for the system-level environment.
//=============================================================================
typedef enum {
  NO_MSG_SER_IN_PROGRESS,
  MSG_SER_IN_PROGRESS
} msg_ser_status_e;
class ucie_vseqr extends uvm_sequencer;

  `uvm_component_utils(ucie_vseqr)

  // -------------------------------------------------------------------------
  //  Child Sequencer Handles
  // -------------------------------------------------------------------------
  LTSM_pkg::ltsm_rdi_sequencer                      ltsm_rdi_seqr;
  sb_pkg::phylink_sequencer                         sb_phylink_seqr;
  rp_pkg::rmblink_sequencer                         rp_rmblink_seqr;
  tx_tb_pkg::rdi_sequencer                          tx_rdi_seqr;

  sb_pkg::sb_pred_link2ltsm                         prd_link2ltsm;
  sb_pkg::sb_pred_ltsm2link                         prd_ltsm2link;

  uvm_analysis_export #(phylink_seq_item)           axp_in;
  
  uvm_tlm_analysis_fifo #(sb_pkg::ltsm_seq_item)    tx_fifo;
  uvm_tlm_analysis_fifo #(sb_pkg::ltsm_seq_item)    rx_fifo;
  uvm_tlm_analysis_fifo #(sb_pkg::phylink_seq_item) link_fifo;

  msg_ser_status_e msg_ser_status;
  bit transmission_thread_started;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_vseqr", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // build_phase
  // -----------

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    prd_link2ltsm = sb_pred_link2ltsm::type_id::create("prd_link2ltsm", this);
    prd_ltsm2link = sb_pred_ltsm2link::type_id::create("prd_ltsm2link", this);

    axp_in    = new("axp_in", this);
    tx_fifo   = new("tx_fifo", this);
    rx_fifo   = new("rx_fifo", this);
    link_fifo = new("link_fifo", this);
  endfunction : build_phase

  // connect_phase
  // -------------

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    axp_in.connect(prd_link2ltsm.analysis_export);
    prd_link2ltsm.results_ap_tx.connect(
        rx_fifo.analysis_export);  // Message from DUT's TX to my RX
    prd_link2ltsm.results_ap_rx.connect(
        tx_fifo.analysis_export);  // Message from DUT's RX to my TX
    prd_ltsm2link.results_ap_phy.connect(link_fifo.analysis_export);
  endfunction : connect_phase

  task pre_reset_phase(uvm_phase phase);
    super.pre_reset_phase(phase);

    // Stop all the virtual sequences before restarting the main phase
    stop_sequences();
    transmission_thread_started = 0;

    // Flush the FIFOs to avoid getting old messages from the prvious main phase run
    tx_fifo.flush();
    rx_fifo.flush();
    link_fifo.flush();
  endtask : pre_reset_phase

endclass : ucie_vseqr
