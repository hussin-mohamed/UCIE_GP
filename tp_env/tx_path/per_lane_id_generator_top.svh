module per_lane_id_generator_top #(
    parameter int pDATA_WIDTH = 64,
    parameter int pNUM_LANES  = 16,
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
    }
) (
    input logic                              i_clk,i_reset,
    output logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] o_lane
);

    genvar i;
    generate
        for (i = 0; i < pNUM_LANES; i++) begin : lane_gen
            lane_id_register #(
                .pLANE_ID_PATTERN (pLANE_ID_PATTERN[i])
            ) u_reg (
                .i_clk (i_clk),
                .i_reset (i_reset),
                .pattern (o_lane[i])
            );
        end
    endgenerate

endmodule