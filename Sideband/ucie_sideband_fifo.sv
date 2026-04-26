//------------------------------------------------------------------------------
// Module: ucie_sideband_fifo
// Description: CDC-Safe Asynchronous FIFO (First-Word Fall-Through)
//------------------------------------------------------------------------------
module ucie_sideband_fifo
#(//---- PARAMETER DECLARATIONS ------------------------------------------------
  parameter  pFIFO_WIDTH      = 128,  // Width of data bus
  parameter  pFIFO_DEPTH      = 16    // Depth of the FIFO memory (Must be power of 2)
)
(//---- PORT DECLARATIONS -----------------------------------------------------
  input  wire                   i_clk_rd,
  input  wire                   i_clk_wr,
  input  wire                   i_reset,
  input  wire                   i_wr_en,
  input  wire                   i_rd_en,
  input  wire [pFIFO_WIDTH-1:0] i_data_in,
  output wire [pFIFO_WIDTH-1:0] o_data_out, 
  output reg                    o_full,
  output reg                    o_empty
);

  //---- SIGNAL DECLARATIONS ---------------------------------------------------
  localparam AW = $clog2(pFIFO_DEPTH);

  // Memory array
  reg [pFIFO_WIDTH-1:0] fifo_mem [pFIFO_DEPTH-1:0];

  // Pointers with an extra bit for full/empty wrap detection
  reg [AW:0] wr_ptr_bin, rd_ptr_bin;
  reg [AW:0] wr_ptr_gray, rd_ptr_gray;

  // 2-Stage Synchronizer registers
  reg [AW:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;
  reg [AW:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;

  // Actual memory addresses (stripping the wrap bit)
  wire [AW-1:0] wr_addr = wr_ptr_bin[AW-1:0];
  wire [AW-1:0] rd_addr = rd_ptr_bin[AW-1:0];

  // Next-state logic for pointers
  wire [AW:0] wr_ptr_bin_next  = wr_ptr_bin + (i_wr_en & ~o_full);
  wire [AW:0] wr_ptr_gray_next = wr_ptr_bin_next ^ (wr_ptr_bin_next >> 1);

  wire [AW:0] rd_ptr_bin_next  = rd_ptr_bin + (i_rd_en & ~o_empty);
  wire [AW:0] rd_ptr_gray_next = rd_ptr_bin_next ^ (rd_ptr_bin_next >> 1);


  //---- WRITE CLOCK DOMAIN (i_clk_wr) -----------------------------------------

  // Write Pointers Update
  always @(posedge i_clk_wr or posedge i_reset) begin
    if (i_reset) begin
      wr_ptr_bin  <= 0;
      wr_ptr_gray <= 0;
    end else begin
      wr_ptr_bin  <= wr_ptr_bin_next;
      wr_ptr_gray <= wr_ptr_gray_next;
    end
  end

  // Memory Write
  always @(posedge i_clk_wr) begin
    if (i_wr_en && !o_full) begin
      fifo_mem[wr_addr] <= i_data_in;
    end
  end

  // Synchronize Read Pointer into Write Domain
  always @(posedge i_clk_wr or posedge i_reset) begin
    if (i_reset) begin
      rd_ptr_gray_sync1 <= 0;
      rd_ptr_gray_sync2 <= 0;
    end else begin
      rd_ptr_gray_sync1 <= rd_ptr_gray;
      rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
    end
  end

  // Full Flag Generation
  wire full_val = (wr_ptr_gray_next == {~rd_ptr_gray_sync2[AW:AW-1], rd_ptr_gray_sync2[AW-2:0]});
  
  always @(posedge i_clk_wr or posedge i_reset) begin
    if (i_reset) o_full <= 1'b0;
    else         o_full <= full_val;
  end


  //---- READ CLOCK DOMAIN (i_clk_rd) ------------------------------------------

  // Memory Read (FWFT - Combinational)
  // Data is always available at the current read address immediately
  assign o_data_out = fifo_mem[rd_addr];

  // Read Pointers Update
  always @(posedge i_clk_rd or posedge i_reset) begin
    if (i_reset) begin
      rd_ptr_bin  <= 0;
      rd_ptr_gray <= 0;
    end else begin
      rd_ptr_bin  <= rd_ptr_bin_next;
      rd_ptr_gray <= rd_ptr_gray_next;
    end
  end

  // Synchronize Write Pointer into Read Domain
  always @(posedge i_clk_rd or posedge i_reset) begin
    if (i_reset) begin
      wr_ptr_gray_sync1 <= 0;
      wr_ptr_gray_sync2 <= 0;
    end else begin
      wr_ptr_gray_sync1 <= wr_ptr_gray;
      wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
    end
  end

  // Empty Flag Generation (Read Gray == Sync Write Gray)
  wire empty_val = (rd_ptr_gray_next == wr_ptr_gray_sync2);
  
  always @(posedge i_clk_rd or posedge i_reset) begin
    if (i_reset) o_empty <= 1'b1; // Default to empty on reset
    else         o_empty <= empty_val;
  end

endmodule