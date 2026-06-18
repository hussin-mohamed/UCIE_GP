//=============================================================================
// File       : ucie_D2C_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_TX_D2C_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_TX_D2C_vseq)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_TX_D2C_vseq");
    super.new(name);
  endfunction

  protected D2c_mode_e      D2c_mode;
  protected pattern_mode_e  pattern_mode;
  protected data_mode_e     data_mode;
  protected info_mode_e     info_mode;
  protected message_mode_e  message_mode;
  protected valid_mode_e    valid_mode;
  protected lane_map_code_e lane_map_code;
  int                       i              = 0;
  protected bit             is_configured;

  function configure(D2c_mode_e D2c_mode, pattern_mode_e pattern_mode, data_mode_e data_mode,
                     info_mode_e info_mode, message_mode_e message_mode, valid_mode_e valid_mode,
                     lane_map_code_e lane_map_code);
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

    if (data_mode == VALID_PATTERN) begin
      `uvm_fatal("SEQ_CFG_ERR",
                 "There is no VALID pattern for TX D2C, please choose a different data pattern!")
    end

    if (D2c_mode == LOOP_TILL_ERROR) begin
      `uvm_fatal("SEQ_CFG_ERR",
                 "There is no Loop for TX D2C, please choose a different data pattern!")
    end

    is_configured = 0;

    // D2C_RX_initiated_INIT_TX_LTSM
    `uvm_info("VSEQ", $sformatf("D2C_RX_initiated__TX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    p_sequencer.rx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::Data_To_Clock_test_TX_TX_INIT_Handshake);
    send_sb_msg(sb_ltsm_item);

    // D2C_RX_initiated_INIT_RX_LTSM
    `uvm_info("VSEQ", $sformatf("D2C_RX_initiated__RX_LTSM\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    p_sequencer.tx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::Data_To_Clock_test_RX_TX_INIT_Handshake);
    send_sb_msg(sb_ltsm_item);

    // D2C_RX_initiated_LFSR_CLEAR_TX_LTSM
    `uvm_info("VSEQ", $sformatf("D2C_RX_initiated_LFSR_CLEAR_TX_LTSM\n %s", sb_ltsm_item.sprint()),
              UVM_LOW)

    clear_LFSR_to_result_handshake();

    // Data_To_Clock_test_RX_RX_INIT_End_Init_Handshake_TX_LTSM
    `uvm_info("VSEQ", $sformatf("Data_To_Clock_test_RX_RX_INIT_End_Init_Handshake_TX_LTSM\n %s",
                                sb_ltsm_item.sprint()), UVM_LOW)

    p_sequencer.rx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::Data_To_Clock_test_TX_TX_INIT_End_Init_Handshake);
    send_sb_msg(sb_ltsm_item);

    // Data_To_Clock_test_RX_RX_INIT_End_Init_Handshake_RX_LTSM
    `uvm_info("VSEQ", $sformatf("Data_To_Clock_test_RX_RX_INIT_End_Init_Handshake_RX_LTSM\n %s",
                                sb_ltsm_item.sprint()), UVM_LOW)

    p_sequencer.tx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::Data_To_Clock_test_RX_TX_INIT_End_Init_Handshake);
    send_sb_msg(sb_ltsm_item);
  endtask

  task clear_LFSR_to_result_handshake();

    p_sequencer.rx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::Data_To_Clock_test_TX_TX_INIT_LFSR_Clear_Handshake);
    send_sb_msg(sb_ltsm_item);

    // D2C_RX_initiated_LFSR_CLEAR_RX_LTSM
    `uvm_info("VSEQ", $sformatf("D2C_RX_initiated_LFSR_CLEAR_RX_LTSM\n %s", sb_ltsm_item.sprint()),
              UVM_LOW)


    // load lfsr for model
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::Data_To_Clock_test_RX_TX_INIT_LFSR_Clear_Handshake);
    send_sb_msg(sb_ltsm_item);

    if (data_mode == PER_LANE_ID_PATTERN) begin
      if (pattern_mode == PAT_ALL_LANES_VALID) begin
        rmblink_PerLaneID_seq.configure(._scenario(SCENARIO_IDEAL), ._num_iterations('d32)
                                        // ,._lane_map_code(lane_map_code)
                                        , ._mixed_mode(MIXED_ALTERNATING));
      end else if (pattern_mode == PAT_UPPER_8_LANES_VALID) begin
          rmblink_PerLaneID_seq.configure(SCENARIO_MIXED_SUCCESS, 32, X16_MODE, MIXED_ALTERNATING,ERR_INJECT_UPPER_LANES_ONLY);

      end else if (pattern_mode == PAT_LOWER_8_LANES_VALID) begin
          rmblink_PerLaneID_seq.configure(SCENARIO_MIXED_SUCCESS, 32, X16_MODE, MIXED_ALTERNATING,ERR_INJECT_LOWER_LANES_ONLY);

      end else begin
        rmblink_PerLaneID_seq.configure(._scenario(SCENARIO_MIXED_SUCCESS), ._num_iterations('d32)
                                        // ,._lane_map_code(lane_map_code)
                                        , ._mixed_mode(MIXED_ALTERNATING));
      end
      rmblink_PerLaneID_seq.start(rp_rmblink_seqr);
    end else if (data_mode == LFSR_PATTERN) begin
      rmblink_lfsr_seq.rx_lfsr_pattern_generation(1'b0, 1'b1, rmblink_lfsr_seq.dummy_data);
      if (pattern_mode == PAT_ALL_LANES_VALID) begin
        rmblink_lfsr_seq.scenario = SCENARIO_EXACT_MATCH;
      end else if (pattern_mode == PAT_UPPER_8_LANES_VALID) begin
        rmblink_lfsr_seq.scenario       = SCENARIO_ERROR_LOWER_RAND_LANE_ABOVE_THRESH_RANDOM;
      end else if (pattern_mode == PAT_LOWER_8_LANES_VALID) begin
        rmblink_lfsr_seq.scenario       = SCENARIO_ERROR_UPPER_RAND_LANE_ABOVE_THRESH_RANDOM;
      end else begin
        rmblink_lfsr_seq.scenario = SCENARIO_ERROR_ABOVE_THRESH_RANDOM;
      end
      rmblink_lfsr_seq.num_iterations = 64;
      rmblink_lfsr_seq.train_mode = 1'b1;
      rmblink_lfsr_seq.start(rp_rmblink_seqr);
    end


    // D2C_RX_initiated_Pattern_detection_RX_LTSM
    `uvm_info("VSEQ", $sformatf("D2C_RX_initiated_Pattern_detection_RX_LTSM\n %s",
                                sb_ltsm_item.sprint()), UVM_LOW)


    `uvm_info("VSEQ", $sformatf("End Pattern Detection\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // D2C_RX_initiated_Result_handshake_TX_LTSM
    `uvm_info("VSEQ", $sformatf("D2C_RX_initiated_Result_handshake_TX_LTSM\n %s",
                                sb_ltsm_item.sprint()), UVM_LOW)

    p_sequencer.rx_fifo.get(sb_ltsm_item);

    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::Data_To_Clock_test_TX_TX_INIT_Result_Handshake);
    send_sb_msg(sb_ltsm_item);

    // D2C_RX_initiated_Result_handshake_RX_LTSM
    `uvm_info("VSEQ", $sformatf("D2C_RX_initiated_Result_handshake_RX_LTSM\n %s",
                                sb_ltsm_item.sprint()), UVM_LOW)

    p_sequencer.tx_fifo.get(sb_ltsm_item);

    if (info_mode == CORRECT) begin
      sb_ltsm_item.info[5] = 1'b1;
      sb_ltsm_item.info[4] = 1'b1;  // No error
    end else begin
      sb_ltsm_item.info[5] = 1'b0;
      sb_ltsm_item.info[4] = 1'b0;  // Error
    end
    sb_ltsm_item.data[63:16] = '1;
    if (message_mode == ALL_LANES_VALID) begin
      sb_ltsm_item.data[15:0] = '1;
    end else if (message_mode == UPPER_8_LANES_VALID) begin
      sb_ltsm_item.data[15:8] = '1;
      sb_ltsm_item.data[7:0]  = '0;
    end else if (message_mode == LOWER_8_LANES_VALID) begin
      sb_ltsm_item.data[15:8] = '0;
      sb_ltsm_item.data[7:0]  = '1;
    end else begin
      sb_ltsm_item.data[15:0] = '0;
    end

    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::Data_To_Clock_test_RX_TX_INIT_Result_Handshake);
    send_sb_msg(sb_ltsm_item);

    // Data_To_Clock_test_RX_Sweep_Result_Handshake_TX_LTSM
    `uvm_info("VSEQ", $sformatf("Data_To_Clock_test_RX_Sweep_Result_Handshake_TX_LTSM\n %s",
                                sb_ltsm_item.sprint()), UVM_LOW)

  endtask
endclass : ucie_TX_D2C_vseq
