`define SIM 
module ucie_ltsm_rx_mbinit_param #(
    parameter DECODING_WIDTH = 9,
    parameter DATA_WIDTH     = 64,
    parameter INFO_WIDTH     = 16
) (
    input                      i_clk,
    input                      i_reset,
    input [DECODING_WIDTH-1:0] i_rx_decoding,
    input [    DATA_WIDTH-1:0] i_rx_data,
    input [    INFO_WIDTH-1:0] i_rx_info,
    input                      i_sb_rx_req,
    input                      i_sb_rx_rsp,
    input                      i_sb_rx_done,
    input                      i_rx_done,
    input                      init_train_en,
    input [               3:0] i_current_state,
    input                      o_timer_8ms,

    output logic [DECODING_WIDTH-1:0] o_rx_encoding,
    output logic [    DATA_WIDTH-1:0] o_rx_data,
    output logic [    INFO_WIDTH-1:0] o_rx_info,
    output logic                      o_rx_sb_req,
    output logic                      o_rx_sb_rsp,
    output logic                      o_rx_sb_done,
    output logic                      o_train_error,
    output logic                      o_done_mbinit_param_rx
);

  // -------------------------------------------------------------------------
  // Local parameters
  // -------------------------------------------------------------------------
  localparam logic [3:0] MBINIT_PARAM = 4'b0010;

  localparam logic [2:0] WAIT_CONFIG_REQ = 3'b000;
  localparam logic [2:0] CHECK_PARAMETERS = 3'b001;

  // -------------------------------------------------------------------------
  // Local max-speed capability register
  //   Holds the maximum IO link speed this module supports.
  //   Encoding matches UCIe spec "Max Link Speeds" table:
  //     4'b0101 = 5 = 32 GT/s
  // -------------------------------------------------------------------------
  localparam logic [3:0] LOCAL_MAX_SPEED = 4'b0101;  // 32 GT/s

  logic [3:0] r_local_max_speed;  // read-only after reset

  // Fix: Prevent r_local_max_speed from being inferred as a latch.
  //   // Assign it on reset, and assign it explicitly otherwise (hold value).
  //   always_ff @(posedge i_clk or posedge i_reset) begin
  //     if (i_reset) r_local_max_speed <= LOCAL_MAX_SPEED;
  //     else r_local_max_speed <= r_local_max_speed;
  //     // Read-only capability; never changes after reset
  //   end

  assign r_local_max_speed = LOCAL_MAX_SPEED;

  // -------------------------------------------------------------------------
  // Internal signals
  // -------------------------------------------------------------------------
  logic [           2:0] current_substate;
  logic [           2:0] next_substate;
  logic                  done_ack;
  logic                  substates_done;

  logic [DATA_WIDTH-1:0] i_rx_data_reg;

  // -------------------------------------------------------------------------
  // Common speed — minimum of partner advertised speed and our local max
  // The spec requires the responding module to pick the common (lower) value.
  // -------------------------------------------------------------------------
  logic [           3:0] w_common_speed;
  assign w_common_speed = (i_rx_data_reg[3:0] < r_local_max_speed)
                            ? i_rx_data_reg[3:0]
                            : r_local_max_speed;

  // -------------------------------------------------------------------------
  // State memory
  // -------------------------------------------------------------------------
  always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
      current_substate <= WAIT_CONFIG_REQ;
      substates_done   <= 0;
      i_rx_data_reg    <= '0;
    end else if (i_current_state != MBINIT_PARAM) begin
      current_substate <= WAIT_CONFIG_REQ;
      substates_done   <= 0;
      i_rx_data_reg    <= '0;
    end else begin
      // Park in CHECK_PARAMETERS when response is accepted so encoding/data
      // stay visible until parent MBINIT_PARAM exits (partner may still be finishing).
      if (current_substate == CHECK_PARAMETERS && i_sb_rx_done) begin
        substates_done   <= 1;
        current_substate <= CHECK_PARAMETERS;
      end else begin
        current_substate <= next_substate;
        // Latch rx_data when config REQ arrives so it is stable during CHECK
        if (current_substate == WAIT_CONFIG_REQ && i_sb_rx_req && i_rx_decoding == 9'h10)
          i_rx_data_reg <= i_rx_data;
      end
    end
  end

  // -------------------------------------------------------------------------
  // RSP / Done handshake register
  // done_ack latches when i_sb_rx_done (our RSP accepted by sideband)
  // clears when new i_sb_rx_req arrives
  // -------------------------------------------------------------------------
  always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) done_ack <= 0;
    else if (i_sb_rx_done) done_ack <= 1;
    else if (i_sb_rx_req) done_ack <= 0;
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

    if (!substates_done && o_timer_8ms) begin
      o_train_error = 1;
      next_substate = WAIT_CONFIG_REQ;
    end else if (i_current_state == MBINIT_PARAM) begin
      case (current_substate)

        // --------------------------------------------------------------
        // WAIT_CONFIG_REQ
        // Wait for TX CONFIG_HANDSHAKE REQ (encoding 0x10).
        // Acknowledge with o_rx_sb_done; latch i_rx_data in always_ff.
        // --------------------------------------------------------------
        WAIT_CONFIG_REQ: begin  // i need a response here
          o_rx_encoding = 9'h10;

          if (!substates_done) begin
            if (i_sb_rx_req && i_rx_decoding == 9'h10) begin
              o_rx_sb_done  = 1;

              next_substate = CHECK_PARAMETERS;
            end else begin
              next_substate = WAIT_CONFIG_REQ;
            end
          end
        end

        // --------------------------------------------------------------
        // CHECK_PARAMETERS
        // Compare partner's max speed (i_rx_data_reg[3:0]) with our
        // local max speed, pick the lower common value, and return it
        // in the response data field [3:0].
        //
        // Response data layout (MBINIT.PARAM configuration resp):
        //   [63:16] : Reserved → 0
        //   [15]    : TARR negotiated     → 0
        //   [14]    : SB feature ext.     → 0
        //   [13:11] : Reserved            → 0
        //   [10]    : Clock Phase          → 0
        //   [9]     : Clock Mode           → 0
        //   [8:4]   : Reserved            → 0
        //   [3:0]   : Max IO Link Speed   → w_common_speed
        // --------------------------------------------------------------
        CHECK_PARAMETERS: begin
          o_rx_encoding = 9'h11;  // 2nd error

          // Build response: only [3:0] carries the negotiated speed
          o_rx_data = {{(DATA_WIDTH - 4) {1'b0}}, w_common_speed};

          if (!substates_done) begin
            o_rx_sb_rsp = done_ack ? 0 : 1;

            if (i_sb_rx_done) begin
              o_done_mbinit_param_rx = 1;
              next_substate          = WAIT_CONFIG_REQ;
            end else next_substate = CHECK_PARAMETERS;
          end else next_substate = CHECK_PARAMETERS;
        end

        default: next_substate = WAIT_CONFIG_REQ;

      endcase
    end
  end

  // =========================================================================
  // Assertions
  // =========================================================================
  /*
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

    // --------------------------------------------------------------------------
    // Common speed in o_rx_data must equal min(partner speed, local max speed)
    // when in CHECK_PARAMETERS
    // --------------------------------------------------------------------------
    property common_speed_correct;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_PARAM && current_substate == CHECK_PARAMETERS
         && !substates_done)
        |-> (o_rx_data[3:0] == w_common_speed && o_rx_data[63:4] == '0);
    endproperty
    COMMON_SPEED_CORRECT : assert property (common_speed_correct)
        else $error("ASSERT FAIL [COMMON_SPEED_CORRECT]: o_rx_data negotiated speed incorrect");

    property done_only_in_state;
        @(posedge i_clk) disable iff (i_reset)
        i_current_state != MBINIT_PARAM |-> !o_done_mbinit_param_rx;
    endproperty
    DONE_ONLY_IN_STATE : assert property (done_only_in_state)
        else $error("ASSERT FAIL [DONE_ONLY_IN_STATE]: done asserted outside MBINIT_PARAM");

`endif
*/
endmodule
