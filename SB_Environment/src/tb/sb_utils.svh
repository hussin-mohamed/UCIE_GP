`define true 1
`define SBINIT_PATTERN {32{2'b01}}
typedef class phylink_seq_item;

function logic [127:0] struct2raw(input message_t _msg);
  logic [31:0] phase0, phase1, phase2, phase3;
  logic [7:0]  code, subcode;

  extract_codes(_msg.fullcode, code, subcode);

  // Phase0 population
  phase0 [4:0]   = _msg.opcode;
  phase0 [13:5]  = _msg.rsvd1;     // Reserved
  phase0 [21:14] = code;
  phase0 [26:22] = _msg.rsvd2;     // Reserved
  phase0 [28:27] = _msg.rsvd3;     // Reserved
  phase0 [31:29] = _msg.srcid;

  // Phase2 population
  phase2         = _msg.data[31:0];
  
  // Phase3 population
  phase3         = _msg.data[63:32];

  // Phase1 population
  phase1 [7:0]   = subcode;
  phase1 [23:8]  = _msg.info;
  phase1 [26:24] = _msg.dstid;
  phase1 [29:27] = _msg.rsvd4;     // Reserved

  // Parity Bits
  phase1 [30]    = _msg.cp;        // Control Parity
  phase1 [31]    = _msg.dp;        // Data Parity
  
  return {phase3, phase2, phase1, phase0};
endfunction : struct2raw

function message_t raw2struct(input logic [127:0] _msg_raw);
  message_t msg;

  logic [31:0]  phase0, phase1, phase2, phase3;
  bit           cp, dp;

  // Decode the raw message into the 4 phases
  phase0 = _msg_raw[31:0];
  phase1 = _msg_raw[63:32];
  phase2 = _msg_raw[95:64];
  phase3 = _msg_raw[127:96];

  // Conversion to struct
  msg.fullcode = fullcode_t'({phase0[21:14], phase1[7:0]});
  msg.opcode   = opcode_t'(phase0[4:0]);
  msg.srcid    = srcid_t'(phase0[31:29]);
  msg.dstid    = dstid_t'(phase1[26:24]);
  msg.info     = phase1 [23:8];
  msg.data     = {phase3, phase2};

  // Parity Bits
  msg.cp = _msg_raw[62];
  msg.dp = _msg_raw[63];

  // Reserved fields
  msg.rsvd1 = phase0 [13:5];
  msg.rsvd2 = phase0 [26:22];
  msg.rsvd3 = phase0 [28:27];
  msg.rsvd4 = phase1 [29:27];

  return msg;
endfunction : raw2struct

function void print_message(message_t msg);
    $display("----------- message_t -----------");
    $display("fullcode : %s", msg.fullcode.name());
    $display("opcode   : %s", msg.opcode.name());
    $display("srcid    : %s", msg.srcid.name());
    $display("dstid    : %s", msg.dstid.name());
    $display("info     : 0x%04h", msg.info);
    $display("data     : 0x%016h", msg.data);
    $display("---------------------------------");
endfunction

// Function to extract the 8-bit MsgCode and 8-bit MsgSubcode from the 16-bit fullcode_t
function void extract_codes(
  input  fullcode_t  _fullcode_in,
  output logic [7:0] _code,
  output logic [7:0] _subcode
);
  _code    = _fullcode_in[15:8]; 
  _subcode = _fullcode_in[7:0];  
endfunction : extract_codes

function msgtype_t get_msgtype_by_fullcode(fullcode_t _fullcode);
  if (_fullcode[11:8] == 'h5) begin
    return REQ_MSG;
  end else if (_fullcode[11:8] == 'hA) begin
    return RSP_MSG;
  end else if (_fullcode == SBINIT_out_of_Reset || _fullcode == Rx_Init_D_to_C_sweep_done_with_results) begin
    return REQ_MSG;
  end else begin
    return NO_TYPE;
  end
endfunction : get_msgtype_by_fullcode

function msgtype_t get_msgtype_by_encoding(tx_encoding_t _tx_enc, rx_encoding_t _rx_enc);
  if (_tx_enc != NOP_TX) begin
    if (
      _tx_enc == Data_To_Clock_test_TX_RX_INIT_Handshake ||
      _tx_enc == Data_To_Clock_test_TX_RX_INIT_End_Init_Handshake
    ) begin
      return RSP_MSG;
    end else begin
      return REQ_MSG;
    end
  end else begin
    if (
      _rx_enc == Data_To_Clock_test_RX_RX_INIT_Handshake ||
      _rx_enc == Data_To_Clock_test_RX_RX_INIT_End_Init_Handshake
    ) begin
      return REQ_MSG;
    end else begin
      return RSP_MSG;
    end
  end
endfunction : get_msgtype_by_encoding

function opcode_t get_opcode(tx_encoding_t _tx_enc, rx_encoding_t _rx_enc);
  if (_tx_enc != NOP_TX) begin
    return tx_messages[_tx_enc].opcode;
  end else begin
    return rx_messages[_rx_enc].opcode;
  end
endfunction : get_opcode

function void populate_item_with_msg (input message_t _msg, inout phylink_seq_item _item);
  _item.fullcode = _msg.fullcode;
  _item.opcode   = _msg.opcode;
  _item.srcid    = _msg.srcid;
  _item.dstid    = _msg.dstid;
  _item.info     = _msg.info;
  _item.data     = _msg.data;
  _item.cp       = _msg.cp;
  _item.dp       = _msg.dp;
  _item.rsvd1    = _msg.rsvd1;
  _item.rsvd2    = _msg.rsvd2;
  _item.rsvd3    = _msg.rsvd3;
  _item.rsvd4    = _msg.rsvd4;
endfunction : populate_item_with_msg

function message_t item2struct(input phylink_seq_item _item);
  item2struct.fullcode = _item.fullcode;
  item2struct.opcode   = _item.opcode;
  item2struct.srcid    = _item.srcid;
  item2struct.dstid    = _item.dstid;
  item2struct.info     = _item.info;
  item2struct.data     = _item.data;
  item2struct.cp       = _item.cp;
  item2struct.dp       = _item.dp;
  item2struct.rsvd1    = _item.rsvd1;
  item2struct.rsvd2    = _item.rsvd2;
  item2struct.rsvd3    = _item.rsvd3;
  item2struct.rsvd4    = _item.rsvd4;
endfunction : item2struct

function logic [127:0] item2raw(input phylink_seq_item _item);
  message_t msg;
  msg = item2struct(_item);
  return struct2raw(msg);
endfunction : item2raw

function bit get_msg_by_fullcode(input fullcode_t _fullcode, output message_t _msg);
  foreach (tx_messages[tx_enc]) begin
    if (tx_messages[tx_enc].fullcode == _fullcode) begin
      _msg = tx_messages[tx_enc];
      return 1;
    end
  end
  foreach (rx_messages[rx_enc]) begin
    if (rx_messages[rx_enc].fullcode == _fullcode) begin
      _msg = rx_messages[rx_enc];
      return 1;
    end
  end
  return 0;
endfunction : get_msg_by_fullcode

function void calculate_parity_by_stuct(
  input  message_t _msg,
  output bit       _cp,
  output bit       _dp
);
  logic [127:0] msg_raw;

  msg_raw = struct2raw(_msg);
  _cp = ^{msg_raw[61:0]};   // cp (even parity of header bits)
  _dp = ^{msg_raw[127:64]}; // dp (even parity of data payload)
endfunction : calculate_parity_by_stuct

function void calculate_parity_by_item(
  input  phylink_seq_item _item,
  output bit              _cp,
  output bit              _dp
);

  logic [127:0] msg_raw;

  msg_raw = item2raw(_item);
  _cp = ^{msg_raw[61:0]};   // cp (even parity of header bits)
  _dp = ^{msg_raw[127:64]}; // dp (even parity of data payload)
endfunction : calculate_parity_by_item

function bit is_valid(input phylink_seq_item _item);
  bit cp, dp;

  calculate_parity_by_item(_item, cp, dp);

  if ((_item.cp != cp) || (_item.dp != dp)) begin
    return 0;
  end else begin
    return 1;
  end
endfunction : is_valid

function bit is_supported_fullcode(input fullcode_t _fullcode);
  foreach (tx_messages[tx_enc]) begin
    if (tx_messages[tx_enc].fullcode == _fullcode) begin
      return 1;
    end
  end
  foreach (rx_messages[rx_enc]) begin
    if (rx_messages[rx_enc].fullcode == _fullcode) begin
      return 1;
    end
  end
  return 0;
endfunction : is_supported_fullcode

function bit is_unsupported_existing_fullcode(input fullcode_t _fullcode);
  foreach (unsupported_messages[code]) begin
    if (code == _fullcode) begin
      return 1;
    end
  end
  return 0;
endfunction : is_unsupported_existing_fullcode
