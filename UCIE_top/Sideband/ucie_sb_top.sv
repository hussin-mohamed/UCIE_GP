//------------------------------------------------------------------------------
// Module: ucie_sb_top
// Description: ...
//------------------------------------------------------------------------------
module ucie_sb_top
#(//---- PARAMETER DECLARATIONS ------------------------------------------------
  parameter pMSG_WIDTH            = 128 // Width of messsage bus
  ,parameter pDESER_WIDTH         = 64   // Width of deserialized output
  ,parameter pSER_WIDTH           = 64   // Width of serialized output
  ,parameter pFIFO_WIDTH          = 128   // Width of data bus
  ,parameter pFIFO_DEPTH          = 32  // Depth of the FIFO memory
  ,parameter pENCODING_WIDTH      = 9   // Width of Encoding field
  ,parameter pDECODING_WIDTH      = 9   // Width of Decoding field
  ,parameter pDATA_WIDTH          = 64  // Width of data bus
  ,parameter pINFO_WIDTH          = 16  // Width of info field
  ,parameter pMSG_CODE_WIDTH      = 8   // Width of message code field
  ,parameter pMSG_SUBCODE_WIDTH   = 8   // Width of message subcode field
  ,parameter pOP_CODE_WIDTH       = 5   // Width of operation code field
  ,parameter pRESERVED            = 1'b0   // Reserved bits

)
(//---- PORT DECLARATIONS -----------------------------------------------------
  input   wire                  i_clk
  ,input  wire                  i_reset
  ,input   wire                 i_800MHz_clk

  ,input  wire                  i_tx_sb_req
  ,input  wire                  i_tx_sb_rsp
  ,input  wire                  i_tx_sb_done
  ,input  wire [pDATA_WIDTH-1:0] i_tx_data
  ,input  wire [pENCODING_WIDTH-1:0] i_tx_encoding
  ,input  wire [pINFO_WIDTH-1:0] i_tx_info

  ,input  wire                  i_rx_sb_req
  ,input  wire                  i_rx_sb_rsp
  ,input  wire                  i_rx_sb_done
  ,input  wire [pDATA_WIDTH-1:0] i_rx_data
  ,input  wire [pENCODING_WIDTH-1:0] i_rx_encoding
  ,input  wire [pINFO_WIDTH-1:0] i_rx_info

  ,input  wire                  i_sb_init_start
  ,input  wire                  i_timer_1ms
  ,input  wire                  i_rx_sb_clk
  ,input  wire                  i_rx_sb_data

  ,output wire                  o_sb_tx_req
  ,output wire                  o_sb_tx_rsp
  ,output wire                  o_sb_tx_done
  ,output wire  [pDATA_WIDTH-1:0] o_tx_data
  ,output wire  [pDECODING_WIDTH-1:0] o_tx_decoding
  ,output wire  [pINFO_WIDTH-1:0] o_tx_info
  ,output wire                  o_tx_valid

  ,output wire                  o_sb_rx_req
  ,output wire                  o_sb_rx_rsp
  ,output wire                  o_sb_rx_done
  ,output wire  [pDATA_WIDTH-1:0] o_rx_data
  ,output wire  [pDECODING_WIDTH-1:0] o_rx_decoding
  ,output wire  [pINFO_WIDTH-1:0] o_rx_info
  ,output wire                  o_rx_valid

  ,output wire                  o_sb_ready
  ,output wire                  o_tx_sb_data
  ,output wire                  o_tx_sb_clk
  ,output wire                  o_sb_cur_msg_done
);

  //---- SIGNAL DECLARATIONS ---------------------------------------------------                        
  // Traffic FIFO signals
  wire                         sb_tx_clk;
  wire                         sb_tx_data;
  wire                         sb_init_tx_clk;
  wire                         sb_init_tx_data;
  wire                         sb_rx_clk;
  wire                         sb_rx_data;
  wire                         sb_init_rx_clk;
  wire                         sb_init_rx_data;
  
  wire                         rx_init_done;

  wire                         stall_traffic_tx;
  wire                         stall_traffic_rx;
  wire       [pMSG_WIDTH-1:0]  msg_tx;
  wire                         msg_ready_tx;
  wire                         msg_ready_rx;
  wire       [pMSG_WIDTH-1:0]  msg_rx;

  wire                         tx_traffic_fifo_rd_en;
  wire                         traffic_tx_fifo_wr_en;
  wire       [pMSG_WIDTH-1:0]  traffic_tx_fifo_msg;
  wire       [pMSG_WIDTH-1:0]  tx_traffic_fifo_msg;
  wire                         tx_traffic_fifo_empty;
  wire                         traffic_tx_fifo_full;

  wire                         rx_traffic_fifo_rd_en;
  wire                         traffic_rx_fifo_wr_en;
  wire       [pMSG_WIDTH-1:0]  traffic_rx_fifo_msg;
  wire                         rx_traffic_fifo_empty;
  wire       [pMSG_WIDTH-1:0]  rx_traffic_fifo_msg;
  wire                         traffic_rx_fifo_full;

  //---- MODULE INSTANTIATIONS -------------------------------------------------


    ucie_sb_tx_path u_sb_tx_init (
    .i_clk(i_clk),
    .i_s_clk(i_800MHz_clk),
    .i_reset(i_reset),
    .i_sb_init_start(i_sb_init_start),
    .i_timer_1ms(i_timer_1ms),
    .i_rx_done(rx_init_done),
    .o_tx_sb_data(sb_init_tx_data),
    .o_tx_sb_clk(sb_init_tx_clk),
    .o_stop(o_sb_ready)
    );

    ucie_sideband_mux u_sb_tx_clk_mux (
    .i_a(sb_init_tx_clk),
    .i_b(sb_tx_clk),
    .i_sel(i_sb_init_start),
    .o_c(o_tx_sb_clk)
    );

    ucie_sideband_mux u_sb_tx_data_mux (
    .i_a(sb_init_tx_data),
    .i_b(sb_tx_data),
    .i_sel(i_sb_init_start),
    .o_c(o_tx_sb_data)
    );

    ucie_sb_rx_path u_sb_rx_init (
    .i_rx_sb_clk(sb_init_rx_clk),
    .i_reset(i_reset),
    .i_sb_init_start(i_sb_init_start),
    .i_rx_sb_data(sb_init_rx_data),
    .o_done(rx_init_done)
    );

    ucie_sideband_demux u_sb_rx_clk_demux (
    .i_a(i_rx_sb_clk),
    .i_sel(i_sb_init_start),
    .o_b(sb_init_rx_clk),
    .o_c(sb_rx_clk)
    );

    ucie_sideband_demux u_sb_rx_data_demux (
    .i_a(i_rx_sb_data),
    .i_sel(i_sb_init_start),
    .o_b(sb_init_rx_data),
    .o_c(sb_rx_data)
    );

    ucie_sideband_out #(
    .pMSG_WIDTH(pMSG_WIDTH),
    .pSER_WIDTH(pDESER_WIDTH),
    .pFIFO_WIDTH(pFIFO_WIDTH),
    .pFIFO_DEPTH(pFIFO_DEPTH))
    u_sideband_out (
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_800MHz_clk(i_800MHz_clk),
    .i_traffic_msg_ready(msg_ready_tx),
    .i_sb_msg(msg_tx),
    .i_enable(!i_sb_init_start),
    .o_tx_sb_data(sb_tx_data),
    .o_tx_sb_clk(sb_tx_clk),
    .o_stall_traffic(stall_traffic_tx),
    .o_sb_cur_msg_done(o_sb_cur_msg_done)
  );
  
   ucie_sideband_in #(
    .pMSG_WIDTH(pMSG_WIDTH),
    .pDESER_WIDTH(pDESER_WIDTH),
    .pFIFO_WIDTH(pFIFO_WIDTH),
    .pFIFO_DEPTH(pFIFO_DEPTH)
  ) u_sideband_in (
    .i_clk(i_clk),
    .i_800MHz_clk(i_800MHz_clk),
    .i_reset(i_reset),
    .i_stall_traffic(stall_traffic_rx),
    .i_rx_sb_data(sb_rx_data),
    .i_rx_sb_clk(sb_rx_clk),
    .o_traffic_msg_ready(msg_ready_rx),
    .o_sb_msg(msg_rx)
  );

  ucie_sb_traffic #(
    .pMSG_WIDTH(pMSG_WIDTH)
  ) u_sb_traffic (
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_tx_traffic_fifo_msg(tx_traffic_fifo_msg),
    .i_tx_traffic_fifo_empty(tx_traffic_fifo_empty),
    .i_traffic_tx_fifo_full(traffic_tx_fifo_full),
    .i_rx_traffic_fifo_empty(rx_traffic_fifo_empty),
    .i_rx_traffic_fifo_msg(rx_traffic_fifo_msg),
    .i_traffic_rx_fifo_full(traffic_rx_fifo_full),
    .i_sb_msg_in(msg_rx),
    .i_stall_traffic(stall_traffic_tx),
    .i_traffic_msg_ready(msg_ready_rx),
    .o_sb_msg_out(msg_tx), 
    .o_tx_traffic_fifo_rd_en(tx_traffic_fifo_rd_en),
    .o_traffic_tx_fifo_wr_en(traffic_tx_fifo_wr_en),
    .o_rx_traffic_fifo_rd_en(rx_traffic_fifo_rd_en),
    .o_traffic_rx_fifo_wr_en(traffic_rx_fifo_wr_en),
    .o_traffic_tx_fifo_msg(traffic_tx_fifo_msg),
    .o_traffic_rx_fifo_msg(traffic_rx_fifo_msg),
    .o_msg_ready(msg_ready_tx),
    .o_stall_traffic(stall_traffic_rx) 
  );


