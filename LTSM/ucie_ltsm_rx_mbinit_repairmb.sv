`define SIM
module ucie_ltsm_rx_mbinit_repairmb #(
    parameter DECODING_WIDTH = 9,
    parameter DATA_WIDTH     = 64,
    parameter INFO_WIDTH     = 16
) (
    input                               i_clk,
    input                               i_reset,
    input   [DECODING_WIDTH-1:0]        i_rx_decoding,
    input   [DATA_WIDTH-1:0]            i_rx_data,
    input   [INFO_WIDTH-1:0]            i_rx_info,
    input                               i_sb_rx_req,
    input                               i_sb_rx_rsp,
    input                               i_sb_rx_done,
    input                               i_rx_done,
    input                               init_train_en,
    input   [3:0]                       i_current_state,
    input                               o_timer_8ms,

    // Eye sweep result measurement from RX PHY (Data To Clock Test)
    input   [7:0]                       i_rx_sweep_result,

    output  logic [DECODING_WIDTH-1:0]  o_rx_encoding,
    output  logic [DATA_WIDTH-1:0]      o_rx_data,
    output  logic [INFO_WIDTH-1:0]      o_rx_info,
    output  logic                       o_rx_sb_req,
    output  logic                       o_rx_sb_rsp,
    output  logic                       o_rx_sb_done,
    output  logic                       o_train_error,
    output  logic                       o_done_mbinit_repairmb_rx
);

    // -------------------------------------------------------------------------
    // Local parameters
    // -------------------------------------------------------------------------
    localparam logic [3:0] MBINIT_REPAIRMB = 4'b0111;

    // REPAIRMB RX substates:
    //   INIT_HANDSHAKE       : wait for TX REQ 0x38, send RSP, enable eye sweep
    //   DATA_TO_CLOCK_TEST   : RX eye sweep running (init=0, RX responds to TX)
    //                          compute lane_map from i_xx_data[15:0]
    //   WAIT_FOR_DEGRADE_REQ : wait for TX to send degrade REQ 0x3A with extracted_lane_map
    //   DEGRADE              : wait for i_rx_done (RX path applied degrade), re-run test
    //   SEND_RESP            : send RSP 0x3A to confirm degrade receipt
    //   DONE_HANDSHAKE       : wait for TX REQ 0x3B, send RSP, assert done
    localparam logic [2:0] INIT_HANDSHAKE       = 3'b000;
    localparam logic [2:0] DATA_TO_CLOCK_TEST   = 3'b001;
    localparam logic [2:0] WAIT_FOR_DEGRADE_REQ = 3'b010;
    localparam logic [2:0] DEGRADE              = 3'b011;
    localparam logic [2:0] SEND_RESP            = 3'b100;
    localparam logic [2:0] DONE_HANDSHAKE       = 3'b101;

    // Lane map codes — default ALL_LANES_FUNCTIONAL = 3'b011
    localparam logic [2:0] DEGRADE_NOT_POSSIBLE = 3'b000;
    localparam logic [2:0] LANES_0_TO_7         = 3'b001;
    localparam logic [2:0] LANES_8_TO_15        = 3'b010;
    localparam logic [2:0] ALL_LANES_FUNCTIONAL = 3'b011;

    // -------------------------------------------------------------------------
    // Internal signals
    // -------------------------------------------------------------------------
    logic [2:0] current_substate;
    logic [2:0] next_substate;
    logic       done_ack;
    logic       substates_done;

    logic       clock_to_test_enable;
    logic       clock_to_test_done;

    // Submodule signals
    logic [DECODING_WIDTH-1:0] o_rx_encoding_sweep;
    logic [DATA_WIDTH-1:0]     o_rx_data_sweep;
    logic [INFO_WIDTH-1:0]     o_rx_info_sweep;
    logic [7:0]                o_rx_sweep_result;
    logic                      o_rx_sb_req_sweep;
    logic                      o_rx_sb_rsp_sweep;
    logic                      train_error_sweep;
    logic                      failed_test_sweep;

    // Lane map tracking
    // default lane_map = ALL_LANES_FUNCTIONAL (3'b011)
    logic [2:0] lane_map;
    logic [2:0] extracted_lane_map;

        logic r_eye_sweep_reset;

    // -------------------------------------------------------------------------
    // RX Eye Sweep Submodule (init=0: RX responds to TX-initiated test)
    // -------------------------------------------------------------------------
    ucie_RX_Data_to_Clock_eye_sweep ucie_RX_Data_to_Clock_eye_sweep_inst (
        .i_clk          (i_clk),
        .i_reset        (r_eye_sweep_reset),
        .i_xx_decoding  (i_rx_decoding),
        .i_xx_data      (i_rx_data),
        .i_sb_xx_req    (i_sb_rx_req),
        .i_sb_xx_rsp    (i_sb_rx_rsp),
        .i_sb_xx_done   (i_sb_rx_done),
        .i_xx_done      (i_rx_done),
        .done_ack       (done_ack),
        .init           (1'b0),             // RX responds, TX initiates
        .no_retry       (1'b0),             // allow retries
        .result         (i_rx_sweep_result),
        .o_xx_encoding  (o_rx_encoding_sweep),
        .o_xx_data      (o_rx_data_sweep),
        .o_xx_info      (o_rx_info_sweep),
        .o_xx_sweep_result(o_rx_sweep_result),
        .o_xx_sb_req    (o_rx_sb_req_sweep),
        .o_xx_sb_rsp    (o_rx_sb_rsp_sweep),
        .train_error    (train_error_sweep),
        .failed_test    (failed_test_sweep),
        .done           (clock_to_test_done)
    );



always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) r_eye_sweep_reset <= 1'b1;
    else         r_eye_sweep_reset <= !clock_to_test_enable;
end

    // -------------------------------------------------------------------------
    // State memory
    // -------------------------------------------------------------------------
    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset || i_current_state != MBINIT_REPAIRMB) begin
            current_substate <= INIT_HANDSHAKE;
            substates_done   <= 0;
            lane_map         <= ALL_LANES_FUNCTIONAL;  // default all functional
        end else begin
            current_substate <= next_substate;

            // Update lane_map when a new extracted_lane_map is confirmed different
            if (current_substate == WAIT_FOR_DEGRADE_REQ &&
                i_sb_rx_req && i_rx_decoding == 9'h3A &&
                extracted_lane_map != lane_map)
                lane_map <= extracted_lane_map;

            // Latch substates_done on DONE_HANDSHAKE completion
            if (current_substate == DONE_HANDSHAKE &&
                i_sb_rx_req && i_rx_decoding == 9'h3B)
                substates_done <= 1;
        end
    end

    // -------------------------------------------------------------------------
    // RSP / Done handshake register
    // -------------------------------------------------------------------------
    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset)
            done_ack <= 0;
        else if (i_sb_rx_done)
            done_ack <= 1;
        else if (i_sb_rx_req)
            done_ack <= 0;
    end

    // -------------------------------------------------------------------------
    // Lane map extraction from i_rx_data[15:0]
    // Bits [15:0] represent 16 lanes: 1=good, 0=bad.
    // Good lanes 0-7  only  → LANES_0_TO_7
    // Good lanes 8-15 only  → LANES_8_TO_15
    // All good           → ALL_LANES_FUNCTIONAL
    // None recoverable   → DEGRADE_NOT_POSSIBLE
    // This logic is evaluated when the eye sweep test completes.
    // -------------------------------------------------------------------------
    always_comb begin
        // Default: all functional until sweep says otherwise
        extracted_lane_map = ALL_LANES_FUNCTIONAL;

        if (clock_to_test_done) begin
            // i_rx_data[15:0]: each bit = 1 means lane is good
            if (&i_rx_data[15:0])
                // All 16 lanes good
                extracted_lane_map = ALL_LANES_FUNCTIONAL;
          else if (|i_rx_data[7:0] && !(|i_rx_data[15:8]))
                // Some of 0-7 good, none of 8-15 good
                extracted_lane_map = LANES_0_TO_7;
          else if (!(|i_rx_data[7:0]) && |i_rx_data[15:8])
                // None of 0-7 good, some of 8-15 good
                extracted_lane_map = LANES_8_TO_15;
            else
                extracted_lane_map = DEGRADE_NOT_POSSIBLE;
        end
    end

    // -------------------------------------------------------------------------
    // Next-state / output combinational logic
    //
    // Encoding map (mirrors TX REPAIRMB encodings):
    //   INIT_HANDSHAKE       : 0x38
    //   DATA_TO_CLOCK_TEST   : forwarded from submodule
    //   WAIT_FOR_DEGRADE_REQ : 0x3A
    //   DEGRADE              : 0x3A  (waiting for RX to apply degrade)
    //   SEND_RESP            : 0x3A  (RSP to confirm degrade)
    //   DONE_HANDSHAKE       : 0x3B  
    // -------------------------------------------------------------------------
    always_comb begin
        o_rx_encoding              = 9'h38;
        o_rx_data                  = '0;
        o_rx_info                  = '0;
        o_rx_sb_req                = 0;
        o_rx_sb_rsp                = 0;
        o_rx_sb_done               = 0;
        o_train_error              = 0;
        o_done_mbinit_repairmb_rx  = 0;
        next_substate              = INIT_HANDSHAKE;
        clock_to_test_enable       = 0;

        // Timeout or sweep train error — highest priority
        if (o_timer_8ms || train_error_sweep) begin
            o_train_error = 1;
            next_substate = INIT_HANDSHAKE;
        end
        else if (i_current_state == MBINIT_REPAIRMB && !substates_done) begin
            case (current_substate)

                // --------------------------------------------------------------
                // INIT_HANDSHAKE
                // Wait for TX REQ 0x38. Send RSP.
                // Enable eye sweep submodule one cycle early (same reasoning as TX).
                // --------------------------------------------------------------
                INIT_HANDSHAKE: begin
                    o_rx_encoding = 9'h38;
                    o_rx_sb_rsp   = done_ack ? 0 : 1;

                    if (i_sb_rx_req && i_rx_decoding == 9'h38) begin
                        clock_to_test_enable = 1;   // enable one cycle early
                        next_substate        = DATA_TO_CLOCK_TEST;
                    end else begin
                        next_substate = INIT_HANDSHAKE;
                    end
                end

                // --------------------------------------------------------------
                // DATA_TO_CLOCK_TEST
                // Forward submodule outputs. Keep sweep enabled.
                // Submodule runs in init=0 (RX responds to TX-initiated test).
                // When done: compute extracted_lane_map from i_rx_data[15:0].
                // --------------------------------------------------------------
                DATA_TO_CLOCK_TEST: begin
                    clock_to_test_enable = 1;

                    // Forward submodule outputs
                    o_rx_encoding = o_rx_encoding_sweep;
                    o_rx_data     = o_rx_data_sweep;
                    o_rx_info     = o_rx_info_sweep;
                    o_rx_sb_req   = o_rx_sb_req_sweep;
                    o_rx_sb_rsp   = o_rx_sb_rsp_sweep;

                    if (clock_to_test_done)
                        next_substate = WAIT_FOR_DEGRADE_REQ;
                    else
                        next_substate = DATA_TO_CLOCK_TEST;
                end

                // --------------------------------------------------------------
                // WAIT_FOR_DEGRADE_REQ
                // TX sends degrade REQ 0x3A with its extracted_lane_map in i_rx_info.
                // If our extracted_lane_map matches → send RSP and go to SEND_RESP
                // If mismatch → degrade and re-run test
                // --------------------------------------------------------------
                WAIT_FOR_DEGRADE_REQ: begin
                    o_rx_encoding = 9'h3A;

                    if (i_sb_rx_req && i_rx_decoding == 9'h3A) begin
                        o_rx_info = extracted_lane_map;
                        if (extracted_lane_map == lane_map) begin
                            next_substate = SEND_RESP;
                        end else begin
                            // Mismatch — need to degrade and re-run
                            next_substate = DEGRADE;
                        end
                    end else begin
                        next_substate = WAIT_FOR_DEGRADE_REQ;
                    end
                end

                // --------------------------------------------------------------
                // DEGRADE
                // Wait for RX path to apply the degrade (i_rx_done).
                // Then re-run the eye sweep test.
                // --------------------------------------------------------------
                DEGRADE: begin
                    o_rx_encoding = 9'h3A;

                    if (i_rx_done)
                        next_substate = DATA_TO_CLOCK_TEST;  // re-run test
                    else
                        next_substate = DEGRADE;
                end

                // --------------------------------------------------------------
                // SEND_RESP
                // Send RSP 0x3A to acknowledge the degrade.
                // Wait for i_sb_rx_done (our RSP accepted) then advance.
                // ---------------------------------------------------------------
                SEND_RESP: begin
                    o_rx_encoding = 9'h3A;
                    o_rx_sb_rsp   = 1;

                    if (i_sb_rx_done)
                        next_substate = DONE_HANDSHAKE;
                    else
                        next_substate = SEND_RESP;
                end

                // --------------------------------------------------------------
                // DONE_HANDSHAKE
                // Wait for TX DONE REQ 0x3B. Send RSP. Assert done.
                // ---------------------------------------------------------------
                DONE_HANDSHAKE: begin
                    o_rx_encoding = 9'h3B;
                    o_rx_sb_rsp   = done_ack ? 0 : 1;

                    if (i_sb_rx_req && i_rx_decoding == 9'h3B) begin
                        o_done_mbinit_repairmb_rx = 1;
                        next_substate             = INIT_HANDSHAKE;
                    end else begin
                        next_substate = DONE_HANDSHAKE;
                    end
                end

                default: next_substate = INIT_HANDSHAKE;

            endcase
        end
    end

    // =========================================================================
    // Assertions
    // =========================================================================
`ifdef SIM

    property enc_check(substate, logic [8:0] enc);
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms || train_error_sweep)
        (i_current_state == MBINIT_REPAIRMB && current_substate == substate)
        |-> o_rx_encoding == enc;
    endproperty

    ENC_INIT_HANDSHAKE       : assert property (enc_check(INIT_HANDSHAKE,       9'h38))
        else $error("ASSERT FAIL [ENC_INIT_HANDSHAKE]: wrong encoding");
    ENC_WAIT_FOR_DEGRADE_REQ : assert property (enc_check(WAIT_FOR_DEGRADE_REQ, 9'h3A))
        else $error("ASSERT FAIL [ENC_WAIT_FOR_DEGRADE_REQ]: wrong encoding");
    ENC_DEGRADE              : assert property (enc_check(DEGRADE,              9'h3A))
        else $error("ASSERT FAIL [ENC_DEGRADE]: wrong encoding");
    ENC_SEND_RESP            : assert property (enc_check(SEND_RESP,            9'h3A))
        else $error("ASSERT FAIL [ENC_SEND_RESP]: wrong encoding");
    ENC_DONE_HANDSHAKE       : assert property (enc_check(DONE_HANDSHAKE,       9'h3B))
        else $error("ASSERT FAIL [ENC_DONE_HANDSHAKE]: wrong encoding");

    property timeout_error;
        @(posedge i_clk) disable iff (i_reset)
        (o_timer_8ms || train_error_sweep) |-> o_train_error;
    endproperty
    TIMEOUT_TRAIN_ERROR : assert property (timeout_error)
        else $error("ASSERT FAIL [TIMEOUT_TRAIN_ERROR]: train_error not set on timeout/sweep error");

    property timeout_reset_sub;
        @(posedge i_clk) disable iff (i_reset)
        (o_timer_8ms || train_error_sweep) |=> current_substate == INIT_HANDSHAKE;
    endproperty
    TIMEOUT_RESETS_SUBSTATE : assert property (timeout_reset_sub)
        else $error("ASSERT FAIL [TIMEOUT_RESETS_SUBSTATE]: substate not reset after timeout");

    // Sweep enabled in DATA_TO_CLOCK_TEST
    property sweep_enabled;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRMB && current_substate == DATA_TO_CLOCK_TEST)
        |-> clock_to_test_enable;
    endproperty
    SWEEP_ENABLED : assert property (sweep_enabled)
        else $error("ASSERT FAIL [SWEEP_ENABLED]: clock_to_test_enable not set in DATA_TO_CLOCK_TEST");

    // Mismatch → DEGRADE; match → SEND_RESP
    property degrade_on_mismatch;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRMB &&
         current_substate == WAIT_FOR_DEGRADE_REQ &&
         i_sb_rx_req && i_rx_decoding == 9'h3A &&
         extracted_lane_map != lane_map)
        |=> current_substate == DEGRADE;
    endproperty
    DEGRADE_ON_MISMATCH : assert property (degrade_on_mismatch)
        else $error("ASSERT FAIL [DEGRADE_ON_MISMATCH]: did not enter DEGRADE on lane_map mismatch");

    property send_resp_on_match;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRMB &&
         current_substate == WAIT_FOR_DEGRADE_REQ &&
         i_sb_rx_req && i_rx_decoding == 9'h3A &&
         extracted_lane_map == lane_map)
        |=> current_substate == SEND_RESP;
    endproperty
    SEND_RESP_ON_MATCH : assert property (send_resp_on_match)
        else $error("ASSERT FAIL [SEND_RESP_ON_MATCH]: did not advance to SEND_RESP on lane_map match");

    property done_on_req;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRMB &&
         current_substate == DONE_HANDSHAKE &&
         i_sb_rx_req && i_rx_decoding == 9'h3B)
        |-> o_done_mbinit_repairmb_rx;
    endproperty
    DONE_REPAIRMB_RX : assert property (done_on_req)
        else $error("ASSERT FAIL [DONE_REPAIRMB_RX]: done not asserted on REQ + 0x3B");

    property done_only_in_state;
        @(posedge i_clk) disable iff (i_reset)
        i_current_state != MBINIT_REPAIRMB |-> !o_done_mbinit_repairmb_rx;
    endproperty
    DONE_ONLY_IN_STATE : assert property (done_only_in_state)
        else $error("ASSERT FAIL [DONE_ONLY_IN_STATE]: done asserted outside MBINIT_REPAIRMB");

`endif

endmodule