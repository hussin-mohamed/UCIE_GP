//=============================================================================
// File       : ucie_vseq_base.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

// enum for determining the whole behavioural of the D2c
typedef enum {
  SUCCESS,
  LOOP_TILL_ERROR
} D2c_mode_e;

// enum for determining the value of the pattern driven to the rx path
typedef enum {
  PAT_ALL_LANES_VALID,
  PAT_UPPER_8_LANES_VALID,
  PAT_LOWER_8_LANES_VALID,
  PAT_NO_LANES_VALID
} pattern_mode_e;

typedef enum {
  VALID_CORRECT,
  VALID_ERROR
} valid_mode_e;

typedef enum {
  CORRECT,
  ERROR
} info_mode_e;

typedef enum {
  ALL_LANES_VALID,
  UPPER_8_LANES_VALID,
  LOWER_8_LANES_VALID,
  NO_LANES_VALID
} message_mode_e;

typedef enum {
  LFSR_PATTERN,
  VALID_PATTERN,
  PER_LANE_ID_PATTERN
} data_mode_e;

typedef enum {
  ALL_LANES,
  UPPER_8_LANES,
  LOWER_8_LANES,
  NO_LANES
} lane_map_code_e;

typedef enum {
  TIMEOUT,
  TRAINERROR_STATE
  } trainerror_e;

typedef class ucie_mbtrain_valverf_vseq;
typedef class ucie_mbtrain_dataverf_vseq;
typedef class ucie_mbtrain_speedidle_vseq;
typedef class ucie_mbtrain_txselfcal_vseq;
typedef class ucie_mbtrain_rxclkcal_vseq;
typedef class ucie_mbtrain_valtraincenter_vseq;
typedef class ucie_mbtrain_valtrainverf_vseq;
typedef class ucie_mbtrain_DTC1_vseq;
typedef class ucie_mbtrain_datatrainvref_vseq;
typedef class ucie_mbtrain_rxdskew_vseq;
typedef class ucie_mbtrain_DTC2_vseq;
typedef class ucie_mbtrain_linkspeed_vseq;

