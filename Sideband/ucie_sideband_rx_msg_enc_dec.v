//------------------------------------------------------------------------------
// Module: ucie_sideband_rx_msg_enc_dec
// Description: ...
//------------------------------------------------------------------------------
module ucie_sideband_rx_msg_enc_dec
#(//---- PARAMETER DECLARATIONS ------------------------------------------------
  parameter  pENCODING_WIDTH      = 9   // Width of Encoding field
  ,parameter pDECODING_WIDTH      = 9   // Width of Decoding field
  ,parameter pDATA_WIDTH          = 64  // Width of data bus
  ,parameter pINFO_WIDTH          = 16  // Width of info field
  ,parameter pMSG_CODE_WIDTH      = 8   // Width of message code field
  ,parameter pMSG_SUBCODE_WIDTH   = 8   // Width of message subcode field
  ,parameter pOP_CODE_WIDTH       = 5   // Width of operation code field
  ,parameter pRESERVED            = 0   // Reserved bits
  ,parameter pMSG_WIDTH           = 128 // Width of messsage bus
)
(//---- PORT DECLARATIONS -----------------------------------------------------
  input  wire                   i_clk
  ,input  wire                  i_reset
  ,input  wire                  i_req
  ,input  wire                  i_resp
  ,input  wire                  i_done
  ,input  wire [pDATA_WIDTH-1:0] i_data_in
  ,input  wire [pENCODING_WIDTH-1:0] i_encoding
  ,input  wire [pINFO_WIDTH-1:0] i_info_in
  ,input  wire [pMSG_WIDTH-1:0] i_msg_in
  ,input  wire                  i_full
  ,input  wire                  i_empty
  ,output reg                   o_req
  ,output reg                   o_resp
  ,output reg                   o_done
  ,output reg  [pDATA_WIDTH-1:0] o_data_out
  ,output reg  [pDECODING_WIDTH-1:0] o_decoding
  ,output reg  [pINFO_WIDTH-1:0] o_info_out
  ,output reg  [pMSG_WIDTH-1:0] o_msg_out
  ,output reg                  o_enc_ready
  ,output reg                  o_dec_ready
  ,output reg                  o_valid
);

  //---- SIGNAL DECLARATIONS ---------------------------------------------------
  
  reg  [pMSG_CODE_WIDTH-1:0] enc_msg_code;
  reg  [pMSG_SUBCODE_WIDTH-1:0] enc_msg_subcode;
  reg  [pOP_CODE_WIDTH-1:0] enc_op_code;
  reg  [2:0] enc_srcid;
  reg  [2:0] enc_dstid;
  reg  enc_dp;
  reg  enc_cp;

  reg  [pMSG_CODE_WIDTH-1:0] dec_msg_code;
  reg  [pMSG_SUBCODE_WIDTH-1:0] dec_msg_subcode;
  reg  [pOP_CODE_WIDTH-1:0] dec_op_code;
  reg  [2:0] dec_srcid;
  reg  [2:0] dec_dstid;
  reg  dec_dp;
  reg  dec_cp;
  reg  stall_flag;

  
  //---- SEQUENTIAL PROCESSES --------------------------------------------------

  // Encoding Process
  always @(posedge i_clk or posedge i_reset) 
  begin: Encoding_proc
    if (i_reset) 
    begin
      enc_msg_code    <= {pMSG_CODE_WIDTH{1'b0}};
      enc_msg_subcode <= {pMSG_SUBCODE_WIDTH{1'b0}};
      enc_op_code     <= {pOP_CODE_WIDTH{1'b0}};
      enc_srcid       <= 3'b000;
      enc_dstid       <= 3'b000;
      enc_dp          <= 1'b0;
      enc_cp          <= 1'b0;
      o_msg_out        <= {pMSG_WIDTH{1'b0}};
      o_enc_ready          <= 1'b0;
      o_done           <= 1'b0;
    end 
    else begin
    if ((i_req || i_resp ) && !i_full) 
    begin
      case (i_encoding)
      
      // ========== SBINIT Messages ==========
        'h9: begin
          enc_msg_code    <= 'h9A; // SBINIT done resp message code
          enc_msg_subcode <= 'h01; // SBINIT done resp message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end

        // ========== MBINIT.PARAM Messages ==========
        'h12: begin
          enc_msg_code    <= 'hAA; // MBINIT.PARAM done resp message code
          enc_msg_subcode <= 'h00; // MBINIT.PARAM done resp message subcode
          enc_op_code     <= 'b11011; // Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer destination ID 
          enc_dstid       <= 3'b110; // Remote Die Physical Layer source ID
          enc_dp          <= ^i_data_in; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,i_data_in}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end

      // ========== MBINIT.CAL Messages ==========
        'h18: begin
          enc_msg_code    <= 'hAA; // MBINIT.CAL Done resp message code
          enc_msg_subcode <= 'h02; // MBINIT.CAL Done resp message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end

      // ========== MBINIT.REPAIRCLK Messages ==========
        'h20: begin
          enc_msg_code    <= 'hAA; // MBINIT.REPAIRCLK init resp message code
          enc_msg_subcode <= 'h03; // MBINIT.REPAIRCLK init resp message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'h23: begin
          enc_msg_code    <= 'hAA; // MBINIT.REPAIRCLK result resp message code
          enc_msg_subcode <= 'h04; // MBINIT.REPAIRCLK result resp message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'h24: begin
          enc_msg_code    <= 'hAA; // MBINIT.REPAIRCLK done resp message code
          enc_msg_subcode <= 'h08; // MBINIT.REPAIRCLK done resp message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end

      // ========== MBINIT.REPAIRVAL Messages ==========
        'h28: begin
          enc_msg_code    <= 'hAA; // MBINIT.REPAIRVAL init resp message code
          enc_msg_subcode <= 'h09; // MBINIT.REPAIRVAL init resp message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'h2B: begin
          enc_msg_code    <= 'hAA; // MBINIT.REPAIRVAL result resp message code
          enc_msg_subcode <= 'h0A; // MBINIT.REPAIRVAL result resp message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'h2C: begin
          enc_msg_code    <= 'hAA; // MBINIT.REPAIRVAL done resp message code
          enc_msg_subcode <= 'h0C; // MBINIT.REPAIRVAL done resp message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end

      // ========== MBINIT.REVERSALMB Messages ==========
        'h30: begin
          enc_msg_code    <= 'hAA; // MBINIT.REVERSALMB init resp message code
          enc_msg_subcode <= 'h0D; // MBINIT.REVERSALMB init resp message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'h31: begin
          enc_msg_code    <= 'hAA; // MBINIT.REVERSALMB clear error resp message code
          enc_msg_subcode <= 'h0E; // MBINIT.REVERSALMB clear error resp message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'h33: begin
          enc_msg_code    <= 'hAA; // MBINIT.REVERSALMB result resp message code
          enc_msg_subcode <= 'h0F; // MBINIT.REVERSALMB result resp message subcode
          enc_op_code     <= 'b11011; // Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= ^i_data_in; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,i_data_in}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'h34: begin
          enc_msg_code    <= 'hAA; // MBINIT.REVERSALMB done resp message code
          enc_msg_subcode <= 'h10; // MBINIT.REVERSALMB done resp message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end

      // ========== MBINIT.REPAIRMB Messages ==========
        'h38: begin
          enc_msg_code    <= 'hAA; // MBINIT.REPAIRMB start resp message code
          enc_msg_subcode <= 'h11; // MBINIT.REPAIRMB start resp message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'h3C: begin
          enc_msg_code    <= 'hAA; // MBINIT.REPAIRMB apply degrade resp message code
          enc_msg_subcode <= 'h14; // MBINIT.REPAIRMB apply degrade resp message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'h3D: begin
          enc_msg_code    <= 'hAA; // MBINIT.REPAIRMB end resp message code
          enc_msg_subcode <= 'h13; // MBINIT.REPAIRMB end resp message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
      
      // ========== MBTRAIN.VALVREF Messages ==========
        'h80: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.VALVREF start resp) message code
          enc_msg_subcode <= 'h00; // (MBTRAIN.VALVREF start resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'h82: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.VALVREF end resp) message code
          enc_msg_subcode <= 'h01; // (MBTRAIN.VALVREF end resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end

      // ========== MBTRAIN.DATAVREF Messages ==========
        'h88: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.DATAVREF start resp) message code
          enc_msg_subcode <= 'h02; // (MBTRAIN.DATAVREF start resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'h8A: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.DATAVREF end resp) message code
          enc_msg_subcode <= 'h03; // (MBTRAIN.DATAVREF end resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end

      // ========== MBTRAIN.SPEEDIDLE Messages ==========
        'hCA: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.SPEEDIDLE done resp) message code
          enc_msg_subcode <= 'h04; // (MBTRAIN.SPEEDIDLE done resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end

      // ========== MBTRAIN.TXSELFCAL Messages ==========
        'hD0: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.TXSELFCAL Done resp) message code
          enc_msg_subcode <= 'h05; // (MBTRAIN.TXSELFCAL Done resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end

      // ========== MBTRAIN.RXCLKCAL Messages ==========
        'h98: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.RXCLKCAL start resp) message code
          enc_msg_subcode <= 'h06; // (MBTRAIN.RXCLKCAL start resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'h9A: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.RXCLKCAL done resp) message code
          enc_msg_subcode <= 'h07; // (MBTRAIN.RXCLKCAL done resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end

      // ========== MBTRAIN.VALTRAINCENTER Messages ==========
        'hA0: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.VALTRAINCENTER start resp) message code
          enc_msg_subcode <= 'h08; // (MBTRAIN.VALTRAINCENTER start resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'hA2: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.VALTRAINCENTER done resp) message code
          enc_msg_subcode <= 'h09; // (MBTRAIN.VALTRAINCENTER done resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end

      // ========== MBTRAIN.VALTRAINVREF Messages ==========
        'hE8: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.VALTRAINVREF start resp) message code
          enc_msg_subcode <= 'h0A; // (MBTRAIN.VALTRAINVREF start resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'hEA: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.VALTRAINVREF done resp) message code
          enc_msg_subcode <= 'h0B; // (MBTRAIN.VALTRAINVREF done resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end

      // ========== MBTRAIN.DATATRAINCENTER1 Messages ==========
        'h90: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.DATATRAINCENTER1 start resp) message code
          enc_msg_subcode <= 'h0C; // (MBTRAIN.DATATRAINCENTER1 start resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'h92: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.DATATRAINCENTER1 end resp) message code
          enc_msg_subcode <= 'h0D; // (MBTRAIN.DATATRAINCENTER1 end resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end

      // ========== MBTRAIN.DATATRAINVREF Messages ==========
        'hF0: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.DATATRAINVREF start resp) message code
          enc_msg_subcode <= 'h0E; // (MBTRAIN.DATATRAINVREF start resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'hF2: begin
          enc_msg_code    <= 'hB5; // (MBTRAIN.DATATRAINVREF end req) message code
          enc_msg_subcode <= 'h10; // (MBTRAIN.DATATRAINVREF end req) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end

      // ========== MBTRAIN.RXDESKEW Messages ==========
        'hA8: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.RXDESKEW start resp) message code
          enc_msg_subcode <= 'h11; // (MBTRAIN.RXDESKEW start resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'hAC: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.RXDESKEW end resp) message code
          enc_msg_subcode <= 'h12; // (MBTRAIN.RXDESKEW end resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end

      // ========== MBTRAIN.DATATRAINCENTER2 Messages ==========
        'hB0: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.DATATRAINCENTER2 start resp) message code
          enc_msg_subcode <= 'h13; // (MBTRAIN.DATATRAINCENTER2 start resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'hB2: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.DATATRAINCENTER2 end resp) message code
          enc_msg_subcode <= 'h14; // (MBTRAIN.DATATRAINCENTER2 end resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end

      // ========== MBTRAIN.LINKSPEED Messages ==========
        'hB8: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.LINKSPEED start resp) message code
          enc_msg_subcode <= 'h15; // (MBTRAIN.LINKSPEED start resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'hBF: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.LINKSPEED error resp) message code
          enc_msg_subcode <= 'h16; // (MBTRAIN.LINKSPEED error resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'hBD: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.LINKSPEED exit to repair resp) message code
          enc_msg_subcode <= 'h17; // (MBTRAIN.LINKSPEED exit to repair resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'hBB: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.LINKSPEED exit to speed degrade resp) message code
          enc_msg_subcode <= 'h18; // (MBTRAIN.LINKSPEED exit to speed degrade resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'hBE: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.LINKSPEED done resp) message code
          enc_msg_subcode <= 'h19; // (MBTRAIN.LINKSPEED done resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'hBC: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.LINKSPEED exit to phy retrain resp) message code
          enc_msg_subcode <= 'h1F; // (MBTRAIN.LINKSPEED exit to phy retrain resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end

      // ========== MBTRAIN.REPAIR Messages ==========
        'hC0: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.REPAIR init resp) message code
          enc_msg_subcode <= 'h1B; // (MBTRAIN.REPAIR init resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'hC3: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.REPAIR end resp) message code
          enc_msg_subcode <= 'h1D; // (MBTRAIN.REPAIR end resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'hC4: begin
          enc_msg_code    <= 'hBA; // (MBTRAIN.REPAIR Apply degrade resp) message code
          enc_msg_subcode <= 'h1E; // (MBTRAIN.REPAIR Apply degrade resp) message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end

      // ========== PHYRETRAIN Messages ==========
        'hDA: begin
          enc_msg_code    <= 'hCA; // PHYRETRAIN.retrain start resp message code
          enc_msg_subcode <= 'h01; // PHYRETRAIN.retrain start resp message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end

      // ========== TRAINERROR Messages ==========
        'hE0: begin
          enc_msg_code    <= 'hEA; // TRAINERROR Entry resp message code
          enc_msg_subcode <= 'h00; // TRAINERROR Entry resp message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end

      // ========== TX INIT D to C Messages ==========
        'h180: begin
          enc_msg_code    <= 'h8A; // Start Tx Init D to C eye sweep resp message code
          enc_msg_subcode <= 'h05; // Start Tx Init D to C eye sweep resp message subcode
          enc_op_code     <= 'b10010; // Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0;   // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'h181: begin
          enc_msg_code    <= 'h8A; // LFSR_clear_error resp message code
          enc_msg_subcode <= 'h02; // LFSR_clear_error resp message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'h183: begin
          enc_msg_code    <= 'h8A; // Tx Init D to C results resp message code
          enc_msg_subcode <= 'h03; // Tx Init D to C results resp message subcode
          enc_op_code     <= 'b11011; // Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= ^i_data_in; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,i_data_in}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'h184: begin
          enc_msg_code    <= 'h8A; // End Tx Init D to C eye sweep resp message code
          enc_msg_subcode <= 'h06; // End Tx Init D to C eye sweep resp message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end

      // ========== RX INIT D to C Messages ==========
        'h185: begin
          enc_msg_code    <= 'h85; // Start Rx Init D to C eye sweep req message code
          enc_msg_subcode <= 'h0A; // Start Rx Init D to C eye sweep req message subcode
          enc_op_code     <= 'b11011; // Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= ^i_data_in; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,i_data_in}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'h188: begin
          enc_msg_code    <= 'h8A; // Rx Init D to C results resp message code
          enc_msg_subcode <= 'h0B; // Rx Init D to C results resp message subcode
          enc_op_code     <= 'b11011; // Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= ^i_data_in; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,i_data_in}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end
        'h18A: begin
          enc_msg_code    <= 'h8A; // End Rx Init D to C eye sweep resp message code
          enc_msg_subcode <= 'h0D; // End Rx Init D to C eye sweep resp message subcode
          enc_op_code     <= 'b10010; // No Data Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                              enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
          o_msg_out       <= {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                             enc_dstid,i_info_in,enc_msg_subcode,{64{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b1;
          o_done          <= 1'b1;
        end

        default: begin
          enc_msg_code    <= 'h00; // Default message code
          enc_msg_subcode <= 'h00; // Default message subcode
          enc_op_code     <= 'b10101; // Default Operation message code
          enc_srcid       <= 3'b010; // Physical Layer source ID
          enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
          enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
          enc_cp          <= 1'b0; // Control Parity (even parity over header fields)
          o_msg_out       <= {{128{1'b0}}}; // Construct message
          o_enc_ready         <= 1'b0;
          o_done          <= 1'b0;
        end
      endcase
      
    end
    else begin
      enc_msg_code    <= 'h00;
      enc_msg_subcode <= 'h00;
      enc_op_code     <= 'b10101; // Default Operation message code
      enc_srcid       <= 3'b010; // Physical Layer source ID
      enc_dstid       <= 3'b110; // Remote Die Physical Layer destination ID
      enc_dp          <= 1'b0; // Data Parity (even parity over all data bits)
      enc_cp          <= 1'b0; // Control Parity (even parity over header fields)
      o_msg_out       <= {{128{1'b0}}}; // Construct message
      o_enc_ready         <= 1'b0;
      o_done          <= 1'b0;
    end
    end
  end // Encoding_proc

  //Decoding process
  always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
      o_req           <= 1'b0;
      o_resp          <= 1'b0;
      o_info_out      <= {pINFO_WIDTH{1'b0}};
      o_data_out      <= {pDATA_WIDTH{1'b0}};
      o_decoding      <= {pDECODING_WIDTH{1'b0}};
      o_valid         <= 1'b0;
      o_dec_ready     <= 1'b0;
      stall_flag      <= 1'b0;
    end
    else begin
    if (!i_empty && !stall_flag) begin
      o_dec_ready     <= 1'b1; // Indicate ready to take input message
      dec_msg_code    <= i_msg_in[117:110]; // Extract message code from input message
      dec_msg_subcode <= i_msg_in[71:64]; // Extract message subcode from input message
      dec_op_code     <= i_msg_in[100:96]; // Extract operation code from input message
      dec_srcid       <= i_msg_in[127:125]; // Extract source ID from input message
      dec_dstid       <= i_msg_in[90:88]; // Extract destination ID from input message
      dec_dp          <= ^{i_msg_in[63:0]}; // Extract data parity bit from input message
      dec_cp          <= ^{{i_msg_in[127:96], i_msg_in[93:64]}}; // Extract control parity bit from input message
      if (dec_cp != i_msg_in[94] || dec_dp != i_msg_in[95] || dec_srcid != 3'b010 || dec_dstid != 3'b110) begin
        o_valid     <= 1'b0; // Invalid message due to parity error
      end
      else begin
        o_valid     <= 1'b1; // Valid message
      end
      o_info_out  <= i_msg_in[87:72]; // Extract info field from input message
      o_data_out  <= i_msg_in[63:0]; // Extract data field from input message
      stall_flag  <= 1'b1; // Mark that first message has been processed
      case ({dec_msg_code, dec_msg_subcode, dec_op_code})
      
      // ========== SBINIT Messages ==========
        {8'h91, 8'h00, 5'b10010}: begin  // SBINIT out of Reset
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h8;
        end
        {8'h95, 8'h01, 5'b10010}: begin  // SBINIT done req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h9;
        end
      // ========== MBINIT.PARAM Messages ==========
        {8'hA5, 8'h00, 5'b11011}: begin  // MBINIT.PARAM Done req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h12;
        end

      // ========== MBINIT.CAL Messages ==========
        {8'hA5, 8'h02, 5'b10010}: begin  // MBINIT.CAL Done req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h18;
        end

      // ========== MBINIT.REPAIRCLK Messages ==========
        {8'hA5, 8'h03, 5'b10010}: begin  // MBINIT.REPAIRCLK init req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h20;
        end
        {8'hA5, 8'h04, 5'b10010}: begin  // MBINIT.REPAIRCLK result req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h23;
        end
        {8'hA5, 8'h08, 5'b10010}: begin  // MBINIT.REPAIRCLK done req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h24;
        end

      // ========== MBINIT.REPAIRVAL Messages ==========
        {8'hA5, 8'h09, 5'b10010}: begin  // MBINIT.REPAIRVAL init req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h28;
        end
        {8'hA5, 8'h0A, 5'b10010}: begin  // MBINIT.REPAIRVAL result req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h2B;
        end
        {8'hA5, 8'h0C, 5'b10010}: begin  // MBINIT.REPAIRVAL done req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h2C;
        end

      // ========== MBINIT.REVERSALMB Messages ==========
        {8'hA5, 8'h0D, 5'b10010}: begin  // MBINIT.REVERSALMB init req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h30;
        end
        {8'hA5, 8'h0E, 5'b10010}: begin  // MBINIT.REVERSALMB clear error req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h31;
        end
        {8'hA5, 8'h0F, 5'b11011}: begin  // MBINIT.REVERSALMB result req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h33;
        end
        {8'hA5, 8'h10, 5'b10010}: begin  // MBINIT.REVERSALMB done req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h34;
        end

      // ========== MBINIT.REPAIRMB Messages ==========
        {8'hA5, 8'h11, 5'b10010}: begin  // MBINIT.REPAIRMB start req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h38;
        end
        {8'hA5, 8'h14, 5'b10010}: begin  // MBINIT.REPAIRMB apply degrade req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h3C;
        end
        {8'hA5, 8'h13, 5'b10010}: begin  // MBINIT.REPAIRMB end req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h3D;
        end

      // ========== MBTRAIN.VALVREF Messages ==========
        {8'hB5, 8'h00, 5'b10010}: begin  // MBTRAIN.VALVREF start req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h80;
        end
        {8'hB5, 8'h01, 5'b10010}: begin  // MBTRAIN.VALVREF end req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h82;
        end

      // ========== MBTRAIN.DATAVREF Messages ==========
        {8'hB5, 8'h02, 5'b10010}: begin  // MBTRAIN.DATAVREF start req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h88;
        end
        {8'hB5, 8'h03, 5'b10010}: begin  // MBTRAIN.DATAVREF end req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h8A;
        end

      // ========== MBTRAIN.SPEEDIDLE Messages ==========
        {8'hB5, 8'h04, 5'b10010}: begin  // MBTRAIN.SPEEDIDLE done req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'hCA;
        end

      // ========== MBTRAIN.TXSELFCAL Messages ==========
        {8'hB5, 8'h05, 5'b10010}: begin  // MBTRAIN.TXSELFCAL Done req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'hD0;
        end

      // ========== MBTRAIN.RXCLKCAL Messages ==========
        {8'hB5, 8'h06, 5'b10010}: begin  // MBTRAIN.RXCLKCAL start req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h98;
        end
        {8'hB5, 8'h07, 5'b10010}: begin  // MBTRAIN.RXCLKCAL done req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h9A;
        end

      // ========== MBTRAIN.VALTRAINCENTER Messages ==========
        {8'hB5, 8'h08, 5'b10010}: begin  // MBTRAIN.VALTRAINCENTER start req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'hA0;
        end
        {8'hB5, 8'h09, 5'b10010}: begin  // MBTRAIN.VALTRAINCENTER done req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'hA2;
        end

      // ========== MBTRAIN.VALTRAINVREF Messages ==========
        {8'hB5, 8'h0A, 5'b10010}: begin  // MBTRAIN.VALTRAINVREF start req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'hE8;
        end
        {8'hB5, 8'h0B, 5'b10010}: begin  // MBTRAIN.VALTRAINVREF done req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'hEA;
        end

      // ========== MBTRAIN.DATATRAINCENTER1 Messages ==========
        {8'hB5, 8'h0C, 5'b10010}: begin  // MBTRAIN.DATATRAINCENTER1 start req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h90;
        end
        {8'hB5, 8'h0D, 5'b10010}: begin  // MBTRAIN.DATATRAINCENTER1 end req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h92;
        end

      // ========== MBTRAIN.DATATRAINVREF Messages ==========
        {8'hB5, 8'h0E, 5'b10010}: begin  // MBTRAIN.DATATRAINVREF start req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'hF0;
        end
        {8'hB5, 8'h0F, 5'b10010}: begin  // MBTRAIN.DATATRAINVREF end req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'hF2;
        end

      // ========== MBTRAIN.RXDESKEW Messages ==========
        {8'hB5, 8'h11, 5'b10010}: begin  // MBTRAIN.RXDESKEW start req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'hA8;
        end
        {8'hB5, 8'h12, 5'b10010}: begin  // MBTRAIN.RXDESKEW end req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'hAC;
        end

      // ========== MBTRAIN.DATATRAINCENTER2 Messages ==========
        {8'hB5, 8'h13, 5'b10010}: begin  // MBTRAIN.DATATRAINCENTER2 start req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'hB0;
        end
        {8'hB5, 8'h14, 5'b10010}: begin  // MBTRAIN.DATATRAINCENTER2 end req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'hB2;
        end

      // ========== MBTRAIN.LINKSPEED Messages ==========
        {8'hB5, 8'h15, 5'b10010}: begin  // MBTRAIN.LINKSPEED start req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'hB8;
        end
        {8'hB5, 8'h16, 5'b10010}: begin  // MBTRAIN.LINKSPEED error req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'hBF;
        end
        {8'hB5, 8'h17, 5'b10010}: begin  // MBTRAIN.LINKSPEED exit to repair req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'hBD;
        end
        {8'hB5, 8'h18, 5'b10010}: begin  // MBTRAIN.LINKSPEED exit to speed degrade req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'hBB;
        end
        {8'hB5, 8'h19, 5'b10010}: begin  // MBTRAIN.LINKSPEED done req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'hBE;
        end
        {8'hB5, 8'h1F, 5'b10010}: begin  // MBTRAIN.LINKSPEED exit to phy retrain req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'hBC;
        end

      // ========== MBTRAIN.REPAIR Messages ==========
        {8'hB5, 8'h1B, 5'b10010}: begin  // MBTRAIN.REPAIR init req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'hC0;
        end
        {8'hB5, 8'h1E, 5'b10010}: begin  // MBTRAIN.REPAIR Apply degrade req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'hC3;
        end
        {8'hB5, 8'h1D, 5'b10010}: begin  // MBTRAIN.REPAIR end req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'hC4;
        end

      // ========== PHYRETRAIN Messages ==========
        {8'hC5, 8'h01, 5'b10010}: begin  // PHYRETRAIN.retrain start req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'hDA;
        end

      // ========== TRAINERROR Messages ==========
        {8'hE5, 8'h00, 5'b10010}: begin  // TRAINERROR Entry req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'hE0;
        end

      // ========== TX INIT D to C Messages ==========
        {8'h85, 8'h05, 5'b11011}: begin  // Start Tx Init D to C eye sweep req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h180;
        end
        {8'h85, 8'h02, 5'b10010}: begin  // LFSR_clear_error req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h181;
        end
        {8'h85, 8'h03, 5'b10010}: begin  // Tx Init D to C results req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h183;
        end
        {8'h85, 8'h06, 5'b10010}: begin  // End Tx Init D to C eye sweep req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h184;
        end

      // ========== RX INIT D to C Messages ==========
        {8'h8A, 8'h0A, 5'b10010}: begin  // Start Rx Init D to C eye sweep resp
          o_req         <= 1'b0;
          o_resp        <= 1'b1;
          o_decoding    <= 'h185;
        end
        {8'h85, 8'h0B, 5'b10010}: begin  // Rx Init D to C results req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h188;
        end
        {8'h81, 8'h0C, 5'b11011}: begin  //Rx Init D to C sweep done with results req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h189;
        end
        {8'h85, 8'h0D, 5'b10010}: begin  // End Rx Init D to C eye sweep req
          o_req         <= 1'b1;
          o_resp        <= 1'b0;
          o_decoding    <= 'h18A;
        end

        default: begin
          o_req         <= 1'b0;
          o_resp        <= 1'b0;
          o_decoding    <= {pDECODING_WIDTH{1'b0}};
        end
      endcase
    end
    else if (stall_flag)begin
      o_req           <= o_req;
      o_resp          <= o_resp;
      o_info_out      <= o_info_out;
      o_data_out      <= o_data_out;
      o_decoding      <= o_decoding;
      o_valid         <= o_valid;
      o_dec_ready     <= o_dec_ready;
    end
    else begin
      o_req           <= 1'b0;
      o_resp          <= 1'b0;
      o_info_out      <= {pINFO_WIDTH{1'b0}};
      o_data_out      <= {pDATA_WIDTH{1'b0}};
      o_decoding      <= {pDECODING_WIDTH{1'b0}};
      o_valid         <= 1'b0;
      o_dec_ready     <= 1'b0;
    end
    if (i_done) begin
      stall_flag      <= 1'b0; // Clear stall flag on done signal
    end
    end
  end // Decoding_proc
endmodule