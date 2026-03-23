module rx_path#(
    parameter int pDATA_WIDTH = 32,
    parameter int pNUM_LANES  = 16
    ) (
    input iclk,i_reset_n;
);
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] lane_id_in,lane_LFSR_out,lane_LFSR_in,lane_demux_in;
    logic [pNUM_LANES-1:0] enable_lfsr,enable_laneid,lane_id_success,lane_lfsr_succes,error_threshhold;
    logic load,train;
    logic sel_demux;
    logic sel_reverse;
    per_lane_id_detector_top per_lane_id(
        .i_clk(i_clk),
        .i_reset_n(i_reset_n),
        .i_enable(enable_laneid),
        .i_data_in(lane_id_in),
        .o_laneid_success(lane_id_success)
    );

    rx_LFSR_top LFSR(
        .o_data_out(lane_LFSR_out),
        .o_lane_success(lane_lfsr_succes),
        .iclk(iclk),
        .i_load(load),
        .i_train(train),
        .i_reset_n(i_reset_n),
        .i_enable(enable_lfsr),
        .i_data_in(lane_LFSR_in),
        .i_error_threshhold(error_threshhold)
    );
    demux_1_2 demux (
        .sel(sel_demux),
        .din(lane_demux_in),
        .y0(lane_id_in),
        .y1(lane_LFSR_in)
    );
endmodule