ucie_sideband_tx_msg #(
  .pENCODING_WIDTH(pENCODING_WIDTH),
  .pDECODING_WIDTH(pDECODING_WIDTH),
  .pDATA_WIDTH(pDATA_WIDTH),
  .pINFO_WIDTH(pINFO_WIDTH),
  .pMSG_CODE_WIDTH(pMSG_CODE_WIDTH),
  .pMSG_SUBCODE_WIDTH(pMSG_SUBCODE_WIDTH),
  .pOP_CODE_WIDTH(pOP_CODE_WIDTH),
  .pRESERVED(pRESERVED),
  .pMSG_WIDTH(pMSG_WIDTH)
) u_tx_msg (
  .i_clk(i_clk),
  .i_reset(i_reset),
  .i_tx_sb_req(i_tx_sb_req),
  .i_tx_sb_rsp(i_tx_sb_rsp),
  .i_tx_sb_done(i_tx_sb_done),
  .i_tx_data(i_tx_data),
  .i_tx_encoding(i_tx_encoding),
  .i_tx_info(i_tx_info),
  .i_traffic_tx_fifo_msg_in(traffic_tx_fifo_msg),
  .i_tx_traffic_fifo_rd_en(tx_traffic_fifo_rd_en),
  .i_traffic_tx_fifo_wr_en(traffic_tx_fifo_wr_en),
  .o_sb_tx_req(o_sb_tx_req),
  .o_sb_tx_rsp(o_sb_tx_rsp),
  .o_sb_tx_done(o_sb_tx_done),
  .o_tx_data(o_tx_data),
  .o_tx_decoding(o_tx_decoding),
  .o_tx_info(o_tx_info),
  .o_tx_valid(o_tx_valid),
  .o_tx_traffic_fifo_empty(tx_traffic_fifo_empty),
  .o_traffic_tx_fifo_full(traffic_tx_fifo_full),
  .o_tx_traffic_fifo_msg_out(tx_traffic_fifo_msg)
);

