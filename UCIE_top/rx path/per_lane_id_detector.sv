module per_lane_id_detector #(
    parameter pLANE_ID_PATTERN = 8'b0000_0000  ,
    parameter pDATA_WIDTH = 64 
) (
    input [pDATA_WIDTH-1:0]i_data_in,
    input i_clk,i_enable,i_reset,
    output o_laneid_success
);
    wire [pDATA_WIDTH-1:0] pattern;
    logic pclk;
    logic enable;
    lane_id_register #(pLANE_ID_PATTERN,pDATA_WIDTH) reg_0 (
        .i_clk (i_clk),
        .i_reset (i_reset),
        .pattern (pattern)
    );
    //assign counter_reset = !(|(pattern ^ i_data_in));
    always @(*) begin
        if (!i_clk) begin
            enable = i_enable & !o_laneid_success;
        end
    end
    assign pclk=i_clk & enable;
    counter_compare counter(
        .pclk(pclk),
        .pattern(pattern),
        .i_data_in(i_data_in),
        .i_reset(i_reset),
        .o_laneid_success(o_laneid_success)
    );
endmodule