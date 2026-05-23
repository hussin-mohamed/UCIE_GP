module tx_path #(
    parameter int pDATA_WIDTH   = 64,
    parameter int pNUM_LANES    = 16,
    parameter int pRDI_IN_WIDTH = 2048
) (
    // Clock and reset
    input  logic                      i_clk_l,
    input  logic                      i_reset,
    input  logic                      i_dclk,
    // Control
    input  logic                      i_halfrate,
    input  logic                      i_lp_irdy,
    input  logic                      i_lp_valid,
    input  logic [8:0]                i_tx_encoding,
    input  logic [2:0]                i_lane_map_code,
    // Data
    input  logic [pRDI_IN_WIDTH-1:0]  i_lp_data,
    // Outputs
    output logic                      o_pl_trdy,
    output logic                      o_tx_done,
    output logic [pNUM_LANES-1:0]     o_data_out,
    output logic                      o_clk_p,
    output logic                      o_clk_n,
    output logic                      o_track,
    output logic                      o_valid
);

    // -------------------------------------------------------------------------
    // Internal signals
    // -------------------------------------------------------------------------

    // Per-lane data paths
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] lane_id_out;
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] lane_LFSR_in;
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] lane_LFSR_out;
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] lane_mux_out;
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] lane_reversal_out;
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] lane_serializer_in;

    // Per-lane status
    logic [pNUM_LANES-1:0] enable_lfsr;
    logic [pNUM_LANES-1:0] enable_lanes;
    logic [pNUM_LANES-1:0] serializer_out;
    logic [pNUM_LANES-1:0] msg_done;
    logic [pNUM_LANES-1:0] active;
    logic [pNUM_LANES-1:0] w_en;
    logic [pNUM_LANES-1:0] rd_en;
    logic [pNUM_LANES-1:0] full;
    logic [pNUM_LANES-1:0] empty;

    // Clock/valid generation
    logic clk_p, clk_n, track, valid;

    // Controller outputs
    logic load, train;
    logic reset;
    logic sel_mux;
    logic sel_reverse;
    logic halfrate;
    logic B2L_enable;
    logic mb_clk_n_en, mb_track_en;
    logic enable_clk_drive, enable_valid_drive, enable_data_drive;
    logic o_per_lane_id_gen_enable;

    // Pattern and decoder
    logic [1:0] pattern_type;
    logic [1:0] pattern_type_sync;
    logic [2:0] lane_map;

    // Aggregated lane status (decoder outputs)
    logic empty_result, done_result, active_result;
    logic no_data;

    // Unused
    logic B2L_ready;
    logic data_sent;

    // -------------------------------------------------------------------------
    // Clock-domain crossing: pattern_type synchronizer
    // -------------------------------------------------------------------------

    synchonizer sync (
        .i_clk    (i_dclk),
        .data_in  (pattern_type),
        .data_out (pattern_type_sync)
    );

    // -------------------------------------------------------------------------
    // TX controller
    // -------------------------------------------------------------------------

    tx_controller controller (
        .i_clk                   (i_clk_l),
        .i_reset                 (i_reset),
        .i_tx_encoding           (i_tx_encoding),
        .i_lane_map_code         (i_lane_map_code),
        .i_lp_valid              (i_lp_valid),
        .o_tx_lfsr_enable        (enable_lfsr),
        .o_tx_lfsr_load          (load),
        .o_tx_lfsr_train         (train),
        .o_tx_path_reset         (reset),
        .o_data_pattern_type     (sel_mux),
        .o_pattern_type          (pattern_type),
        .o_tx_done               (o_tx_done),
        .o_tx_reverse            (sel_reverse),
        .o_per_lane_id_gen_enable(o_per_lane_id_gen_enable),
        .o_b2l_enable            (B2L_enable),
        .mb_valid_en             (enable_valid_drive),
        .mb_clk_p_en             (enable_clk_drive),
        .mb_clk_n_en             (mb_clk_n_en),
        .mb_track_en             (mb_track_en),
        .mb_lanes_en             (enable_lanes),
        .fifo_wr_en              (w_en)
    );

    // -------------------------------------------------------------------------
    // Byte-to-lane mapper
    // -------------------------------------------------------------------------

    ucie_byte_to_lane B2l (
        .i_clk          (i_clk_l),
        .i_reset        (reset),
        .i_enable       (B2L_enable),
        .i_lp_irdy      (i_lp_irdy),
        .i_lp_valid     (i_lp_valid),
        .i_lane_map_code(i_lane_map_code),
        .i_lp_data      (i_lp_data),
        .o_pl_trdy      (o_pl_trdy),
        .o_lane_0       (lane_LFSR_in[0]),
        .o_lane_1       (lane_LFSR_in[1]),
        .o_lane_2       (lane_LFSR_in[2]),
        .o_lane_3       (lane_LFSR_in[3]),
        .o_lane_4       (lane_LFSR_in[4]),
        .o_lane_5       (lane_LFSR_in[5]),
        .o_lane_6       (lane_LFSR_in[6]),
        .o_lane_7       (lane_LFSR_in[7]),
        .o_lane_8       (lane_LFSR_in[8]),
        .o_lane_9       (lane_LFSR_in[9]),
        .o_lane_10      (lane_LFSR_in[10]),
        .o_lane_11      (lane_LFSR_in[11]),
        .o_lane_12      (lane_LFSR_in[12]),
        .o_lane_13      (lane_LFSR_in[13]),
        .o_lane_14      (lane_LFSR_in[14]),
        .o_lane_15      (lane_LFSR_in[15])
    );

    // -------------------------------------------------------------------------
    // Pattern generation: per-lane ID and LFSR
    // -------------------------------------------------------------------------

    per_lane_id_generator_top per_lane_id (
        .i_clk  (i_clk_l),
        .i_reset(reset),
        .o_lane (lane_id_out)
    );

    tx_LFSR_top LFSR (
        .i_clk     (i_clk_l),
        .i_load    (load),
        .i_train   (train),
        .i_enable  (enable_lfsr),
        .i_data_in (lane_LFSR_in),
        .o_data_out(lane_LFSR_out)
    );

    // -------------------------------------------------------------------------
    // Data path: mux → lane reversal
    // -------------------------------------------------------------------------

    mux_2_1 mux (
        .sel(sel_mux),
        .a  (lane_id_out),
        .b  (lane_LFSR_out),
        .y  (lane_mux_out)
    );

    reversal reverse (
        .sel    (sel_reverse),
        .i_lanes(lane_mux_out),
        .o_lanes(lane_reversal_out)
    );

    // -------------------------------------------------------------------------
    // Per-lane FIFO and serializer
    // -------------------------------------------------------------------------

    genvar i;
    generate
        for (i = 0; i < pNUM_LANES; i++) begin : gen_lane

            fifo fifo (
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
                .o_tx_sb_data  (serializer_out[i]),
                .o_fifo_rd_en  (rd_en[i]),
                .o_cur_msg_done(msg_done[i]),
                .o_active      (active[i])
            );

        end
    endgenerate

    // -------------------------------------------------------------------------
    // Clock and valid pattern generation
    // -------------------------------------------------------------------------

    clk_valid_pattern_generation dut(
        .i_no_data(no_data),
        .i_dclk(i_dclk),
        .i_halfrate(i_halfrate),
        .i_reset(reset),
        .i_pattern_type(pattern_type_sync),
        .o_clk_p(clk_p),
        .o_clk_n(clk_n),
        .o_valid(valid),
        .o_track(track)
    );

    // -------------------------------------------------------------------------
    // Lane status decoders (empty / done / active)
    // -------------------------------------------------------------------------

    decoder emp_dec (
        .i_empty_done(empty),
        .i_lane_map  (i_lane_map_code),
        .o_empty     (empty_result)
    );

    decoder done_dec (
        .i_empty_done(msg_done),
        .i_lane_map  (i_lane_map_code),
        .o_empty     (done_result)
    );

    decoder active_dec (
        .i_empty_done(active),
        .i_lane_map  (i_lane_map_code),
        .o_empty     (active_result)
    );

    // -------------------------------------------------------------------------
    // Pattern generation decoder
    // -------------------------------------------------------------------------

    pattern_generation_decoder dec (
        .i_pattern_type(pattern_type_sync),
        .i_empty       (empty_result),
        .i_done        (done_result),
        .i_clk         (i_dclk),
        .o_no_data     (no_data)
    );

    // -------------------------------------------------------------------------
    // Output driver
    // -------------------------------------------------------------------------

    driver driver (
        .i_clk_p        (clk_p),
        .i_clk_n        (clk_n),
        .i_track        (track),
        .i_valid        (valid),
        .i_enable_clk   (enable_clk_drive),
        .i_enable_valid (enable_valid_drive),
        .i_enable_data  (enable_data_drive),
        .i_lane_enable  (enable_lanes),
        .i_lanes        (serializer_out),
        .i_lane_map     (i_lane_map_code),
        .o_clk_p        (o_clk_p),
        .o_clk_n        (o_clk_n),
        .o_track        (o_track),
        .o_valid        (o_valid),
        .o_lanes        (o_data_out)
    );

endmodule