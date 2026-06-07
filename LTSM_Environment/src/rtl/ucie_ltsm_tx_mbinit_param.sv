`define SIM 
module ucie_ltsm_tx_mbinit_param #(
    parameter DECODING_WIDTH = 9,
    parameter DATA_WIDTH = 64,
    parameter INFO_WIDTH = 16
) (

    input                      i_clk,
    input                      i_reset,
    input [DECODING_WIDTH-1:0] i_tx_decoding,
    input [    DATA_WIDTH-1:0] i_tx_data,
    input [    INFO_WIDTH-1:0] i_tx_info,
    input                      i_sb_tx_req,
    input                      i_sb_tx_rsp,
    input                      i_sb_tx_done,
    input                      i_tx_done,
    input [               3:0] i_current_state,
    input                      o_timer_8ms,
    input [              15:0] r_local_cap,      // capibility register data

    output logic [DECODING_WIDTH-1:0] o_tx_encoding,
    output logic [    DATA_WIDTH-1:0] o_tx_data,
    output logic [    INFO_WIDTH-1:0] o_tx_info,
    output logic                      o_tx_sb_req,
    output logic                      o_tx_sb_rsp,
    output logic                      o_tx_sb_done,
    output logic                      o_train_error,
    output logic                      o_done_mbinit_param_tx

);


  logic [2:0] current_substate;  // current substate 
  logic [2:0] next_substate;  // next substate

  logic       done_ack;
  logic       substates_done;

  // -------------------------------------------------------------------------
  // Local capability register [15:0]
  //   Bit layout (from UCIe spec MBINIT.PARAM configuration req Data[15:0]):
  //     [15]    : TARR supported             = 0 (not supported)
  //     [14]    : Sideband feature extensions = 0 (not supported)
  //     [13]    : UCIe-A x32 / UCIe-S x8    = 0
  //     [12:11] : Module ID                  = 0
  //     [10]    : Clock Phase                = 0 (Differential)
  //     [9]     : Clock Mode                 = 0 (Strobe mode)
  //     [8:4]   : Voltage Swing              = 5'b00011 (3 = 0.5 V)
  //     [3:0]   : Max IO Link Speed          = 4'b0101  (5 = 32 GT/s)
  //   => 16'h0035
  // -------------------------------------------------------------------------
  // localparam logic [15:0] LOCAL_CAP = 16'h0035;

  // logic [15:0] r_local_cap;   // latched at reset; holds fixed capability word

  // always_ff @(posedge i_clk or posedge i_reset) begin
  //     if (i_reset)
  //         r_local_cap <= LOCAL_CAP;
  //     // Capability register is read-only; value never changes after reset
  // end


  // Local Parameters for states names
  localparam MBINIT_PARAM = 4'b0010;

  // Local Parameters for states names (PARAM)
  localparam CONFIG_HANDSHAKE = 3'b000;


  // State Memory Logic
  always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
      current_substate <= CONFIG_HANDSHAKE;
      substates_done   <= 0;
    end else if (i_current_state != MBINIT_PARAM) begin
      current_substate <= CONFIG_HANDSHAKE;
      substates_done   <= 0;
    end else begin
      current_substate <= next_substate;
      if (current_substate == CONFIG_HANDSHAKE && i_sb_tx_rsp && i_tx_decoding == 9'h10)
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
    o_tx_encoding          = 9'h10;
    o_tx_data              = '0;
    o_tx_sb_req            = 0;
    o_tx_sb_rsp            = 0;
    o_tx_sb_done           = 0;
    o_train_error          = 0;
    o_done_mbinit_param_tx = 0;
    o_tx_info              = 0;  // added
    next_substate          = CONFIG_HANDSHAKE;

    // TIMEOUT
    if (!substates_done && o_timer_8ms == 1) begin
      o_train_error = 1;
      next_substate = CONFIG_HANDSHAKE;
    end else if (i_current_state == MBINIT_PARAM) begin
      case (current_substate)
        CONFIG_HANDSHAKE: begin
          // Output State Encoding — held while parent state is MBINIT_PARAM
          o_tx_encoding = 9'h10;
          o_tx_info = 0;  // added

          // Capability word sits in bits [15:0]; bits [63:16] are reserved (0)
          o_tx_data = {{(DATA_WIDTH - 16) {1'b0}}, r_local_cap};

          if (!substates_done) begin
            // TX Sending REQ Handshake
            if (done_ack) o_tx_sb_req = 0;
            else o_tx_sb_req = 1;

            // Next State Logic
            if (i_sb_tx_rsp && i_tx_decoding == 9'h10) o_done_mbinit_param_tx = 1;
          end
        end
      endcase
    end
  end

  // ==========================================================================
  // Assertions
  // ==========================================================================
  /*
`ifdef SIM

    // --------------------------------------------------------------------------
    // Encoding is 0x10 whenever we are in MBINIT_PARAM
    // --------------------------------------------------------------------------
    property encoding_config_handshake;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_PARAM && current_substate == CONFIG_HANDSHAKE)
        |-> o_tx_encoding == 9'h10;
    endproperty
    ENC_CONFIG_HANDSHAKE : assert property (encoding_config_handshake)
        else $error("ASSERT FAIL [ENC_CONFIG_HANDSHAKE]: wrong encoding in CONFIG_HANDSHAKE");

    // --------------------------------------------------------------------------
    // Capability word is driven correctly during CONFIG_HANDSHAKE
    // --------------------------------------------------------------------------
    // property cap_word_driven;
    //     @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
    //     (i_current_state == MBINIT_PARAM && current_substate == CONFIG_HANDSHAKE
    //      && !substates_done)
    //     |-> (o_tx_data[15:0] == LOCAL_CAP && o_tx_data[63:16] == '0);
    // endproperty
    // CAP_WORD_DRIVEN : assert property (cap_word_driven)
    //     else $error("ASSERT FAIL [CAP_WORD_DRIVEN]: o_tx_data capability word incorrect");

    // --------------------------------------------------------------------------
    // Train error asserted on 8ms timeout
    // --------------------------------------------------------------------------
    property timeout_sets_train_error;
        @(posedge i_clk) disable iff (i_reset)
        o_timer_8ms |-> o_train_error;
    endproperty
    TIMEOUT_TRAIN_ERROR : assert property (timeout_sets_train_error)
        else $error("ASSERT FAIL [TIMEOUT_TRAIN_ERROR]: train_error not set on 8ms timeout");

    property timeout_resets_substate;
        @(posedge i_clk) disable iff (i_reset)
        o_timer_8ms |=> current_substate == CONFIG_HANDSHAKE;
    endproperty
    TIMEOUT_RESETS_SUBSTATE : assert property (timeout_resets_substate)
        else $error("ASSERT FAIL [TIMEOUT_RESETS_SUBSTATE]: substate not reset after timeout");

    // --------------------------------------------------------------------------
    // done asserted when RSP arrives with correct decoding
    // --------------------------------------------------------------------------
    property done_on_rsp;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_PARAM &&
         current_substate == CONFIG_HANDSHAKE &&
         i_sb_tx_rsp && i_tx_decoding == 9'h10)
        |-> o_done_mbinit_param_tx;
    endproperty
    DONE_MBINIT_PARAM : assert property (done_on_rsp)
        else $error("ASSERT FAIL [DONE_MBINIT_PARAM]: done not asserted on RSP + correct decoding");

    // --------------------------------------------------------------------------
    // REQ handshake — raised when no done_ack, dropped when done_ack received
    // --------------------------------------------------------------------------
    property req_raised_when_needed;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_PARAM &&
         current_substate == CONFIG_HANDSHAKE &&
         !done_ack && !substates_done)
        |-> o_tx_sb_req;
    endproperty
    REQ_RAISED : assert property (req_raised_when_needed)
        else $error("ASSERT FAIL [REQ_RAISED]: tx_sb_req not asserted when handshake pending");

    property req_dropped_after_done_ack;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_PARAM &&
         current_substate == CONFIG_HANDSHAKE &&
         done_ack)
        |-> !o_tx_sb_req;
    endproperty
    REQ_DROPPED : assert property (req_dropped_after_done_ack)
        else $error("ASSERT FAIL [REQ_DROPPED]: tx_sb_req still high after done_ack received");

    // --------------------------------------------------------------------------
    // No done assertion outside MBINIT_PARAM state
    // --------------------------------------------------------------------------
    property done_only_in_state;
        @(posedge i_clk) disable iff (i_reset)
        i_current_state != MBINIT_PARAM |-> !o_done_mbinit_param_tx;
    endproperty
    DONE_ONLY_IN_STATE : assert property (done_only_in_state)
        else $error("ASSERT FAIL [DONE_ONLY_IN_STATE]: done asserted outside MBINIT_PARAM");

`endif
*/
endmodule
