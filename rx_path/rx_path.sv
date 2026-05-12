module rx_path#(
    parameter int pDATA_WIDTH = 64,
    parameter int pNUM_LANES  = 16,
    parameter int pDATA_RDI_WIDTH   = 2048
    ) (
    input i_clk_l,i_reset,i_clk_p,i_clk_n,i_valid,i_track,i_hclk,i_dclk,
    input [pNUM_LANES-1:0] i_lanes

);
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] lane_id_in,lane_LFSR_out,lane_LFSR_in,lane_demux_in,deserializer_out;
    logic [pNUM_LANES-1:0] enable_lfsr,enable_laneid,lane_id_success,lane_lfsr_succes,error_threshhold;
    logic [pDATA_RDI_WIDTH-1:0] lane_byte_out;
    logic load,train;
    logic sel_demux;
    logic data_valid;
    logic sel_reverse;
    logic halfrate;
    logic reset;
    logic [2:0] clk_result;
    logic [2:0] clk_result_sync;
    logic valid_result;
    logic L2B_enable;
    logic valid_result_sync;
    logic clk_p,clk_n,track,valid;
    logic enable_clk_drive,enable_valid_drive,enable_data_drive;
    logic [2:0] lane_map;
    logic [pNUM_LANES-1:0] w_en,rd_en;
    logic [pNUM_LANES-1:0] full,empty;
    logic [1:0] pattern_type;
    logic [1:0] pattern_type_sync;
    logic detection_type;
    logic [pNUM_LANES-1:0] deserializer_in;

    per_lane_id_detector_top per_lane_id(
        .i_clk(i_clk_l),
        .i_reset(reset),
        .i_enable(enable_laneid),
        .i_data_in(lane_id_in),
        .o_laneid_success(lane_id_success)
    );

    synchonizer sync (
        .i_clk(i_dclk),
        .data_in(pattern_type),
        .data_out(pattern_type_sync)
    );

    rx_LFSR_top LFSR(
        .o_data_out(lane_LFSR_out),
        .o_lane_success(lane_lfsr_succes),
        .i_clk(i_clk_l),
        .i_load(load),
        .i_train(train),
        .i_reset(reset),
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
        .i_reset(reset),
        .i_halfrate(halfrate),
        .i_pattern_type(pattern_type_sync),
        .i_detection_type(detection_type),
        .i_error_threshhold(error_threshhold),
        .o_clk_result(clk_result),
        .o_valid_result(valid_result)
    );
    synchonizer #(
        .width(3)
    ) clk_result_sync (
        .i_clk(i_clk_l),
        .data_in(clk_result),
        .data_out(clk_result_sync)
    );
    synchonizer #(
        .width(1)
    ) valid_result_sync (
        .i_clk(i_clk_l),
        .data_in(valid_result),
        .data_out(valid_result_sync)
    );
    genvar i;
    generate 
        for (i = 0; i < pNUM_LANES; i++) begin : gen_lane
            fifo fif (
                .i_clk_wr  (i_hclk),
                .i_clk_rd  (i_clk_l),
                .i_reset   (reset),
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
                .i_clk_n(clk_n),
                .i_hclk(i_hclk),
                .i_reset(reset),
                .i_rx_data(i_lanes[i]),
                .i_fifo_full(full[i]),
                .o_fifo_deser_msg(deserializer_out[i]),
                .o_fifo_wr_en(w_en[i])
            );
        end
    endgenerate

    ucie_lane_to_byte L2B(
        .i_clk(i_clk_l),
        .i_reset(reset),
        .i_enable(L2B_enable),
        .i_lane_map_code(lane_map),
        .i_lane_0(lane_LFSR_out[0]),
        .i_lane_1(lane_LFSR_out[1]),
        .i_lane_2(lane_LFSR_out[2]),
        .i_lane_3(lane_LFSR_out[3]),
        .i_lane_4(lane_LFSR_out[4]),
        .i_lane_5(lane_LFSR_out[5]),
        .i_lane_6(lane_LFSR_out[6]),
        .i_lane_7(lane_LFSR_out[7]),
        .i_lane_8(lane_LFSR_out[8]),
        .i_lane_9(lane_LFSR_out[9]),
        .i_lane_10(lane_LFSR_out[10]),
        .i_lane_11(lane_LFSR_out[10]),
        .i_lane_12(lane_LFSR_out[11]),
        .i_lane_13(lane_LFSR_out[12]),
        .i_lane_14(lane_LFSR_out[13]),
        .i_lane_15(lane_LFSR_out[14]),
        .o_data_out(lane_byte_out),
        .o_data_valid(data_valid)
    )
endmodule