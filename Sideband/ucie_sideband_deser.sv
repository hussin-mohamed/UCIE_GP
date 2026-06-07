//------------------------------------------------------------------------------
// Module: ucie_sideband_deser
// Description: Deserializes 64-bit messages and uses a toggle synchronizer 
//              to safely generate a single 800MHz FIFO write pulse.
//------------------------------------------------------------------------------
module ucie_sideband_deser #(
  parameter pDESER_WIDTH = 64
)(
  input  wire                    i_rx_sb_clk,
  input  wire                    i_800MHz_clk,
  input  wire                    i_reset,
  input  wire                    i_rx_sb_data,
  input  wire                    i_fifo_full,
  output reg  [pDESER_WIDTH-1:0] o_fifo_deser_msg,
  output wire                    o_fifo_wr_en
);

  //---- SIGNAL DECLARATIONS ---------------------------------------------------
  reg [pDESER_WIDTH-1:0] shift_reg;
  reg [5:0]              bit_counter;
  reg                    data_rdy_toggle;
  
  reg                    sync1_800mhz;
  reg                    sync2_800mhz;
  reg                    sync3_800mhz;

  //---- RX CLOCK DOMAIN (Strictly Input Clock Logic) --------------------------
  always @(negedge i_rx_sb_clk or posedge i_reset) begin
    if (i_reset) begin
      shift_reg         <= {pDESER_WIDTH{1'b0}};
      bit_counter       <= 6'd0;
      o_fifo_deser_msg  <= {pDESER_WIDTH{1'b0}};
      data_rdy_toggle   <= 1'b0;
    end 
    else begin
      shift_reg <= {i_rx_sb_data, shift_reg[pDESER_WIDTH-1:1]}; 

      if (bit_counter == 6'd63) begin
        bit_counter      <= 6'd0;
        o_fifo_deser_msg <= {i_rx_sb_data, shift_reg[pDESER_WIDTH-1:1]};
        data_rdy_toggle  <= ~data_rdy_toggle;
      end 
      else begin
        bit_counter <= bit_counter + 1;
      end
    end
  end

  //---- 800MHz CLOCK DOMAIN (CDC & Pulse Generation) --------------------------
  always @(posedge i_800MHz_clk or posedge i_reset) begin
    if (i_reset) begin
      sync1_800mhz <= 1'b0;
      sync2_800mhz <= 1'b0;
      sync3_800mhz <= 1'b0;
    end 
    else begin
      sync1_800mhz <= data_rdy_toggle;
      sync2_800mhz <= sync1_800mhz;
      sync3_800mhz <= sync2_800mhz;
    end
  end

  //---- COMBINATIONAL PROCESSES ------------------------------------------------
  wire write_pulse = sync2_800mhz ^ sync3_800mhz;
  assign o_fifo_wr_en = write_pulse & (!i_fifo_full);

endmodule