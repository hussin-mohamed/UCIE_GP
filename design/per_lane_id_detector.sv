module per_lane_id_detector #(
    parameter pLANE_ID_PATTERN = 8'b0000_0000  ,
    parameter pDATA_WIDTH = 32 
) (
    input [pDATA_WIDTH-1:0]i_data_in,
    input i_clk,i_enable,i_reset_n,
    output o_laneid_success
);
    wire [pDATA_WIDTH-1:0] pattern;
    wire counter_reset,pclk;
    lane_id_register #(pLANE_ID_PATTERN,pDATA_WIDTH) reg_0 (pattern);
    assign counter_reset = !(|(pattern ^ i_data_in));
    assign pclk=i_clk & i_enable & !o_laneid_success;
    counter_compare counter(
        .pclk(pclk),
        .counter_reset(counter_reset),
        .i_reset_n(i_reset_n),
        .o_laneid_success(o_laneid_success)
    );
endmodule