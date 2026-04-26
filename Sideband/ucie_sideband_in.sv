//------------------------------------------------------------------------------
// Module: ucie_sideband_in
// Description: ...
//------------------------------------------------------------------------------
module ucie_sideband_in
#(//---- PARAMETER DECLARATIONS ------------------------------------------------
  parameter pMSG_WIDTH            = 128 // Width of messsage bus
  ,parameter pDESER_WIDTH           = 64   // Width of serialized output
  ,parameter pFIFO_WIDTH          = 128   // Width of data bus
  ,parameter pFIFO_DEPTH          = 32  // Depth of the FIFO memory

)
(//---- PORT DECLARATIONS -----------------------------------------------------
  input   wire                  i_clk
  ,input  wire                  i_800MHz_clk
  ,input  wire                  i_reset
  ,input  wire                  i_stall_traffic
  ,input wire                   i_rx_sb_data
  ,input wire                   i_rx_sb_clk
  ,output wire                  o_traffic_msg_ready
  ,output  wire [pMSG_WIDTH-1:0] o_sb_msg
);

  //---- SIGNAL DECLARATIONS ---------------------------------------------------                        
  // Traffic FIFO signals
  wire                         fifo_full;
  wire                         fifo_wr_en;
  wire  [pDESER_WIDTH-1:0]      fifo_msg_in;
  
  // FIFO SER signals
  wire                         fifo_empty;
  wire                         fifo_rd_en;
  wire  [pDESER_WIDTH-1:0]      fifo_msg_out;

  //---- MODULE INSTANTIATIONS -------------------------------------------------

  //---- FIFO TRAFFIC INSTANTIATION --------------------------------------------
  
  ucie_sideband_fifo_traffic #(
    .pMSG_WIDTH(pMSG_WIDTH),
    .pDESER_WIDTH(pDESER_WIDTH)
  ) u_fifo_traffic (
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_fifo_empty(fifo_empty),
    .i_traffic_deser_fifo(fifo_msg_out),
    .i_stall_traffic(i_stall_traffic),
    .o_traffic_ready(o_traffic_msg_ready),
    .o_sb_msg(o_sb_msg),
    .o_fifo_rd_en(fifo_rd_en)
  );

  
  ucie_sideband_fifo #(
    .pFIFO_WIDTH      (pDESER_WIDTH),
    .pFIFO_DEPTH      (32)
  )
  u_rx_deser_fifo (
    .i_clk_rd         (i_clk),
    .i_clk_wr         (i_800MHz_clk),
    .i_reset          (i_reset),
    .i_wr_en          (fifo_wr_en),
    .i_rd_en          (fifo_rd_en),
    .i_data_in        (fifo_msg_in),
    .o_data_out       (fifo_msg_out),
    .o_full           (fifo_full),
    .o_empty          (fifo_empty)
  );



  //---- DESERIALIZER INSTANTIATION ----------------------------------------------
  ucie_sideband_deser #(
    .pDESER_WIDTH(pDESER_WIDTH)
  ) u_deser (
    .i_reset(i_reset),
    .i_800MHz_clk(i_800MHz_clk),
    .i_rx_sb_data(i_rx_sb_data),
    .i_rx_sb_clk(i_rx_sb_clk),
    .i_fifo_full(fifo_full),
    .o_fifo_deser_msg(fifo_msg_in),
    .o_fifo_wr_en(fifo_wr_en)
  );




endmodule