
module per_lane_id_detector_tb;
parameter int pDATA_WIDTH = 64;
    parameter int pNUM_LANES  = 16;
    // packed array of all lane ID patterns
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
    bit                              i_clk;
    logic                              i_reset;
    logic [pNUM_LANES-1:0]             i_enable;
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] i_data_in;
    logic [pNUM_LANES-1:0]             o_laneid_success;
    int                                i;
    per_lane_id_detector_top #(
        .pDATA_WIDTH(pDATA_WIDTH),
        .pNUM_LANES(pNUM_LANES),
        .pLANE_ID_PATTERN(pLANE_ID_PATTERN)
    ) dut (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_enable(i_enable),
        .i_data_in(i_data_in),
        .o_laneid_success(o_laneid_success)
    );
    initial begin
        forever begin
            #5 i_clk = ~i_clk;
        end
    end
initial begin
    i_reset = 1;
    i_enable = 0;
    for (i = 0; i < pNUM_LANES; i = i + 1) begin
        i_data_in[i] = 32'b0;
    end
    @(negedge i_clk);
    i_reset = 0;
    i_enable = 16'hFFFF; // Enable all lanes
    repeat (18) @(negedge i_clk);
    if (!o_laneid_success) begin
        $display("first test is successful");
    end
    else begin
        $display("first test failed");
    end
    for (i = 0; i < pNUM_LANES; i = i + 1) begin
        i_data_in[i] = {4{4'b1010,pLANE_ID_PATTERN[i],4'b1010}};
    end
    repeat (2) @(negedge i_clk);
    for (i = 0; i < pNUM_LANES; i = i + 1) begin
        i_data_in[i] = 32'b0;
    end
    repeat (3) @(negedge i_clk);
    if (!o_laneid_success) begin
        $display("second test is successful");
    end
    else begin
        $display("second test failed");
    end
    for (i = 0; i < pNUM_LANES; i = i + 1) begin
        i_data_in[i] = {4{4'b1010,pLANE_ID_PATTERN[i],4'b1010}};
    end
    repeat (18) @(negedge i_clk);
    if (o_laneid_success) begin
        $display("third test is successful");
    end
    else begin
        $display("third test failed");
    end
    $stop;
end

endmodule
