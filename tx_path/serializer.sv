//------------------------------------------------------------------------------
// Module: ucie_sideband_ser
// Description: ...
//------------------------------------------------------------------------------
module serializer
#(
  parameter pSER_WIDTH = 64
)
(
  input  wire                  i_clk,
  input  wire                  i_reset,
  input  wire [pSER_WIDTH-1:0] i_fifo_ser_msg,
  input  wire                  i_fifo_empty,
  input  wire                  i_enable,
  output wire                  o_tx_sb_data,
  output wire                  o_fifo_rd_en
);

  //---- STATE DEFINITIONS -----------------------------------------------------
  localparam ST_IDLE = 1'b0;
  localparam ST_TX   = 1'b1;

  reg  state, next_state;
  
  //---- SIGNAL DECLARATIONS ---------------------------------------------------
  reg  [pSER_WIDTH-1:0] shift_reg;
  reg  [5:0]            bit_counter;
  reg                   clk_en_ff;  
  
  wire flag_63 = (bit_counter == 6'd63);

  //---- FSM STATE REGISTER ----------------------------------------------------
  always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
      state <= ST_IDLE;
    end else if (!i_enable) begin
      state <= ST_IDLE;
    end else begin
      state <= next_state;
    end
  end

  //---- FSM NEXT STATE LOGIC --------------------------------------------------
  always @(*) begin
    next_state = state;
    case (state)
      ST_IDLE: begin
        if (!i_fifo_empty)
          next_state = ST_TX;
      end
      
      
      ST_TX: begin
        if (flag_63) begin
          if (i_fifo_empty)
            next_state = ST_IDLE;
        end
      end
      
      default: next_state = ST_IDLE;
    endcase
  end

  //---- COUNTER ---------------------------------------------------------------
  always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
      bit_counter <= 6'd0;
    end else if (!i_enable) begin
      bit_counter <= 6'd0;
    end else begin
      if (state == ST_IDLE || (state == ST_TX && flag_63)) begin
        bit_counter <= 6'd0;
      end else if (state == ST_TX) begin
        bit_counter <= bit_counter + 6'd1;
      end
    end
  end

  //---- SHIFT REGISTER & FIFO READ --------------------------------------------
  // Read from FIFO at the end of the 31st low cycle
  assign o_fifo_rd_en = (state == ST_TX && flag_63) ? 1'b1 : 1'b0;

  always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
      shift_reg <= {pSER_WIDTH{1'b0}};
    end else if (!i_enable) begin
      shift_reg <= {pSER_WIDTH{1'b0}};
    end else begin
      if (state == ST_TX && flag_63) begin
        shift_reg <= i_fifo_ser_msg;
      end else if (state == ST_TX && !flag_63) begin
        shift_reg <= {1'b0, shift_reg[pSER_WIDTH-1:1]};
      end
    end
  end

  //---- OUTPUTS ---------------------------------------------------------------
  assign o_tx_sb_data      = (state == ST_TX) ? shift_reg[0] : 1'b0;


endmodule