//------------------------------------------------------------------------------
// Module: deser_h
// Description: Deserializes 64-bit messages and uses a toggle synchronizer 
//              to safely generate a single  FIFO write pulse.
//------------------------------------------------------------------------------
module deser_h #(
  parameter pDESER_WIDTH = 64
)(
  input  wire                    i_clk_p,
  input  wire                    i_clk_n,
  input  wire                    i_dclk,
  input  wire                    i_reset,
  input  wire                    i_rx_data,
  input  wire                    i_fifo_full,
  input  wire                    i_valid,
  output reg  [pDESER_WIDTH-1:0] o_fifo_deser_msg,
  output wire                    o_fifo_wr_en
);

  //---- SIGNAL DECLARATIONS ---------------------------------------------------
  reg [pDESER_WIDTH-1:0] shift_reg;
  reg [6:0]              bit_counter;
  reg                    data_rdy_toggle;
  reg                    enable;
  reg                    sync1;
  reg                    sync2;
  reg                    sync3;

  //---- RX CLOCK DOMAIN (Strictly Input Clock Logic) --------------------------

  always_ff @( posedge i_clk_p or posedge i_clk_n or posedge i_reset) begin : blockName
    if (i_reset) begin
      shift_reg         <= {pDESER_WIDTH{1'b0}};
      bit_counter       <= 6'd0;
      o_fifo_deser_msg  <= {pDESER_WIDTH{1'b0}};
      data_rdy_toggle   <= 1'b0;
      enable <=0;
    end 
    else begin
      if (i_valid && !enable) begin
        shift_reg <= {i_rx_data, shift_reg[pDESER_WIDTH-1:1]};  
        enable <= 1'b1;
        bit_counter <= bit_counter + 1;
      end
      else if (enable) begin
        if (bit_counter == 7'd63) begin
          bit_counter      <= 'd0;
          o_fifo_deser_msg <= {i_rx_data, shift_reg[pDESER_WIDTH-1:1]};
          enable           <= 0;
          data_rdy_toggle  <= ~data_rdy_toggle;
        end 
        else begin
          shift_reg <= {i_rx_data, shift_reg[pDESER_WIDTH-1:1]};
          bit_counter <= bit_counter + 1;
        end
      end
    end
  end

  
  //---- 800MHz CLOCK DOMAIN (CDC & Pulse Generation) --------------------------
  always @(posedge i_dclk or posedge i_reset) begin
    if (i_reset) begin
      sync1 <= 1'b0;
      sync2 <= 1'b0;
      sync3 <= 1'b0;
    end 
    else begin
      sync1 <= data_rdy_toggle;
      sync2 <= sync1;
      sync3 <= sync2;
    end
  end

  //---- COMBINATIONAL PROCESSES ------------------------------------------------
  wire write_pulse = sync2 ^ sync3;
  assign o_fifo_wr_en = write_pulse & (!i_fifo_full);

endmodule