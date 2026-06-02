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

  ucie_mbtrain_valverf_vseq valverf_vseq;
  ucie_mbtrain_dataverf_vseq dataverf_vseq;
  ucie_mbtrain_speedidle_vseq speedidle_vseq;
  ucie_mbtrain_txselfcal_vseq txselfcal_vseq;
  ucie_mbtrain_rxclkcal_vseq rxclkcal_vseq;
  ucie_mbtrain_valtraincenter_vseq valtraincenter_vseq;
  ucie_mbtrain_valtrainverf_vseq valtrainverf_vseq;
  ucie_mbtrain_DTC1_vseq DTC1_vseq;
  ucie_mbtrain_datatrainvref_vseq datatrainvref_vseq;
  ucie_mbtrain_rxdskew_vseq rxdskew_vseq;
  ucie_mbtrain_DTC2_vseq DTC2_vseq;
  ucie_mbtrain_linkspeed_vseq LINKSPEED_vseq;

  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();
  valverf_vseq = ucie_mbtrain_valverf_vseq::type_id::create("valverf_vseq");
  dataverf_vseq = ucie_mbtrain_dataverf_vseq::type_id::create("valverf_vseq");
  speedidle_vseq = ucie_mbtrain_speedidle_vseq::type_id::create("speedidle_vseq");
  txselfcal_vseq = ucie_mbtrain_txselfcal_vseq::type_id::create("txselfcal_vseq");
  rxclkcal_vseq = ucie_mbtrain_rxclkcal_vseq::type_id::create("rxclkcal_vseq");
  valtraincenter_vseq = ucie_mbtrain_valtraincenter_vseq::type_id::create("valtraincenter_vseq");
  valtrainverf_vseq = ucie_mbtrain_valtrainverf_vseq::type_id::create("valtrainverf_vseq");
  DTC1_vseq = ucie_mbtrain_DTC1_vseq::type_id::create("DTC1_vseq");
  datatrainvref_vseq = ucie_mbtrain_datatrainvref_vseq::type_id::create("datatrainvref_vseq");
  rxdskew_vseq = ucie_mbtrain_rxdskew_vseq::type_id::create("rxdskew_vseq");
  DTC2_vseq = ucie_mbtrain_DTC2_vseq::type_id::create("DTC2_vseq");
  LINKSPEED_vseq = ucie_mbtrain_linkspeed_vseq::type_id::create("LINKSPEED_vseq");
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
        .valid_mode(VALID_CORRECT)
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

    $display("ana get hena emta %0t",$time);

    // wake_req_handshake.start(ltsm_rdi_seqr);
    // state_req_handshake.start(ltsm_rdi_seqr);
    
    // p_sequencer.rx_fifo.get(sb_ltsm_item);
    // sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBTRAIN_VALVREF_TX_End_Handshake);
    // send_sb_msg(sb_ltsm_item);

  endtask
endclass : ucie_mbtrain_vseq
