module rx_path#(
    parameter int pDATA_WIDTH = 64,
    parameter int pNUM_LANES  = 16
    ) (
    input i_clk_l,i_reset,i_clk_p,i_clk_n,i_valid,i_track,i_hclk,i_dclk,
    input [pNUM_LANES-1:0] i_lanes,

);
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] lane_id_in,lane_LFSR_out,lane_LFSR_in,lane_demux_in,deserializer_out;
    logic [pNUM_LANES-1:0] enable_lfsr,enable_laneid,lane_id_success,lane_lfsr_succes,error_threshhold;
    logic load,train;
    logic sel_demux;
    logic sel_reverse;
    logic halfrate;
    logic clk_result,valid_result;
    logic clk_p,clk_n,track,valid;
    logic enable_clk_drive,enable_valid_drive,enable_data_drive;
    logic [2:0] lane_map;
    logic [pNUM_LANES-1:0] w_en,rd_en;
    logic [pNUM_LANES-1:0] full,empty;
    logic [1:0] pattern_type;
    logic detection_type;
    logic [pNUM_LANES-1:0] deserializer_in;

    per_lane_id_detector_top per_lane_id(
        .i_clk(i_clk_l),
        .i_reset(i_reset),
        .i_enable(enable_laneid),
        .i_data_in(lane_id_in),
        .o_laneid_success(lane_id_success)
    );

    rx_LFSR_top LFSR(
        .o_data_out(lane_LFSR_out),
        .o_lane_success(lane_lfsr_succes),
        .i_clk(i_clk_l),
        .i_load(load),
        .i_train(train),
        .i_reset(i_reset),
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

    driver driver (
        .i_clk_p(i_clk_p),
        .i_clk_n(i_clk_n),
        .i_track(i_track),
        .i_valid(i_valid),
        .i_enable_clk(enable_clk_drive),
        .i_enable_valid(enable_valid_drive),
        .i_enable_data(enable_data_drive),
        .i_lanes(i_lanes),
        .i_lane_map(lane_map),
        .o_clk_p(clk_p),
        .o_clk_n(clk_n),
        .o_track(track),
        .o_valid(valid),
        .o_lanes(deserializer_in)
    );

    clk_valid_pattern_detection pattern_detect (
        .i_clk_p(clk_p),
        .i_clk_n(clk_n),
        .i_valid(valid),
        .i_track(track),
        .i_hclk(i_hclk),
        .i_dclk(i_dclk),
        .i_reset(i_reset),
        .i_halfrate(halfrate),
        .i_pattern_type(pattern_type),
        .i_detection_type(detection_type),
        .i_error_threshhold(error_threshhold),
        .o_clk_result(clk_result),
        .o_valid_result(valid_result)
    );

    genvar i;
    generate 
        for (i = 0; i < pNUM_LANES; i++) begin : gen_lane
            fifo fif (
                .i_clk_wr  (i_hclk),
                .i_clk_rd  (i_clk_l),
                .i_reset   (i_reset),
                .i_wr_en   (w_en[i]),
                .i_rd_en   (rd_en[i]),
                .i_data_in (deserializer_out[i]),
                .o_data_out(lane_demux_in[i]),
                .o_empty   (empty[i]),
                .o_full    (full[i])
            );

            deserializer_h #(
                .pDESER_WIDTH(pDATA_WIDTH)
            ) deser (
                .i_clk_p(clk_p),
                .i_hclk(i_hclk),
                .i_reset(i_reset),
                .i_rx_data(deserializer_in[i]),
                .i_fifo_full(full[i]),
                .o_fifo_deser_msg(deserializer_out[i]),
                .o_fifo_wr_en(w_en[i])
            );
        end
    endgenerate
endmodule