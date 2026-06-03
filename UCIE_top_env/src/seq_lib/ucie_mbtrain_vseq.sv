//=============================================================================
// File       : ucie_mbtrain_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_mbtrain_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_mbtrain_vseq)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_mbtrain_vseq");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();
    valverf_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(VALID_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT)
    );

    dataverf_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT)
    );

    valtraincenter_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(VALID_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT),
        .trainerror(TRAINERROR_STATE)
    );
    
    valtrainverf_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(VALID_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT)
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
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT),
        .lane_map_code(ALL_LANES)
    );

    valverf_vseq.start(p_sequencer);
    dataverf_vseq.start(p_sequencer);
    speedidle_vseq.start(p_sequencer);
    txselfcal_vseq.start(p_sequencer);
    rxclkcal_vseq.start(p_sequencer);
    valtraincenter_vseq.start(p_sequencer);
    valtrainverf_vseq.start(p_sequencer);
    DTC1_vseq.start(p_sequencer);
    datatrainvref_vseq.start(p_sequencer);
    rxdskew_vseq.start(p_sequencer);
    DTC2_vseq.start(p_sequencer);
    LINKSPEED_vseq.start(p_sequencer);

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
    

  endtask
endclass : ucie_mbtrain_vseq
