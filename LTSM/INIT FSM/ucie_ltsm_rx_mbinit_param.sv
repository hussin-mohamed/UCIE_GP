`define SIM
module ucie_ltsm_rx_mbinit_param #(
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
    output  logic [DECODING_WIDTH-1:0]  o_rx_encoding,      
    output  logic [DATA_WIDTH-1:0]      o_rx_data,
    output  logic [INFO_WIDTH-1:0]      o_rx_info,
    output  logic                       o_rx_sb_req,
    output  logic                       o_rx_sb_rsp,        
    output  logic                       o_rx_sb_done,
    output  logic                       o_train_error,      
    output  logic                       o_done_mbinit_param_rx 
);

    // -------------------------------------------------------------------------
    // Local parameters
    // -------------------------------------------------------------------------
    localparam logic [3:0] MBINIT_PARAM    = 4'b0010;

    localparam logic [2:0] WAIT_CONFIG_REQ  = 3'b000;
    localparam logic [2:0] CHECK_PARAMETERS = 3'b001;

    // -------------------------------------------------------------------------
    // Internal signals
    // -------------------------------------------------------------------------
    logic [2:0] current_substate;
    logic [2:0] next_substate;
    logic       done_ack;
    logic       substates_done;

    logic [DATA_WIDTH-1:0] i_rx_data_reg;

    // -------------------------------------------------------------------------
    // State memory
    // -------------------------------------------------------------------------
    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset || i_current_state != MBINIT_PARAM) begin
            current_substate <= WAIT_CONFIG_REQ;
            substates_done   <= 0;
            i_rx_data_reg    <= '0;
        end else begin
            current_substate <= next_substate;
            // Latch rx_data when config REQ arrives
            if (current_substate == WAIT_CONFIG_REQ &&
                i_sb_rx_req && i_rx_decoding == 9'h10)
                i_rx_data_reg <= i_rx_data;
            // Latch substates_done when CHECK_PARAMETERS gets done signal
            if (current_substate == CHECK_PARAMETERS && i_sb_rx_done)
                substates_done <= 1;
        end
    end

    // -------------------------------------------------------------------------
    // RSP / Done handshake register
    // done_ack latches when i_sb_rx_done (our RSP accepted by sideband)
    // clears when new i_sb_rx_req arrives
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
    // -------------------------------------------------------------------------
    always_comb begin
        o_rx_encoding          = 9'h10;
        o_rx_data              = '0;
        o_rx_info              = '0;
        o_rx_sb_req            = 0;
        o_rx_sb_rsp            = 0;
        o_rx_sb_done           = 0;
        o_train_error          = 0;
        o_done_mbinit_param_rx = 0;
        next_substate          = WAIT_CONFIG_REQ;

        if (o_timer_8ms) begin
            o_train_error = 1;
            next_substate = WAIT_CONFIG_REQ;
        end
        else if (i_current_state == MBINIT_PARAM && !substates_done) begin
            case (current_substate)

                // --------------------------------------------------------------
                // WAIT_CONFIG_REQ
                // Wait for TX CONFIG_HANDSHAKE REQ (encoding 0x10) with config
                // parameters in i_rx_data. Acknowledge with o_rx_sb_done.
                // --------------------------------------------------------------
                WAIT_CONFIG_REQ: begin
                    o_rx_encoding = 9'h10;

                    if (i_sb_rx_req && i_rx_decoding == 9'h10) begin
                        o_rx_sb_done  = 1;          // acknowledge receipt of config
                        next_substate = CHECK_PARAMETERS;
                    end else begin
                        next_substate = WAIT_CONFIG_REQ;
                    end
                end

                // --------------------------------------------------------------
                // CHECK_PARAMETERS
                // Compare received parameters (i_rx_data_reg) with local
                // register file values. Logic placeholder — register file not
                // yet implemented. Send RSP 0x10 to confirm parameters.
                // When i_sb_rx_done confirms our RSP was sent: assert done.
                // --------------------------------------------------------------
                CHECK_PARAMETERS: begin
                    o_rx_encoding = 9'h10;
                    // TODO: parameter comparison logic goes here when
                    //       register file is implemented. For now, always ACK.
                    o_rx_sb_rsp = done_ack ? 0 : 1;

                    if (i_sb_rx_done) begin
                        // substates_done latched in always_ff
                        o_done_mbinit_param_rx = 1;
                        next_substate          = WAIT_CONFIG_REQ;
                    end else begin
                        next_substate = CHECK_PARAMETERS;
                    end
                end

                default: next_substate = WAIT_CONFIG_REQ;

            endcase
        end
    end

    // =========================================================================
    // Assertions
    // =========================================================================
`ifdef SIM

    property enc_wait_config;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_PARAM && current_substate == WAIT_CONFIG_REQ)
        |-> o_rx_encoding == 9'h10;
    endproperty
    ENC_WAIT_CONFIG : assert property (enc_wait_config)
        else $error("ASSERT FAIL [ENC_WAIT_CONFIG]: wrong encoding in WAIT_CONFIG_REQ");

    property enc_check_param;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_PARAM && current_substate == CHECK_PARAMETERS)
        |-> o_rx_encoding == 9'h10;
    endproperty
    ENC_CHECK_PARAM : assert property (enc_check_param)
        else $error("ASSERT FAIL [ENC_CHECK_PARAM]: wrong encoding in CHECK_PARAMETERS");

    property timeout_error;
        @(posedge i_clk) disable iff (i_reset)
        o_timer_8ms |-> o_train_error;
    endproperty
    TIMEOUT_TRAIN_ERROR : assert property (timeout_error)
        else $error("ASSERT FAIL [TIMEOUT_TRAIN_ERROR]: train_error not set on timeout");

    property timeout_reset_sub;
        @(posedge i_clk) disable iff (i_reset)
        o_timer_8ms |=> current_substate == WAIT_CONFIG_REQ;
    endproperty
    TIMEOUT_RESETS_SUBSTATE : assert property (timeout_reset_sub)
        else $error("ASSERT FAIL [TIMEOUT_RESETS_SUBSTATE]: substate not reset after timeout");

    property rsp_raised;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_PARAM &&
         current_substate == CHECK_PARAMETERS &&
         !done_ack && !substates_done)
        |-> o_rx_sb_rsp;
    endproperty
    RSP_RAISED : assert property (rsp_raised)
        else $error("ASSERT FAIL [RSP_RAISED]: rx_sb_rsp not asserted in CHECK_PARAMETERS");

    property rsp_dropped;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_PARAM &&
         current_substate == CHECK_PARAMETERS && done_ack)
        |-> !o_rx_sb_rsp;
    endproperty
    RSP_DROPPED : assert property (rsp_dropped)
        else $error("ASSERT FAIL [RSP_DROPPED]: rx_sb_rsp still high after done_ack");

    property done_on_sb_done;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_PARAM &&
         current_substate == CHECK_PARAMETERS && i_sb_rx_done)
        |-> o_done_mbinit_param_rx;
    endproperty
    DONE_PARAM_RX : assert property (done_on_sb_done)
        else $error("ASSERT FAIL [DONE_PARAM_RX]: done not asserted on sb_rx_done");

    property done_only_in_state;
        @(posedge i_clk) disable iff (i_reset)
        i_current_state != MBINIT_PARAM |-> !o_done_mbinit_param_rx;
    endproperty
    DONE_ONLY_IN_STATE : assert property (done_only_in_state)
        else $error("ASSERT FAIL [DONE_ONLY_IN_STATE]: done asserted outside MBINIT_PARAM");

`endif

endmodule