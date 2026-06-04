//=============================================================================
// File       : ucie_mbinit_bringup_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_mbinit_bringup_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_mbinit_bringup_vseq)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_mbinit_bringup_vseq");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();
    `uvm_info("UCIE_VSEQ", "Starting system-level sanity virtual sequence", UVM_LOW)

    sbinit_phylink_seq.start(sb_phylink_seqr);

    // Get out of reset
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send out of reset
    sb_ltsm_item.data        = 64'h0;
    sb_ltsm_item.info        = 16'h0;
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::SBINIT_TX_Out_Of_Reset_MSG);
    send_sb_msg(sb_ltsm_item);

    // get sbinit done req
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send sbinit done req
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::SBINIT_TX_Done_Handshake);
    send_sb_msg(sb_ltsm_item);

    // get sbinit done resp
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send sbinit done resp
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::SBINIT_RX_Done_Handshake);
    send_sb_msg(sb_ltsm_item);

    // get mbinit param req
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit param req
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_PARAM_TX_Config_Handshake);
    send_sb_msg(sb_ltsm_item);

    // get mbinit param resp
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit param resp
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_PARAM_RX_Send_RESP);
    send_sb_msg(sb_ltsm_item);

    // get mbinit cal req
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit cal req
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_CAL_TX_Done_Handshake);
    send_sb_msg(sb_ltsm_item);

    // get mbinit cal resp
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit param resp
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_CAL_RX_Done_Handshake);
    send_sb_msg(sb_ltsm_item);

    ////////////////////////////////////////////////////////////////////////////
    // MBINIT REPAIRCLK
    ////////////////////////////////////////////////////////////////////////////

    // get mbinit repairclk init req
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    // send mbinit repairclk init req
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_TX_Init_Handshake);
    send_sb_msg(sb_ltsm_item);
    // get mbinit repairclk init resp
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    // send mbinit repairclk init resp
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_RX_Init_Handshake);
    send_sb_msg(sb_ltsm_item);
    // send RMBLink Clock Pattern Sequence
    `uvm_info("UCIE_VSEQ", "Starting rmblink_clk_seq on rp_rmblink_seqr", UVM_LOW)
    rmblink_clk_seq.test_mode = TEST_CLK_IDEAL_ALL;
    rmblink_clk_seq.start(rp_rmblink_seqr);
    `uvm_info("UCIE_VSEQ", "rmblink_clk_seq completed", UVM_LOW)
    // get mbinit repairclk result req
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)
    // send mbinit repairclk result req
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_TX_Result_Handshake);
    send_sb_msg(sb_ltsm_item);
    // get mbinit repairclk result resp
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit repairclk result resp
    sb_ltsm_item.info        = 16'h7; // [15:3]: Reserved, [2]: Compare Results from RTRK_L, [1]: Compare Results from RCKN_L, [0]: Compare Results from RCKP_L
    sb_ltsm_item.msgtype     = RSP_MSG;
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_RX_Send_RESP);
    send_sb_msg(sb_ltsm_item);

    // get mbinit repairclk done req
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit repairclk done req
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_TX_Done_Handshake);
    send_sb_msg(sb_ltsm_item);

    // get mbinit repairclk done resp
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit repairclk done resp
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRCLK_RX_Done_Handshake);
    send_sb_msg(sb_ltsm_item);


    //////////////////////////////////////////////////////////////////////////////
    // MBINIT REPAIRVAL
    //////////////////////////////////////////////////////////////////////////////

    // get mbinit repairval init req
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit repairval init req
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRVAL_TX_Init_Handshake);
    send_sb_msg(sb_ltsm_item);

    // get mbinit repairval init resp
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit repairval init resp
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRVAL_RX_Init_Handshake);
    send_sb_msg(sb_ltsm_item);

    // send RMBLink Valid Pattern Sequence
    `uvm_info("UCIE_VSEQ", "Starting rmblink_valid_seq on rp_rmblink_seqr", UVM_LOW)
    rmblink_valid_seq.test_mode = TEST_IDEAL_ALL_0F;
    rmblink_valid_seq.start(rp_rmblink_seqr);
    `uvm_info("UCIE_VSEQ", "rmblink_valid_seq completed", UVM_LOW)

    // get mbinit repairval result req
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit repairval result req
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRVAL_TX_Result_Handshake);
    send_sb_msg(sb_ltsm_item);

    // get mbinit repairval result resp
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit repairval result resp
    sb_ltsm_item.info        = 16'h1; // [15:1]: Reserved, [0]: Compare Results from RVLD_L
    sb_ltsm_item.msgtype     = RSP_MSG;
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRVAL_RX_Send_Result_RESP);
    send_sb_msg(sb_ltsm_item);

    // get mbinit repairval done req
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit repairval done req
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRVAL_TX_Done_Handshake);
    send_sb_msg(sb_ltsm_item);

    // get mbinit repairval done resp
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit repairval done resp
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRVAL_RX_Done_Handshake);
    send_sb_msg(sb_ltsm_item);

    //////////////////////////////////////////////////////////////////////////////
    // MBINIT REVERSAL
    //////////////////////////////////////////////////////////////////////////////

    // get mbinit reversal init req
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit reversal init req
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REVERSAL_TX_Init_Handshake);
    send_sb_msg(sb_ltsm_item);

    // get mbinit reversal init resp
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit reversal init resp
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Init_Handshake);
    send_sb_msg(sb_ltsm_item);

    // get mbinit reversal clear lfsr req
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit reversal clear lfsr req
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REVERSAL_TX_Clear_Log_Handshake);
    send_sb_msg(sb_ltsm_item);

    // get mbinit reversal clear lfsr resp
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:22\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit reversal clear lfsr resp
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Clear_Log_Hnd);
    send_sb_msg(sb_ltsm_item);

    // send RMBLink Per Lane ID Pattern Sequence
    `uvm_info("UCIE_VSEQ", "Starting rmblink_PerLaneID_seq on rp_rmblink_seqr", UVM_LOW)
    rmblink_PerLaneID_seq.configure(._scenario(SCENARIO_IDEAL), ._num_iterations(32),
                                    ._lane_map_code(), ._mixed_mode());
    rmblink_PerLaneID_seq.start(rp_rmblink_seqr);
    `uvm_info("UCIE_VSEQ", "rmblink_PerLaneID_seq completed", UVM_LOW)

    // get mbinit reversal result req
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit reversal result req
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REVERSAL_TX_Result_Handshake);
    send_sb_msg(sb_ltsm_item);

    // get mbinit reversal result resp
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit reversal result resp
    sb_ltsm_item.data        = 64'h000000000000FFFF; // 16 bits for the 16 lanes
    sb_ltsm_item.info        = 16'h0000;             // Reserved: Used for standard package
    sb_ltsm_item.msgtype     = RSP_MSG;
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Result_Handshake);
    send_sb_msg(sb_ltsm_item);

    // get mbinit reversal done req
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit reversal done req
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REVERSAL_TX_Done_Handshake);
    send_sb_msg(sb_ltsm_item);

    // get mbinit reversal done resp
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit reversal done resp
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REVERSAL_RX_Done_Handshake);
    send_sb_msg(sb_ltsm_item);

    //////////////////////////////////////////////////////////////////////////////
    // MBINIT REPAIRMB 
    //////////////////////////////////////////////////////////////////////////////

    // get mbinit repairmb init req
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit repairmb init req
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_TX_Init_Handshake);
    send_sb_msg(sb_ltsm_item);

    // get mbinit repairmb init resp
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit repairmb init resp
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_RX_Init_Handshake);
    send_sb_msg(sb_ltsm_item);

    // TX Initiated Data To Clock Test - Per Lane ID Gen - Success pattern
    ucie_TX_D2C.configure(SUCCESS, PAT_ALL_LANES_VALID, PER_LANE_ID_PATTERN, CORRECT,
                          ALL_LANES_VALID, VALID_CORRECT, ALL_LANES);
    ucie_TX_D2C.start(p_sequencer);

    // get mbinit repairmb apply degrade req
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit repairmb apply degrade req
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_TX_Apply_Degrade_Hnd);
    send_sb_msg(sb_ltsm_item);

    // get mbinit repairmb apply degrade resp
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit repairmb apply degrade resp
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_RX_Send_Degrade_Resp);
    send_sb_msg(sb_ltsm_item);

    // get mbinit repairmb done req
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit repairmb done req
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_TX_Done_Handshake);
    send_sb_msg(sb_ltsm_item);

    // get mbinit repairmb done resp
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

    // send mbinit repairmb done resp
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_REPAIRMB_RX_Done_Handshake);
    send_sb_msg(sb_ltsm_item);

    `uvm_info("UCIE_VSEQ", "System-level sanity virtual sequence finished", UVM_LOW)
  endtask
