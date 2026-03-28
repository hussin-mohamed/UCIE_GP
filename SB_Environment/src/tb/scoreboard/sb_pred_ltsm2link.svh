// ****************************************************************************
// *                                                                          *
// * Copyright (c) 2014-2015 Synopsys Inc. All rights reserved.               *
// *                                                                          *
// * Synopsys Proprietary and Confidential. This file contains confidential   *
// * information and the trade secrets of Synopsys Inc. Use, disclosure, or   *
// * reproduction is prohibited without the prior express written permission  *
// * of Synopsys, Inc.                                                        *
// *                                                                          *
// * Synopsys, Inc.                                                           *
// * 700 East Middlefield Road                                                *
// * Mountain View, California 94043                                          *
// * (800) 541-7737                                                           *
// *                                                                          *
// ****************************************************************************

//---------------------------------------------------------------------------
//
// CLASS: sb_pred_ltsm2link
//
// Description: ...
//---------------------------------------------------------------------------

// ****************************************************************************
// *                                                                          *
// * Copyright (c) 2014-2015 Synopsys Inc. All rights reserved.               *
// *                                                                          *
// * Synopsys Proprietary and Confidential. This file contains confidential   *
// * information and the trade secrets of Synopsys Inc. Use, disclosure, or   *
// * reproduction is prohibited without the prior express written permission  *
// * of Synopsys, Inc.                                                        *
// *                                                                          *
// * Synopsys, Inc.                                                           *
// * 700 East Middlefield Road                                                *
// * Mountain View, California 94043                                          *
// * (800) 541-7737                                                           *
// *                                                                          *
// ****************************************************************************

`uvm_analysis_imp_decl(_tx)
`uvm_analysis_imp_decl(_rx)
`uvm_analysis_imp_decl(_rdi)

//---------------------------------------------------------------------------
//
// CLASS: sb_pred_ltsm2link
//
// Description: ...
//---------------------------------------------------------------------------

class sb_pred_ltsm2link extends uvm_component;
  `uvm_component_utils(sb_pred_ltsm2link)

  uvm_analysis_imp_tx  #(ltsm_seq_item,  sb_pred_ltsm2link) axp_in_tx;
  uvm_analysis_imp_rx  #(ltsm_seq_item,  sb_pred_ltsm2link) axp_in_rx;
  uvm_analysis_imp_rdi #(rdi_seq_item, sb_pred_ltsm2link) axp_in_rdi;

  uvm_analysis_port #(phylink_seq_item) results_ap_phy;

  mailbox tx_mb  = new(TX_FIFO_SIZE);
  mailbox rx_mb  = new(RX_FIFO_SIZE);
  mailbox rdi_mb = new(RDI_FIFO_SIZE);

  ltsm_seq_item    ltsm_item;
  phylink_seq_item phylink_item;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axp_in_tx      = new("axp_in_tx", this);
    axp_in_rx      = new("axp_in_rx", this);
    axp_in_rdi     = new("axp_in_rdi", this);
    results_ap_phy = new("results_ap_phy", this);
  endfunction : build_phase

  function void write_tx(ltsm_seq_item t);
    if(!tx_mb.try_put(t)) begin
      `uvm_fatal("LTSM2PHY", "Invalid case: TX mailbox is full; a new item is trying to enter")
    end
  endfunction : write_tx

  function void write_rx(ltsm_seq_item t);
    if(!rx_mb.try_put(t)) begin
      `uvm_fatal("LTSM2PHY", "Invalid case: RX mailbox is full; a new item is trying to enter")
    end
  endfunction : write_rx

  function void write_rdi(rdi_seq_item t);
    if(!rdi_mb.try_put(t)) begin
      `uvm_fatal("LTSM2PHY", "Invalid case: RDI mailbox is full; a new item is trying to enter")
    end
  endfunction : write_rdi
  
  extern virtual task run_phase(uvm_phase phase);

  extern function phylink_seq_item get_predicted_item(ltsm_seq_item _t_in);

  extern function message_t get_message_struct(ltsm_seq_item _t_in);
endclass

task sb_pred_ltsm2link::run_phase(uvm_phase phase);
    forever begin
      // Block until at least one mailbox has an item
      wait(tx_mb.num() > 0 || rx_mb.num() > 0);

      // If both mailboxes have items, alternate between sending TX and RX items
      if (tx_mb.num() > 0 && rx_mb.num() > 0) begin
        // Alternate between sending TX and RX items till sending all the existing items
        for (int i = 0; tx_mb.num() > 0 || rx_mb.num() > 0; i++) begin
          // Give TX the priority to start if both have existing items
          if(tx_mb.try_get(ltsm_item)) begin
            phylink_item = get_predicted_item(ltsm_item);
            results_ap_phy.write(phylink_item);          
          end
          if(rx_mb.try_get(ltsm_item)) begin
            phylink_item = get_predicted_item(ltsm_item);
            results_ap_phy.write(phylink_item);           
          end
        end
      // Else if TX mailbox only has items, send all the existing TX items
      end else if (tx_mb.num() > 0) begin
        while(tx_mb.try_get(ltsm_item)) begin
          phylink_item = get_predicted_item(ltsm_item);
          results_ap_phy.write(phylink_item);
        end
      // Else if RX mailbox only has items, send all the existing RX items
      end else if (rx_mb.num() > 0) begin
        while(rx_mb.try_get(ltsm_item)) begin
          phylink_item = get_predicted_item(ltsm_item);
          results_ap_phy.write(phylink_item);
        end
      end
    end
  endtask : run_phase


function phylink_seq_item sb_pred_ltsm2link::get_predicted_item(ltsm_seq_item _t_in);
  phylink_seq_item t_out;
  message_t        msg;
  logic [127:0]    msg_raw;
  
  msg = get_message_struct(_t_in);

  // Build the output transaction
  t_out = new("t_out");

  t_out.op_mode  = ACTIVE;
  t_out.fullcode = msg.fullcode;
  t_out.opcode   = msg.opcode;
  t_out.srcid    = msg.srcid;
  t_out.dstid    = msg.dstid;
  t_out.info     = msg.info;
  t_out.data     = msg.data;

  msg_raw = struct2raw(msg);

  // Parity Bits Calculation
  t_out.cp = ^{msg_raw[61:0]};    // cp (even parity of header bits)
  t_out.dp = ^{msg_raw[127:64]};  // dp (even parity of data payload)

  return t_out;
endfunction : get_predicted_item

function message_t sb_pred_ltsm2link::get_message_struct(ltsm_seq_item _t_in);
  message_t msg;

  if (_t_in.get_dir() == MSG_FROM_TX) begin
    msg = tx_messages[_t_in.get_tx_encoding()];
  end else if (_t_in.get_dir() == MSG_FROM_RX) begin
    msg = rx_messages[_t_in.get_rx_encoding()];
  end else begin
    `uvm_fatal("LTSM2LINK", "Invalid direction flag on sequence item!")
  end
  
  msg.info = _t_in.info;
  msg.data = _t_in.data;

  return msg;
endfunction : get_message_struct
