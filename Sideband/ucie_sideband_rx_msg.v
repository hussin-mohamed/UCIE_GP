//------------------------------------------------------------------------------
// Module: ucie_sideband_rx_msg
// Description: ...
//------------------------------------------------------------------------------
module ucie_sideband_rx_msg
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
  ,input  wire                  i_rx_sb_req
  ,input  wire                  i_rx_sb_rsp
  ,input  wire                  i_rx_sb_done
  ,input  wire [pDATA_WIDTH-1:0] i_rx_data
  ,input  wire [pENCODING_WIDTH-1:0] i_rx_encoding
  ,input  wire [pINFO_WIDTH-1:0] i_rx_info
  ,input  wire [pMSG_WIDTH-1:0] i_traffic_rx_fifo_msg_in
  ,input  wire                  i_rx_traffic_fifo_rd_en
  ,input  wire                  i_traffic_rx_fifo_wr_en
  ,output wire                  o_sb_rx_req
  ,output wire                  o_sb_rx_rsp
  ,output wire                  o_sb_rx_done
  ,output wire  [pDATA_WIDTH-1:0] o_rx_data
  ,output wire  [pDECODING_WIDTH-1:0] o_rx_decoding
  ,output wire  [pINFO_WIDTH-1:0] o_rx_info
  ,output wire                  o_rx_valid
  ,output wire                  o_rx_traffic_fifo_empty
  ,output wire                  o_traffic_rx_fifo_full
  ,output wire [pMSG_WIDTH-1:0] o_rx_traffic_fifo_msg_out
);

  //---- SIGNAL DECLARATIONS ---------------------------------------------------
  
  // rx Traffic FIFO signals
  wire                         rx_traffic_fifo_full;
  wire                         rx_traffic_fifo_wr_en;
  wire  [pMSG_WIDTH-1:0]       rx_traffic_fifo_msg;
  
  // Traffic rx FIFO signals
  wire                         traffic_rx_fifo_empty;
  wire                         traffic_rx_fifo_rd_en;
  wire  [pMSG_WIDTH-1:0]       traffic_rx_fifo_msg;

  //---- MODULE INSTANTIATIONS -------------------------------------------------

  // ========== rx Traffic FIFO Instance ==========
  // FIFO for storing rx encoded messages to be transmitted
  ucie_sideband_fifo
  #(
    .pFIFO_WIDTH      (pMSG_WIDTH),
    .pFIFO_DEPTH      (32)
  )
  u_rx_traffic_fifo (
    .i_clk            (i_clk),
    .i_reset          (i_reset),
    .i_wr_en          (rx_traffic_fifo_wr_en),
    .i_rd_en          (i_rx_traffic_fifo_rd_en),
    .i_data_in        (rx_traffic_fifo_msg),
    .o_data_out       (o_rx_traffic_fifo_msg_out),
    .o_full           (rx_traffic_fifo_full),
    .o_empty          (o_rx_traffic_fifo_empty)
  );

  // ========== Traffic rx FIFO Instance ==========
  // FIFO for storing received rx messages (responses from RX)
  ucie_sideband_fifo
  #(
    .pFIFO_WIDTH      (pMSG_WIDTH),
    .pFIFO_DEPTH      (32)
  )
  u_traffic_rx_fifo (
    .i_clk            (i_clk),
    .i_reset          (i_reset),
    .i_wr_en          (i_traffic_rx_fifo_wr_en),
    .i_rd_en          (traffic_rx_fifo_rd_en),
    .i_data_in        (i_traffic_rx_fifo_msg_in),
    .o_data_out       (traffic_rx_fifo_msg),
    .o_full           (o_traffic_rx_fifo_full),
    .o_empty          (traffic_rx_fifo_empty)
  );


  // ========== rx Message Encoder/Decoder Instance ==========
  // Handles encoding of rx requests and decoding of RX responses
  ucie_sideband_rx_msg_enc_dec
  #(
    .pENCODING_WIDTH      (pENCODING_WIDTH),
    .pDECODING_WIDTH      (pDECODING_WIDTH),
    .pDATA_WIDTH          (pDATA_WIDTH),
    .pINFO_WIDTH          (pINFO_WIDTH),
    .pMSG_CODE_WIDTH      (pMSG_CODE_WIDTH),
    .pMSG_SUBCODE_WIDTH   (pMSG_SUBCODE_WIDTH),
    .pOP_CODE_WIDTH       (pOP_CODE_WIDTH),
    .pRESERVED            (pRESERVED),
    .pMSG_WIDTH           (pMSG_WIDTH)
  )
  u_rx_msg_enc_dec (
    .i_clk                (i_clk),
    .i_reset              (i_reset),
    .i_req                (i_rx_sb_req),
    .i_resp               (i_rx_sb_rsp),
    .i_done               (i_rx_sb_done),
    .i_data_in            (i_rx_data),
    .i_encoding           (i_rx_encoding),
    .i_info_in            (i_rx_info),
    .i_msg_in             (traffic_rx_fifo_msg),
    .i_full               (rx_traffic_fifo_full),
    .i_empty              (traffic_rx_fifo_empty),
    .o_req                (o_sb_rx_req),
    .o_resp               (o_sb_rx_rsp),
    .o_done               (o_sb_rx_done),
    .o_data_out           (o_rx_data),
    .o_decoding           (o_rx_decoding),
    .o_info_out           (o_rx_info),
    .o_msg_out            (rx_traffic_fifo_msg),
    .o_enc_ready          (rx_traffic_fifo_wr_en),
    .o_dec_ready          (traffic_rx_fifo_rd_en),
    .o_valid              (o_rx_valid)
  );

endmodule