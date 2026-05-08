module tx_path#(
    parameter int pDATA_WIDTH = 64,
    parameter int pNUM_LANES  = 16
    ) (
    input i_clk_l,i_reset,i_dclk,i_valid,
    output logic [pNUM_LANES-1:0] o_data_out,
    output logic o_clk_p,o_clk_n,o_track,o_valid
);
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] lane_id_out,lane_LFSR_out,lane_LFSR_in,lane_mux_out,lane_reversal_out,lane_serializer_in;
    logic [pNUM_LANES-1:0] enable_lfsr,enable_serializer;
    logic [pNUM_LANES-1:0] serializer_out,msg_done;
    logic [pNUM_LANES-1:0] active;
    logic clk_p,clk_n,track,valid;
    logic load,train;
    logic sel_mux;
    logic reset;
    logic sel_reverse;
    logic halfrate;
    logic no_data ;
    logic empty_result,done_result,active_result;
    logic enable_clk_drive,enable_valid_drive,enable_data_drive;
    logic [2:0] lane_map;
    logic [pNUM_LANES-1:0] w_en,rd_en;
    logic [pNUM_LANES-1:0] full,empty;
    logic [1:0] pattern_type,pattern_type_sync;

    synchonizer sync (
        .i_clk(i_dclk),
        .data_in(pattern_type),
        .data_out(pattern_type_sync)
    );
    per_lane_id_generator_top per_lane_id(
        .o_lane(lane_id_out),
        .i_clk(i_clk_l),
        .i_reset(reset)
    );
 
    tx_LFSR_top LFSR(
        .o_data_out(lane_LFSR_out),
        .i_clk(i_clk_l),
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

    genvar i;
    generate
        for (i = 0; i < pNUM_LANES; i++) begin : gen_lane

            fifo fif (
                .i_clk_wr  (i_clk_l),
                .i_clk_rd  (i_dclk),
                .i_reset   (reset),
                .i_wr_en   (w_en[i]),
                .i_rd_en   (rd_en[i]),
                .i_data_in (lane_reversal_out[i]),
                .o_data_out(lane_serializer_in[i]),
                .o_empty   (empty[i]),
                .o_full    (full[i])
            );

            serializer ser (
                .i_clk         (i_dclk),
                .i_reset       (reset),
                .i_fifo_ser_msg(lane_serializer_in[i]),
                .i_fifo_empty  (empty[i]),
                .i_enable      (enable_serializer[i]),
                .o_tx_sb_data  (serializer_out[i]),
                .o_fifo_rd_en  (rd_en[i]),
                .o_msg_done    (msg_done[i]),
                .o_active      (active[i])
            );

        end
    endgenerate
    clk_valid_pattern_generation pattern_gen (
        .i_valid(i_valid),
        .i_reset(reset),
        .i_hclk(i_hclk),
        .i_halfrate(halfrate),
        .i_pattern_type(pattern_type_sync),
        .i_no_data(no_data),
        .o_clk_p(clk_p),
        .o_clk_n(clk_n),
        .o_track(track),
        .o_valid(valid)
    );
    decoder emp_dec(
        .i_empty_done(empty),
        .i_lane_map(lane_map),
        .o_empty(empty_result)
    );

    decoder done_dec(
        .i_empty_done(msg_done),
        .i_lane_map(lane_map),
        .o_empty(done_result)
    );

    decoder active_dec(
        .i_empty_done(active),
        .i_lane_map(lane_map),
        .o_empty(active_result)
    );

    pattern_generation_decoder dec(
        .i_pattern_type(pattern_type_sync),
        .i_empty(empty_result),
        .i_done(done_result),
        .i_clk(i_dclk),
        .o_no_data(no_data)
    );
    driver driver (
        .i_clk_p(clk_p),
        .i_clk_n(clk_n),
        .i_track(track),
        .i_valid(valid),
        .i_enable_clk(enable_clk_drive),
        .i_enable_valid(enable_valid_drive),
        .i_enable_data(enable_data_drive),
        .i_lanes(serializer_out),
        .i_lane_map(lane_map),
        .o_clk_p(o_clk_p),
        .o_clk_n(o_clk_n),
        .o_track(o_track),
        .o_valid(o_valid),
        .o_lanes(o_data_out)
    );
endmodule