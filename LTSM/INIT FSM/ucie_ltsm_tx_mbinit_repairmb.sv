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

    // Lane map codes — default ALL_LANES_FUNCTIONAL = 3'b011
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

    logic [2:0] lane_map;
    logic [2:0] extracted_lane_map;

    logic       clock_to_test_enable;

    // Signals from / to eye sweep submodule
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

    // -------------------------------------------------------------------------
    // Eye sweep submodule
    // -------------------------------------------------------------------------
    ucie_TX_Data_to_Clock_eye_sweep ucie_TX_Data_to_Clock_eye_sweep_inst (
        .i_clk              (i_clk),
        .i_reset            (i_reset || !clock_to_test_enable),
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
        .o_xx_sb_done       (o_tx_sb_done_data_to_clock_test),
        .train_error        (train_error_data_to_clock_test),
        .failed_test        (failed_test),
        .done               (clock_to_test_done)
    );

    // -------------------------------------------------------------------------
    // State memory
    // -------------------------------------------------------------------------
    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset || i_current_state != MBINIT_REPAIRMB) begin
            current_substate <= INIT_HANDSHAKE;
            substates_done   <= 0;
        end else begin
            current_substate <= next_substate;
            if (current_substate == DONE_HANDSHAKE &&
                i_sb_tx_rsp && i_tx_decoding == 9'h3B)
                substates_done <= 1;
        end
    end

    // -------------------------------------------------------------------------
    // REQ / Done handshake register
    // -------------------------------------------------------------------------
    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset)
            done_ack <= 0;
        else if (i_sb_tx_done)
            done_ack <= 1;
        else if (i_sb_tx_rsp)
            done_ack <= 0;
    end

    // -------------------------------------------------------------------------
    // Next-state / output combinational logic
    // -------------------------------------------------------------------------
    always_comb begin
        // Defaults — prevent unwanted latches
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
        // extracted_lane_map        = '0;      
        // lane_map                  = '0;     
        init                      = 0;       
        no_retry                  = 0;       

        // TIMEOUT or submodule train error — highest priority
        if (o_timer_8ms || train_error_data_to_clock_test) begin
            o_train_error = 1;
            next_substate = INIT_HANDSHAKE;
        end
        else if (i_current_state == MBINIT_REPAIRMB && !substates_done) begin
            case (current_substate)

                // --------------------------------------------------------------
                // INIT_HANDSHAKE
                // Send encoding 0x38, assert REQ.
                // When RSP arrives with 0x38 enable the eye sweep submodule
                // one cycle early so it is ready when we enter DATA_TO_CLOCK_TEST.
                // --------------------------------------------------------------
                INIT_HANDSHAKE: begin
                    o_tx_encoding = 9'h38;
                    o_tx_sb_req   = done_ack ? 0 : 1;
                    lane_map = ALL_LANES_FUNCTIONAL;

                    if (i_sb_tx_rsp && i_tx_decoding == 9'h38) begin
                        clock_to_test_enable = 1;   // enable submodule one cycle early
                        next_substate = DATA_TO_CLOCK_TEST;
                    end else begin
                        next_substate = INIT_HANDSHAKE;
                    end
                end

                // --------------------------------------------------------------
                // DATA_TO_CLOCK_TEST
                // Keep clock_to_test_enable asserted so submodule stays active.
                // Forward all submodule outputs directly to TX outputs.
                // Stay until clock_to_test_done then evaluate failed_test for lane map.
                // --------------------------------------------------------------
                DATA_TO_CLOCK_TEST: begin
                    clock_to_test_enable = 1;
                    init                 = 1;    // TX-initiated mode
                    no_retry             = 0;    // allow retries

                    // Forward submodule outputs
                    o_tx_encoding = o_tx_encoding_data_to_clock_test;
                    o_tx_data     = o_tx_data_data_to_clock_test;
                    o_tx_info     = o_tx_info_data_to_clock_test;
                    o_tx_sb_req   = o_tx_sb_req_data_to_clock_test;
                    o_tx_sb_rsp   = o_tx_sb_rsp_data_to_clock_test;
                    o_tx_sb_done  = o_tx_sb_done_data_to_clock_test;

                    if (clock_to_test_done) begin
                        extracted_lane_map = failed_test ? LANES_8_TO_15
                                                         : ALL_LANES_FUNCTIONAL;
                        next_substate = APPLY_DEGRADE;
                    end else begin
                        next_substate = DATA_TO_CLOCK_TEST;
                    end
                end

                // --------------------------------------------------------------
                // APPLY_DEGRADE
                // Send encoding 0x3A, forward lane map in o_tx_info.
                // If rx confirms same lane map → advance to DONE_HANDSHAKE.
                // If rx has different lane map → re-run eye test from scratch.
                // --------------------------------------------------------------
                APPLY_DEGRADE: begin
                    o_tx_encoding = 9'h3A;
                    o_tx_sb_req   = done_ack ? 0 : 1;

                    if (!done_ack)
                        o_tx_info = extracted_lane_map;

                    if (i_sb_tx_rsp && i_tx_decoding == 9'h3A) begin
//                         if (extracted_lane_map == lane_map)
                            next_substate = DONE_HANDSHAKE;
//                         else begin
//                             lane_map      = extracted_lane_map;
//                             next_substate = DATA_TO_CLOCK_TEST;
//                         end
                    end else begin
                        next_substate = APPLY_DEGRADE;
                    end
                end

                // --------------------------------------------------------------
                // DONE_HANDSHAKE
                // Send encoding 0x3B, assert REQ.
                // Assert done when RSP arrives with matching encoding 0x3B.
                // --------------------------------------------------------------
                DONE_HANDSHAKE: begin
                    o_tx_encoding = 9'h3B;
                    o_tx_sb_req   = done_ack ? 0 : 1;

                    if (i_sb_tx_rsp && i_tx_decoding == 9'h3B) begin
                        o_done_mbinit_repairmb_tx = 1;
                        next_substate = INIT_HANDSHAKE;
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

    // --------------------------------------------------------------------------
    // Encoding correct per substate (not checked inside DATA_TO_CLOCK_TEST
    // since encoding comes from the submodule and can vary)
    // --------------------------------------------------------------------------
    property encoding_check(substate, logic [8:0] expected_enc);
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms || train_error_data_to_clock_test)
        (i_current_state == MBINIT_REPAIRMB && current_substate == substate)
        |-> o_tx_encoding == expected_enc;
    endproperty

    ENC_INIT_HANDSHAKE  : assert property (encoding_check(INIT_HANDSHAKE,  9'h38))
        else $error("ASSERT FAIL [ENC_INIT_HANDSHAKE]: wrong encoding");
    ENC_APPLY_DEGRADE   : assert property (encoding_check(APPLY_DEGRADE,   9'h3A))
        else $error("ASSERT FAIL [ENC_APPLY_DEGRADE]: wrong encoding");
    ENC_DONE_HANDSHAKE  : assert property (encoding_check(DONE_HANDSHAKE,  9'h3B))
        else $error("ASSERT FAIL [ENC_DONE_HANDSHAKE]: wrong encoding");

    // --------------------------------------------------------------------------
    // Train error on 8ms timeout
    // --------------------------------------------------------------------------
    property timeout_sets_train_error;
        @(posedge i_clk) disable iff (i_reset)
        o_timer_8ms |-> o_train_error;
    endproperty
    TIMEOUT_TRAIN_ERROR : assert property (timeout_sets_train_error)
        else $error("ASSERT FAIL [TIMEOUT_TRAIN_ERROR]: train_error not set on 8ms timeout");

    property timeout_resets_substate;
        @(posedge i_clk) disable iff (i_reset)
        o_timer_8ms |=> current_substate == INIT_HANDSHAKE;
    endproperty
    TIMEOUT_RESETS_SUBSTATE : assert property (timeout_resets_substate)
        else $error("ASSERT FAIL [TIMEOUT_RESETS_SUBSTATE]: substate not reset after timeout");

    // --------------------------------------------------------------------------
    // Eye sweep submodule train error also triggers o_train_error
    // --------------------------------------------------------------------------
    property sweep_error_sets_train_error;
        @(posedge i_clk) disable iff (i_reset)
        train_error_data_to_clock_test |-> o_train_error;
    endproperty
    SWEEP_TRAIN_ERROR : assert property (sweep_error_sets_train_error)
        else $error("ASSERT FAIL [SWEEP_TRAIN_ERROR]: train_error not set on sweep module error");

    // --------------------------------------------------------------------------
    // Eye sweep submodule is enabled when in DATA_TO_CLOCK_TEST
    // --------------------------------------------------------------------------
    property sweep_enabled_in_test;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRMB && current_substate == DATA_TO_CLOCK_TEST)
        |-> clock_to_test_enable;
    endproperty
    SWEEP_ENABLED : assert property (sweep_enabled_in_test)
        else $error("ASSERT FAIL [SWEEP_ENABLED]: clock_to_test_enable not set in DATA_TO_CLOCK_TEST");

    // --------------------------------------------------------------------------
    // Done asserted as combinational pulse on RSP + 0x3B in DONE_HANDSHAKE
    // --------------------------------------------------------------------------
    property done_on_rsp;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRMB &&
         current_substate == DONE_HANDSHAKE &&
         i_sb_tx_rsp && i_tx_decoding == 9'h3B)
        |-> o_done_mbinit_repairmb_tx;
    endproperty
    DONE_REPAIRMB : assert property (done_on_rsp)
        else $error("ASSERT FAIL [DONE_REPAIRMB]: done not asserted on RSP + 0x3B");

    // --------------------------------------------------------------------------
    // REQ raised when no done_ack; dropped once done_ack received
    // (not checked inside DATA_TO_CLOCK_TEST since REQ comes from submodule)
    // --------------------------------------------------------------------------
    property req_raised_when_needed;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRMB &&
         current_substate != DATA_TO_CLOCK_TEST &&
         !done_ack && !substates_done)
        |-> o_tx_sb_req;
    endproperty
    REQ_RAISED : assert property (req_raised_when_needed)
        else $error("ASSERT FAIL [REQ_RAISED]: tx_sb_req not asserted when handshake pending");

    property req_dropped_after_done_ack;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRMB &&
         current_substate != DATA_TO_CLOCK_TEST &&
         done_ack)
        |-> !o_tx_sb_req;
    endproperty
    REQ_DROPPED : assert property (req_dropped_after_done_ack)
        else $error("ASSERT FAIL [REQ_DROPPED]: tx_sb_req still high after done_ack received");

    // --------------------------------------------------------------------------
    // Done never asserts outside MBINIT_REPAIRMB
    // --------------------------------------------------------------------------
    property done_only_in_state;
        @(posedge i_clk) disable iff (i_reset)
        i_current_state != MBINIT_REPAIRMB |-> !o_done_mbinit_repairmb_tx;
    endproperty
    DONE_ONLY_IN_STATE : assert property (done_only_in_state)
        else $error("ASSERT FAIL [DONE_ONLY_IN_STATE]: done asserted outside MBINIT_REPAIRMB");

`endif

endmodule