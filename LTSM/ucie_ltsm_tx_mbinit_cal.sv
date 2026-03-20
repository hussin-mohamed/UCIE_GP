module ucie_ltsm_tx_mbinit_cal #(
    parameter DECODING_WIDTH = 9,
    parameter DATA_WIDTH = 64,
    parameter INFO_WIDTH = 16
) (

    input                           i_clk,
    input                           i_reset,
    input   [DECODING_WIDTH-1:0]    i_tx_decoding,
    input   [DATA_WIDTH-1:0]        i_tx_data,
    input   [INFO_WIDTH-1:0]        i_tx_info,
    input                           i_sb_tx_req,
    input                           i_sb_tx_rsp,
    input                           i_sb_tx_done,
    input                           i_tx_done,
    input   [3:0]                   i_current_state,
    input                           o_timer_8ms,

    output  logic [DECODING_WIDTH-1:0]  o_tx_encoding,
    output  logic [DATA_WIDTH-1:0]      o_tx_data,
    output  logic [INFO_WIDTH-1:0]      o_tx_info,
    output  logic                       o_tx_sb_req, 
    output  logic                       o_tx_sb_rsp,
    output  logic                       o_tx_sb_done,
    output  logic                       o_train_error,
    output  logic                       o_done_mbinit_cal_tx

);

            
logic [2:0] current_substate;                   // current substate 
logic [2:0] next_substate;                      // next substate

logic done_ack;
logic substates_done;


// Local Parameters for states names
localparam MBINIT_CAL           = 4'b0011;

// Local Parameters for states names (CAL)
localparam DONE_HANDSHAKE = 3'b000;


// State Memory Logic
always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset || i_current_state != MBINIT_CAL) begin
        current_substate <= DONE_HANDSHAKE;
        substates_done   <= 0;
    end else begin
        current_substate <= next_substate;
        if (current_substate == DONE_HANDSHAKE && i_sb_tx_rsp && i_tx_decoding == 9'h18)
            substates_done <= 1;
    end
end


always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) done_ack <= 0;
    else if (i_sb_tx_done) begin
        done_ack <= 1;
    end else if (i_sb_tx_rsp) begin 
        done_ack <= 0;
    end
end


always_comb begin 
    o_tx_encoding = 9'h18;
    o_tx_sb_req = 0;
    o_tx_sb_rsp = 0;
    o_tx_sb_done = 0;
    o_train_error = 0;
    o_done_mbinit_cal_tx = 0;
    next_substate = DONE_HANDSHAKE;

    // TIMEOUT
    if(o_timer_8ms == 1) begin 
        o_train_error = 1;
        next_substate = DONE_HANDSHAKE;
    end 

    else if(i_current_state == MBINIT_CAL && substates_done == 0) begin
        case(current_substate)
            DONE_HANDSHAKE: begin 
                // Output State Encoding
                o_tx_encoding = 9'h18;

                // TX Sending REQ Handshake
                if (done_ack) begin 
                    o_tx_sb_req = 0;
                end
                else begin 
                    o_tx_sb_req = 1;
                end 

                // Next State Logic
                if(i_sb_tx_rsp && i_tx_decoding == 9'h18) begin 
                    o_done_mbinit_cal_tx = 1;
                end 
            end 
        endcase 
    end 
    
end 

    // ==========================================================================
    // Assertions
    // ==========================================================================
`ifdef SIM

    // --------------------------------------------------------------------------
    // Encoding is 0x18 whenever we are in MBINIT_CAL
    // --------------------------------------------------------------------------
    property encoding_done_handshake;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_CAL && current_substate == DONE_HANDSHAKE)
        |-> o_tx_encoding == 9'h18;
    endproperty
    ENC_DONE_HANDSHAKE : assert property (encoding_done_handshake)
        else $error("ASSERT FAIL [ENC_DONE_HANDSHAKE]: wrong encoding in DONE_HANDSHAKE");

    // --------------------------------------------------------------------------
    // Train error asserted on 8ms timeout; substate resets next cycle
    // --------------------------------------------------------------------------
    property timeout_sets_train_error;
        @(posedge i_clk) disable iff (i_reset)
        o_timer_8ms |-> o_train_error;
    endproperty
    TIMEOUT_TRAIN_ERROR : assert property (timeout_sets_train_error)
        else $error("ASSERT FAIL [TIMEOUT_TRAIN_ERROR]: train_error not set on 8ms timeout");

    property timeout_resets_substate;
        @(posedge i_clk) disable iff (i_reset)
        o_timer_8ms |=> current_substate == DONE_HANDSHAKE;
    endproperty
    TIMEOUT_RESETS_SUBSTATE : assert property (timeout_resets_substate)
        else $error("ASSERT FAIL [TIMEOUT_RESETS_SUBSTATE]: substate not reset after timeout");

    // --------------------------------------------------------------------------
    // Done asserted as combinational pulse on RSP + correct decoding
    // --------------------------------------------------------------------------
    property done_on_rsp;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_CAL &&
         current_substate == DONE_HANDSHAKE &&
         i_sb_tx_rsp && i_tx_decoding == 9'h18)
        |-> o_done_mbinit_cal_tx;
    endproperty
    DONE_MBINIT_CAL : assert property (done_on_rsp)
        else $error("ASSERT FAIL [DONE_MBINIT_CAL]: done not asserted on RSP + correct decoding");

    // --------------------------------------------------------------------------
    // REQ handshake — raised while no done_ack; dropped once done_ack received
    // --------------------------------------------------------------------------
    property req_raised_when_needed;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_CAL &&
         current_substate == DONE_HANDSHAKE &&
         !done_ack && !substates_done)
        |-> o_tx_sb_req;
    endproperty
    REQ_RAISED : assert property (req_raised_when_needed)
        else $error("ASSERT FAIL [REQ_RAISED]: tx_sb_req not asserted when handshake pending");

    property req_dropped_after_done_ack;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_CAL &&
         current_substate == DONE_HANDSHAKE &&
         done_ack)
        |-> !o_tx_sb_req;
    endproperty
    REQ_DROPPED : assert property (req_dropped_after_done_ack)
        else $error("ASSERT FAIL [REQ_DROPPED]: tx_sb_req still high after done_ack received");

    // --------------------------------------------------------------------------
    // Done never asserts outside MBINIT_CAL
    // --------------------------------------------------------------------------
    property done_only_in_state;
        @(posedge i_clk) disable iff (i_reset)
        i_current_state != MBINIT_CAL |-> !o_done_mbinit_cal_tx;
    endproperty
    DONE_ONLY_IN_STATE : assert property (done_only_in_state)
        else $error("ASSERT FAIL [DONE_ONLY_IN_STATE]: done asserted outside MBINIT_CAL");

`endif
endmodule