endclass : ucie_mbinit_bringup_vseq




//////////////////////////////////////////////////////////////// TWO THREAD APPROACH
// sbinit_phylink_seq.start(sb_phylink_seqr);

// // send out of reset
// sb_ltsm_item.data        = 64'h0;
// sb_ltsm_item.info        = 16'h0;
// sb_ltsm_item.set_tx_encoding(sb_shared_pkg::SBINIT_TX_Out_Of_Reset_MSG);
// send_sb_msg(sb_ltsm_item);

// // Get out of reset
// p_sequencer.rx_fifo.get(sb_ltsm_item);
// `uvm_info("MBINIT_BRINGUP_VSEQ_RX", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

// fork
//   begin // RX Thread
//     // get sbinit done req
//     p_sequencer.rx_fifo.get(sb_ltsm_item);
//     `uvm_info("MBINIT_BRINGUP_VSEQ_RX", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

//     // send sbinit done resp
//     sb_ltsm_item.set_rx_encoding(sb_shared_pkg::SBINIT_RX_Done_Handshake);
//     send_sb_msg(sb_ltsm_item);

//     //////////////////////////////////////////////////////////////////////////////
//     // MBINIT.PARAM
//     //////////////////////////////////////////////////////////////////////////////
//     // get mbinit param req
//     p_sequencer.rx_fifo.get(sb_ltsm_item);
//     `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

