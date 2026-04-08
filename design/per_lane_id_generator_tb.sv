
module per_lane_id_generator_tb;
    parameter int pDATA_WIDTH = 32;
    parameter int pNUM_LANES  = 16;
    parameter logic [pNUM_LANES-1:0][7:0] pLANE_ID_PATTERN = {
        8'b1111_0000,  // lane 15
        8'b0111_0000,  // lane 14
        8'b1011_0000,  // lane 13
        8'b0011_0000,  // lane 12
        8'b1101_0000,  // lane 11
        8'b0101_0000,  // lane 10
        8'b1001_0000,  // lane 9
        8'b0001_0000,  // lane 8
        8'b1110_0000,  // lane 7
        8'b0110_0000,  // lane 6
        8'b1010_0000,  // lane 5
        8'b0010_0000,  // lane 4
        8'b1100_0000,  // lane 3
        8'b0100_0000,  // lane 2
        8'b1000_0000,  // lane 1
        8'b0000_0000   // lane 0
    };

 logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] o_lane,o_lane_expected;

per_lane_id_generator_top #(
    .pDATA_WIDTH (pDATA_WIDTH),
    .pNUM_LANES (pNUM_LANES),
    .pLANE_ID_PATTERN (pLANE_ID_PATTERN)
) dut (
    .o_lane (o_lane)
);

int i;

initial begin
    for ( i=0 ; i<pNUM_LANES ; i++ ) begin
        o_lane_expected[i] = {2{4'b1010,pLANE_ID_PATTERN[i],4'b1010}};
    end
    #10;
    
    
    if (o_lane == o_lane_expected) begin
        $display("Test passed!");
    end
    else begin
        $display("Test failed!");
    end
    $stop;
end

endmodule
