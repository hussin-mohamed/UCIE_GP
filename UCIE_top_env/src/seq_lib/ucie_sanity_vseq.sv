//=============================================================================
// File       : ucie_sanity_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_sanity_vseq extends uvm_sequence;

  `uvm_object_utils(ucie_sanity_vseq)
  `uvm_declare_p_sequencer(ucie_vseqr)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_sanity_vseq");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();
    `uvm_info("UCIE_VSEQ", "Starting system-level sanity virtual sequence", UVM_LOW)

    // Run the sub-sequences concurrently
    fork
      // 1. LTSM: only rdi_agt is active; FSM-SB/controllers stay passive (SB env + TB).
      //    Drive linkinit RDI handshakes on ltsm_rdi_seqr after partner init progresses.
      begin
        virtual ltsm_rdi_if ltsm_rdi_vif;
        LTSM_pkg::linkinit_wake_req_handshake  ltsm_wake_seq;
        LTSM_pkg::linkinit_state_req_handshake ltsm_active_seq;

        if (p_sequencer.ltsm_rdi_seqr == null) begin
          `uvm_error("UCIE_VSEQ", "ltsm_rdi_seqr is null!")
        end else begin
          if (!uvm_config_db#(virtual ltsm_rdi_if)::get(null, "", "ltsm_rdi_vif", ltsm_rdi_vif))
            `uvm_fatal("UCIE_VSEQ", "ltsm_rdi_vif not set")

          @(negedge ltsm_rdi_vif.i_reset);

          forever begin
            @(posedge ltsm_rdi_vif.clk);
            if (ltsm_rdi_vif.o_pl_inband_pres || ltsm_rdi_vif.o_pl_clk_req)
              break;
          end

          ltsm_wake_seq   = LTSM_pkg::linkinit_wake_req_handshake::type_id::create("ltsm_wake_seq");
          ltsm_active_seq = LTSM_pkg::linkinit_state_req_handshake::type_id::create("ltsm_active_seq");
          ltsm_wake_seq.start(p_sequencer.ltsm_rdi_seqr);
          ltsm_active_seq.start(p_sequencer.ltsm_rdi_seqr);
        end
      end

      // 2. Sideband: Phylink Handshakes
      begin
        sb_pkg::sbinit_phylink_sanity_seq sb_init_seq;
        sb_pkg::active_phylink_sanity_seq sb_act_seq;

        sb_init_seq = sb_pkg::sbinit_phylink_sanity_seq::type_id::create("sb_init_seq");
        sb_act_seq  = sb_pkg::active_phylink_sanity_seq::type_id::create("sb_act_seq");

        if (p_sequencer.sb_phylink_seqr != null) begin
          sb_init_seq.start(p_sequencer.sb_phylink_seqr);
          sb_act_seq.start(p_sequencer.sb_phylink_seqr);
        end else begin
          `uvm_error("UCIE_VSEQ", "sb_phylink_seqr is null!")
        end
      end

      // 3. RX-Path: Mainband Training Patterns
      begin
        rp_pkg::rmblink_sanity_valid_sequence rp_seq;
        rp_seq = rp_pkg::rmblink_sanity_valid_sequence::type_id::create("rp_seq");

        if (p_sequencer.rp_rmblink_seqr != null) begin
          rp_seq.start(p_sequencer.rp_rmblink_seqr);
        end else begin
          `uvm_error("UCIE_VSEQ", "rp_rmblink_seqr is null!")
        end
      end

      // 4. TX-Path: RDI FLIT Generation
      begin
        // Note: The active_rdi_seq internally blocks on the TLM FIFO
        // until the LTSM reaches ACTIVE state, so it naturally synchronizes!
        tx_tb_pkg::rdi_base_seq tx_seq;
        tx_seq = tx_tb_pkg::rdi_base_seq::type_id::create("tx_seq");

        if (p_sequencer.tx_rdi_seqr != null) begin
          tx_seq.start(p_sequencer.tx_rdi_seqr);
        end else begin
          `uvm_error("UCIE_VSEQ", "tx_rdi_seqr is null!")
        end
      end
    join

    `uvm_info("UCIE_VSEQ", "System-level sanity virtual sequence finished", UVM_LOW)
  endtask

endclass : ucie_sanity_vseq
