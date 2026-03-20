`define SIM
module ucie_ltsm_rx_mbinit_repairval #(
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

    // Pattern detection results from RX PHY path (1 data lane health bits)
    input                               i_rx_valid_results,

    output  logic [DECODING_WIDTH-1:0]  o_rx_encoding,
    output  logic [DATA_WIDTH-1:0]      o_rx_data,
    output  logic [INFO_WIDTH-1:0]      o_rx_info,
    output  logic                       o_rx_sb_req,
    output  logic                       o_rx_sb_rsp,
    output  logic                       o_rx_sb_done,
    output  logic                       o_train_error,
    output  logic                       o_done_mbinit_repairval_rx
);

    // -------------------------------------------------------------------------
    // Local parameters
    // -------------------------------------------------------------------------
    localparam logic [3:0] MBINIT_REPAIRVAL = 4'b0101;

    // Same substate structure as REPAIRCLK — different encodings and lane bits
    localparam logic [2:0] INIT_HANDSHAKE    = 3'b000;
    localparam logic [2:0] PATTERN_DETECTION = 3'b001;
    localparam logic [2:0] WAIT_RESULT_REQ   = 3'b010;
    localparam logic [2:0] SEND_RESP         = 3'b011;
    localparam logic [2:0] DONE_HANDSHAKE    = 3'b100;

    // -------------------------------------------------------------------------
    // Internal signals
    // -------------------------------------------------------------------------
    logic [2:0] current_substate;
    logic [2:0] next_substate;
    logic       done_ack;
    logic       substates_done;
    logic       i_rx_valid_results_reg;

    // -------------------------------------------------------------------------
    // State memory + result latch
    // -------------------------------------------------------------------------
    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset || i_current_state != MBINIT_REPAIRVAL) begin
            current_substate                <= INIT_HANDSHAKE;
            substates_done                  <= 0;
            i_rx_valid_results_reg <= '0;
        end else begin
            current_substate <= next_substate;

            if ((current_substate == PATTERN_DETECTION && i_rx_done) ||
                (current_substate == PATTERN_DETECTION &&
                 i_sb_rx_req && i_rx_decoding == 9'h2A))
                i_rx_valid_results_reg <= i_rx_valid_results;

            if (current_substate == DONE_HANDSHAKE &&
                i_sb_rx_req && i_rx_decoding == 9'h2B)
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
    // Next-state / output combinational logic
    //
    // Encoding map:
    //   INIT_HANDSHAKE    : 0x28
    //   PATTERN_DETECTION : 0x29
    //   WAIT_RESULT_REQ   : 0x2A
    //   SEND_RESP         : 0x2A  (result in o_rx_info[1:0] — 2 data lanes)
    //   DONE_HANDSHAKE    : 0x2B
    // -------------------------------------------------------------------------
    always_comb begin
        o_rx_encoding              = 9'h28;
        o_rx_data                  = '0;
        o_rx_info                  = '0;
        o_rx_sb_req                = 0;
        o_rx_sb_rsp                = 0;
        o_rx_sb_done               = 0;
        o_train_error              = 0;
        o_done_mbinit_repairval_rx = 0;
        next_substate              = INIT_HANDSHAKE;

        if (o_timer_8ms) begin
            o_train_error = 1;
            next_substate = INIT_HANDSHAKE;
        end
        else if (i_current_state == MBINIT_REPAIRVAL && !substates_done) begin
            case (current_substate)

                INIT_HANDSHAKE: begin
                    o_rx_encoding = 9'h28;
                    o_rx_sb_rsp   = done_ack ? 0 : 1;

                    if (i_sb_rx_req && i_rx_decoding == 9'h28)
                        next_substate = PATTERN_DETECTION;
                    else
                        next_substate = INIT_HANDSHAKE;
                end

                PATTERN_DETECTION: begin
                    o_rx_encoding = 9'h29;

                    if (i_rx_done) begin
                        next_substate = WAIT_RESULT_REQ;
                    end else if (i_sb_rx_req && i_rx_decoding == 9'h29) begin
                        o_rx_sb_rsp   = 1;
                        next_substate = SEND_RESP;
                    end else begin
                        next_substate = PATTERN_DETECTION;
                    end
                end

                WAIT_RESULT_REQ: begin
                    o_rx_encoding = 9'h2A;
                    o_rx_sb_rsp   = done_ack ? 0 : 1;

                    if (i_sb_rx_req && i_rx_decoding == 9'h2A)
                        next_substate = SEND_RESP;
                    else
                        next_substate = WAIT_RESULT_REQ;
                end

                SEND_RESP: begin
                    o_rx_encoding   = 9'h2A;
                    o_rx_info[0]    = i_rx_valid_results_reg; // 2 data lanes
                    o_rx_sb_rsp     = 1;

                    if (i_sb_rx_done)
                        next_substate = DONE_HANDSHAKE;
                    else
                        next_substate = SEND_RESP;
                end

                DONE_HANDSHAKE: begin
                    o_rx_encoding = 9'h2B;
                    o_rx_sb_rsp   = done_ack ? 0 : 1;

                    if (i_sb_rx_req && i_rx_decoding == 9'h2B) begin
                        o_done_mbinit_repairval_rx = 1;
                        next_substate              = INIT_HANDSHAKE;
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
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRVAL && current_substate == substate)
        |-> o_rx_encoding == enc;
    endproperty

    ENC_INIT_HANDSHAKE    : assert property (enc_check(INIT_HANDSHAKE,    9'h28))
        else $error("ASSERT FAIL [ENC_INIT_HANDSHAKE]: wrong encoding");
    ENC_PATTERN_DETECTION : assert property (enc_check(PATTERN_DETECTION, 9'h29))
        else $error("ASSERT FAIL [ENC_PATTERN_DETECTION]: wrong encoding");
    ENC_WAIT_RESULT_REQ   : assert property (enc_check(WAIT_RESULT_REQ,   9'h2A))
        else $error("ASSERT FAIL [ENC_WAIT_RESULT_REQ]: wrong encoding");
    ENC_SEND_RESP         : assert property (enc_check(SEND_RESP,         9'h2A))
        else $error("ASSERT FAIL [ENC_SEND_RESP]: wrong encoding");
    ENC_DONE_HANDSHAKE    : assert property (enc_check(DONE_HANDSHAKE,    9'h2B))
        else $error("ASSERT FAIL [ENC_DONE_HANDSHAKE]: wrong encoding");

    property timeout_error;
        @(posedge i_clk) disable iff (i_reset)
        o_timer_8ms |-> o_train_error; 
    endproperty
    TIMEOUT_TRAIN_ERROR : assert property (timeout_error)
        else $error("ASSERT FAIL [TIMEOUT_TRAIN_ERROR]: train_error not set on timeout");

    property timeout_reset_sub;
        @(posedge i_clk) disable iff (i_reset)
        o_timer_8ms |=> current_substate == INIT_HANDSHAKE;
    endproperty
    TIMEOUT_RESETS_SUBSTATE : assert property (timeout_reset_sub)
        else $error("ASSERT FAIL [TIMEOUT_RESETS_SUBSTATE]: substate not reset after timeout");

    property result_latched;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRVAL && current_substate == SEND_RESP)
        |-> (o_rx_info[0] === i_rx_valid_results_reg);
    endproperty
    RESULT_LATCHED : assert property (result_latched)
        else $error("ASSERT FAIL [RESULT_LATCHED]: wrong lane health bits in SEND_RESP");

    property done_on_req;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRVAL &&
         current_substate == DONE_HANDSHAKE &&
         i_sb_rx_req && i_rx_decoding == 9'h2B)
        |-> o_done_mbinit_repairval_rx;
    endproperty
    DONE_REPAIRVAL_RX : assert property (done_on_req)
        else $error("ASSERT FAIL [DONE_REPAIRVAL_RX]: done not asserted on REQ + 0x2B");

    property done_only_in_state;
        @(posedge i_clk) disable iff (i_reset)
        i_current_state != MBINIT_REPAIRVAL |-> !o_done_mbinit_repairval_rx;
    endproperty
    DONE_ONLY_IN_STATE : assert property (done_only_in_state)
        else $error("ASSERT FAIL [DONE_ONLY_IN_STATE]: done asserted outside MBINIT_REPAIRVAL");

`endif

endmodule