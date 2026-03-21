`define true 1
`define SBINIT_PATTERN {32{2'b01}}

function logic [127:0] struct2raw(input message_t _msg);
  logic [31:0] phase0, phase1, phase2, phase3;
  logic [7:0]  code, subcode;

  extract_codes(_msg.fullcode, code, subcode);

  // Phase0 population
  phase0 [4:0]   = _msg.opcode;
  phase0 [13:5]  = '0;                      // Reserved
  phase0 [21:14] = code;
  phase0 [26:22] = '0;                      // Reserved
  phase0 [28:27] = '0;                      // Reserved
  phase0 [31:29] = _msg.srcid;

  // Phase2 population
  phase2         = _msg.data[31:0];
  
  // Phase3 population
  phase3         = _msg.data[63:32];

  // Phase1 population
  phase1 [7:0]   = subcode;
  phase1 [23:8]  = _msg.info;
  phase1 [26:24] = _msg.dstid;
  phase1 [29:27] = '0;                      // Reserved

  // Parity Bits
  phase1 [30]    = _msg.cp;                 // Control Parity
  phase1 [31]    = _msg.dp;                 // Data Parity
  
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
  msg.info     = '0;
  msg.data     = '0;

  // Parity Bits
  msg.cp = _msg_raw[62];
  msg.dp = _msg_raw[63];

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

function msgtype_t get_msgtype(fullcode_t _fullcode);
  if (_fullcode[11:8] == 'h5) begin
    return REQ_MSG;
  end else if (_fullcode[11:8] == 'hA) begin
    return RSP_MSG;
  end else begin
    return NO_TYPE;
  end
endfunction : get_msgtype
