module ucie_ltsm_tx_mbinit_repairmb #(
    parameter DECODING_WIDTH = 9,
    parameter DATA_WIDTH     = 64,
    parameter INFO_WIDTH     = 16
) ( 
    input                               i_clk,
    input                               i_reset,
    input   [DECODING_WIDTH-1:0]        i_tx_decoding,
    input   [DATA_WIDTH-1:0]            i_tx_data,
    input   [INFO_WIDTH-1:0]            i_tx_info,
    input                               i_sb_tx_req,
    input                               i_sb_tx_rsp,
    input                               i_sb_tx_done,
    input                               i_tx_done,
    input                               init_train_en,
    input                               o_rx_sb_rsp,
    input   [3:0]                       i_current_state,
    input                               o_timer_8ms,
    input   [7:0]                       i_tx_sweep_result,

    output  logic [DECODING_WIDTH-1:0]  o_tx_encoding,
    output  logic [DATA_WIDTH-1:0]      o_tx_data,
    output  logic [INFO_WIDTH-1:0]      o_tx_info,
    output  logic                       o_tx_sb_req,
    output  logic                       o_tx_sb_rsp,
    output  logic                       o_tx_sb_done,
    output  logic                       o_train_error,
    output  logic                       o_done_mbinit_repairmb_tx
);

    // -------------------------------------------------------------------------
    // Local parameters
    // -------------------------------------------------------------------------
    localparam logic [3:0] MBINIT_REPAIRMB    = 4'b0111;

    localparam logic [2:0] INIT_HANDSHAKE     = 3'b000;
    localparam logic [2:0] DATA_TO_CLOCK_TEST = 3'b001;
    localparam logic [2:0] APPLY_DEGRADE      = 3'b010;
    localparam logic [2:0] DONE_HANDSHAKE     = 3'b011;

    localparam logic [2:0] DEGRADE_NOT_POSSIBLE = 3'b000;
    localparam logic [2:0] LANES_0_TO_7         = 3'b001;
    localparam logic [2:0] LANES_8_TO_15        = 3'b010;
    localparam logic [2:0] ALL_LANES_FUNCTIONAL  = 3'b011;

    // -------------------------------------------------------------------------
    // Internal signals
    // -------------------------------------------------------------------------
    logic [2:0] current_substate;
    logic [2:0] next_substate;
    logic       done_ack;
    logic       substates_done;

    // r_lane_map: current accepted lane configuration register.
    //   Initialised to ALL_LANES_FUNCTIONAL.  Updated in always_ff when
    //   APPLY_DEGRADE detects extracted != current, so the re-run sweep uses
    //   the correct new baseline.
    // r_per_lane_result: latched per_lane_result at the clock clock_to_test_done
    //   fires, keeping it stable through APPLY_DEGRADE evaluation.
    // w_extracted_lane_map: combinational decode of r_per_lane_result[15:0].
    logic [2:0]            r_lane_map;
    logic [DATA_WIDTH-1:0] r_per_lane_result;
    logic [2:0]            w_extracted_lane_map;

    logic clock_to_test_enable;

    // Eye sweep submodule wires
    logic [DECODING_WIDTH-1:0] o_tx_encoding_data_to_clock_test;
    logic [DATA_WIDTH-1:0]     o_tx_data_data_to_clock_test;
    logic [INFO_WIDTH-1:0]     o_tx_info_data_to_clock_test;
    logic                      o_tx_sb_req_data_to_clock_test;
    logic                      o_tx_sb_rsp_data_to_clock_test;
    logic                      o_tx_sb_done_data_to_clock_test;
    logic                      train_error_data_to_clock_test;
    logic                      no_retry;
    logic                      init;
    logic                      failed_test;
    logic                      clock_to_test_done;
    logic [DATA_WIDTH-1:0]     per_lane_result;

    logic r_eye_sweep_reset; 

    // -------------------------------------------------------------------------
    // Eye sweep submodule (TX-initiated, init = 1)
    // -------------------------------------------------------------------------
    ucie_TX_Data_to_Clock_eye_sweep ucie_TX_Data_to_Clock_eye_sweep_inst (
        .i_clk              (i_clk),
        .i_reset            (r_eye_sweep_reset),
        .i_xx_decoding      (i_tx_decoding),
        .i_xx_data          (i_tx_data),
        .i_xx_sweep_result  (i_tx_sweep_result),
        .i_sb_xx_req        (i_sb_tx_req),
        .i_sb_xx_rsp        (i_sb_tx_rsp),
        .i_sb_xx_done       (i_sb_tx_done),
        .i_xx_done          (i_tx_done),
        .done_ack           (done_ack),
        .init               (init),
        .no_retry           (no_retry),
        .o_xx_encoding      (o_tx_encoding_data_to_clock_test),
        .o_xx_data          (o_tx_data_data_to_clock_test),
        .o_xx_info          (o_tx_info_data_to_clock_test),
        .o_xx_sb_req        (o_tx_sb_req_data_to_clock_test),
        .o_xx_sb_rsp        (o_tx_sb_rsp_data_to_clock_test),
        .train_error        (train_error_data_to_clock_test),
        .failed_test        (failed_test),
        .per_lane_result    (per_lane_result),
        .done               (clock_to_test_done)
    );

    // -------------------------------------------------------------------------
    // w_extracted_lane_map — combinational from registered r_per_lane_result
    //   Bits [15:0]: 1 = lane good, 0 = lane bad
    //   ALL_LANES_FUNCTIONAL : all 16 bits set
    //   LANES_0_TO_7         : some good in [7:0], none in [15:8]
    //   LANES_8_TO_15        : none in [7:0], some good in [15:8]
    //   DEGRADE_NOT_POSSIBLE : both halves mixed, or all bad
    // -------------------------------------------------------------------------
    always_comb begin
        if (&r_per_lane_result[15:0])
            w_extracted_lane_map = ALL_LANES_FUNCTIONAL;
        else if (&r_per_lane_result[7:0] && !(&r_per_lane_result[15:8]))
            w_extracted_lane_map = LANES_0_TO_7;
        else if (!(&r_per_lane_result[7:0]) && &r_per_lane_result[15:8])
            w_extracted_lane_map = LANES_8_TO_15;
        else
            w_extracted_lane_map = DEGRADE_NOT_POSSIBLE;
    end

    // -------------------------------------------------------------------------
    // State memory + lane map registers
    // -------------------------------------------------------------------------
    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset || i_current_state != MBINIT_REPAIRMB) begin
            current_substate  <= INIT_HANDSHAKE;
            substates_done    <= 0;
            r_lane_map        <= ALL_LANES_FUNCTIONAL;
            r_per_lane_result <= '0;
        end else begin
            current_substate <= next_substate;

            // Latch sweep result the cycle clock_to_test_done fires
            if (current_substate == DATA_TO_CLOCK_TEST && clock_to_test_done)
                r_per_lane_result <= per_lane_result;

            // Update lane map on mismatch so the re-run sweep has the new target
            if (current_substate == APPLY_DEGRADE &&
                i_sb_tx_rsp && i_tx_decoding == 9'h3A &&
                w_extracted_lane_map != r_lane_map)
                r_lane_map <= w_extracted_lane_map;

            if (current_substate == DONE_HANDSHAKE &&
                i_sb_tx_rsp && i_tx_decoding == 9'h3B)
                substates_done <= 1;
        end
    end

    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset) r_eye_sweep_reset <= 1'b1;
        else         r_eye_sweep_reset <= !clock_to_test_enable;
    end

    // -------------------------------------------------------------------------
    // REQ / Done handshake register
    // -------------------------------------------------------------------------
    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset)           done_ack <= 0;
        else if (i_sb_tx_done) done_ack <= 1;
        else if (i_sb_tx_rsp)  done_ack <= 0;
    end

    // -------------------------------------------------------------------------
    // Next-state / output combinational logic
    // -------------------------------------------------------------------------
    always_comb begin
        o_tx_encoding             = 9'h38;
        o_tx_data                 = '0;
        o_tx_info                 = '0;
        o_tx_sb_req               = 0;
        o_tx_sb_rsp               = 0;
        o_tx_sb_done              = 0;
        o_train_error             = 0;
        o_done_mbinit_repairmb_tx = 0;
        next_substate             = INIT_HANDSHAKE;
        clock_to_test_enable      = 0;
        init                      = 0;
        no_retry                  = 0;

        // Timeout or sweep train error — highest priority
        if (o_timer_8ms || train_error_data_to_clock_test) begin
            o_train_error = 1;
            next_substate = INIT_HANDSHAKE;
        end
        else if (i_current_state == MBINIT_REPAIRMB && !substates_done) begin
            case (current_substate)

                // --------------------------------------------------------------
                // INIT_HANDSHAKE (0x38)
                // --------------------------------------------------------------
                INIT_HANDSHAKE: begin
                    o_tx_encoding = 9'h38;
                    o_tx_sb_req   = ~done_ack;
                    if (i_sb_tx_rsp && i_tx_decoding == 9'h38) begin
                        clock_to_test_enable = 1;
                        next_substate        = DATA_TO_CLOCK_TEST;
                    end else begin
                        next_substate = INIT_HANDSHAKE;
                    end
                end

                // --------------------------------------------------------------
                // DATA_TO_CLOCK_TEST — forward all sweep submodule outputs
                // --------------------------------------------------------------
                DATA_TO_CLOCK_TEST: begin
                    clock_to_test_enable = 1;
                    init                 = 1;
                    no_retry             = 0;

                    o_tx_encoding = o_tx_encoding_data_to_clock_test;
                    o_tx_data     = o_tx_data_data_to_clock_test;
                    o_tx_info     = o_tx_info_data_to_clock_test;
                    o_tx_sb_req   = o_tx_sb_req_data_to_clock_test;
                    o_tx_sb_rsp   = o_tx_sb_rsp_data_to_clock_test;
                    o_tx_sb_done  = o_tx_sb_done_data_to_clock_test;

                    if (clock_to_test_done)
                        next_substate = APPLY_DEGRADE;
                    else
                        next_substate = DATA_TO_CLOCK_TEST;
                end // ← was MISSING in original; caused APPLY_DEGRADE to be nested inside

                // --------------------------------------------------------------
                // APPLY_DEGRADE (0x3A)
                //   DEGRADE_NOT_POSSIBLE → spec mandates exit to TRAINERROR
                //   Mismatch → update r_lane_map (in always_ff) and re-run sweep
                //   Match    → advance to DONE_HANDSHAKE
                // --------------------------------------------------------------
                APPLY_DEGRADE: begin
                    o_tx_encoding = 9'h3A;

                    if (w_extracted_lane_map == DEGRADE_NOT_POSSIBLE) begin
                        // Spec: "Degrade not possible" encoding → exit TRAINERROR
                        o_train_error = 1;
                        next_substate = INIT_HANDSHAKE;
                    end else begin
                        o_tx_sb_req = ~done_ack;
                        // Send extracted lane map to partner in o_tx_info[2:0]
                        if (~done_ack)
                            o_tx_info = {{(INFO_WIDTH-3){1'b0}}, w_extracted_lane_map};

                        if (i_sb_tx_rsp && i_tx_decoding == 9'h3A) begin
                            if (w_extracted_lane_map == r_lane_map)
                                next_substate = DONE_HANDSHAKE;
                            else
                                next_substate = DATA_TO_CLOCK_TEST; // re-run with updated map
                        end else begin
                            next_substate = APPLY_DEGRADE;
                        end
                    end
                end

                // --------------------------------------------------------------
                // DONE_HANDSHAKE (0x3B)
                // --------------------------------------------------------------
                DONE_HANDSHAKE: begin
                    o_tx_encoding = 9'h3B;
                    o_tx_sb_req   = ~done_ack;
                    if (i_sb_tx_rsp && i_tx_decoding == 9'h3B) begin
                        o_done_mbinit_repairmb_tx = 1;
                        next_substate             = INIT_HANDSHAKE;
                    end else begin
                        next_substate = DONE_HANDSHAKE;
                    end
                end

                default: next_substate = INIT_HANDSHAKE;
            endcase
        end
    end

    // ==========================================================================
    // Assertions
    // ==========================================================================
`ifdef SIM

    property encoding_check(substate, logic [8:0] expected_enc);
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms || train_error_data_to_clock_test)
        (i_current_state == MBINIT_REPAIRMB && current_substate == substate)
        |-> o_tx_encoding == expected_enc;
    endproperty

    ENC_INIT_HANDSHAKE  : assert property (encoding_check(INIT_HANDSHAKE,  9'h38))
        else $error("ASSERT FAIL [ENC_INIT_HANDSHAKE]");
    ENC_APPLY_DEGRADE   : assert property (encoding_check(APPLY_DEGRADE,   9'h3A))
        else $error("ASSERT FAIL [ENC_APPLY_DEGRADE]");
    ENC_DONE_HANDSHAKE  : assert property (encoding_check(DONE_HANDSHAKE,  9'h3B))
        else $error("ASSERT FAIL [ENC_DONE_HANDSHAKE]");

    property timeout_sets_train_error;
        @(posedge i_clk) disable iff (i_reset)
        o_timer_8ms |-> o_train_error;
    endproperty
    TIMEOUT_TRAIN_ERROR : assert property (timeout_sets_train_error)
        else $error("ASSERT FAIL [TIMEOUT_TRAIN_ERROR]");

    property timeout_resets_substate;
        @(posedge i_clk) disable iff (i_reset)
        o_timer_8ms |=> current_substate == INIT_HANDSHAKE;
    endproperty
    TIMEOUT_RESETS_SUBSTATE : assert property (timeout_resets_substate)
        else $error("ASSERT FAIL [TIMEOUT_RESETS_SUBSTATE]");

    property sweep_error_propagates;
        @(posedge i_clk) disable iff (i_reset)
        train_error_data_to_clock_test |-> o_train_error;
    endproperty
    SWEEP_TRAIN_ERROR : assert property (sweep_error_propagates)
        else $error("ASSERT FAIL [SWEEP_TRAIN_ERROR]");

    property degrade_not_possible_error;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRMB &&
         current_substate == APPLY_DEGRADE &&
         w_extracted_lane_map == DEGRADE_NOT_POSSIBLE)
        |-> o_train_error;
    endproperty
    DEGRADE_NOT_POSSIBLE_ERROR : assert property (degrade_not_possible_error)
        else $error("ASSERT FAIL [DEGRADE_NOT_POSSIBLE_ERROR]");

    property mismatch_reruns_sweep;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRMB &&
         current_substate == APPLY_DEGRADE &&
         i_sb_tx_rsp && i_tx_decoding == 9'h3A &&
         w_extracted_lane_map != DEGRADE_NOT_POSSIBLE &&
         w_extracted_lane_map != r_lane_map)
        |=> current_substate == DATA_TO_CLOCK_TEST;
    endproperty
    MISMATCH_RERUNS : assert property (mismatch_reruns_sweep)
        else $error("ASSERT FAIL [MISMATCH_RERUNS]");

    property match_advances_to_done;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRMB &&
         current_substate == APPLY_DEGRADE &&
         i_sb_tx_rsp && i_tx_decoding == 9'h3A &&
         w_extracted_lane_map == r_lane_map)
        |=> current_substate == DONE_HANDSHAKE;
    endproperty
    MATCH_ADVANCES : assert property (match_advances_to_done)
        else $error("ASSERT FAIL [MATCH_ADVANCES]");

    property sweep_enabled_in_test;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRMB && current_substate == DATA_TO_CLOCK_TEST)
        |-> clock_to_test_enable;
    endproperty
    SWEEP_ENABLED : assert property (sweep_enabled_in_test)
        else $error("ASSERT FAIL [SWEEP_ENABLED]");

    property done_on_rsp;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRMB &&
         current_substate == DONE_HANDSHAKE &&
         i_sb_tx_rsp && i_tx_decoding == 9'h3B)
        |-> o_done_mbinit_repairmb_tx;
    endproperty
    DONE_REPAIRMB : assert property (done_on_rsp)
        else $error("ASSERT FAIL [DONE_REPAIRMB]");

    property done_only_in_state;
        @(posedge i_clk) disable iff (i_reset)
        i_current_state != MBINIT_REPAIRMB |-> !o_done_mbinit_repairmb_tx;
    endproperty
    DONE_ONLY_IN_STATE : assert property (done_only_in_state)
        else $error("ASSERT FAIL [DONE_ONLY_IN_STATE]");

`endif

endmodule