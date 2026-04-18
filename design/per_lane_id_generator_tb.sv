
module per_lane_id_generator_tb;
    parameter int pDATA_WIDTH = 32;
    parameter int pNUM_LANES  = 16;
    parameter logic [pNUM_LANES-1:0][7:0] pLANE_ID_PATTERN = {
        8'b0000_1111,  // lane 15
        8'b0000_1110,  // lane 14
        8'b0000_1101,  // lane 13
        8'b0000_1100,  // lane 12
        8'b0000_1011,  // lane 11
        8'b0000_1010,  // lane 10
        8'b0000_1001,  // lane 9
        8'b0000_1000,  // lane 8
        8'b0000_0111,  // lane 7
        8'b0000_0110,  // lane 6
        8'b0000_0101,  // lane 5
        8'b0000_0100,  // lane 4
        8'b0000_0011,  // lane 3
        8'b0000_0010,  // lane 2
        8'b0000_0001,  // lane 1
        8'b0000_0000   // lane 0
    };

 logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] o_lane,o_lane_expected;
 bit i_clk,i_reset;
initial begin
    forever begin
        #5;
        i_clk = ~i_clk;
    end
end
per_lane_id_generator_top #(
    .pDATA_WIDTH (pDATA_WIDTH),
    .pNUM_LANES (pNUM_LANES),
    .pLANE_ID_PATTERN (pLANE_ID_PATTERN)
) dut (
    .i_clk (i_clk),
    .i_reset (i_reset),
    .o_lane (o_lane)
);

int i;

initial begin
    for ( i=0 ; i<pNUM_LANES ; i++ ) begin
        o_lane_expected[i] = {2{4'b1010,pLANE_ID_PATTERN[i],4'b1010}};
    end
    i_reset = 0;
    @(negedge i_clk);
    i_reset = 1;
    repeat (10) @(negedge i_clk);
    if (o_lane == o_lane_expected) begin
        $display("Test passed!");
    end
    else begin
        $display("Test failed!");
    end
    $stop;
end

endmodule
