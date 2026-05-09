module rx_LFSR_top #(
    parameter int pDATA_WIDTH = 64,
    parameter int pNUM_LANES  = 16,
    parameter logic [pNUM_LANES-1:0][22:0] pLANE_ID_SEED = {
    23'h1BB807,  // lane 15
    23'h0277CE,  // lane 14
    23'h19CFC9,  // lane 13
    23'h010F12,  // lane 12
    23'h18C0DB,  // lane 11
    23'h1EC760,  // lane 10
    23'h0607BB,  // lane 9
    23'h1DBFBC,  // lane 8
    23'h1BB807,  // lane 7
    23'h0277CE,  // lane 6
    23'h19CFC9,  // lane 5
    23'h010F12,  // lane 4
    23'h18C0DB,  // lane 3
    23'h1EC760,  // lane 2
    23'h0607BB,  // lane 1
    23'h1DBFBC   // lane 0
    }
) (
    output logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] o_data_out,
    output logic [pNUM_LANES-1:0] o_lane_success,
    input i_clk,i_reset,i_load,i_train,
    input [pNUM_LANES-1:0] i_enable,
    input [pNUM_LANES-1:0][pDATA_WIDTH-1:0] i_data_in,
    input [15:0] i_error_threshhold
);

    genvar i;
    generate
        for (i = 0; i < pNUM_LANES; i++) begin : lane_gen
            rx_LFSR #(
                .pLANE_ID_SEED (pLANE_ID_SEED[i])
            ) u_LFSR (
                .i_clk (i_clk),
                .i_reset(i_reset),
                .i_load(i_load),
                .i_train(i_train),
                .i_enable(i_enable[i]),
                .i_data_in(i_data_in[i]),
                .i_error_threshhold(i_error_threshhold),
                .o_data_out(o_data_out[i]),
                .o_lane_success(o_lane_success[i])
            );
        end
    endgenerate

endmodule