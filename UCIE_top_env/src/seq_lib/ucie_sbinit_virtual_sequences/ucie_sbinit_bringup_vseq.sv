//=============================================================================
// File       : ucie_sbinit_bringup_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

typedef enum {
   NO_DROP
  ,DROP_OUT_OF_RESET
  ,DROP_DONE_REQ
  ,DROP_DONE_RSP
} sbinit_msg_drop_mode_e;

class ucie_sbinit_bringup_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_sbinit_bringup_vseq)

  event out_of_rst_msg_received;
  int sbinit_fail_cnt;
  sbinit_msg_drop_mode_e m_sbinit_msg_drop_mode;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_sbinit_bringup_vseq");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  Configure
  // -------------------------------------------------------------------------
  function void configure(
     sbinit_msg_drop_mode_e _msg_drop_mode = NO_DROP
  );
    m_sbinit_msg_drop_mode = _msg_drop_mode;
  endfunction

  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();
    fork
      begin // TX Thread
        if (m_sbinit_msg_drop_mode != DROP_OUT_OF_RESET) begin
          sb_ltsm_item.wait_cycles = 100;
          sb_ltsm_item.set_tx_encoding(sb_shared_pkg::SBINIT_TX_Out_Of_Reset_MSG);
          fork
            begin
              forever begin
                // send out of reset
                send_sb_msg_blocking(sb_ltsm_item);
              end
            end
          join_none
          
          // Wait for the SBINIT_Out_Of_Reset message to be received at the RX side to be able to send the SBINIT_done_req
          @(out_of_rst_msg_received);
  
          // Stop sending SBINIT_Out_Of_Reset
          disable fork;
        end else begin
          // Wait for the SBINIT_Out_Of_Reset message to be received at the RX side to be able to send the SBINIT_done_req
          @(out_of_rst_msg_received);
        end
        
        // send sbinit done req
        sb_ltsm_item.set_tx_encoding(sb_shared_pkg::SBINIT_TX_Done_Handshake);
        send_sb_msg_blocking(sb_ltsm_item);

        if (m_sbinit_msg_drop_mode != DROP_OUT_OF_RESET) begin
          // get sbinit done resp
          p_sequencer.tx_fifo.get(sb_ltsm_item);
          `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)
        end
      end

      begin // RX Thread
        // Get out of reset
        p_sequencer.rx_fifo.get(sb_ltsm_item);
        `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)
        -> out_of_rst_msg_received;

        if (m_sbinit_msg_drop_mode != DROP_OUT_OF_RESET) begin
          forever begin
            // get sbinit done req
            p_sequencer.rx_fifo.get(sb_ltsm_item);

            if (sb_ltsm_item.get_rx_encoding() == sb_shared_pkg::SBINIT_RX_Done_Handshake) begin
              `uvm_info("MBINIT_BRINGUP_VSEQ", $sformatf("RECEIVED SB MESSAGE:\n %s", sb_ltsm_item.sprint()), UVM_LOW)
              break;
            end
          end

          // send sbinit done resp
          sb_ltsm_item.set_rx_encoding(sb_shared_pkg::SBINIT_RX_Done_Handshake);
          send_sb_msg_blocking(sb_ltsm_item);
        end
      end
    join
  endtask
endclass : ucie_sbinit_bringup_vseq
