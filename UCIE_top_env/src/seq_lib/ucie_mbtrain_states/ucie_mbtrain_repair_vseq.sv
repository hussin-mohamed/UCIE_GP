//=============================================================================
// File       : ucie_mbtrain_repair_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_mbtrain_repair_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_mbtrain_repair_vseq)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_mbtrain_repair_vseq");
    super.new(name);
  endfunction

  function configure (lane_map_code_e lane_map_code);
    this.lane_map_code = lane_map_code;
    is_configured = 1;
  endfunction

  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();
    if (!is_configured) begin
      `uvm_fatal("SEQ_CFG_ERR", "Sequence must be configured via configure() before starting!")
    end

    is_configured = 0;

    // Repair_Start_TX_LTSM
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBTRAIN_REPAIR_TX_Start_Handshake);
    send_sb_msg(sb_ltsm_item);

    // recieve and send response
    p_sequencer.tx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBTRAIN_REPAIR_RX_Start_Handshake);
    send_sb_msg(sb_ltsm_item);

    //  recieve and send apply degrade request
    p_sequencer.rx_fifo.get(sb_ltsm_item);
    sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBTRAIN_REPAIR_TX_Apply_Degrade_Handshake);
    if (lane_map_code == ALL_LANES) begin
        sb_ltsm_item.info[2:0] = 3'b011;
    end
    else if (lane_map_code == LANE_MAP_UPPER) begin
        sb_ltsm_item.info[2:0] = 3'b010;
    end
    else if (lane_map_code == LANE_MAP_LOWER) begin
        sb_ltsm_item.info[2:0] = 3'b001;
    end
    else begin
        sb_ltsm_item.info[2:0] = 3'b000;
    end
    send_sb_msg(sb_ltsm_item);

    
    if (lane_map_code != NO_LANES) begin
        // recieve and send degrade response
        p_sequencer.tx_fifo.get(sb_ltsm_item);
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBTRAIN_REPAIR_RX_Apply_Degrade_Handshake);
        send_sb_msg(sb_ltsm_item);
        // end handshake
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::MBTRAIN_REPAIR_TX_End_Handshake);
        send_sb_msg(sb_ltsm_item);
        p_sequencer.tx_fifo.get(sb_ltsm_item);
        sb_ltsm_item.set_rx_encoding(sb_shared_pkg::MBTRAIN_REPAIR_RX_End_Handshake);
        send_sb_msg(sb_ltsm_item);
    end
    else begin
        return 1;
    end


  endtask
endclass : ucie_mbtrain_repair_vseq
