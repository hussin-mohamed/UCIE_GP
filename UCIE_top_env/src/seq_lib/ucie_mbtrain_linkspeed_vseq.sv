//=============================================================================
// File       : ucie_mbtrain_linkspeed_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_mbtrain_linkspeed_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_mbtrain_linkspeed_vseq)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_mbtrain_linkspeed_vseq");
    super.new(name);
  endfunction

  function configure (D2c_mode_e D2c_mode, pattern_mode_e pattern_mode,
                      data_mode_e data_mode, info_mode_e info_mode, message_mode_e message_mode, valid_mode_e valid_mode, lane_map_code_e lane_map_code);
    this.D2c_mode = D2c_mode;
    this.pattern_mode = pattern_mode;
    this.data_mode = data_mode;
    this.info_mode = info_mode;
    this.message_mode = message_mode;
    this.valid_mode = valid_mode;
    this.lane_map_code = lane_map_code;
    is_configured = 1;
  endfunction

  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();
    `uvm_info("UCIE_VSEQ", "Starting system-level sanity virtual sequence", UVM_LOW)

    if (!is_configured) begin
      `uvm_fatal("SEQ_CFG_ERR", "Sequence must be configured via configure() before starting!")
    end

    is_configured = 0;

    // DTC2_Start_TX_LTSM
    `uvm_info("VSEQ", $sformatf("DTC2_Start_TX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    p_sequencer.rx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBTRAIN_LINKSPEED_TX_Start_Handshake);
    send_sb_msg(sb_ltsm_item);

    // DTC2_Start_RX_LTSM
    `uvm_info("VSEQ", $sformatf("DTC2_Start_RX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBTRAIN_LINKSPEED_RX_Start_Handshake);
    send_sb_msg(sb_ltsm_item);

    // DTC2_D2C_RX_LTSM
    `uvm_info("VSEQ", $sformatf("DTC2_D2C_RX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    ucie_TX_D2C.configure(
      D2c_mode,
      pattern_mode,
      data_mode,
      info_mode,
      message_mode,
      valid_mode,
      lane_map_code
    );

    ucie_TX_D2C.start(p_sequencer);

    // DTC2_End_TX_LTSM
    `uvm_info("VSEQ", $sformatf("DTC2_End_TX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    if ((message_mode == ALL_LANES_VALID && pattern_mode != PAT_ALL_LANES_VALID) || (message_mode != ALL_LANES_VALID && pattern_mode == PAT_ALL_LANES_VALID)) begin
      `uvm_fatal("TEST_ERROR", "invalid configuration")
    end

    if (message_mode == ALL_LANES_VALID && pattern_mode == PAT_ALL_LANES_VALID) begin
      p_sequencer.rx_fifo.get(sb_ltsm_item);
      sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBTRAIN_LINKSPEED_TX_LinksSpeed_Done_Hnd);
      send_sb_msg(sb_ltsm_item);

      p_sequencer.tx_fifo.get(sb_ltsm_item);
      sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBTRAIN_LINKSPEED_RX_Send_Done_RESP);
      send_sb_msg(sb_ltsm_item);
    end else if (message_mode != ALL_LANES_VALID && pattern_mode != PAT_ALL_LANES_VALID) begin
      // p_sequencer.rx_fifo.get(sb_ltsm_item);
      // sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBTRAIN_LINKSPEED_TX_End_Handshake);
      // send_sb_msg(sb_ltsm_item);
      
      // p_sequencer.rx_fifo.get(sb_ltsm_item);
      // sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBTRAIN_LINKSPEED_TX_End_Handshake);
      // send_sb_msg(sb_ltsm_item);
    end

  endtask
endclass : ucie_mbtrain_linkspeed_vseq
