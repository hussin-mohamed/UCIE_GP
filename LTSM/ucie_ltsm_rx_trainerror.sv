module ucie_ltsm_rx_trainerror #(
    parameter DECODING_WIDTH = 9,
    parameter DATA_WIDTH = 64,
    parameter INFO_WIDTH = 16
) (

    input                           i_clk,
    input                           i_reset,
    input   [DECODING_WIDTH-1:0]    i_rx_decoding,
    input   [DATA_WIDTH-1:0]        i_rx_data,
    input   [INFO_WIDTH-1:0]        i_rx_info,
    input                           i_sb_rx_req,
    input                           i_sb_rx_rsp,
    input                           i_sb_rx_done,
    input                           i_rx_done,
    input   [3:0]                   i_current_state,
    input                           o_timer_8ms,
    input                           i_sb_cur_msg_done,
    input                           i_lp_linkerror,

    output  logic [DECODING_WIDTH-1:0]  o_rx_encoding,
    output  logic [DATA_WIDTH-1:0]      o_rx_data,
    output  logic [INFO_WIDTH-1:0]      o_rx_info,
    output  logic                       o_rx_sb_req, 
    output  logic                       o_rx_sb_rsp,
    output  logic                       o_rx_sb_done,
    output  logic                       o_train_error,
    output  logic                       o_done_trainerror_rx

);

            
logic [2:0] current_substate;                   // current substate 
logic [2:0] next_substate;                      // next substate

logic done_ack;
logic substates_done;

// Local Parameters for states names
localparam TRAINERROR           = 4'b1000;

// Local Parameters for states names (TRAINERROR)
localparam ENTRY_HANDSHAKE = 3'b000;
localparam RX_TRAINERROR   = 3'b001;


// State Memory Logic
always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset || i_current_state != TRAINERROR) begin
        current_substate <= ENTRY_HANDSHAKE;
        substates_done   <= 0;
    end else begin
        current_substate <= next_substate;
        if (current_substate == RX_TRAINERROR && i_sb_cur_msg_done && !i_lp_linkerror)
            substates_done <= 1;
    end
end


always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) done_ack <= 0;
    else if (i_sb_rx_done) begin
        done_ack <= 1;
    end else if (i_sb_rx_req) begin // shouldn't we here raise the done_ack
        done_ack <= 0;
    end
end


always_comb begin 
    o_rx_sb_req = 0;
    o_rx_sb_rsp = 0;
    o_rx_sb_done = 0;
    o_train_error = 0;
    o_done_trainerror_rx = 0;
    next_substate = ENTRY_HANDSHAKE;

    // TIMEOUT
    if(o_timer_8ms == 1) begin 
        o_train_error = 1;
        next_substate = ENTRY_HANDSHAKE;
    end 

    else if(i_sb_rx_req && i_rx_decoding == 9'h40 && i_current_state == TRAINERROR && substates_done == 0) begin
        case(current_substate)
            ENTRY_HANDSHAKE: begin 
                // Output State Encoding
                o_rx_encoding = 9'h40;

                // rx Sending RSP Handshake
                if (done_ack) begin 
                    o_rx_sb_rsp = 0;
                end else o_rx_sb_rsp = 1;
                
                // RSP TIMEOUT
                if(o_timer_8ms == 1) begin 
                    next_substate = RX_TRAINERROR;
                end 

                // Next State Logic
                if(i_sb_rx_done) begin 
                    next_substate = RX_TRAINERROR;
                end 
            end

            RX_TRAINERROR: begin 
                // Output State Encoding
                o_rx_encoding = 9'h41;


                // assuming the done signal is always high when no traffic on SB
                if(i_sb_cur_msg_done == 1 && !i_lp_linkerror) begin 
                    o_done_trainerror_rx = 1;
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
    // Encoding is 0x40 whenever we are in TRAINERROR
    // --------------------------------------------------------------------------
    property encoding_done_handshake;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == TRAINERROR && current_substate == ENTRY_HANDSHAKE)
        |-> o_rx_encoding == 9'h40;
    endproperty
    ENC_ENTRY_HANDSHAKE : assert property (encoding_done_handshake)
        else $error("ASSERT FAIL [ENC_ENTRY_HANDSHAKE]: wrong encoding in ENTRY_HANDSHAKE");

    // --------------------------------------------------------------------------
    // Train error asserted on 8ms timeout
    // --------------------------------------------------------------------------

    property timeout_resets_substate;
        @(posedge i_clk) disable iff (i_reset)
        o_timer_8ms |=> current_substate == RX_TRAINERROR;
    endproperty
    TIMEOUT_RESETS_SUBSTATE : assert property (timeout_resets_substate)
        else $error("ASSERT FAIL [TIMEOUT_RESETS_SUBSTATE]: substate not reset after timeout");

    // --------------------------------------------------------------------------
    // Done asserted as combinational pulse on RSP + correct decoding 0x40
    // --------------------------------------------------------------------------
    property done_on_rsp;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == TRAINERROR &&
         current_substate == RX_TRAINERROR &&
         !i_lp_linkerror && i_sb_cur_msg_done)
        |-> o_done_trainerror_rx;
    endproperty
    DONE_TRAINERROR : assert property (done_on_rsp)
        else $error("ASSERT FAIL [DONE_TRAINERROR]: done not asserted on RSP + 0x40");

   
    // --------------------------------------------------------------------------
    // Done never asserts outside TRAINERROR state
    // --------------------------------------------------------------------------
    property done_only_in_state;
        @(posedge i_clk) disable iff (i_reset)
        i_current_state != TRAINERROR |-> !o_done_trainerror_rx;
    endproperty
    DONE_ONLY_IN_STATE : assert property (done_only_in_state)
        else $error("ASSERT FAIL [DONE_ONLY_IN_STATE]: done asserted outside TRAINERROR");

    // --------------------------------------------------------------------------
    // substates_done blocks re-assertion of done after first completion
    // --------------------------------------------------------------------------
    property done_blocked_after_substates_done;
        @(posedge i_clk) disable iff (i_reset)
        (i_current_state == TRAINERROR && substates_done)
        |-> !o_done_trainerror_rx;
    endproperty
    DONE_BLOCKED : assert property (done_blocked_after_substates_done)
        else $error("ASSERT FAIL [DONE_BLOCKED]: done re-asserted after substates_done latched");

`endif
endmodule