class ucie_vseq_base extends uvm_sequence;

  `uvm_object_utils(ucie_vseq_base)
  `uvm_declare_p_sequencer(ucie_vseqr)

  LTSM_pkg::ltsm_rdi_sequencer  ltsm_rdi_seqr;
  sb_pkg::phylink_sequencer     sb_phylink_seqr;
  rp_pkg::rmblink_sequencer     rp_rmblink_seqr;
  tx_tb_pkg::rdi_sequencer      tx_rdi_seqr;

  phylink_seq_item      phylink_item;
  sb_pkg::ltsm_seq_item sb_ltsm_item;
  
  static int  ltsm2link_msg_cnt;
  local event msg_serialization_finished;

  active_phylink_sequence           active_phylink_seq;
  sbinit_phylink_sanity_seq         sbinit_phylink_seq;
  rmblink_sanity_clk_sequence       rmblink_clk_seq;
  rmblink_sanity_valid_sequence     rmblink_valid_seq;
  rmblink_sanity_lfsr_sequence      rmblink_lfsr_seq;
  rmblink_sanity_PerLaneID_sequence rmblink_PerLaneID_seq;

  ucie_mbtrain_valverf_vseq         valverf_vseq;
  ucie_mbtrain_dataverf_vseq        dataverf_vseq;
  ucie_mbtrain_speedidle_vseq       speedidle_vseq;
  ucie_mbtrain_txselfcal_vseq       txselfcal_vseq;
  ucie_mbtrain_rxclkcal_vseq        rxclkcal_vseq;
  ucie_mbtrain_valtraincenter_vseq  valtraincenter_vseq;
  ucie_mbtrain_valtrainverf_vseq    valtrainverf_vseq;
  ucie_mbtrain_DTC1_vseq            DTC1_vseq;
  ucie_mbtrain_datatrainvref_vseq   datatrainvref_vseq;
  ucie_mbtrain_rxdskew_vseq         rxdskew_vseq;
  ucie_mbtrain_DTC2_vseq            DTC2_vseq;
  ucie_mbtrain_linkspeed_vseq       LINKSPEED_vseq;

  rdi_base_seq            active_tx_seq;
  rmblink_active_sequence active_rx_seq;

  protected D2c_mode_e       D2c_mode;
  protected pattern_mode_e   pattern_mode;
  protected data_mode_e      data_mode;
  protected info_mode_e      info_mode;
  protected message_mode_e   message_mode;
  protected valid_mode_e     valid_mode;
  protected lane_map_code_e  lane_map_code;
  protected trainerror_e     train_error_state;
  protected bit              is_configured;

  ucie_RX_D2C_vseq  ucie_RX_D2C;
  ucie_TX_D2C_vseq  ucie_TX_D2C;

  LTSM_pkg::linkinit_wake_req_handshake   wake_req_handshake;
  LTSM_pkg::linkinit_state_req_handshake  state_req_handshake;
  
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_vseq_base");
    super.new(name);
  endfunction

  virtual task pre_body();
    p_sequencer.msg_ser_status = NO_MSG_SER_IN_PROGRESS;
    
    ltsm_rdi_seqr   = p_sequencer.ltsm_rdi_seqr;
    sb_phylink_seqr = p_sequencer.sb_phylink_seqr;
    rp_rmblink_seqr = p_sequencer.rp_rmblink_seqr;
    tx_rdi_seqr     = p_sequencer.tx_rdi_seqr;

    active_phylink_seq    = active_phylink_sequence::type_id::create("active_phylink_seq");
    sbinit_phylink_seq    = sbinit_phylink_sanity_seq::type_id::create("sbinit_phylink_seq");
    rmblink_clk_seq       = rmblink_sanity_clk_sequence::type_id::create("rmblink_clk_seq");
    rmblink_valid_seq     = rmblink_sanity_valid_sequence::type_id::create("rmblink_valid_seq");
    rmblink_lfsr_seq      = rmblink_sanity_lfsr_sequence::type_id::create("rmblink_lfsr_seq");
    ucie_RX_D2C           = ucie_RX_D2C_vseq::type_id::create("ucie_RX_D2C");
    ucie_TX_D2C           = ucie_TX_D2C_vseq::type_id::create("ucie_TX_D2C");
    wake_req_handshake    = linkinit_wake_req_handshake::type_id::create("wake_req_handshake");
    state_req_handshake   = linkinit_state_req_handshake::type_id::create("state_req_handshake");
    rmblink_PerLaneID_seq = rmblink_sanity_PerLaneID_sequence::type_id::create("rmblink_PerLaneID_seq");

    valverf_vseq        = ucie_mbtrain_valverf_vseq::type_id::create("valverf_vseq");
    dataverf_vseq       = ucie_mbtrain_dataverf_vseq::type_id::create("valverf_vseq");
    speedidle_vseq      = ucie_mbtrain_speedidle_vseq::type_id::create("speedidle_vseq");
    txselfcal_vseq      = ucie_mbtrain_txselfcal_vseq::type_id::create("txselfcal_vseq");
    rxclkcal_vseq       = ucie_mbtrain_rxclkcal_vseq::type_id::create("rxclkcal_vseq");
    valtraincenter_vseq = ucie_mbtrain_valtraincenter_vseq::type_id::create("valtraincenter_vseq");
    valtrainverf_vseq   = ucie_mbtrain_valtrainverf_vseq::type_id::create("valtrainverf_vseq");
    DTC1_vseq           = ucie_mbtrain_DTC1_vseq::type_id::create("DTC1_vseq");
    datatrainvref_vseq  = ucie_mbtrain_datatrainvref_vseq::type_id::create("datatrainvref_vseq");
    rxdskew_vseq        = ucie_mbtrain_rxdskew_vseq::type_id::create("rxdskew_vseq");
    DTC2_vseq           = ucie_mbtrain_DTC2_vseq::type_id::create("DTC2_vseq");
    LINKSPEED_vseq      = ucie_mbtrain_linkspeed_vseq::type_id::create("LINKSPEED_vseq");

    active_tx_seq = rdi_base_seq::type_id::create("active_tx_seq");
    active_rx_seq = rmblink_active_sequence::type_id::create("active_rx_seq");
    
    sb_ltsm_item = new("sb_ltsm_item");
    
    fork
      begin  // Sideband ltsm2link Transmission Thread
        forever begin
          p_sequencer.link_fifo.get(phylink_item);
          active_phylink_seq.req = phylink_item;
          p_sequencer.msg_ser_status = MSG_SER_IN_PROGRESS;
          active_phylink_seq.start(sb_phylink_seqr);
          p_sequencer.msg_ser_status = NO_MSG_SER_IN_PROGRESS;
        end
      end
    join_none
  endtask : pre_body

  function void send_sb_msg(sb_pkg::ltsm_seq_item _sb_ltsm_item);
    string enc_type;
    string enc_name;
    sb_pkg::tx_encoding_t tx_enc;
    sb_pkg::rx_encoding_t rx_enc;

    // Fatal message incase the user passed _sb_ltsm_item gotten from tx/rx encoding directly
    if (_sb_ltsm_item.get_dir() == MSG_TO_RX || _sb_ltsm_item.get_dir() == MSG_TO_TX) begin
      `uvm_fatal("VSEQ_BASE", "TX/RX Encoding is not set. You must call _sb_ltsm_item's set_tx/rx_encoding() before passing it to send_sb_msg(). \
        \nMost Probably, you have passed the _sb_ltsm_item you got from tx/rx_fifo directly to send_sb_msg()")
    end

    tx_enc = _sb_ltsm_item.get_tx_encoding();
    rx_enc = _sb_ltsm_item.get_rx_encoding();

    if (tx_enc != NOP_TX) begin
      enc_type = "TX Encoding";
      enc_name = tx_enc.name();
      p_sequencer.prd_ltsm2link.write_tx(_sb_ltsm_item);
    end else begin
      enc_type = "RX Encoding";
      enc_name = rx_enc.name();
      p_sequencer.prd_ltsm2link.write_rx(_sb_ltsm_item);
    end

    ltsm2link_msg_cnt++;

    `uvm_info("VSEQ_BASE", $sformatf("Sending LTSM2LINK Sideband message [Index %0d]. %s: %s", ltsm2link_msg_cnt, enc_type, enc_name), UVM_DEBUG)
  endfunction : send_sb_msg

  task wait_for_msg_ser_end();
    #0;
    if (p_sequencer.msg_ser_status == MSG_SER_IN_PROGRESS) begin
      wait(p_sequencer.msg_ser_status == NO_MSG_SER_IN_PROGRESS);
    end
  endtask : wait_for_msg_ser_end

endclass : ucie_vseq_base
