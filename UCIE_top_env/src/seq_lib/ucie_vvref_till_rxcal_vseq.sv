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
          .missing_msg(MISS)
      );
      valverf_vseq.start(p_sequencer);
    end

    else if (TRAINERROR_vseq.trainerr_cnt == 5) begin
      valverf_vseq.configure(
          .D2c_mode(LOOP_TILL_ERROR),
          .pattern_mode(PAT_UPPER_8_LANES_VALID),
          .data_mode(VALID_PATTERN),
          .info_mode(ERROR),
          .message_mode(ALL_LANES_VALID),
          .valid_mode(VALID_CORRECT),
          .missing_msg(IDEAL)
      );
      valverf_vseq.start(p_sequencer);
    end




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

    if (TRAINERROR_vseq.trainerr_cnt == 6) begin
      dataverf_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT),
        .missing_msg(MISS)
    );
    dataverf_vseq.start(p_sequencer);
    end

    else if (TRAINERROR_vseq.trainerr_cnt == 7) begin
      dataverf_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT),
        .missing_msg(MISS)
    );
    dataverf_vseq.start(p_sequencer);
    end

    else if (TRAINERROR_vseq.trainerr_cnt == 8) begin
      dataverf_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT),
        .missing_msg(MISS)
    );
    dataverf_vseq.start(p_sequencer);
    end

    else if (TRAINERROR_vseq.trainerr_cnt == 9) begin
      dataverf_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT),
        .missing_msg(MISS)
    );
    dataverf_vseq.start(p_sequencer);
    end

    else if (TRAINERROR_vseq.trainerr_cnt == 10) begin
      dataverf_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT),
        .missing_msg(MISS)
    );
    dataverf_vseq.start(p_sequencer);
    end

    else if (TRAINERROR_vseq.trainerr_cnt == 11) begin
      dataverf_vseq.configure(
        .D2c_mode(LOOP_TILL_ERROR),
        .pattern_mode(PAT_UPPER_8_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(ERROR),
        .message_mode(UPPER_8_LANES_VALID),
        .valid_mode(VALID_CORRECT),
        .missing_msg(IDEAL)
    );
    dataverf_vseq.start(p_sequencer);
    end





    dataverf_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT),
        .missing_msg(IDEAL)
    );
    dataverf_vseq.start(p_sequencer);

    if (TRAINERROR_vseq.trainerr_cnt == 12) begin
      speedidle_vseq.configure(
        .missing_msg(MISS)
    );
    speedidle_vseq.start(p_sequencer);
    end

    else if (TRAINERROR_vseq.trainerr_cnt == 13) begin
      speedidle_vseq.configure(
        .missing_msg(MISS)
    );
    speedidle_vseq.start(p_sequencer);
    end




    speedidle_vseq.configure(
        .missing_msg(IDEAL)
    );
    speedidle_vseq.start(p_sequencer);

    if (TRAINERROR_vseq.trainerr_cnt == 14) begin
      txselfcal_vseq.configure(
        .missing_msg(MISS)
    );
    txselfcal_vseq.start(p_sequencer);
    end

    else if (TRAINERROR_vseq.trainerr_cnt == 15) begin
      txselfcal_vseq.configure(
        .missing_msg(MISS)
    );
    txselfcal_vseq.start(p_sequencer);
    end




    txselfcal_vseq.configure(
        .missing_msg(IDEAL)
    );
    txselfcal_vseq.start(p_sequencer);

    if (TRAINERROR_vseq.trainerr_cnt == 16) begin
      rxclkcal_vseq.configure(
        .missing_msg(MISS)
    );
    rxclkcal_vseq.start(p_sequencer);
    end

    else if (TRAINERROR_vseq.trainerr_cnt == 17) begin
      rxclkcal_vseq.configure(
        .missing_msg(MISS)
    );
    rxclkcal_vseq.start(p_sequencer);
    end

    else if (TRAINERROR_vseq.trainerr_cnt == 18) begin
      rxclkcal_vseq.configure(
        .missing_msg(MISS)
    );
    rxclkcal_vseq.start(p_sequencer);
    end

    else if (TRAINERROR_vseq.trainerr_cnt == 19) begin
      rxclkcal_vseq.configure(
        .missing_msg(MISS)
    );
    rxclkcal_vseq.start(p_sequencer);
    end

    rxclkcal_vseq.configure(
        .missing_msg(IDEAL)
    );
    rxclkcal_vseq.start(p_sequencer);

    valtraincenter_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(VALID_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT),
        .trainerror(NOT_TRAINERROR)
    );

    valtrainverf_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(VALID_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT),
        .trainerror(NOT_TRAINERROR)
    );
    
    DTC1_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT)
    );

    datatrainvref_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT)
    );

    DTC2_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT)
    );

    LINKSPEED_vseq.configure(
        .linkspeed_dest(LINKINIT)
        ,.pattern_mode(PAT_ALL_LANES_VALID)
        ,.message_mode(ALL_LANES_VALID)
        ,.speed_idle_entry(CURRENT_DIE)
    );


    valtraincenter_vseq.start(p_sequencer);
    valtrainverf_vseq.start(p_sequencer);
    DTC1_vseq.start(p_sequencer);
    datatrainvref_vseq.start(p_sequencer);
    rxdskew_vseq.start(p_sequencer);
    DTC2_vseq.start(p_sequencer);
    LINKSPEED_vseq.start(p_sequencer);

    wait_for_msg_ser_end();
    // #1000ns;

    wake_req_handshake.start(ltsm_rdi_seqr);
    state_req_handshake.start(ltsm_rdi_seqr);
    
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::ACTIVE_LINKINIT_STATE_REQ);
    send_sb_msg(sb_ltsm_item);

    p_sequencer.tx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::ACTIVE_LINKINIT_STATE_RESP);
    send_sb_msg(sb_ltsm_item);

    wait_for_msg_ser_end();

    fork
        begin
            active_tx_seq.start(tx_rdi_seqr);
        end
        begin
            active_rx_seq.configure(
                ._num_256b_chunks(2),
                ._lane_map_code(X16_MODE),
                ._scenario(ACTIVE_SCENARIO_IDEAL)
            );
            active_rx_seq.start(rp_rmblink_seqr);
        end     
    join_any
    
    wait_for_msg_ser_end();
    

  endtask
endclass : ucie_vvref_till_rxcal_vseq
