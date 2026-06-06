//=============================================================================
// File       : ucie_vvref_till_rxcal_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_vvref_till_rxcal_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_vvref_till_rxcal_vseq)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_vvref_till_rxcal_vseq");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();


    trainerror_rdi_exit_vseq.start(ltsm_rdi_seqr);
    mbinit_vseq.start(p_sequencer);

  // -------------------------------------------------------------------------
  //  TEST 1 : No Start HS Req Sent to RX 
  // -------------------------------------------------------------------------
    if (TRAINERROR_vseq.trainerr_cnt == 0) begin
      valverf_vseq.configure(
          .D2c_mode(SUCCESS),
          .pattern_mode(PAT_ALL_LANES_VALID),
          .data_mode(VALID_PATTERN),
          .info_mode(CORRECT),
          .message_mode(ALL_LANES_VALID),
          .valid_mode(VALID_CORRECT),
          .missing_msg(MISS)
      );
      valverf_vseq.start(p_sequencer);
    end

    else if (TRAINERROR_vseq.trainerr_cnt == 1) begin
      valverf_vseq.configure(
          .D2c_mode(SUCCESS),
          .pattern_mode(PAT_ALL_LANES_VALID),
          .data_mode(VALID_PATTERN),
          .info_mode(CORRECT),
          .message_mode(ALL_LANES_VALID),
          .valid_mode(VALID_CORRECT),
          .missing_msg(MISS)
      );

      valverf_vseq.start(p_sequencer);
    end

    else if (TRAINERROR_vseq.trainerr_cnt == 2) begin
      valverf_vseq.configure(
          .D2c_mode(SUCCESS),
          .pattern_mode(PAT_ALL_LANES_VALID),
          .data_mode(VALID_PATTERN),
          .info_mode(CORRECT),
          .message_mode(ALL_LANES_VALID),
          .valid_mode(VALID_CORRECT),
          .missing_msg(MISS)
      );
      valverf_vseq.start(p_sequencer);
    end

    else if (TRAINERROR_vseq.trainerr_cnt == 3) begin
      valverf_vseq.configure(
          .D2c_mode(SUCCESS),
          .pattern_mode(PAT_ALL_LANES_VALID),
          .data_mode(VALID_PATTERN),
          .info_mode(CORRECT),
          .message_mode(ALL_LANES_VALID),
          .valid_mode(VALID_CORRECT),
          .missing_msg(MISS)
      );
      valverf_vseq.start(p_sequencer);
    end

    else if (TRAINERROR_vseq.trainerr_cnt == 4) begin
      valverf_vseq.configure(
          .D2c_mode(SUCCESS),
          .pattern_mode(PAT_ALL_LANES_VALID),
          .data_mode(VALID_PATTERN),
          .info_mode(CORRECT),
          .message_mode(ALL_LANES_VALID),
          .valid_mode(VALID_CORRECT),
          .missing_msg(IDEAL)
      );
      valverf_vseq.start(p_sequencer);
    end



    //dataverf_vseq.configure(
    //    .D2c_mode(SUCCESS),
    //    .pattern_mode(PAT_ALL_LANES_VALID),
    //    .data_mode(LFSR_PATTERN),
    //    .info_mode(CORRECT),
    //    .message_mode(ALL_LANES_VALID),
    //    .valid_mode(VALID_CORRECT)
    //);
    //dataverf_vseq.start(p_sequencer);
    //speedidle_vseq.start(p_sequencer);
    //txselfcal_vseq.start(p_sequencer);
    //rxclkcal_vseq.start(p_sequencer);

    wait_for_msg_ser_end();
    

  endtask
endclass : ucie_vvref_till_rxcal_vseq
