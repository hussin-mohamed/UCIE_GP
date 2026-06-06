//------------------------------------------------------------------------------
// Module: ucie_sideband_fifo
// Description: Asynchronous FIFO
//------------------------------------------------------------------------------
module ucie_sideband_fifo_FWFT
#(//---- PARAMETER DECLARATIONS ------------------------------------------------
  parameter  pFIFO_WIDTH      = 128   // Width of data bus
  ,parameter pFIFO_DEPTH      = 16  // Depth of the FIFO memory
)
(//---- PORT DECLARATIONS -----------------------------------------------------
  input  wire                   i_clk_rd
  ,input  wire                   i_clk_wr
  ,input  wire                  i_reset
  ,input  wire                  i_wr_en
  ,input  wire                  i_rd_en
  ,input  wire [pFIFO_WIDTH-1:0] i_data_in
  ,output wire  [pFIFO_WIDTH-1:0] o_data_out
  ,output wire                  o_full
  ,output wire                  o_empty
);

  //---- SIGNAL DECLARATIONS ---------------------------------------------------
  localparam lp_max_fifo_addr = $clog2(pFIFO_DEPTH);

  reg  [pFIFO_WIDTH-1:0]    fifo_mem [pFIFO_DEPTH-1:0];
  reg  [lp_max_fifo_addr-1:0] wr_ptr;
  reg  [lp_max_fifo_addr-1:0] rd_ptr;
  reg  [lp_max_fifo_addr:0]   wr_count;
  reg  [lp_max_fifo_addr:0]   rd_count;
  wire [lp_max_fifo_addr:0]   count;

  //---- SEQUENTIAL PROCESSES --------------------------------------------------

  // Write Pointer Process
  always @(posedge i_clk_wr or posedge i_reset) 
  begin: wr_ptr_proc
    if (i_reset) 
    begin
      wr_ptr <= {lp_max_fifo_addr{1'b0}};
    end 
    else if (i_wr_en && !o_full) 
    begin
      fifo_mem[wr_ptr] <= i_data_in;
      wr_ptr           <= wr_ptr + 1'b1;
    end
  end // wr_ptr_proc

  // Read Pointer Process
  always @(posedge i_clk_rd or posedge i_reset) 
  begin: rd_ptr_proc
    if (i_reset) 
    begin
      rd_ptr <= {lp_max_fifo_addr{1'b0}};
    end 
    else if (i_rd_en && !o_empty) 
    begin
      rd_ptr     <= rd_ptr + 1'b1;
    end
  end // rd_ptr_proc

  // Write Counter Process
  always @(posedge i_clk_wr or posedge i_reset) 
  begin: wr_count_proc
    if (i_reset) 
    begin
      wr_count <= {(lp_max_fifo_addr+1){1'b0}};
    end 
    else 
    begin
      if (i_wr_en && !o_full)
        wr_count <= wr_count + 1'b1;
      else
        wr_count <= wr_count;
    end
  end // wr_count_proc

  // Read Counter Process
  always @(posedge i_clk_rd or posedge i_reset) 
  begin: rd_count_proc
    if (i_reset) 
    begin
      rd_count <= {(lp_max_fifo_addr+1){1'b0}};
    end 
    else 
    begin
      if (i_rd_en && !o_empty)
        rd_count <= rd_count + 1'b1;
      else
        rd_count <= rd_count;
    end
  end // rd_count_proc

  //---- COMBINATIONAL LOGIC ---------------------------------------------------
  assign o_data_out = fifo_mem[rd_ptr];
  assign count   = wr_count - rd_count;
  assign o_full  = (count == pFIFO_DEPTH) ? 1'b1 : 1'b0;
  assign o_empty = (count == 0)           ? 1'b1 : 1'b0;

endmodule