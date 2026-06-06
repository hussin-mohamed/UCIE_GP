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
// Predictor for the LTSM-to-link direction. It converts TX/RX LTSM items into
// the phylink transactions expected from the DUT.
//
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

  // Function: new
  //
  // Creates the LTSM-to-link predictor.

  extern function new(string name, uvm_component parent);

  // Function: build_phase
  //
  // Constructs the predictor inputs and output analysis port.

  extern virtual function void build_phase(uvm_phase phase);

  // Task: pre_reset_phase
  //
  // Flushes any queued LTSM items from previous runs.

  extern virtual task pre_reset_phase(uvm_phase phase);

  // Function: write_tx
  //
  // Queues an incoming TX-side LTSM item for prediction.

  extern function void write_tx(ltsm_seq_item t);

  // Function: write_rx
  //
  // Queues an incoming RX-side LTSM item for prediction.

  extern function void write_rx(ltsm_seq_item t);

  // Function: write_rdi
  //
  // Queues an incoming RDI item. The mailbox is kept for future path support.

  extern function void write_rdi(rdi_seq_item t);

  // Task: main_phase
  //
  // Pulls queued LTSM items, predicts the equivalent phylink items, and sends
  // them to the phylink comparator.

  extern virtual task main_phase(uvm_phase phase);

  // Function: get_predicted_item
  //
  // Builds the expected phylink item corresponding to one LTSM transaction.

  extern function phylink_seq_item get_predicted_item(ltsm_seq_item _t_in);

  // Function: get_message_struct
  //
  // Looks up the message template associated with the LTSM item encoding.

  extern function message_t get_message_struct(ltsm_seq_item _t_in);
endclass : sb_pred_ltsm2link

//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: sb_pred_ltsm2link
//
//---------------------------------------------------------------------------

// new
// ---

function sb_pred_ltsm2link::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void sb_pred_ltsm2link::build_phase(uvm_phase phase);
  super.build_phase(phase);
  axp_in_tx      = new("axp_in_tx", this);
  axp_in_rx      = new("axp_in_rx", this);
  axp_in_rdi     = new("axp_in_rdi", this);
  results_ap_phy = new("results_ap_phy", this);
endfunction : build_phase

// pre_reset_phase
// ---------------

task sb_pred_ltsm2link::pre_reset_phase(uvm_phase phase);
  ltsm_seq_item dummy;
  super.pre_reset_phase(phase);
  
  // Flush the mailboxes to prevent messages from the old run from failing the test of the next run
  while(tx_mb.try_get(dummy));
  while(rx_mb.try_get(dummy));
  while(rdi_mb.try_get(dummy));
endtask : pre_reset_phase

// write_tx
// --------

function void sb_pred_ltsm2link::write_tx(ltsm_seq_item t);
  if(!tx_mb.try_put(t)) begin
    `uvm_fatal("LTSM2PHY", "Invalid case: TX mailbox is full; a new item is trying to enter")
  end
endfunction : write_tx

// write_rx
// --------

function void sb_pred_ltsm2link::write_rx(ltsm_seq_item t);
  if(!rx_mb.try_put(t)) begin
    `uvm_fatal("LTSM2PHY", "Invalid case: RX mailbox is full; a new item is trying to enter")
  end
endfunction : write_rx

// write_rdi
// ---------

function void sb_pred_ltsm2link::write_rdi(rdi_seq_item t);
  if(!rdi_mb.try_put(t)) begin
    `uvm_fatal("LTSM2PHY", "Invalid case: RDI mailbox is full; a new item is trying to enter")
  end
endfunction : write_rdi

// main_phase
// ----------

task sb_pred_ltsm2link::main_phase(uvm_phase phase);
  super.main_phase(phase);
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
endtask : main_phase

// get_predicted_item
// ------------------

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
  if (t_out.opcode == MSG_WO_DATA) begin // Data takes the default value (i.e., 0) in case of MSG_WO_DATA
    t_out.data   = 0;
  end else if (t_out.opcode == MSG_W_64B_DATA) begin
    t_out.data   = msg.data;
  end 

  msg_raw = struct2raw(msg);

  // Parity Bits Calculation
  t_out.cp = ^{msg_raw[61:0]}; // cp (even parity of header bits)
  if (t_out.opcode == MSG_WO_DATA) begin // Data parity takes the default value (i.e., 0) in case of MSG_WO_DATA
    t_out.dp = 0;
  end else if (t_out.opcode == MSG_W_64B_DATA) begin
    t_out.dp = ^{msg_raw[127:64]};
  end

  // Reserved fields
  t_out.rsvd1 = '0;
  t_out.rsvd2 = '0;
  t_out.rsvd3 = '0;
  t_out.rsvd4 = '0;

  return t_out;
endfunction : get_predicted_item

// get_message_struct
// ------------------

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
