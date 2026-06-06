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

  function configure (linkspeed_destination_e linkspeed_dest, pattern_mode_e pattern_mode, message_mode_e message_mode, speed_idle_entry_e speed_idle_entry );
    this.linkspeed_dest = linkspeed_dest;
    this.pattern_mode = pattern_mode;
    this.message_mode = message_mode;
    this.speed_idle_entry = speed_idle_entry;
    if (linkspeed_dest == LINKINIT) begin
      this.D2c_mode = SUCCESS;
      this.pattern_mode = PAT_ALL_LANES_VALID;
      this.data_mode = LFSR_PATTERN;
      this.info_mode = CORRECT;
      this.message_mode = ALL_LANES_VALID;
      this.valid_mode = VALID_CORRECT;
      this.lane_map_code = ALL_LANES;
    end
    else if (linkspeed_dest == SPEEDIDLE ) begin
      this.D2c_mode = SUCCESS;
      this.pattern_mode = PAT_NO_LANES_VALID;
      this.data_mode = LFSR_PATTERN;
      this.info_mode = ERROR;
      if (speed_idle_entry == CURRENT_DIE) begin
        this.message_mode = NO_LANES_VALID;
      end else begin
        this.message_mode = UPPER_8_LANES_VALID;
      end
      this.valid_mode = VALID_CORRECT;
      this.lane_map_code = ALL_LANES;
    end
    else if (linkspeed_dest == REPAIR) begin
      this.D2c_mode = SUCCESS;
      this.pattern_mode = pattern_mode;
      this.data_mode = LFSR_PATTERN;
      this.info_mode = ERROR;
      this.message_mode = message_mode;
      this.valid_mode = VALID_CORRECT;
      this.lane_map_code = ALL_LANES;
    end
    else if(linkspeed_dest == TRAINERROR) begin
      this.D2c_mode = SUCCESS;
      this.pattern_mode = PAT_NO_LANES_VALID;
      this.data_mode = LFSR_PATTERN;
      this.info_mode = ERROR;
      this.message_mode = NO_LANES_VALID;
      this.valid_mode = VALID_CORRECT;
      this.lane_map_code = ALL_LANES;
    end
    else begin
      `uvm_fatal("SEQ_CFG_ERR", "Invalid linkspeed destination specified in configure()")
    end
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

    if (linkspeed_dest == LINKINIT) begin
      p_sequencer.rx_fifo.get(sb_ltsm_item);
      sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBTRAIN_LINKSPEED_TX_LinksSpeed_Done_Hnd);
      send_sb_msg(sb_ltsm_item);

      p_sequencer.tx_fifo.get(sb_ltsm_item);
      sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBTRAIN_LINKSPEED_RX_Wait_REQ);
      send_sb_msg(sb_ltsm_item);
    end 

    else if (linkspeed_dest == REPAIR) begin
      // waiting for error request and sending it again

      p_sequencer.rx_fifo.get(sb_ltsm_item);
      sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBTRAIN_LINKSPEED_TX_LinksSpeed_Done_Hnd);
      send_sb_msg(sb_ltsm_item);

      // waiting for error response and sending it again

      p_sequencer.tx_fifo.get(sb_ltsm_item);
      sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBTRAIN_LINKSPEED_RX_Wait_REQ);
      send_sb_msg(sb_ltsm_item);

      // waiting for repair request and sending it again

      p_sequencer.rx_fifo.get(sb_ltsm_item);
      sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBTRAIN_LINKSPEED_TX_LinksSpeed_Done_Hnd);
      send_sb_msg(sb_ltsm_item);

      // waiting for repair response and sending it again

      p_sequencer.tx_fifo.get(sb_ltsm_item);
      sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBTRAIN_LINKSPEED_RX_Wait_REQ);
      send_sb_msg(sb_ltsm_item);

    end

    else if ((linkspeed_dest == SPEEDIDLE && speed_idle_entry == CURRENT_DIE) || (linkspeed_dest == TRAINERROR))begin
      // waiting for error request and sending it again

      p_sequencer.rx_fifo.get(sb_ltsm_item);
      $display("zobryyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy");
      sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBTRAIN_LINKSPEED_TX_Error_REQ);
      send_sb_msg(sb_ltsm_item);

      // waiting for error response and sending it again

      p_sequencer.tx_fifo.get(sb_ltsm_item);
      sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBTRAIN_LINKSPEED_RX_Send_Error_RESP);
      send_sb_msg(sb_ltsm_item);

      // waiting for speeddegrade request and sending it again

      p_sequencer.rx_fifo.get(sb_ltsm_item);
      sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBTRAIN_LINKSPEED_TX_Exit_SpeedDegrade_Hnd);
      send_sb_msg(sb_ltsm_item);

      // waiting for speeddegrade response and sending it again

      p_sequencer.tx_fifo.get(sb_ltsm_item);
      sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBTRAIN_LINKSPEED_RX_Send_SpeedDegrade_RESP);
      send_sb_msg(sb_ltsm_item);
    end

    else if (linkspeed_dest == SPEEDIDLE && speed_idle_entry == OTHER_DIE) begin
      // waiting for error request and sending it again

      p_sequencer.rx_fifo.get(sb_ltsm_item);
      sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBTRAIN_LINKSPEED_TX_LinksSpeed_Done_Hnd);
      send_sb_msg(sb_ltsm_item);

      // waiting for error response and sending it again

      p_sequencer.tx_fifo.get(sb_ltsm_item);
      sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBTRAIN_LINKSPEED_RX_Wait_REQ);
      send_sb_msg(sb_ltsm_item);

      // waiting for repair request and sending it again

      p_sequencer.rx_fifo.get(sb_ltsm_item);

      // sending speed degrade request
      sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBTRAIN_LINKSPEED_TX_LinksSpeed_Done_Hnd);
      send_sb_msg(sb_ltsm_item);

      // waiting for speeddegrade response and sending it again

      p_sequencer.tx_fifo.get(sb_ltsm_item);

      // waiting for speeddegrade req

      p_sequencer.rx_fifo.get(sb_ltsm_item);
  
    end

  endtask
endclass : ucie_mbtrain_linkspeed_vseq
