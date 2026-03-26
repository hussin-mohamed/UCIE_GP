//------------------------------------------------------------------------------
// Module: ucie_sideband_out
// Description: ...
//------------------------------------------------------------------------------
module ucie_sideband_out
#(//---- PARAMETER DECLARATIONS ------------------------------------------------
  parameter pMSG_WIDTH            = 128 // Width of messsage bus
  ,parameter pSER_WIDTH           = 64   // Width of serialized output
  ,parameter pFIFO_WIDTH          = 128   // Width of data bus
  ,parameter pFIFO_DEPTH          = 32  // Depth of the FIFO memory

)
(//---- PORT DECLARATIONS -----------------------------------------------------
  input   wire                  i_clk
  ,input  wire                 i_800MHz_clk
  ,input  wire                  i_reset
  ,input  wire                  i_traffic_msg_ready
  ,input  wire [pMSG_WIDTH-1:0] i_sb_msg
  ,input  wire                  i_enable
  
  ,output wire                  o_tx_sb_data
  ,output wire                  o_tx_sb_clk
  ,output wire                  o_stall_traffic
  ,output wire                  o_sb_cur_msg_done
);

  //---- SIGNAL DECLARATIONS ---------------------------------------------------                        
  // Traffic FIFO signals
  wire                         fifo_full;
  wire                         fifo_wr_en;
  wire  [pSER_WIDTH-1:0]       fifo_msg_in;
  
  // FIFO SER signals
  wire                         fifo_empty;
  wire                         fifo_rd_en;
  wire  [pSER_WIDTH-1:0]       fifo_msg_out;

  //---- MODULE INSTANTIATIONS -------------------------------------------------

  //---- TRAFFIC FIFO INSTANTIATION --------------------------------------------
  ucie_sideband_traffic_fifo #(
    .pMSG_WIDTH(pMSG_WIDTH),
    .pSER_WIDTH(pSER_WIDTH)
  ) u_traffic_fifo (
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_sb_msg(i_sb_msg),
    .i_fifo_full(fifo_full),
    .i_traffic_ready(i_traffic_msg_ready),
    .o_stall_traffic(o_stall_traffic),
    .o_fifo_wr_en(fifo_wr_en),
    .o_traffic_ser_fifo(fifo_msg_in)
  );

  // ========== fifo Instance ==========
  ucie_sideband_fifo_FWFT
  #(
    .pFIFO_WIDTH      (pSER_WIDTH),
    .pFIFO_DEPTH      (32)
  )
  u_tx_ser_fifo (
    .i_clk_rd         (i_800MHz_clk),
    .i_clk_wr         (i_clk),
    .i_reset          (i_reset),
    .i_wr_en          (fifo_wr_en),
    .i_rd_en          (fifo_rd_en),
    .i_data_in        (fifo_msg_in),
    .o_data_out       (fifo_msg_out),
    .o_full           (fifo_full),
    .o_empty          (fifo_empty)
  );

  //---- SERIALIZER INSTANTIATION ----------------------------------------------
  ucie_sideband_ser #(
    .pSER_WIDTH(pSER_WIDTH)
  ) u_ser (
    .i_clk(i_800MHz_clk),
    .i_reset(i_reset),
    .i_fifo_ser_msg(fifo_msg_out),
    .i_fifo_empty(fifo_empty),
    .i_enable(i_enable),
    .o_tx_sb_data(o_tx_sb_data),
    .o_tx_sb_clk(o_tx_sb_clk),
    .o_fifo_rd_en(fifo_rd_en),
    .o_sb_cur_msg_done(o_sb_cur_msg_done)
  );




endmodule