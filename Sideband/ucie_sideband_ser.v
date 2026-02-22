//------------------------------------------------------------------------------
// Module: ucie_sideband_ser
// Description: ...
//------------------------------------------------------------------------------
module ucie_sideband_ser
#(//---- PARAMETER DECLARATIONS ------------------------------------------------
  parameter pSER_WIDTH           = 64   // Width of serialized output
)
(//---- PORT DECLARATIONS -----------------------------------------------------
  input   wire                  i_clk
  ,input  wire                  i_reset
  ,input  wire [pSER_WIDTH-1:0] i_fifo_ser_msg
  ,input  wire                  i_fifo_empty
  ,output wire                  o_tx_sb_data
  ,output wire                  o_tx_sb_clk
  ,output wire                  o_fifo_rd_en
);

  //---- SIGNAL DECLARATIONS ---------------------------------------------------
  reg [pSER_WIDTH-1:0]          shift_reg;
  reg [5:0]                     bit_counter;     
  wire                          enable_counter;
  reg                           flag_32;
  reg                           flag_64;
  reg                           transmitting;
  reg                           low;

  //---- SEQUENTIAL PROCESSES --------------------------------------------------
always @(posedge i_clk or posedge i_reset) 
begin: ser_proc
    if (i_reset) begin
        transmitting <= 1'b0;
        low          <= 1'b1;
        shift_reg <= {pSER_WIDTH{1'b0}};
    end 
    else begin
        if ( !transmitting && !low) begin
            shift_reg <= i_fifo_ser_msg; // load the message into the shift register
            transmitting <= 1'b1;
            low          <= 1'b0; 
        end
        else if (transmitting) begin
            shift_reg <= {1'b0,shift_reg[63:1]};  // shift right (LSB first)
            low          <= 1'b0; 
            if (flag_64) begin
                transmitting <= 1'b0;
                low          <= 1'b1; // set low for 32 cycle after transmitting the whole message
            end
        end
        else if (low) begin
            if (flag_32) begin
                low <= 1'b0; // end of low period after 32 cycles
            end
        end
        else begin
            low          <= 1'b0; // set low for 32 cycle until the next message is ready
            shift_reg <= {pSER_WIDTH{1'b0}};
            transmitting <= 1'b1;
        end
    end
end // ser_proc

always @(posedge i_clk or posedge i_reset) 
begin: counter_proc
    if (i_reset) begin
        bit_counter <= 6'd0;
        flag_32 <= 1'b0;
        flag_64 <= 1'b0;
    end
    else if (enable_counter) begin
        flag_32 <= (bit_counter == 6'd30) ? 1'b1 : 1'b0;
        if (bit_counter == 6'd62) begin
            bit_counter <= 6'd0;
            flag_64 <= 1'b1;
        end
        else begin
            bit_counter <= bit_counter + 1;
            flag_64 <= 1'b0;
        end
    end
    else begin
        bit_counter <= 6'd0;
        flag_32 <= 1'b0;
        flag_64 <= 1'b0;
    end
end



  //---- COMBINATIONAL PROCESSES ------------------------------------------------
  assign enable_counter  = (transmitting || low) ? 1'b1 : 1'b0;
  assign o_fifo_rd_en    = (!i_fifo_empty && !transmitting && flag_32) ? 1'b1 : 1'b0; // read from FIFO when not empty and not currently transmitting or in low period
  assign o_tx_sb_data    = (transmitting) ? shift_reg[0] : 1'b0; // output LSB only when transmitting
  assign o_tx_sb_clk     = (transmitting) ? i_clk : 1'b0; // output clock only when transmitting

endmodule