//     // send mbinit param resp
//     sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_PARAM_RX_Send_RESP);
//     send_sb_msg(sb_ltsm_item);

//     //////////////////////////////////////////////////////////////////////////////
//     // MBINIT.CAL
//     //////////////////////////////////////////////////////////////////////////////
//     // get mbinit cal req
//     p_sequencer.rx_fifo.get(sb_ltsm_item);
//     `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

//     // send mbinit cal resp
//     sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBINIT_CAL_RX_Done_Handshake);
//     send_sb_msg(sb_ltsm_item);

//     //////////////////////////////////////////////////////////////////////////////
//     // MBINIT.REPAIRCLK
//     //////////////////////////////////////////////////////////////////////////////

//   end

//   begin // TX Thread
//     // send sbinit done req
//     sb_ltsm_item.set_tx_encoding(sb_shared_pkg::SBINIT_TX_Done_Handshake);
//     send_sb_msg(sb_ltsm_item);

//     // get sbinit done resp
//     p_sequencer.tx_fifo.get(sb_ltsm_item);
//     `uvm_info("MBINIT_BRINGUP_VSEQ_tx", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

//     //////////////////////////////////////////////////////////////////////////////
//     // MBINIT.PARAM
//     //////////////////////////////////////////////////////////////////////////////
//     // send mbinit param req
//     sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_PARAM_TX_Config_Handshake);
//     send_sb_msg(sb_ltsm_item);
    
//     // get mbinit param resp
//     p_sequencer.tx_fifo.get(sb_ltsm_item);
//     `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

//     //////////////////////////////////////////////////////////////////////////////
//     // MBINIT.CAL
//     //////////////////////////////////////////////////////////////////////////////
//     // send mbinit cal req
//     sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBINIT_CAL_TX_Done_Handshake);
//     send_sb_msg(sb_ltsm_item);

//     // get mbinit cal resp
//     p_sequencer.tx_fifo.get(sb_ltsm_item);
//     `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)

//     //////////////////////////////////////////////////////////////////////////////
//     // MBINIT.REPAIRCLK
//     //////////////////////////////////////////////////////////////////////////////
//   end
// join