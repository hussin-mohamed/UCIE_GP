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
// Description: ...
//---------------------------------------------------------------------------

class sb_pred_link2ltsm extends uvm_subscriber #(phylink_seq_item);
  `uvm_component_utils(sb_pred_link2ltsm)

  uvm_analysis_port #(ltsm_seq_item)  results_ap_tx;
  uvm_analysis_port #(ltsm_seq_item)  results_ap_rx;
  uvm_analysis_port #(rdi_seq_item)   results_ap_rdi;

  extern function new(string name, uvm_component parent);

  extern function void build_phase(uvm_phase phase);

  extern function void write(phylink_seq_item t);

  extern function bit is_supported_msg(phylink_seq_item _t_in);

  extern function ltsm_seq_item get_predicted_item(phylink_seq_item _t_in);

  extern function bit lookup_encoding_tx(
    input  phylink_seq_item _t_in,
    output tx_encoding_t    _tx_enc
  );

  extern function bit lookup_encoding_rx(
    input  phylink_seq_item _t_in,
    output rx_encoding_t    _rx_enc
  );

  extern function bit is_valid(input phylink_seq_item _t_in);
endclass

function sb_pred_link2ltsm::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

function void sb_pred_link2ltsm::build_phase(uvm_phase phase);
  super.build_phase(phase);
  results_ap_tx  = new("results_ap_tx", this);
  results_ap_rx  = new("results_ap_rx", this);
  results_ap_rdi = new("results_ap_rdi", this);
endfunction

function void sb_pred_link2ltsm::write(phylink_seq_item t);
  ltsm_seq_item ltsm_item;

  // If the message is not supported, then do not send anything
  if (!is_supported_msg(t)) begin
    return;
  end
  
  // Get the predicted ltsm item
  ltsm_item = get_predicted_item(t);

  // Route the item to the correct port based on the item's direction assigned by get_predicted_item()
  if (ltsm_item.get_dir() == MSG_FROM_TX) begin
    results_ap_tx.write(ltsm_item);
  end else begin
    results_ap_rx.write(ltsm_item);
  end
endfunction : write

function bit sb_pred_link2ltsm::is_supported_msg(phylink_seq_item _t_in);
  bit is_supported_opcode;
  bit is_supported_srcid;
  bit is_supported_dstid;
  bit is_supported_fullcode;

  is_supported_opcode   = (_t_in.opcode == MSG_WO_DATA || _t_in.opcode == MSG_W_64B_DATA);
  is_supported_srcid    = (_t_in.srcid == SRC_PHY);
  is_supported_dstid    = (_t_in.dstid == DST_PHY);
  is_supported_fullcode =
  (
    _t_in.fullcode              == SBINIT_out_of_Reset                    ||
    _t_in.fullcode              == Rx_Init_D_to_C_sweep_done_with_results ||
    get_msgtype(_t_in.fullcode) == REQ_MSG                                ||
    get_msgtype(_t_in.fullcode) == RSP_MSG
  );

  // Return 1 if and only if the message is supported
  if (
    !is_supported_opcode   ||
    !is_supported_srcid    ||
    !is_supported_dstid    ||
    !is_supported_fullcode
  ) begin
    return 0;
  end else begin
    return 1;
  end
endfunction : is_supported_msg

function ltsm_seq_item sb_pred_link2ltsm::get_predicted_item(phylink_seq_item _t_in);
  ltsm_seq_item ltsm_item;
  tx_encoding_t tx_enc;
  rx_encoding_t rx_enc;

  ltsm_item = new();

  if (lookup_encoding_tx(_t_in, tx_enc)) begin
    ltsm_item.set_tx_encoding(tx_enc);
  end else if (lookup_encoding_rx(_t_in, rx_enc)) begin
    ltsm_item.set_rx_encoding(rx_enc);
  end

  ltsm_item.info    = _t_in.info;
  ltsm_item.data    = _t_in.data;
  ltsm_item.msgtype = get_msgtype(_t_in.fullcode);
  ltsm_item.valid   = is_valid(_t_in);

  return ltsm_item;
endfunction : get_predicted_item

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

function bit sb_pred_link2ltsm::is_valid(input phylink_seq_item _t_in);
  message_t     msg;
  logic [127:0] msg_raw;
  bit           cp, dp;

  msg.fullcode = _t_in.fullcode;
  msg.opcode   = _t_in.opcode;
  msg.srcid    = _t_in.srcid;
  msg.dstid    = _t_in.dstid;
  msg.info     = _t_in.info;
  msg.data     = _t_in.data;
  msg.cp       = _t_in.cp;
  msg.dp       = _t_in.dp;

  msg_raw = struct2raw(msg);

  // Parity Bits Calculation
  cp = ^{msg_raw[61:0]};  // cp (even parity of header bits)
  dp = ^{msg_raw[127:64]};  // dp (even parity of data payload)

  if ((_t_in.cp != cp) || (_t_in.dp != dp)) begin
    return 0;
  end else begin
    return 1;
  end
endfunction : is_valid
