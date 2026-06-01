module toggle_sync(
  input wire                     i_clk,
  input wire                     i_reset,
  input wire                     i_cnt,
  output wire                    o_cnt
);

  //---- SIGNAL DECLARATIONS ---------------------------------------------------
  reg  sync1;
  reg  sync2;
  reg  sync3;

  //---- --------------------------
  always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
      sync1 <= 1'b0;
      sync2 <= 1'b0;
      sync3 <= 1'b0;
    end 
    else begin
      sync1 <= i_cnt;
      sync2 <= sync1;
      sync3 <= sync2;
    end
  end

  assign o_cnt = (sync2 ^ sync3) & sync1;

endmodule