ucie_sideband_rx_msg #(
  .pENCODING_WIDTH(pENCODING_WIDTH),
  .pDECODING_WIDTH(pDECODING_WIDTH),
  .pDATA_WIDTH(pDATA_WIDTH),
  .pINFO_WIDTH(pINFO_WIDTH),
  .pMSG_CODE_WIDTH(pMSG_CODE_WIDTH),
  .pMSG_SUBCODE_WIDTH(pMSG_SUBCODE_WIDTH),
  .pOP_CODE_WIDTH(pOP_CODE_WIDTH),
  .pRESERVED(pRESERVED),
  .pMSG_WIDTH(pMSG_WIDTH)
) u_rx_msg (
  .i_clk(i_clk),
  .i_reset(i_reset),
  .i_rx_sb_req(i_rx_sb_req),
  .i_rx_sb_rsp(i_rx_sb_rsp),
  .i_rx_sb_done(i_rx_sb_done),
  .i_rx_data(i_rx_data),
  .i_rx_encoding(i_rx_encoding),
  .i_rx_info(i_rx_info),
  .i_traffic_rx_fifo_msg_in(traffic_rx_fifo_msg),
  .i_rx_traffic_fifo_rd_en(rx_traffic_fifo_rd_en),
  .i_traffic_rx_fifo_wr_en(traffic_rx_fifo_wr_en),
  .o_sb_rx_req(o_sb_rx_req),
  .o_sb_rx_rsp(o_sb_rx_rsp),
  .o_sb_rx_done(o_sb_rx_done),
  .o_rx_data(o_rx_data),
  .o_rx_decoding(o_rx_decoding),
  .o_rx_info(o_rx_info),
  .o_rx_valid(o_rx_valid),
  .o_rx_traffic_fifo_empty(rx_traffic_fifo_empty),
  .o_traffic_rx_fifo_full(traffic_rx_fifo_full),
  .o_rx_traffic_fifo_msg_out(rx_traffic_fifo_msg)
);


endmodule