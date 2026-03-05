//------------------------------------------------------------------------------
// Module: ucie_sideband_ser
// Description: Fixed-frame serializer: 32-cycle low after reset, then 64-bit tx then 32-cycle low, continuous
//------------------------------------------------------------------------------
module ucie_sideband_ser
#(
  parameter pSER_WIDTH = 64
)
(
  input  wire                   i_clk,
  input  wire                   i_reset,
  input  wire [pSER_WIDTH-1:0]  i_fifo_ser_msg,
  input  wire                   i_fifo_empty,
  output wire                   o_tx_sb_data,
  output wire                   o_tx_sb_clk,
  output wire                   o_fifo_rd_en
);

  //---- SIGNAL DECLARATIONS ---------------------------------------------------
  reg  [pSER_WIDTH-1:0] shift_reg;
  reg  [5:0]            bit_counter;   // 0-63 tx / 0-31 low (resets each phase)
  reg                   transmitting;
  reg                   low;
  reg                   clk_en_latch;

  wire flag_31 = (bit_counter == 6'd31);  // last low cycle
  wire flag_63 = (bit_counter == 6'd63);  // last tx bit

  //---- COUNTER ---------------------------------------------------------------
  always @(posedge i_clk or posedge i_reset)
  begin : counter_proc
    if (i_reset)
      bit_counter <= 6'd0;
    else if (transmitting || low) begin
      if ((transmitting && flag_63) || (low && flag_31))
        bit_counter <= 6'd0;
      else
        bit_counter <= bit_counter + 6'd1;
    end
    else
      bit_counter <= 6'd0;
  end

  //---- STATE -----------------------------------------------------------------
  always @(posedge i_clk or posedge i_reset)
  begin : state_proc
    if (i_reset) begin
      transmitting <= 1'b0;
      low          <= 1'b1;
    end
    else begin
      if (low && flag_31) begin
        transmitting <= 1'b1;
        low          <= 1'b0;
      end
      else if (transmitting && flag_63) begin
        transmitting <= 1'b0;
        low          <= 1'b1;
      end
    end
  end

  //---- SHIFT REGISTER --------------------------------------------------------
  always @(posedge i_clk or posedge i_reset)
  begin : shift_proc
    if (i_reset) begin
      shift_reg <= {pSER_WIDTH{1'b0}};
    end
    else begin
      if (low && flag_31)
        shift_reg <= i_fifo_empty ? {pSER_WIDTH{1'b0}} : i_fifo_ser_msg;
      else if (transmitting)
        shift_reg <= {1'b0, shift_reg[63:1]};
    end
  end

  //---- OUTPUTS ---------------------------------------------------------------
  assign o_fifo_rd_en = (!i_fifo_empty && low && flag_31) ? 1'b1 : 1'b0;
  assign o_tx_sb_data = transmitting ? shift_reg[0] : 1'b0;
  assign o_tx_sb_clk  = clk_en_latch & i_clk;

  always @(*) begin
    if (i_reset)
      clk_en_latch = 1'b0;
    else if (!i_clk)
      clk_en_latch = transmitting;
  end

endmodule