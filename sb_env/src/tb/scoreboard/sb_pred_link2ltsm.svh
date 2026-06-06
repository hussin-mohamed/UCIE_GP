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
// CLASS: sb_pred_link2ltsm
//
// Predictor for the link-to-LTSM direction. It decodes monitored phylink items
// into the LTSM transactions expected on the DUT outputs.
//
//---------------------------------------------------------------------------

class sb_pred_link2ltsm extends uvm_subscriber #(phylink_seq_item);
  `uvm_component_utils(sb_pred_link2ltsm)

  uvm_analysis_port #(ltsm_seq_item)  results_ap_tx;
  uvm_analysis_port #(ltsm_seq_item)  results_ap_rx;
  uvm_analysis_port #(rdi_seq_item)   results_ap_rdi;

  int unsigned invalid_msg_cnt;


  // Function: new
  //
  // Creates the link-to-LTSM predictor component.

  extern function new(string name, uvm_component parent);


  // Function: build_phase
  //
  // Constructs the predictor output ports for TX, RX, and RDI paths.

  extern function void build_phase(uvm_phase phase);

  // Function: write
  //
  // Decodes one ACTIVE phylink item and forwards the resulting LTSM item to the
  // correct destination stream.

  extern function void write(phylink_seq_item t);

  // Function: get_predicted_item
  //
  // Produces the expected LTSM item and tags it with direction, data, and
  // validity information derived from the phylink item.

  extern function bit get_predicted_item(
    input phylink_seq_item _t_in,
    output ltsm_seq_item   _ltsm_item
  );

  // Function: lookup_encoding_tx
  //
  // Finds the TX encoding whose message template matches the incoming phylink
  // header fields.

  extern function bit lookup_encoding_tx(
    input  phylink_seq_item _t_in,
    output tx_encoding_t    _tx_enc
  );

  // Function: lookup_encoding_rx
  //
  // Finds the RX encoding whose message template matches the incoming phylink
  // header fields.

  extern function bit lookup_encoding_rx(
    input  phylink_seq_item _t_in,
    output rx_encoding_t    _rx_enc
  );
endclass

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

function sb_pred_link2ltsm::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

// build_phase
// -----------

function void sb_pred_link2ltsm::build_phase(uvm_phase phase);
  super.build_phase(phase);
  results_ap_tx  = new("results_ap_tx", this);
  results_ap_rx  = new("results_ap_rx", this);
  results_ap_rdi = new("results_ap_rdi", this);
endfunction

// write
// -----

function void sb_pred_link2ltsm::write(phylink_seq_item t);
  ltsm_seq_item ltsm_item;
  msg_dir_t     msg_dir;

  if (t.op_mode != ACTIVE) begin
    `uvm_fatal(get_type_name(), $sformatf("The sb_pred_link2ltsm handles only ACTIVE items. Received item:\n %s", t.sprint()))
  end
  
  if (get_predicted_item(t, ltsm_item)) begin
    // Store the direction for checking it
    msg_dir = ltsm_item.get_dir();
    
    // Route the item to the correct port based on the item's direction assigned by get_predicted_item()
    if (msg_dir == MSG_TO_RX) begin
      results_ap_tx.write(ltsm_item);
    end else if (msg_dir == MSG_TO_TX) begin
      results_ap_rx.write(ltsm_item);
    end
  end else begin // If the message is not supported, then do not send anything
    invalid_msg_cnt++;
    return;
  end
endfunction : write

// get_predicted_item
// ------------------

function bit sb_pred_link2ltsm::get_predicted_item(
  input phylink_seq_item _t_in,
  output ltsm_seq_item   _ltsm_item
);
  tx_encoding_t tx_enc;
  rx_encoding_t rx_enc;

  _ltsm_item = new();

  if (lookup_encoding_tx(_t_in, tx_enc)) begin // From TX to RX
    rx_enc = tx2rx_enc_lut[tx_enc];
    _ltsm_item.set_rx_encoding(rx_enc, 1);
    get_predicted_item = 1;
  end else if (lookup_encoding_rx(_t_in, rx_enc)) begin // From RX to TX
    tx_enc = rx2tx_enc_lut[rx_enc];
    _ltsm_item.set_tx_encoding(tx_enc, 1);
    get_predicted_item = 1;
  end else begin
    get_predicted_item = 0;
  end

  _ltsm_item.info    = _t_in.info;
  _ltsm_item.data    = _t_in.data;
  _ltsm_item.msgtype = get_msgtype_by_fullcode(_t_in.fullcode);
  _ltsm_item.valid   = is_valid(_t_in);
endfunction : get_predicted_item

// lookup_encoding_tx
// ------------------

function bit sb_pred_link2ltsm::lookup_encoding_tx(
  input  phylink_seq_item _t_in,
  output tx_encoding_t    _tx_enc
);
  message_t msg;

  msg.fullcode = _t_in.fullcode;
  msg.opcode   = _t_in.opcode;
  msg.srcid    = _t_in.srcid;
  msg.dstid    = _t_in.dstid;
  msg.info     = '0;
  msg.data     = '0;
  msg.cp       = '0;
  msg.dp       = '0;
  msg.rsvd1    = '0;
  msg.rsvd2    = '0;
  msg.rsvd3    = '0;
  msg.rsvd4    = '0;

  // Search for the tx_encoding that corresponds to this message
  foreach (tx_messages[key]) begin
    // Compare the struct in the array against our target struct
    if (tx_messages[key] == msg) begin
      _tx_enc = key;
      return 1;
    end
  end

  return 0;
endfunction : lookup_encoding_tx

// lookup_encoding_rx
// ------------------

function bit sb_pred_link2ltsm::lookup_encoding_rx(
  input  phylink_seq_item _t_in,
  output rx_encoding_t    _rx_enc
);
  message_t msg;

  msg.fullcode = _t_in.fullcode;
  msg.opcode   = _t_in.opcode;
  msg.srcid    = _t_in.srcid;
  msg.dstid    = _t_in.dstid;
  msg.info     = '0;
  msg.data     = '0;
  msg.cp       = '0;
  msg.dp       = '0;
  msg.rsvd1    = '0;
  msg.rsvd2    = '0;
  msg.rsvd3    = '0;
  msg.rsvd4    = '0;

  // Search for the rx_encoding that corresponds to this message
  foreach (rx_messages[key]) begin
    // Compare the struct in the array against our target struct
    if (rx_messages[key] == msg) begin
      _rx_enc = key;
      return 1;
    end
  end

  return 0;
endfunction : lookup_encoding_rx
