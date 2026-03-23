module tx_path#(
    parameter int pDATA_WIDTH = 32,
    parameter int pNUM_LANES  = 16
    ) (
    input iclk;
);
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] lane_id_out,lane_LFSR_out,lane_LFSR_in,lane_mux_out,lane_reversal_out;
    logic [pNUM_LANES-1:0] enable_lfsr;
    logic load,train;
    logic sel_mux;
    logic sel_reverse;
    per_lane_id_generator_top per_lane_id(
        .o_lane(lane_id_out)
    );

    tx_LFSR_top LFSR(
        .o_data_out(lane_LFSR_out),
        .iclk(iclk),
        .i_load(load),
        .i_train(train),
        .i_enable(enable_lfsr),
        .i_data_in(lane_LFSR_in)
    );

    mux_2_1 mux (
        .sel(sel_mux),
        .a(lane_id_out),
        .b(lane_LFSR_out),
        .y(lane_mux_out)
    );

    reversal reverse (
        .sel(sel_reverse),
        .i_lanes(lane_mux_out),
        .o_lanes(lane_reversal_out)
    );

endmodule