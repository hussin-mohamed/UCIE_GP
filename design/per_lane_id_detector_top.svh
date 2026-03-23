module per_lane_id_detector_top #(
    parameter int pDATA_WIDTH = 32,
    parameter int pNUM_LANES  = 16,
    // packed array of all lane ID patterns
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
) (
    input  logic                              i_clk,
    input  logic                              i_reset_n,
    input  logic [pNUM_LANES-1:0]             i_enable,
    input  logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] i_data_in,
    output logic [pNUM_LANES-1:0]             o_laneid_success
);

    genvar i;
    generate
        for (i = 0; i < pNUM_LANES; i++) begin : lane_gen
            per_lane_id_detector #(
                .pLANE_ID_PATTERN  (pLANE_ID_PATTERN[i]),
                .pDATA_WIDTH  (pDATA_WIDTH)
            ) u_detector (
                .i_clk            (i_clk),
                .i_reset_n        (i_reset_n),
                .i_enable         (i_enable[i]),
                .i_data_in        (i_data_in[i]),
                .o_laneid_success  (o_laneid_success[i])
            );
        end
    endgenerate

endmodule