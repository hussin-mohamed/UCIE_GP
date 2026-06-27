//=============================================================================
// File       : ucie_mbinit_fail_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: virtual sequence for all failure scenarios inside the MBINIT
//=============================================================================

class ucie_mbinit_fail_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_mbinit_fail_vseq)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_mbinit_fail_vseq");
    super.new(name);
  endfunction


  protected mbinit_fail_state_e fail_state;
  protected mbinit_fail_side_e fail_side;
  protected clk_fail_select_e clk_fail_select;
  protected lane_map_fail_select_e tx_lane_map;
  protected lane_map_fail_select_e rx_lane_map;
  protected bit is_configured;

  function void configure(mbinit_fail_state_e fail_state, mbinit_fail_side_e fail_side,
                          clk_fail_select_e clk_fail_select = FAIL_CLK_ALL,
                          lane_map_fail_select_e tx_lane_map = LANE_MAP_ALL,
                          lane_map_fail_select_e rx_lane_map = LANE_MAP_ALL);
    this.fail_state = fail_state;
    this.fail_side = fail_side;
    this.clk_fail_select = clk_fail_select;
    this.tx_lane_map = tx_lane_map;
    this.rx_lane_map = rx_lane_map;
    this.is_configured = 1;
  endfunction

  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();
    `uvm_info("UCIE_VSEQ", "Starting system-level sanity virtual sequence", UVM_LOW)

    if (TRAINERROR_vseq.trainerr_cnt == 0 && !is_configured) begin
      `uvm_fatal("SEQ_CFG_ERR", "Sequence must be configured via configure() before starting!")
    end

    trainerror_rdi_exit_vseq.start(ltsm_rdi_seqr);

    // =====================================================================
    // FAIL_ALL: Exhaustive TrainError reachability from every MBINIT state
    // Each iteration (trainerr_cnt 0..31) progresses one step further
    // through the bringup handshake flow, then fires TrainError.
    // On trainerr_cnt == 32, recovery runs (mbinit + train).
    // =====================================================================
    if (fail_state == FAIL_ALL) begin
      int target_step;
      int step;
      target_step = TRAINERROR_vseq.trainerr_cnt + 1;
      step = 0;

      // We clear is_configured during final recovery at step 32 instead of step 0

      if (TRAINERROR_vseq.trainerr_cnt <= 21) begin

        `uvm_info(
            "MBINIT_FAIL_ALL_VSEQ",
            $sformatf(
                "Starting FAIL_ALL iteration: trainerr_cnt=%0d, will fire TrainError after step %0d",
                TRAINERROR_vseq.trainerr_cnt, target_step), UVM_LOW)

        sbinit_phylink_seq.start(sb_phylink_seqr);

        // Out of reset (always present, not a TrainError test point)
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.data = 64'h0;
        sb_ltsm_item.info = 16'h0;
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::SBINIT_TX_Out_Of_Reset_MSG);
        send_sb_msg(sb_ltsm_item);

        // ---------------------------------------------------------------
        // Step 1: SBINIT Done req
        // ---------------------------------------------------------------
        // step++;
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::SBINIT_TX_Done_Handshake);
        send_sb_msg(sb_ltsm_item);
        // if (step == target_step) begin
        //   `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
        //             UVM_LOW)
        //   TRAINERROR_vseq.configure(NORMAL_RX);
        //   TRAINERROR_vseq.start(p_sequencer);
        //   return;
        // end

        // ---------------------------------------------------------------
        // Step 2: SBINIT Done resp
        // ---------------------------------------------------------------
        // step++;
        p_sequencer.tx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::SBINIT_RX_Done_Handshake);
        send_sb_msg(sb_ltsm_item);
        // if (step == target_step) begin
        //   `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
        //             UVM_LOW)
        //   TRAINERROR_vseq.configure(NORMAL_RX);
        //   TRAINERROR_vseq.start(p_sequencer);
        //   return;
        // end

        // ---------------------------------------------------------------
        // Step 3: PARAM req
        // ---------------------------------------------------------------
        step++;
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_PARAM_TX_Config_Handshake);
        send_sb_msg(sb_ltsm_item);
        if (step == target_step) begin
          `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
                    UVM_LOW)
          TRAINERROR_vseq.configure(NORMAL_RX);
          TRAINERROR_vseq.start(p_sequencer);
          return;
        end

        // ---------------------------------------------------------------
        // Step 4: PARAM resp
        // ---------------------------------------------------------------
        step++;
        p_sequencer.tx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_PARAM_RX_Send_RESP);
        send_sb_msg(sb_ltsm_item);
        if (step == target_step) begin
          `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
                    UVM_LOW)
          TRAINERROR_vseq.configure(NORMAL_RX);
          TRAINERROR_vseq.start(p_sequencer);
          return;
        end

        // ---------------------------------------------------------------
        // Step 5: CAL req
        // ---------------------------------------------------------------
        step++;
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_CAL_TX_Done_Handshake);
        send_sb_msg(sb_ltsm_item);
        if (step == target_step) begin
          `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
                    UVM_LOW)
          TRAINERROR_vseq.configure(NORMAL_RX);
          TRAINERROR_vseq.start(p_sequencer);
          return;
        end

        // ---------------------------------------------------------------
        // Step 6: CAL resp
        // ---------------------------------------------------------------
        step++;
        p_sequencer.tx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_CAL_RX_Done_Handshake);
        send_sb_msg(sb_ltsm_item);
        if (step == target_step) begin
          `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
                    UVM_LOW)
          TRAINERROR_vseq.configure(NORMAL_RX);
          TRAINERROR_vseq.start(p_sequencer);
          return;
        end

        // ---------------------------------------------------------------
        // Step 7: REPAIRCLK init req
        // ---------------------------------------------------------------
        step++;
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_TX_Init_Handshake);
        send_sb_msg(sb_ltsm_item);
        if (step == target_step) begin
          `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
                    UVM_LOW)
          TRAINERROR_vseq.configure(NORMAL_RX);
          TRAINERROR_vseq.start(p_sequencer);
          return;
        end

        // ---------------------------------------------------------------
        // Step 8: REPAIRCLK init resp
        // ---------------------------------------------------------------
        step++;
        p_sequencer.tx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_RX_Init_Handshake);
        send_sb_msg(sb_ltsm_item);
        if (step == target_step) begin
          `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
                    UVM_LOW)
          TRAINERROR_vseq.configure(NORMAL_RX);
          TRAINERROR_vseq.start(p_sequencer);
          return;
        end

        // ---------------------------------------------------------------
        // Step 9: REPAIRCLK clock test + result req
        // ---------------------------------------------------------------
        step++;
        `uvm_info("UCIE_VSEQ", "Starting rmblink_clk_seq on rp_rmblink_seqr", UVM_LOW)
        rmblink_clk_seq.test_mode = TEST_CLK_IDEAL_ALL;
        rmblink_clk_seq.start(rp_rmblink_seqr);
        `uvm_info("UCIE_VSEQ", "rmblink_clk_seq completed", UVM_LOW)
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_TX_Result_Handshake);
        send_sb_msg(sb_ltsm_item);
        if (step == target_step) begin
          `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
                    UVM_LOW)
          TRAINERROR_vseq.configure(NORMAL_RX);
          TRAINERROR_vseq.start(p_sequencer);
          return;
        end

        // ---------------------------------------------------------------
        // Step 10: REPAIRCLK result resp
        // ---------------------------------------------------------------
        step++;
        p_sequencer.tx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.info    = 16'h7;
        sb_ltsm_item.msgtype = RSP_MSG;
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_RX_Send_RESP);
        send_sb_msg(sb_ltsm_item);
        if (step == target_step) begin
          `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
                    UVM_LOW)
          TRAINERROR_vseq.configure(NORMAL_RX);
          TRAINERROR_vseq.start(p_sequencer);
          return;
        end

        // ---------------------------------------------------------------
        // Step 11: REPAIRCLK done req
        // ---------------------------------------------------------------
        step++;
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_TX_Done_Handshake);
        send_sb_msg(sb_ltsm_item);
        if (step == target_step) begin
          `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
                    UVM_LOW)
          TRAINERROR_vseq.configure(NORMAL_RX);
          TRAINERROR_vseq.start(p_sequencer);
          return;
        end

        // ---------------------------------------------------------------
        // Step 12: REPAIRCLK done resp
        // ---------------------------------------------------------------
        step++;
        p_sequencer.tx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_RX_Done_Handshake);
        send_sb_msg(sb_ltsm_item);
        if (step == target_step) begin
          `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
                    UVM_LOW)
          TRAINERROR_vseq.configure(NORMAL_RX);
          TRAINERROR_vseq.start(p_sequencer);
          return;
        end

        // ---------------------------------------------------------------
        // Step 13: REPAIRVAL init req
        // ---------------------------------------------------------------
        step++;
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRVAL_TX_Init_Handshake);
        send_sb_msg(sb_ltsm_item);
        if (step == target_step) begin
          `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
                    UVM_LOW)
          TRAINERROR_vseq.configure(NORMAL_RX);
          TRAINERROR_vseq.start(p_sequencer);
          return;
        end

        // ---------------------------------------------------------------
        // Step 14: REPAIRVAL init resp
        // ---------------------------------------------------------------
        step++;
        p_sequencer.tx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRVAL_RX_Init_Handshake);
        send_sb_msg(sb_ltsm_item);
        if (step == target_step) begin
          `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
                    UVM_LOW)
          TRAINERROR_vseq.configure(NORMAL_RX);
          TRAINERROR_vseq.start(p_sequencer);
          return;
        end

        // ---------------------------------------------------------------
        // Step 15: REPAIRVAL valid test + result req
        // ---------------------------------------------------------------
        step++;
        `uvm_info("UCIE_VSEQ", "Starting rmblink_valid_seq on rp_rmblink_seqr", UVM_LOW)
        rmblink_valid_seq.test_mode = TEST_IDEAL_ALL_0F;
        rmblink_valid_seq.start(rp_rmblink_seqr);
        `uvm_info("UCIE_VSEQ", "rmblink_valid_seq completed", UVM_LOW)
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRVAL_TX_Result_Handshake);
        send_sb_msg(sb_ltsm_item);
        if (step == target_step) begin
          `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
                    UVM_LOW)
          TRAINERROR_vseq.configure(NORMAL_RX);
          TRAINERROR_vseq.start(p_sequencer);
          return;
        end

        // ---------------------------------------------------------------
        // Step 16: REPAIRVAL result resp
        // ---------------------------------------------------------------
        step++;
        p_sequencer.tx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.info    = 16'h1;
        sb_ltsm_item.msgtype = RSP_MSG;
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRVAL_RX_Send_Result_RESP);
        send_sb_msg(sb_ltsm_item);
        if (step == target_step) begin
          `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
                    UVM_LOW)
          TRAINERROR_vseq.configure(NORMAL_RX);
          TRAINERROR_vseq.start(p_sequencer);
          return;
        end

        // ---------------------------------------------------------------
        // Step 17: REPAIRVAL done req
        // ---------------------------------------------------------------
        step++;
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRVAL_TX_Done_Handshake);
        send_sb_msg(sb_ltsm_item);
        if (step == target_step) begin
          `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
                    UVM_LOW)
          TRAINERROR_vseq.configure(NORMAL_RX);
          TRAINERROR_vseq.start(p_sequencer);
          return;
        end

        // ---------------------------------------------------------------
        // Step 18: REPAIRVAL done resp
        // ---------------------------------------------------------------
        step++;
        p_sequencer.tx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRVAL_RX_Done_Handshake);
        send_sb_msg(sb_ltsm_item);
        if (step == target_step) begin
          `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
                    UVM_LOW)
          TRAINERROR_vseq.configure(NORMAL_RX);
          TRAINERROR_vseq.start(p_sequencer);
          return;
        end

        // ---------------------------------------------------------------
        // Step 19: REVERSAL init req
        // ---------------------------------------------------------------
        // step++;
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REVERSAL_TX_Init_Handshake);
        send_sb_msg(sb_ltsm_item);
        // if (step == target_step) begin
        //   `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
        //             UVM_LOW)
        //   TRAINERROR_vseq.configure(NORMAL_RX);
        //   TRAINERROR_vseq.start(p_sequencer);
        //   return;
        // end

        // ---------------------------------------------------------------
        // Step 20: REVERSAL init resp
        // ---------------------------------------------------------------
        // step++;
        p_sequencer.tx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Init_Handshake);
        send_sb_msg(sb_ltsm_item);
        // if (step == target_step) begin
        //   `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
        //             UVM_LOW)
        //   TRAINERROR_vseq.configure(NORMAL_RX);
        //   TRAINERROR_vseq.start(p_sequencer);
        //   return;
        // end

        // ---------------------------------------------------------------
        // Step 21: REVERSAL clear lfsr req
        // ---------------------------------------------------------------
        // step++;
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REVERSAL_TX_Clear_Log_Handshake);
        send_sb_msg(sb_ltsm_item);
        // if (step == target_step) begin
        //   `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
        //             UVM_LOW)
        //   TRAINERROR_vseq.configure(NORMAL_RX);
        //   TRAINERROR_vseq.start(p_sequencer);
        //   return;
        // end

        // ---------------------------------------------------------------
        // Step 22: REVERSAL clear lfsr resp
        // ---------------------------------------------------------------
        // step++;
        p_sequencer.tx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:22\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Clear_Log_Hnd);
        send_sb_msg(sb_ltsm_item);
        // if (step == target_step) begin
        //   `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
        //             UVM_LOW)
        //   TRAINERROR_vseq.configure(NORMAL_RX);
        //   TRAINERROR_vseq.start(p_sequencer);
        //   return;
        // end

        // ---------------------------------------------------------------
        // Step 23: REVERSAL PerLaneID test + result req
        // ---------------------------------------------------------------
        // step++;
        `uvm_info("UCIE_VSEQ", "Starting rmblink_PerLaneID_seq on rp_rmblink_seqr", UVM_LOW)
        rmblink_PerLaneID_seq.configure(._scenario(SCENARIO_IDEAL), ._num_iterations(32),
                                        ._lane_map_code(X16_MODE), ._mixed_mode());
        rmblink_PerLaneID_seq.start(rp_rmblink_seqr);
        `uvm_info("UCIE_VSEQ", "rmblink_PerLaneID_seq completed", UVM_LOW)
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REVERSAL_TX_Result_Handshake);
        send_sb_msg(sb_ltsm_item);
        // if (step == target_step) begin
        //   `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
        //             UVM_LOW)
        //   TRAINERROR_vseq.configure(NORMAL_RX);
        //   TRAINERROR_vseq.start(p_sequencer);
        //   return;
        // end

        // ---------------------------------------------------------------
        // Step 24: REVERSAL result resp
        // ---------------------------------------------------------------
        // step++;
        p_sequencer.tx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.data    = 64'h000000000000FFFF;
        sb_ltsm_item.info    = 16'h0000;
        sb_ltsm_item.msgtype = RSP_MSG;
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Result_Handshake);
        send_sb_msg(sb_ltsm_item);
        // if (step == target_step) begin
        //   `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
        //             UVM_LOW)
        //   TRAINERROR_vseq.configure(NORMAL_RX);
        //   TRAINERROR_vseq.start(p_sequencer);
        //   return;
        // end

        // ---------------------------------------------------------------
        // Step 25: REVERSAL done req
        // ---------------------------------------------------------------
        // step++;
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REVERSAL_TX_Done_Handshake);
        send_sb_msg(sb_ltsm_item);
        // if (step == target_step) begin
        //   `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
        //             UVM_LOW)
        //   TRAINERROR_vseq.configure(NORMAL_RX);
        //   TRAINERROR_vseq.start(p_sequencer);
        //   return;
        // end

        // ---------------------------------------------------------------
        // Step 26: REVERSAL done resp
        // ---------------------------------------------------------------
        // step++;
        p_sequencer.tx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Done_Handshake);
        send_sb_msg(sb_ltsm_item);
        // if (step == target_step) begin
        //   `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
        //             UVM_LOW)
        //   TRAINERROR_vseq.configure(NORMAL_RX);
        //   TRAINERROR_vseq.start(p_sequencer);
        //   return;
        // end

        // ---------------------------------------------------------------
        // Step 27: REPAIRMB init req
        // ---------------------------------------------------------------
        step++;
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_TX_Init_Handshake);
        send_sb_msg(sb_ltsm_item);
        if (step == target_step) begin
          `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
                    UVM_LOW)
          TRAINERROR_vseq.configure(NORMAL_RX);
          TRAINERROR_vseq.start(p_sequencer);
          return;
        end

        // ---------------------------------------------------------------
        // Step 28: REPAIRMB init resp
        // ---------------------------------------------------------------
        step++;
        p_sequencer.tx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_RX_Init_Handshake);
        send_sb_msg(sb_ltsm_item);
        if (step == target_step) begin
          `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
                    UVM_LOW)
          TRAINERROR_vseq.configure(NORMAL_RX);
          TRAINERROR_vseq.start(p_sequencer);
          return;
        end

        // ---------------------------------------------------------------
        // Step 29: REPAIRMB D2C test + degrade req
        // ---------------------------------------------------------------
        step++;
        ucie_TX_D2C.configure(SUCCESS, PAT_ALL_LANES_VALID, PER_LANE_ID_PATTERN, CORRECT,
                              ALL_LANES_VALID, VALID_CORRECT, ALL_LANES);
        ucie_TX_D2C.start(p_sequencer);
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_TX_Apply_Degrade_Hnd);
        send_sb_msg(sb_ltsm_item);
        if (step == target_step) begin
          `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
                    UVM_LOW)
          TRAINERROR_vseq.configure(NORMAL_RX);
          TRAINERROR_vseq.start(p_sequencer);
          return;
        end

        // ---------------------------------------------------------------
        // Step 30: REPAIRMB degrade resp
        // ---------------------------------------------------------------
        step++;
        p_sequencer.tx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_RX_Send_Degrade_Resp);
        send_sb_msg(sb_ltsm_item);
        if (step == target_step) begin
          `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
                    UVM_LOW)
          TRAINERROR_vseq.configure(NORMAL_RX);
          TRAINERROR_vseq.start(p_sequencer);
          return;
        end

        // ---------------------------------------------------------------
        // Step 31: REPAIRMB done req
        // ---------------------------------------------------------------
        step++;
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_TX_Done_Handshake);
        send_sb_msg(sb_ltsm_item);
        if (step == target_step) begin
          `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
                    UVM_LOW)
          TRAINERROR_vseq.configure(NORMAL_RX);
          TRAINERROR_vseq.start(p_sequencer);
          return;
        end

        // ---------------------------------------------------------------
        // Step 32: REPAIRMB done resp
        // ---------------------------------------------------------------
        step++;
        p_sequencer.tx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                   sb_ltsm_item.sprint()), UVM_LOW)
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_RX_Done_Handshake);
        send_sb_msg(sb_ltsm_item);
        if (step == target_step) begin
          `uvm_info("MBINIT_FAIL_ALL_VSEQ", $sformatf("Firing TrainError after step %0d", step),
                    UVM_LOW)
          TRAINERROR_vseq.configure(NORMAL_RX);
          TRAINERROR_vseq.start(p_sequencer);
          return;
        end

        `uvm_info("MBINIT_FAIL_ALL_VSEQ",
                  "All 32 FAIL_ALL steps completed without TrainError trigger", UVM_LOW)

      end else if (TRAINERROR_vseq.trainerr_cnt == 32) begin
        // Recovery: all states tested, run normal bringup + train
        `uvm_info(
            "MBINIT_FAIL_ALL_VSEQ",
            "FAIL_ALL complete — all states verified TrainError-reachable. Running recovery.",
            UVM_LOW)
        mbinit_vseq.start(p_sequencer);
        // train_vseq.start(p_sequencer);
        is_configured = 0;  // Clear configuration flag once test completes
      end

      return;
    end  // fail_state == FAIL_ALL

    $display("%0t -- count trainerror = %0d", $time, TRAINERROR_vseq.trainerr_cnt);
    if ((fail_state == FAIL_CLK && TRAINERROR_vseq.trainerr_cnt < 8) 
        || (fail_state == FAIL_VAL && TRAINERROR_vseq.trainerr_cnt == 0)
        || (fail_state == FAIL_REVERSAL && TRAINERROR_vseq.trainerr_cnt < 5)
        || (fail_state == FAIL_REPAIR && fail_side == FAIL_SIDE_TX && TRAINERROR_vseq.trainerr_cnt < 3)
        || (fail_state == FAIL_REPAIR && fail_side == FAIL_SIDE_RX && TRAINERROR_vseq.trainerr_cnt < 1)
        ) begin
      // We clear is_configured at the end of recovery instead of here

      sbinit_phylink_seq.start(sb_phylink_seqr);

      // Get out of reset
      p_sequencer.rx_fifo.get(sb_ltsm_item);
      `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                 sb_ltsm_item.sprint()), UVM_LOW)

      // send out of reset
      sb_ltsm_item.data = 64'h0;
      sb_ltsm_item.info = 16'h0;
      sb_ltsm_item.set_tx_encoding(sb_shared_pkg::SBINIT_TX_Out_Of_Reset_MSG);
      send_sb_msg(sb_ltsm_item);

      // get sbinit done req
      p_sequencer.rx_fifo.get(sb_ltsm_item);
      `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                 sb_ltsm_item.sprint()), UVM_LOW)

      // send sbinit done req
      sb_ltsm_item.set_tx_encoding(sb_shared_pkg::SBINIT_TX_Done_Handshake);
      send_sb_msg(sb_ltsm_item);

      // get sbinit done resp
      p_sequencer.tx_fifo.get(sb_ltsm_item);
      `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                 sb_ltsm_item.sprint()), UVM_LOW)

      // send sbinit done resp
      sb_ltsm_item.set_rx_encoding(sb_shared_pkg::SBINIT_RX_Done_Handshake);
      send_sb_msg(sb_ltsm_item);

      // =======================================================================
      // MBINIT PARAM
      // =======================================================================
      if (fail_state == FAIL_PARAM) begin
        if (fail_side == FAIL_SIDE_TX) begin
          TRAINERROR_vseq.configure(NORMAL_TX);
        end else if (fail_side == FAIL_SIDE_RX) begin
          TRAINERROR_vseq.configure(NORMAL_RX);
        end else begin
          TRAINERROR_vseq.configure(NORMAL_RX);
        end
        TRAINERROR_vseq.start(p_sequencer);
        return;
      end

      // get mbinit param req
      p_sequencer.rx_fifo.get(sb_ltsm_item);
      `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                 sb_ltsm_item.sprint()), UVM_LOW)

      // send mbinit param req
      sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_PARAM_TX_Config_Handshake);
      send_sb_msg(sb_ltsm_item);

      // get mbinit param resp
      p_sequencer.tx_fifo.get(sb_ltsm_item);
      `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                 sb_ltsm_item.sprint()), UVM_LOW)

      // send mbinit param resp
      sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_PARAM_RX_Send_RESP);
      send_sb_msg(sb_ltsm_item);

      // =======================================================================
      // MBINIT CAL
      // =======================================================================
      if (fail_state == FAIL_CAL) begin
        if (fail_side == FAIL_SIDE_TX) begin
          TRAINERROR_vseq.configure(NORMAL_TX);
        end else if (fail_side == FAIL_SIDE_RX) begin
          TRAINERROR_vseq.configure(NORMAL_RX);
        end else begin
          TRAINERROR_vseq.configure(NORMAL_RX);
        end
        TRAINERROR_vseq.start(p_sequencer);
        return;
      end

      // get mbinit cal req
      p_sequencer.rx_fifo.get(sb_ltsm_item);
      `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                 sb_ltsm_item.sprint()), UVM_LOW)

      // send mbinit cal req
      sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_CAL_TX_Done_Handshake);
      send_sb_msg(sb_ltsm_item);

      // get mbinit cal resp
      p_sequencer.tx_fifo.get(sb_ltsm_item);
      `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                 sb_ltsm_item.sprint()), UVM_LOW)

      // send mbinit param resp
      sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_CAL_RX_Done_Handshake);
      send_sb_msg(sb_ltsm_item);

      // =======================================================================
      // MBINIT REPAIRCLK
      // =======================================================================
      // get mbinit repairclk init req
      p_sequencer.rx_fifo.get(sb_ltsm_item);
      `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                 sb_ltsm_item.sprint()), UVM_LOW)

      // send mbinit repairclk init req
      sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_TX_Init_Handshake);
      send_sb_msg(sb_ltsm_item);

      // get mbinit repairclk init resp
      p_sequencer.tx_fifo.get(sb_ltsm_item);
      `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                 sb_ltsm_item.sprint()), UVM_LOW)

      // send mbinit repairclk init resp
      sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_RX_Init_Handshake);
      send_sb_msg(sb_ltsm_item);

      // send RMBLink Clock Pattern Sequence
      `uvm_info("UCIE_VSEQ", "Starting rmblink_clk_seq on rp_rmblink_seqr", UVM_LOW)
      if (fail_state == FAIL_CLK && (fail_side == FAIL_SIDE_RX || fail_side == FAIL_SIDE_BOTH)) begin
        rmblink_clk_seq.select_clkn = TRAINERROR_vseq.trainerr_cnt[2];
        rmblink_clk_seq.select_clkp = TRAINERROR_vseq.trainerr_cnt[1];
        rmblink_clk_seq.select_trk  = TRAINERROR_vseq.trainerr_cnt[0];
        rmblink_clk_seq.test_mode   = TEST_CLK_PURE_RANDOM;
      end else begin
        rmblink_clk_seq.test_mode = TEST_CLK_IDEAL_ALL;
      end
      rmblink_clk_seq.start(rp_rmblink_seqr);
      `uvm_info("UCIE_VSEQ", "rmblink_clk_seq completed", UVM_LOW)

      // get mbinit repairclk result req
      p_sequencer.rx_fifo.get(sb_ltsm_item);
      `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                 sb_ltsm_item.sprint()), UVM_LOW)

      // send mbinit repairclk result req
      sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_TX_Result_Handshake);
      send_sb_msg(sb_ltsm_item);

      // get mbinit repairclk result resp
      p_sequencer.tx_fifo.get(sb_ltsm_item);
      `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                 sb_ltsm_item.sprint()), UVM_LOW)

      if (fail_state == FAIL_CLK) begin
        logic [15:0] clk_info;
        case (clk_fail_select)
          FAIL_CLK_TRACK: clk_info = 16'h3;
          FAIL_CLK_CLKN:  clk_info = 16'h5;
          FAIL_CLK_CLKP:  clk_info = 16'h6;
          default:        clk_info = 16'h3;
        endcase

        if (fail_side == FAIL_SIDE_TX) begin
          sb_ltsm_item.info = clk_info;
          sb_ltsm_item.msgtype = RSP_MSG;
          sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_RX_Send_RESP);
          send_sb_msg(sb_ltsm_item);
          TRAINERROR_vseq.configure(NORMAL_TX);
        end else if (fail_side == FAIL_SIDE_RX) begin
          sb_ltsm_item.info = 16'h001;
          sb_ltsm_item.msgtype = RSP_MSG;
          sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_RX_Send_RESP);
          send_sb_msg(sb_ltsm_item);

          // Done Handshake
          // p_sequencer.rx_fifo.get(sb_ltsm_item);
          // sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_TX_Done_Handshake);
          // send_sb_msg(sb_ltsm_item);

          // p_sequencer.tx_fifo.get(sb_ltsm_item);
          // sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_RX_Done_Handshake);
          // send_sb_msg(sb_ltsm_item);

          TRAINERROR_vseq.configure(NORMAL_RX);
        end else begin
          // BOTH
          sb_ltsm_item.info = clk_info;
          sb_ltsm_item.msgtype = RSP_MSG;
          sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_RX_Send_RESP);
          send_sb_msg(sb_ltsm_item);
          TRAINERROR_vseq.configure(NORMAL_RX);
        end
        TRAINERROR_vseq.start(p_sequencer);
        return;
      end else begin
        // Good repairclk result resp
        sb_ltsm_item.info = 16'h7;
        sb_ltsm_item.msgtype = RSP_MSG;
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_RX_Send_RESP);
        send_sb_msg(sb_ltsm_item);

        // Done Handshake
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_TX_Done_Handshake);
        send_sb_msg(sb_ltsm_item);

        p_sequencer.tx_fifo.get(sb_ltsm_item);
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_RX_Done_Handshake);
        send_sb_msg(sb_ltsm_item);
      end

      // =======================================================================
      // MBINIT REPAIRVAL
      // =======================================================================
      // get mbinit repairval init req
      p_sequencer.rx_fifo.get(sb_ltsm_item);
      `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                 sb_ltsm_item.sprint()), UVM_LOW)

      // send mbinit repairval init req
      sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRVAL_TX_Init_Handshake);
      send_sb_msg(sb_ltsm_item);

      // get mbinit repairval init resp
      p_sequencer.tx_fifo.get(sb_ltsm_item);
      `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                 sb_ltsm_item.sprint()), UVM_LOW)

      // send mbinit repairval init resp
      sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRVAL_RX_Init_Handshake);
      send_sb_msg(sb_ltsm_item);

      // send RMBLink Valid Pattern Sequence
      `uvm_info("UCIE_VSEQ", "Starting rmblink_valid_seq on rp_rmblink_seqr", UVM_LOW)
      if (fail_state == FAIL_VAL && (fail_side == FAIL_SIDE_RX || fail_side == FAIL_SIDE_BOTH)) begin
        rmblink_valid_seq.test_mode = TEST_PURE_RANDOM;
      end else begin
        rmblink_valid_seq.test_mode = TEST_IDEAL_ALL_0F;
      end
      rmblink_valid_seq.start(rp_rmblink_seqr);
      `uvm_info("UCIE_VSEQ", "rmblink_valid_seq completed", UVM_LOW)

      // get mbinit repairval result req
      p_sequencer.rx_fifo.get(sb_ltsm_item);
      `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                 sb_ltsm_item.sprint()), UVM_LOW)

      // send mbinit repairval result req
      sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRVAL_TX_Result_Handshake);
      send_sb_msg(sb_ltsm_item);

      // get mbinit repairval result resp
      p_sequencer.tx_fifo.get(sb_ltsm_item);
      `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                 sb_ltsm_item.sprint()), UVM_LOW)

      if (fail_state == FAIL_VAL) begin
        if (fail_side == FAIL_SIDE_TX) begin
          sb_ltsm_item.info = 16'h0;
          sb_ltsm_item.msgtype = RSP_MSG;
          sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRVAL_RX_Send_Result_RESP);
          send_sb_msg(sb_ltsm_item);
          TRAINERROR_vseq.configure(NORMAL_TX);
        end else if (fail_side == FAIL_SIDE_RX) begin
          sb_ltsm_item.info = 16'h0;
          sb_ltsm_item.msgtype = RSP_MSG;
          sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRVAL_RX_Send_Result_RESP);
          send_sb_msg(sb_ltsm_item);

          // // Done Handshake
          // p_sequencer.rx_fifo.get(sb_ltsm_item);
          // sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRVAL_TX_Done_Handshake);
          // send_sb_msg(sb_ltsm_item);

          // p_sequencer.tx_fifo.get(sb_ltsm_item);
          // sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRVAL_RX_Done_Handshake);
          // send_sb_msg(sb_ltsm_item);

          TRAINERROR_vseq.configure(NORMAL_RX);
        end else begin
          // BOTH
          sb_ltsm_item.info = 16'h0;
          sb_ltsm_item.msgtype = RSP_MSG;
          sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRVAL_RX_Send_Result_RESP);
          send_sb_msg(sb_ltsm_item);
          TRAINERROR_vseq.configure(NORMAL_RX);
        end
        TRAINERROR_vseq.start(p_sequencer);
        return;
      end else begin
        // Good repairval result resp
        sb_ltsm_item.info = 16'h1;
        sb_ltsm_item.msgtype = RSP_MSG;
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRVAL_RX_Send_Result_RESP);
        send_sb_msg(sb_ltsm_item);

        // Done Handshake
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRVAL_TX_Done_Handshake);
        send_sb_msg(sb_ltsm_item);

        p_sequencer.tx_fifo.get(sb_ltsm_item);
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRVAL_RX_Done_Handshake);
        send_sb_msg(sb_ltsm_item);
      end

      // =======================================================================
      // MBINIT REVERSAL
      // =======================================================================
      // get mbinit reversal init req
      p_sequencer.rx_fifo.get(sb_ltsm_item);
      `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                 sb_ltsm_item.sprint()), UVM_LOW)

      // send mbinit reversal init req
      sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REVERSAL_TX_Init_Handshake);
      send_sb_msg(sb_ltsm_item);

      // get mbinit reversal init resp
      p_sequencer.tx_fifo.get(sb_ltsm_item);
      `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                 sb_ltsm_item.sprint()), UVM_LOW)

      // send mbinit reversal init resp
      sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Init_Handshake);
      send_sb_msg(sb_ltsm_item);

      // get mbinit reversal clear lfsr req
      p_sequencer.rx_fifo.get(sb_ltsm_item);
      `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                 sb_ltsm_item.sprint()), UVM_LOW)

      // send mbinit reversal clear lfsr req
      sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REVERSAL_TX_Clear_Log_Handshake);
      send_sb_msg(sb_ltsm_item);

      // get mbinit reversal clear lfsr resp
      p_sequencer.tx_fifo.get(sb_ltsm_item);
      `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:22\n %s",
                                                 sb_ltsm_item.sprint()), UVM_LOW)

      // send mbinit reversal clear lfsr resp
      sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Clear_Log_Hnd);
      send_sb_msg(sb_ltsm_item);

      // send RMBLink Per Lane ID Pattern Sequence
      `uvm_info("UCIE_VSEQ", "Starting rmblink_PerLaneID_seq on rp_rmblink_seqr", UVM_LOW)
      if (fail_state == FAIL_REVERSAL && (fail_side == FAIL_SIDE_RX || fail_side == FAIL_SIDE_BOTH)) begin
        rmblink_PerLaneID_seq.configure(SCENARIO_MIXED_SUCCESS, 32,
                                        ._err_region(error_inject_region_e'(TRAINERROR_vseq.trainerr_cnt % 5)));
      end else begin
        rmblink_PerLaneID_seq.configure(SCENARIO_IDEAL, 32);
      end
      rmblink_PerLaneID_seq.start(rp_rmblink_seqr);
      `uvm_info("UCIE_VSEQ", "rmblink_PerLaneID_seq completed", UVM_LOW)

      // get mbinit reversal result req
      p_sequencer.rx_fifo.get(sb_ltsm_item);
      `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                 sb_ltsm_item.sprint()), UVM_LOW)

      // send mbinit reversal result req
      sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REVERSAL_TX_Result_Handshake);
      send_sb_msg(sb_ltsm_item);

      // get mbinit reversal result resp
      p_sequencer.tx_fifo.get(sb_ltsm_item);
      `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                 sb_ltsm_item.sprint()), UVM_LOW)

      if (fail_state == FAIL_REVERSAL) begin
        if (fail_side == FAIL_SIDE_TX) begin
          sb_ltsm_item.data    = 64'h0;
          sb_ltsm_item.info    = 16'h0000;
          sb_ltsm_item.msgtype = RSP_MSG;
          sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Result_Handshake);
          send_sb_msg(sb_ltsm_item);
          // TRAINERROR_vseq.configure(NORMAL_TX);

          // get mbinit reversal clear lfsr req
          p_sequencer.rx_fifo.get(sb_ltsm_item);
          `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                     sb_ltsm_item.sprint()), UVM_LOW)

          // send mbinit reversal clear lfsr resp
          sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Clear_Log_Hnd);
          send_sb_msg(sb_ltsm_item);

          // get mbinit reversal result req
          p_sequencer.rx_fifo.get(sb_ltsm_item);
          `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                     sb_ltsm_item.sprint()), UVM_LOW)

          sb_ltsm_item.data    = 64'h000000000000FFFF;
          sb_ltsm_item.info    = 16'h0000;
          sb_ltsm_item.msgtype = RSP_MSG;
          sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Result_Handshake);
          send_sb_msg(sb_ltsm_item);
          // TRAINERROR_vseq.configure(N

          // Done Handshake
          p_sequencer.rx_fifo.get(sb_ltsm_item);
          sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REVERSAL_TX_Done_Handshake);
          send_sb_msg(sb_ltsm_item);

          p_sequencer.tx_fifo.get(sb_ltsm_item);
          sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Done_Handshake);
          send_sb_msg(sb_ltsm_item);

        end else if (fail_side == FAIL_SIDE_RX) begin
          sb_ltsm_item.data    = 64'h000000000000FFFF;
          sb_ltsm_item.info    = 16'h0000;
          sb_ltsm_item.msgtype = RSP_MSG;
          sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Result_Handshake);
          send_sb_msg(sb_ltsm_item);

          // Done Handshake
          p_sequencer.rx_fifo.get(sb_ltsm_item);
          // sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Done_Handshake);
          // send_sb_msg(sb_ltsm_item);
          // sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REVERSAL_TX_Done_Handshake);
          // send_sb_msg(sb_ltsm_item);

          // p_sequencer.tx_fifo.get(sb_ltsm_item);
          // sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Done_Handshake);
          // send_sb_msg(sb_ltsm_item);

          // send mbinit reversal clear lfsr req
          sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REVERSAL_TX_Clear_Log_Handshake);
          send_sb_msg(sb_ltsm_item);

          // get mbinit reversal clear lfsr resp
          p_sequencer.tx_fifo.get(sb_ltsm_item);
          `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:22\n %s",
                                                     sb_ltsm_item.sprint()), UVM_LOW)
 
          // send RMBLink Per Lane ID Pattern Sequence
          `uvm_info("UCIE_VSEQ", "Starting rmblink_PerLaneID_seq on rp_rmblink_seqr", UVM_LOW)
          rmblink_PerLaneID_seq.configure(SCENARIO_MIXED_SUCCESS, 32, X16_MODE, MIXED_ALTERNATING,ERR_INJECT_ALTERNATING_A);
          rmblink_PerLaneID_seq.start(rp_rmblink_seqr);
          `uvm_info("UCIE_VSEQ", "rmblink_PerLaneID_seq completed", UVM_LOW)

          // send mbinit reversal result req
          sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REVERSAL_TX_Result_Handshake);
          send_sb_msg(sb_ltsm_item);

          // get mbinit reversal result resp
          p_sequencer.tx_fifo.get(sb_ltsm_item);
          `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                     sb_ltsm_item.sprint()), UVM_LOW)

          // sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REVERSAL_TX_Done_Handshake);
          // send_sb_msg(sb_ltsm_item);

          // p_sequencer.tx_fifo.get(sb_ltsm_item);
          // sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Done_Handshake);
          // send_sb_msg(sb_ltsm_item);

          TRAINERROR_vseq.configure(NORMAL_RX);
        end else begin
          // BOTH
          sb_ltsm_item.data    = 64'h0;
          sb_ltsm_item.info    = 16'h0000;
          sb_ltsm_item.msgtype = RSP_MSG;
          sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Result_Handshake);
          send_sb_msg(sb_ltsm_item);
          // TRAINERROR_vseq.configure(NORMAL_TX);

          // get mbinit reversal clear lfsr req
          p_sequencer.rx_fifo.get(sb_ltsm_item);
          `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf(
                    "RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

          // send mbinit reversal clear lfsr resp
          sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Clear_Log_Hnd);
          send_sb_msg(sb_ltsm_item);

          // get mbinit reversal result req
          p_sequencer.rx_fifo.get(sb_ltsm_item);
          `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf(
                    "RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

          sb_ltsm_item.data    = 64'h000000000000FFFF;
          sb_ltsm_item.info    = 16'h0000;
          sb_ltsm_item.msgtype = RSP_MSG;
          sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Result_Handshake);
          send_sb_msg(sb_ltsm_item);

          // Done Handshake
          p_sequencer.rx_fifo.get(sb_ltsm_item);

          // send mbinit reversal clear lfsr req
          sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REVERSAL_TX_Clear_Log_Handshake);
          send_sb_msg(sb_ltsm_item);

          // get mbinit reversal clear lfsr resp
          p_sequencer.tx_fifo.get(sb_ltsm_item);
          `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf(
                    "RECEIVED SB MESSAGE:22\n %s", sb_ltsm_item.sprint()), UVM_LOW)

          // send RMBLink Per Lane ID Pattern Sequence
          `uvm_info("UCIE_VSEQ", "Starting rmblink_PerLaneID_seq on rp_rmblink_seqr", UVM_LOW)
          rmblink_PerLaneID_seq.configure(SCENARIO_IDEAL, 32);
          rmblink_PerLaneID_seq.start(rp_rmblink_seqr);
          `uvm_info("UCIE_VSEQ", "rmblink_PerLaneID_seq completed", UVM_LOW)

          // send mbinit reversal result req
          sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REVERSAL_TX_Result_Handshake);
          send_sb_msg(sb_ltsm_item);

          // get mbinit reversal result resp
          p_sequencer.tx_fifo.get(sb_ltsm_item);
          `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf(
                    "RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

          sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REVERSAL_TX_Done_Handshake);
          send_sb_msg(sb_ltsm_item);
          p_sequencer.tx_fifo.get(sb_ltsm_item);
          sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Done_Handshake);
          send_sb_msg(sb_ltsm_item);

          // TRAINERROR_vseq.configure(NORMAL);
        end
        TRAINERROR_vseq.start(p_sequencer);
        return;
      end else begin
        // Good result resp
        sb_ltsm_item.data    = 64'h000000000000FFFF;
        sb_ltsm_item.info    = 16'h0000;
        sb_ltsm_item.msgtype = RSP_MSG;
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Result_Handshake);
        send_sb_msg(sb_ltsm_item);

        // Done Handshake
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REVERSAL_TX_Done_Handshake);
        send_sb_msg(sb_ltsm_item);

        p_sequencer.tx_fifo.get(sb_ltsm_item);
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Done_Handshake);
        send_sb_msg(sb_ltsm_item);
      end

      // =======================================================================
      // MBINIT REPAIRMB (REPAIR)
      // =======================================================================
      // get mbinit repairmb init req
      p_sequencer.rx_fifo.get(sb_ltsm_item);
      `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                 sb_ltsm_item.sprint()), UVM_LOW)

      // send mbinit repairmb init req
      sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_TX_Init_Handshake);
      send_sb_msg(sb_ltsm_item);

      // get mbinit repairmb init resp
      p_sequencer.tx_fifo.get(sb_ltsm_item);
      `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s",
                                                 sb_ltsm_item.sprint()), UVM_LOW)

      // send mbinit repairmb init resp
      sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_RX_Init_Handshake);
      send_sb_msg(sb_ltsm_item);

      if (fail_state == FAIL_REPAIR) begin
        info_mode_e info_mode_val;
        pattern_mode_e pattern_mode_val;
        lane_map_code_e lane_map_code_val;
        message_mode_e message_mode_val;
        static int count = 1;

        // Set TX parameters based on tx_lane_map
        if (fail_side == FAIL_SIDE_TX || fail_side == FAIL_SIDE_BOTH) begin
          info_mode_val = ERROR;
          message_mode_val = message_mode_e'(count % 4);
          // message_mode_val = NO_LANES_VALID;
        

          // Good REPAIRMB
          ucie_TX_D2C.configure(SUCCESS, PAT_ALL_LANES_VALID, PER_LANE_ID_PATTERN, ERROR,
                                message_mode_val, VALID_CORRECT, ALL_LANES);
          ucie_TX_D2C.start(p_sequencer);
          count++;

          // Good Degrade / Done Handshake
          p_sequencer.rx_fifo.get(sb_ltsm_item);
          if (message_mode_val == NO_LANES_VALID) begin

            TRAINERROR_vseq.configure(NORMAL_TX);
            TRAINERROR_vseq.start(p_sequencer);
          end else begin
            sb_ltsm_item.info = 3'b011;
            sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_TX_Apply_Degrade_Hnd);
            send_sb_msg(sb_ltsm_item);

            // get degrade resp from rx 
            p_sequencer.tx_fifo.get(sb_ltsm_item);

            #50ns;
            sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_TX_Done_Handshake);
            send_sb_msg(sb_ltsm_item);

            p_sequencer.tx_fifo.get(sb_ltsm_item);

            sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_RX_Send_Degrade_Resp);
            send_sb_msg(sb_ltsm_item);

            p_sequencer.rx_fifo.get(sb_ltsm_item);
            #50ns;
            sb_ltsm_item.set_rx_encoding(sb_shared_pkg::Data_To_Clock_test_RX_TX_INIT_Handshake);
            send_sb_msg(sb_ltsm_item);

            p_sequencer.rx_fifo.get(sb_ltsm_item);
            #50ns;
            sb_ltsm_item.set_rx_encoding(
                sb_shared_pkg::Data_To_Clock_test_RX_TX_INIT_LFSR_Clear_Handshake);
            send_sb_msg(sb_ltsm_item);

            rmblink_PerLaneID_seq.configure(._scenario(SCENARIO_IDEAL), ._num_iterations('d32)
                                            , ._lane_map_code(message_mode_val == LOWER_8_LANES_VALID ? X8_LOWER_MODE :
                                                              message_mode_val == UPPER_8_LANES_VALID ? X8_UPPER_MODE :
                                                              X16_MODE)
                                            , ._mixed_mode(MIXED_ALTERNATING));
            rmblink_PerLaneID_seq.start(rp_rmblink_seqr);

            p_sequencer.rx_fifo.get(sb_ltsm_item);
            #50ns;
            if (message_mode_val == LOWER_8_LANES_VALID) begin
              sb_ltsm_item.data[15:8] = '0;
              sb_ltsm_item.data[7:0]  = '1;
            end else if (message_mode_val == UPPER_8_LANES_VALID) begin
              sb_ltsm_item.data[15:8] = '1;
              sb_ltsm_item.data[7:0]  = '0;
            end else if (message_mode_val == ALL_LANES_VALID) begin
              sb_ltsm_item.data[15:8] = '1;
              sb_ltsm_item.data[7:0]  = '1;
            end else begin
              sb_ltsm_item.data[15:8] = '0;
              sb_ltsm_item.data[7:0]  = '0;
            end
            sb_ltsm_item.set_rx_encoding(
                sb_shared_pkg::Data_To_Clock_test_RX_TX_INIT_Result_Handshake);
            send_sb_msg(sb_ltsm_item);

            p_sequencer.rx_fifo.get(sb_ltsm_item);

            #50ns;
            sb_ltsm_item.set_rx_encoding(
                sb_shared_pkg::Data_To_Clock_test_RX_TX_INIT_End_Init_Handshake);
            send_sb_msg(sb_ltsm_item);

            // Good Degrade / Done Handshake
            p_sequencer.rx_fifo.get(sb_ltsm_item);
            #50ns;

            TRAINERROR_vseq.configure(NORMAL_RX);
            TRAINERROR_vseq.start(p_sequencer);

            sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_RX_Send_Degrade_Resp);
            send_sb_msg(sb_ltsm_item);

            p_sequencer.rx_fifo.get(sb_ltsm_item);
            #50ns;
            sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_RX_Done_Handshake);
            send_sb_msg(sb_ltsm_item);
          end

          // case (tx_lane_map)
          //   LANE_MAP_UPPER: begin
          //     pattern_mode_val  = PAT_LOWER_8_LANES_VALID;
          //     lane_map_code_val = LOWER_8_LANES;
          //   end
          //   LANE_MAP_LOWER: begin
          //     pattern_mode_val  = PAT_UPPER_8_LANES_VALID;
          //     lane_map_code_val = UPPER_8_LANES;
          //   end
          //   default: begin  // LANE_MAP_ALL
          //     pattern_mode_val  = PAT_NO_LANES_VALID;
          //     lane_map_code_val = NO_LANES;
          //   end
          // endcase
        end else begin
          info_mode_val = CORRECT;
          lane_map_code_val = ALL_LANES;
        end

        // Set RX parameters based on rx_lane_map
        if (fail_side == FAIL_SIDE_RX || fail_side == FAIL_SIDE_BOTH) begin
          static int rx_count = 1;
          // pattern_mode_val = pattern_mode_e'(rx_count % 4);
          pattern_mode_val = PAT_UPPER_8_LANES_VALID;

          case (rx_lane_map)
            LANE_MAP_UPPER: message_mode_val = LOWER_8_LANES_VALID;
            LANE_MAP_LOWER: message_mode_val = UPPER_8_LANES_VALID;
            default:        message_mode_val = NO_LANES_VALID;  // LANE_MAP_ALL
          endcase

          ucie_TX_D2C.configure(SUCCESS, pattern_mode_val, PER_LANE_ID_PATTERN, CORRECT,
                                ALL_LANES_VALID, VALID_CORRECT, ALL_LANES);
          ucie_TX_D2C.start(p_sequencer);
          rx_count++;

          // Good Degrade / Done Handshake
          p_sequencer.rx_fifo.get(sb_ltsm_item);
          #50ns;

          if (message_mode_val == LOWER_8_LANES_VALID) begin

            TRAINERROR_vseq.configure(NORMAL_TX);
            TRAINERROR_vseq.start(p_sequencer);
          end else begin
            sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_RX_Send_Degrade_Resp);
            send_sb_msg(sb_ltsm_item);

            p_sequencer.rx_fifo.get(sb_ltsm_item);
            #50ns;
            // sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_RX_Done_Handshake);
            // send_sb_msg(sb_ltsm_item);

            #50ns;

            // sb_ltsm_item.info = pattern_mode_val == PAT_LOWER_8_LANES_VALID ? 3'b001 :
            //                     pattern_mode_val == PAT_UPPER_8_LANES_VALID ? 3'b010 :
            //                     3'b011;
            
            sb_ltsm_item.info = 3'b010;
            sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_TX_Apply_Degrade_Hnd);
            send_sb_msg(sb_ltsm_item);


            #50ns;
            // D2C req entry
            sb_ltsm_item.set_tx_encoding(sb_shared_pkg::Data_To_Clock_test_TX_TX_INIT_Handshake);
            send_sb_msg(sb_ltsm_item);

            #50ns;
            p_sequencer.tx_fifo.get(sb_ltsm_item);

            #50ns;
            sb_ltsm_item.set_tx_encoding(
                sb_shared_pkg::Data_To_Clock_test_TX_TX_INIT_LFSR_Clear_Handshake);
            send_sb_msg(sb_ltsm_item);


            #50ns;
            p_sequencer.tx_fifo.get(sb_ltsm_item);

            rmblink_PerLaneID_seq.configure(._scenario(SCENARIO_IDEAL), ._num_iterations('d32)
                                            // , ._lane_map_code((pattern_mode_val == PAT_LOWER_8_LANES_VALID ? X8_LOWER_MODE :
                                                              // pattern_mode_val == PAT_UPPER_8_LANES_VALID ? X8_UPPER_MODE :
                                                              // X16_MODE))
                                            , ._lane_map_code(X8_UPPER_MODE)
                                            , ._mixed_mode(MIXED_ALTERNATING));
            rmblink_PerLaneID_seq.start(rp_rmblink_seqr);

            sb_ltsm_item.set_tx_encoding(
                sb_shared_pkg::Data_To_Clock_test_TX_TX_INIT_Result_Handshake);
            send_sb_msg(sb_ltsm_item);

            p_sequencer.tx_fifo.get(sb_ltsm_item);

            #50ns;

            sb_ltsm_item.set_tx_encoding(
                sb_shared_pkg::Data_To_Clock_test_TX_TX_INIT_End_Init_Handshake);
            send_sb_msg(sb_ltsm_item);

            p_sequencer.tx_fifo.get(sb_ltsm_item);


            // sb_ltsm_item.info = pattern_mode_val == PAT_LOWER_8_LANES_VALID ? 3'b001 :
            //                     pattern_mode_val == PAT_UPPER_8_LANES_VALID ? 3'b010 :
            //                     3'b011;
            sb_ltsm_item.info = 3'b010;
            sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_TX_Apply_Degrade_Hnd);
            send_sb_msg(sb_ltsm_item);

            p_sequencer.tx_fifo.get(sb_ltsm_item);

            #50ns;
            sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_TX_Done_Handshake);
            send_sb_msg(sb_ltsm_item);

            TRAINERROR_vseq.configure(NORMAL_RX);
            TRAINERROR_vseq.start(p_sequencer);

            // rmblink_PerLaneID_seq.configure(._scenario(SCENARIO_IDEAL), ._num_iterations('d32)
            //                                 // ,._lane_map_code(lane_map_code)
            //                                 , ._mixed_mode(MIXED_ALTERNATING));

          end

        end else begin
          message_mode_val = ALL_LANES_VALID;
        end

        // ucie_TX_D2C.configure(SUCCESS, pattern_mode_val, PER_LANE_ID_PATTERN, info_mode_val,
        //                       message_mode_val, VALID_CORRECT, lane_map_code_val);
        // ucie_TX_D2C.start(p_sequencer);

        if (fail_side == FAIL_SIDE_TX) begin
          // TRAINERROR_vseq.configure(NORMAL_TX);
        end else if (fail_side == FAIL_SIDE_RX) begin
          // Perform Done Handshake for REPAIRMB
          // p_sequencer.rx_fifo.get(sb_ltsm_item);
          // sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_TX_Apply_Degrade_Hnd);
          // send_sb_msg(sb_ltsm_item);

          // p_sequencer.tx_fifo.get(sb_ltsm_item);
          // sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_RX_Send_Degrade_Resp);
          // send_sb_msg(sb_ltsm_item);

          // p_sequencer.rx_fifo.get(sb_ltsm_item);
          // sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_TX_Done_Handshake);
          // send_sb_msg(sb_ltsm_item);

          // p_sequencer.tx_fifo.get(sb_ltsm_item);
          // sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_RX_Done_Handshake);
          // send_sb_msg(sb_ltsm_item);

          TRAINERROR_vseq.configure(NORMAL_RX);
        end else begin
          // BOTH
        end
      //  return;
      end else begin
        // Good REPAIRMB
        ucie_TX_D2C.configure(SUCCESS, PAT_ALL_LANES_VALID, PER_LANE_ID_PATTERN, CORRECT,
                              ALL_LANES_VALID, VALID_CORRECT, ALL_LANES);
        ucie_TX_D2C.start(p_sequencer);

        // Good Degrade / Done Handshake
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_TX_Apply_Degrade_Hnd);
        send_sb_msg(sb_ltsm_item);

        p_sequencer.tx_fifo.get(sb_ltsm_item);
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_RX_Send_Degrade_Resp);
        send_sb_msg(sb_ltsm_item);

        p_sequencer.rx_fifo.get(sb_ltsm_item);
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_RX_Done_Handshake);
        send_sb_msg(sb_ltsm_item);
      end

      // train_vseq.start(p_sequencer);
      `uvm_info("UCIE_VSEQ", "System-level sanity virtual sequence finished", UVM_LOW)
    end else if ((fail_state == FAIL_CLK && TRAINERROR_vseq.trainerr_cnt >= 8) 
          || (fail_state == FAIL_VAL && TRAINERROR_vseq.trainerr_cnt != 0)
          || (fail_state == FAIL_REVERSAL && TRAINERROR_vseq.trainerr_cnt >= 5)
          || (fail_state == FAIL_REPAIR && fail_side == FAIL_SIDE_TX && TRAINERROR_vseq.trainerr_cnt >= 3)
          || (fail_state == FAIL_REPAIR && fail_side == FAIL_SIDE_RX && TRAINERROR_vseq.trainerr_cnt >= 1)
          ) begin
      mbinit_vseq.start(p_sequencer);
      train_vseq.start(p_sequencer);
      is_configured = 0;  // Clear configuration flag once test completes
    end

    // if (fail_state == FAIL_REVERSAL) mbinit_vseq.start(p_sequencer);

  endtask
endclass : ucie_mbinit_fail_vseq
