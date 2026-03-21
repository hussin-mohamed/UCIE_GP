//------------------------------------------------------------------------------
// Module: ucie_sideband_deser
// Description: ...
//------------------------------------------------------------------------------
module ucie_sideband_deser
#(//---- PARAMETER DECLARATIONS ------------------------------------------------
  parameter pDESER_WIDTH           = 64   // Width of serialized output
)
(//---- PORT DECLARATIONS -----------------------------------------------------
  input   wire                  i_rx_sb_clk
  ,input   wire                  i_800MHz_clk
  ,input  wire                  i_reset
  ,input  wire                  i_rx_sb_data
  ,input  wire                  i_fifo_full
  ,output wire [pDESER_WIDTH-1:0] o_fifo_deser_msg
  ,output reg                    o_fifo_wr_en
);

  //---- SIGNAL DECLARATIONS ---------------------------------------------------
  reg [pDESER_WIDTH-1:0]        shift_reg;
  reg                           flag_64_latched;
  reg [5:0]                     bit_counter;     
  reg                           flag_64;
  wire                           low;
 
  //---- SEQUENTIAL PROCESSES --------------------------------------------------
always @(posedge i_rx_sb_clk or posedge i_reset) 
begin: deser_proc
    if (i_reset) begin
        shift_reg <= {pDESER_WIDTH{1'b0}};
        o_fifo_wr_en <= 1'b0;
    end 
    else begin
            shift_reg <= {i_rx_sb_data,shift_reg[pDESER_WIDTH-1:1]};  // shift right (LSB first)
    end
end // deser_proc

always @(posedge i_rx_sb_clk or posedge i_reset) 
begin: counter_proc
    if (i_reset) begin
        bit_counter <= 6'd0;
        flag_64 <= 1'b0;
    end
    else begin
        if (bit_counter == 6'd62) begin
            bit_counter <= 6'd0;
            flag_64 <= 1'b1;
        end
        else if (low) begin
            bit_counter <= 6'd0;
            flag_64 <= 1'b0;
        end
        else begin
            bit_counter <= bit_counter + 1;
            flag_64 <= 1'b0;
        end
    end
end
  always @(posedge i_800MHz_clk or posedge i_reset) begin
    if (i_reset) begin
        flag_64_latched <= 1'b0;
    end
    else flag_64_latched <= flag_64;
end
  //---- COMBINATIONAL PROCESSES ------------------------------------------------
  assign o_fifo_deser_msg = (flag_64_latched) ? shift_reg : o_fifo_deser_msg; // Update output only when a full deserialized message is ready
  assign low = flag_64;
  always @(*) begin
    if (flag_64_latched) begin
                // load the deserialized message to output
               o_fifo_wr_en   <= (!i_fifo_full || !flag_64) ? 1'b1 : 1'b0;
            end
            else begin
               o_fifo_wr_en <= 1'b0;
            end
  end
endmodule