//------------------------------------------------------------------------------
// Module: ucie_sideband_tx_msg
// Description: ...
//------------------------------------------------------------------------------
module ucie_sideband_tx_msg
#(//---- PARAMETER DECLARATIONS ------------------------------------------------
  parameter  pENCODING_WIDTH      = 9   // Width of Encoding field
  ,parameter pDECODING_WIDTH      = 9   // Width of Decoding field
  ,parameter pDATA_WIDTH          = 64  // Width of data bus
  ,parameter pINFO_WIDTH          = 16  // Width of info field
  ,parameter pMSG_CODE_WIDTH      = 8   // Width of message code field
  ,parameter pMSG_SUBCODE_WIDTH   = 8   // Width of message subcode field
  ,parameter pOP_CODE_WIDTH       = 5   // Width of operation code field
  ,parameter pRESERVED            = 1'b0   // Reserved bits
  ,parameter pMSG_WIDTH           = 128 // Width of messsage bus
)
(//---- PORT DECLARATIONS -----------------------------------------------------
  input  wire                   i_clk
  ,input  wire                  i_reset
  ,input  wire                  i_tx_sb_req
  ,input  wire                  i_tx_sb_rsp
  ,input  wire                  i_tx_sb_done
  ,input  wire [pDATA_WIDTH-1:0] i_tx_data
  ,input  wire [pENCODING_WIDTH-1:0] i_tx_encoding
  ,input  wire [pINFO_WIDTH-1:0] i_tx_info
  ,input  wire [pMSG_WIDTH-1:0] i_traffic_tx_fifo_msg_in
  ,input  wire                  i_tx_traffic_fifo_rd_en
  ,input  wire                  i_traffic_tx_fifo_wr_en
  ,output wire                  o_sb_tx_req
  ,output wire                  o_sb_tx_rsp
  ,output reg                  o_sb_tx_done
  ,output wire  [pDATA_WIDTH-1:0] o_tx_data
  ,output wire  [pDECODING_WIDTH-1:0] o_tx_decoding
  ,output wire  [pINFO_WIDTH-1:0] o_tx_info
  ,output wire                  o_tx_valid
  ,output wire                  o_tx_traffic_fifo_empty
  ,output wire                  o_traffic_tx_fifo_full
  ,output wire [pMSG_WIDTH-1:0] o_tx_traffic_fifo_msg_out
);

  //---- SIGNAL DECLARATIONS ---------------------------------------------------
  
  // TX Traffic FIFO signals
  wire                         tx_traffic_fifo_full;
  wire                         tx_traffic_fifo_wr_en;
  wire  [pMSG_WIDTH-1:0]       tx_traffic_fifo_msg;
  
  // Traffic TX FIFO signals
  wire                         traffic_tx_fifo_empty;
  wire                         traffic_tx_fifo_rd_en;
  wire  [pMSG_WIDTH-1:0]       traffic_tx_fifo_msg;

  // Toggle sync signals
  wire                         tx_in_req;
  wire                         tx_in_rsp;

  //---- MODULE INSTANTIATIONS -------------------------------------------------

  // ========== TX Traffic FIFO Instance ==========
  // FIFO for storing TX encoded messages to be transmitted
  ucie_sideband_fifo_FWFT
  #(
    .pFIFO_WIDTH      (pMSG_WIDTH),
    .pFIFO_DEPTH      (32)
  )
  u_tx_traffic_fifo (
    .i_clk_rd            (i_clk),
    .i_clk_wr            (i_clk),
    .i_reset          (i_reset),
    .i_wr_en          (tx_traffic_fifo_wr_en),
    .i_rd_en          (i_tx_traffic_fifo_rd_en),
    .i_data_in        (tx_traffic_fifo_msg),
    .o_data_out       (o_tx_traffic_fifo_msg_out),
    .o_full           (tx_traffic_fifo_full),
    .o_empty          (o_tx_traffic_fifo_empty)
  );

  // ========== Traffic TX FIFO Instance ==========
  // FIFO for storing received TX messages (responses from RX)
  ucie_sideband_fifo_FWFT
  #(
    .pFIFO_WIDTH      (pMSG_WIDTH),
    .pFIFO_DEPTH      (32)
  )
  u_traffic_tx_fifo (
    .i_clk_rd         (i_clk),
    .i_clk_wr         (i_clk),
    .i_reset          (i_reset),
    .i_wr_en          (i_traffic_tx_fifo_wr_en),
    .i_rd_en          (traffic_tx_fifo_rd_en),
    .i_data_in        (i_traffic_tx_fifo_msg_in),
    .o_data_out       (traffic_tx_fifo_msg),
    .o_full           (o_traffic_tx_fifo_full),
    .o_empty          (traffic_tx_fifo_empty)
  );


  // ========== TX Message Encoder/Decoder Instance ==========
  // Handles encoding of TX requests and decoding of RX responses
  ucie_sideband_tx_msg_enc_dec
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
  u_tx_msg_enc_dec (
    .i_clk                (i_clk),
    .i_reset              (i_reset),
    .i_req                (tx_in_req),
    .i_resp               (tx_in_rsp),
    .i_done               (i_tx_sb_done),
    .i_data_in            (i_tx_data),
    .i_encoding           (i_tx_encoding),
    .i_info_in            (i_tx_info),
    .i_msg_in             (traffic_tx_fifo_msg),
    .i_full               (tx_traffic_fifo_full),
    .i_empty              (traffic_tx_fifo_empty),
    .o_req                (o_sb_tx_req),
    .o_resp               (o_sb_tx_rsp),
    .o_data_out           (o_tx_data),
    .o_decoding           (o_tx_decoding),
    .o_info_out           (o_tx_info),
    .o_msg_out            (tx_traffic_fifo_msg),
    .o_enc_ready          (tx_traffic_fifo_wr_en),
    .o_dec_ready          (traffic_tx_fifo_rd_en),
    .o_valid              (o_tx_valid)
  );

  toggle_sync u_toggle_sync_req (
    .i_clk                (i_clk),
    .i_reset              (i_reset),
    .i_cnt                (i_tx_sb_req),
    .o_cnt                (tx_in_req)
  );

  toggle_sync u_toggle_sync_rsp (
    .i_clk                (i_clk),
    .i_reset              (i_reset),
    .i_cnt                (i_tx_sb_rsp),
    .o_cnt                (tx_in_rsp)
  );

  always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset)
      o_sb_tx_done <= 1'b0;
    else if ( i_tx_sb_req || i_tx_sb_rsp)
      o_sb_tx_done <= 1'b1;
    else 
      o_sb_tx_done <= 1'b0;
  end

endmodule