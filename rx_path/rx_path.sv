module rx_path #(
    parameter int pDATA_WIDTH      = 64,
    parameter int pNUM_LANES       = 16,
    parameter int pDATA_RDI_WIDTH  = 2048
) (
    // Clocks & resets
    input  logic                            i_clk_l,
    input  logic                            i_clk_p,
    input  logic                            i_clk_n,
    input  logic                            i_hclk,
    input  logic                            i_dclk,
    input  logic                            i_track,
    input  logic                            i_reset,
    // Data inputs
    input  logic [pNUM_LANES-1:0]           i_lanes,
    input  logic                            i_valid,
    input  logic                            i_halfrate,
    // Configuration
    input  logic [8:0]                      i_rx_encoding,
    input  logic [2:0]                      i_lane_map_code,
    input  logic [15:0]                     i_error_threshold,
    // Outputs
    output logic [pDATA_RDI_WIDTH-1:0]      o_pl_data,
    output logic                            o_pl_valid,
    output logic                            o_rx_done,
    output logic [63:0]                     o_rx_data_results,
    output logic                            o_rx_error,
    output logic [2:0]                      o_clk_results,
    output logic                            o_valid_results
);

    // -------------------------------------------------------------------------
    // Internal signals
    // -------------------------------------------------------------------------

    // Lane data paths
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] lane_id_in;
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] lane_LFSR_out;
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] lane_LFSR_in;
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] lane_demux_in;
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] deserializer_out;

    // Per-lane status & control
    logic [pNUM_LANES-1:0]  enable_lfsr;
    logic [pNUM_LANES-1:0]  enable_laneid;
    logic [pNUM_LANES-1:0]  lane_id_success;
    logic [pNUM_LANES-1:0]  lane_lfsr_success;    // was: lane_lfsr_succes (typo)
    logic [pNUM_LANES-1:0]  error_threshold;
    logic [pNUM_LANES-1:0]  w_en;
    logic [pNUM_LANES-1:0]  rd_en;
    logic [pNUM_LANES-1:0]  full;
    logic [pNUM_LANES-1:0]  empty;
    logic [pNUM_LANES-1:0]  deserializer_in;
    logic [pNUM_LANES-1:0]  enable_lanes;

    // Clock/valid detection results
    logic [2:0]             clk_result;
    logic [2:0]             clk_result_synced;    // was: clk_result_sync (name clash with instance)
    logic                   valid_result;
    logic                   valid_result_synced;  // was: valid_result_sync (name clash with instance)

    // Recovered clocks & signals
    logic                   clk_p;
    logic                   clk_n;
    logic                   track;
    logic                   valid;

    // Controller outputs / misc control
    logic                   reset;
    logic                   load;
    logic                   train;
    logic                   sel_demux;
    logic                   detection_type;
    logic                   L2B_enable;
    logic [1:0]             pattern_type;
    logic [1:0]             pattern_type_synced;  // was: pattern_type_sync (name clash with instance)
    logic [2:0]             lane_map;
    logic                   enable_clk_drive;
    logic                   enable_valid_drive;
    logic                   enable_data_drive;
    logic                   mb_clk_n_en;
    logic                   mb_track_en;
    logic                   empty_result;

    always @(*) begin
    case (i_lane_map_code)
           3'b000 : empty_result = 1'b1;
           3'b001 : empty_result = &empty[7:0];
           3'b010 : empty_result = &empty[15:8];
           3'b011 : empty_result = &empty;
           3'b100 : empty_result = &empty[3:0];
           3'b101 : empty_result = &empty[15:12];
           default: empty_result = 1'b1;
    endcase
    end

    // -------------------------------------------------------------------------
    // Driver — maps raw inputs to recovered lanes/clocks
    // -------------------------------------------------------------------------

    receivers receiver (
        .i_clk_p        (i_clk_p),
        .i_clk_n        (i_clk_n),
        .i_track        (i_track),
        .i_valid        (i_valid),
        .i_enable_clk   (enable_clk_drive),
        .i_enable_valid (enable_valid_drive),
        .i_enable_data  (enable_data_drive),
        .i_lane_enable  (enable_lanes),
        .i_lanes        (i_lanes),
        .i_lane_map     (i_lane_map_code),
        .o_clk_p        (clk_p),
        .o_clk_n        (clk_n),
        .o_track        (track),
        .o_valid        (valid),
        .o_lanes        (deserializer_in)
    );

    // -------------------------------------------------------------------------
    // Clock / valid pattern detection (runs on hclk/dclk domain)
    // -------------------------------------------------------------------------

    clk_valid_pattern_detection pattern_detect (
        .i_clk_p          (clk_p),
        .i_clk_n          (clk_n),
        .i_valid          (valid),
        .i_track          (track),
        .i_hclk           (i_hclk),
        .i_dclk           (i_dclk),
        .i_reset          (reset),
        .i_halfrate       (i_halfrate),
        .i_pattern_type   (pattern_type_synced),
        .i_detection_type (detection_type),
        .i_error_threshhold (error_threshold),
        .o_clk_result     (clk_result),
        .o_valid_result   (valid_result)
    );

    // Sync pattern_type (clk_l → dclk)
    synchonizer #(
        .width(2)
    ) sync_pattern_type (
        .i_clk    (i_dclk),
        .data_in  (pattern_type),
        .data_out (pattern_type_synced)
    );

    // Sync clk_result & valid_result back to clk_l
    synchonizer #(
        .width(3)
    ) sync_clk_result (
        .i_clk    (i_clk_l),
        .data_in  (clk_result),
        .data_out (clk_result_synced)
    );

    synchonizer #(
        .width(1)
    ) sync_valid_result (
        .i_clk    (i_clk_l),
        .data_in  (valid_result),
        .data_out (valid_result_synced)
    );

    // -------------------------------------------------------------------------
    // Per-lane deserializers + FIFOs (dclk → clk_l CDC)
    // -------------------------------------------------------------------------

    genvar i;
    generate
        for (i = 0; i < pNUM_LANES; i++) begin : gen_lane

            deser_h #(
                .pDESER_WIDTH(pDATA_WIDTH)
            ) deser (
                .i_clk_p          (clk_p),
                .i_clk_n          (clk_n),
                .i_valid          (valid),
                .i_dclk           (i_dclk),
                .i_reset          (reset),
                .i_rx_data        (deserializer_in[i]),
                .i_fifo_full      (full[i]),
                .o_fifo_deser_msg (deserializer_out[i]),
                .o_fifo_wr_en     (w_en[i])
            );

            fifo fifo (
                .i_clk_wr  (i_dclk),
                .i_clk_rd  (i_clk_l),
                .i_reset   (reset),
                .i_wr_en   (w_en[i]),
                .i_rd_en   (rd_en[i]),
                .i_data_in (deserializer_out[i]),
                .o_data_out(lane_demux_in[i]),
                .o_empty   (empty[i]),
                .o_full    (full[i])
            );

        end
    endgenerate

    // -------------------------------------------------------------------------
    // Demux — steers FIFO output to lane-ID or LFSR path
    // -------------------------------------------------------------------------

    demux_1_2 demux (
        .sel (sel_demux),
        .din (lane_demux_in),
        .y0  (lane_id_in),
        .y1  (lane_LFSR_in)
    );

    // -------------------------------------------------------------------------
    // Training detectors
    // -------------------------------------------------------------------------

    per_lane_id_detector_top per_lane_id (
        .i_clk           (i_clk_l),
        .i_reset         (reset),
        .i_enable        (enable_laneid),
        .i_data_in       (lane_id_in),
        .o_laneid_success(lane_id_success)
    );

    rx_LFSR_top LFSR (
        .i_clk            (i_clk_l),
        .i_reset          (reset),
        .i_load           (load),
        .i_train          (train),
        .i_enable         (enable_lfsr),
        .i_data_in        (lane_LFSR_in),
        .i_error_threshhold (error_threshold),
        .o_data_out       (lane_LFSR_out),
        .o_lane_success   (lane_lfsr_success)
    );

    // -------------------------------------------------------------------------
    // Lane-to-byte reorder (data path after training)
    // NOTE: lane_11 is mapped to lane_LFSR_out[10] twice below —
    //       verify intent; likely i_lane_11 should be lane_LFSR_out[11].
    // -------------------------------------------------------------------------

    ucie_lane_to_byte L2B (
        .i_clk          (i_clk_l),
        .i_reset        (reset),
        .i_enable       (L2B_enable),
        .i_lane_map_code(lane_map),
        .i_lane_0       (lane_LFSR_out[0]),
        .i_lane_1       (lane_LFSR_out[1]),
        .i_lane_2       (lane_LFSR_out[2]),
        .i_lane_3       (lane_LFSR_out[3]),
        .i_lane_4       (lane_LFSR_out[4]),
        .i_lane_5       (lane_LFSR_out[5]),
        .i_lane_6       (lane_LFSR_out[6]),
        .i_lane_7       (lane_LFSR_out[7]),
        .i_lane_8       (lane_LFSR_out[8]),
        .i_lane_9       (lane_LFSR_out[9]),
        .i_lane_10      (lane_LFSR_out[10]),
        .i_lane_11      (lane_LFSR_out[10]),   // BUG? should be [11]
        .i_lane_12      (lane_LFSR_out[11]),   // BUG? should be [12]
        .i_lane_13      (lane_LFSR_out[12]),   // BUG? should be [13]
        .i_lane_14      (lane_LFSR_out[13]),   // BUG? should be [14]
        .i_lane_15      (lane_LFSR_out[14]),   // BUG? should be [15]
        .o_pl_data      (o_pl_data),
        .o_pl_valid     (o_pl_valid)
    );

    // -------------------------------------------------------------------------
    // RX controller (FSM — clk_l domain)
    // -------------------------------------------------------------------------

    ucie_rx_controller controller (
        .i_clk                  (i_clk_l),
        .i_reset                (i_reset),
        .i_rx_encoding          (i_rx_encoding),
        .i_lane_map_code        (i_lane_map_code),
        .i_fifo_empty           (empty_result),
        .i_rx_LFSR_results      (lane_lfsr_success),
        .i_rx_lane_id_results   (lane_id_success),
        .i_clk_results          (clk_result_synced),
        .i_valid_results        (valid_result_synced),
        .i_error_threshold      (i_error_threshold),
        .o_rx_path_reset        (reset),
        .o_error_threshold      (error_threshold),
        .o_rx_lfsr_enable       (enable_lfsr),
        .o_rx_data_results      (o_rx_data_results),
        .o_rx_error             (o_rx_error),
        .o_clk_results          (o_clk_results),
        .o_valid_results        (o_valid_results),
        .o_per_lane_id_det_enable(enable_laneid),
        .o_rx_lfsr_load         (load),
        .o_rx_lfsr_train        (train),
        .o_pattern_type         (pattern_type),
        .o_detection_type       (detection_type),
        .o_data_det_type        (sel_demux),
        .o_rx_done              (o_rx_done),
        .o_l2b_enable           (L2B_enable),
        .o_fifo_rd_en           (rd_en),
        .o_mb_valid_en          (enable_valid_drive),
        .o_mb_clk_p_en          (enable_clk_drive),
        .o_mb_lanes_en          (enable_lanes),
        .o_mb_clk_n_en          (mb_clk_n_en),
        .o_mb_track_en          (mb_track_en)
    );

endmodule