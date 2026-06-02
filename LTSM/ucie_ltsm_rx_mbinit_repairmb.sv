`define SIM 
module ucie_ltsm_rx_mbinit_repairmb #(
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
    input [               7:0] i_rx_sweep_result,

    output logic [DECODING_WIDTH-1:0] o_rx_encoding,
    output logic [    DATA_WIDTH-1:0] o_rx_data,
    output logic [    INFO_WIDTH-1:0] o_rx_info,
    output logic                      o_rx_sb_req,
    output logic                      o_rx_sb_rsp,
    output logic                      o_rx_sb_done,
    output logic [               2:0] r_lane_map,
    output logic                      o_train_error,
    output logic                      o_done_mbinit_repairmb_rx
);

  localparam logic [3:0] MBINIT_REPAIRMB = 4'b0111;

  localparam logic [2:0] INIT_HANDSHAKE = 3'b000;
  localparam logic [2:0] DATA_TO_CLOCK_TEST = 3'b001;
  localparam logic [2:0] WAIT_FOR_DEGRADE_REQ = 3'b010;
  localparam logic [2:0] DEGRADE = 3'b011;
  localparam logic [2:0] SEND_RESP = 3'b100;
  localparam logic [2:0] DONE_HANDSHAKE = 3'b101;

  localparam logic [2:0] DEGRADE_NOT_POSSIBLE = 3'b000;
  localparam logic [2:0] LANES_0_TO_7 = 3'b001;
  localparam logic [2:0] LANES_8_TO_15 = 3'b010;
  localparam logic [2:0] ALL_LANES_FUNCTIONAL = 3'b011;

  logic [               2:0] current_substate;
  logic [               2:0] next_substate;
  logic                      done_ack;
  logic                      substates_done;

  logic                      clock_to_test_enable;
  logic                      clock_to_test_done;

  logic [DECODING_WIDTH-1:0] o_rx_encoding_sweep;
  logic [    DATA_WIDTH-1:0] o_rx_data_sweep;
  logic [    INFO_WIDTH-1:0] o_rx_info_sweep;
  logic [               7:0] o_rx_sweep_result;
  logic                      o_rx_sb_req_sweep;
  logic                      o_rx_sb_rsp_sweep;
  logic                      train_error_sweep;
  logic                      failed_test_sweep;

  // r_lane_map: current accepted lane configuration, init ALL_LANES_FUNCTIONAL.
  // Updated when TX sends a degrade REQ with a different map in i_rx_info[2:0].
  // logic [               2:0] r_lane_map;
  // w_extracted_lane_map: combinational � TX's requested lane map.
  logic [               2:0] w_extracted_lane_map;

  logic                      r_eye_sweep_reset;

  assign w_extracted_lane_map = i_rx_info[2:0];

  ucie_RX_Data_to_Clock_eye_sweep ucie_RX_Data_to_Clock_eye_sweep_inst (
      .i_clk            (i_clk),
      .i_reset          (r_eye_sweep_reset),
      .i_xx_decoding    (i_rx_decoding),
      .i_xx_data        (i_rx_data),
      .i_sb_xx_req      (i_sb_rx_req),
      .i_sb_xx_rsp      (i_sb_rx_rsp),
      .i_sb_xx_done     (i_sb_rx_done),
      .i_xx_done        (i_rx_done),
      .i_xx_info        (i_rx_info),
      .valid_result     (1'b1),
      .comparison_type  (0),
      .done_ack         (done_ack),
      .init             (1'b0),
      .no_retry         (1'b1),
      .data_result      ({56'h0, i_rx_sweep_result}),
      .o_xx_encoding    (o_rx_encoding_sweep),
      .o_xx_data        (o_rx_data_sweep),
      .o_xx_info        (o_rx_info_sweep),
      .o_xx_sweep_result(o_rx_sweep_result),
      .o_xx_sb_req      (o_rx_sb_req_sweep),
      .o_xx_sb_rsp      (o_rx_sb_rsp_sweep),
      .train_error      (train_error_sweep),
      .failed_test      (failed_test_sweep),
      .done             (clock_to_test_done)
  );

  always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) r_eye_sweep_reset <= 1'b1;
    else r_eye_sweep_reset <= !clock_to_test_enable;
  end


  always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
      current_substate <= INIT_HANDSHAKE;
      substates_done   <= 0;
      r_lane_map       <= ALL_LANES_FUNCTIONAL;
    end else if (i_current_state != MBINIT_REPAIRMB) begin
      current_substate <= INIT_HANDSHAKE;
      substates_done   <= 0;
      r_lane_map       <= ALL_LANES_FUNCTIONAL;
    end else begin
      if (current_substate == DONE_HANDSHAKE && i_sb_rx_req && i_rx_decoding == 9'h3B) begin
        substates_done   <= 1;
        current_substate <= DONE_HANDSHAKE;
      end else begin
        current_substate <= next_substate;

        // Update local lane map when TX requests a different configuration
        if (current_substate == WAIT_FOR_DEGRADE_REQ &&
                    i_sb_rx_req && i_rx_decoding == 9'h3A &&
                    w_extracted_lane_map != r_lane_map)
          r_lane_map <= w_extracted_lane_map;
      end
    end
  end

  always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) done_ack <= 1;
    else if (i_sb_rx_done) done_ack <= 1;
    else if (i_sb_rx_req && (i_rx_decoding == 9'h38 || i_rx_decoding == 9'h3C || i_rx_decoding == 9'h3D))
      done_ack <= 0;
  end

  always_comb begin
    o_rx_sb_rsp = done_ack ? 0 : 1;
  end

  always_comb begin
    o_rx_encoding             = 9'h38;
    o_rx_data                 = '0;
    o_rx_info                 = '0;
    o_rx_sb_req               = 0;
    o_rx_sb_rsp               = 0;
    o_rx_sb_done              = 0;
    o_train_error             = 0;
    o_done_mbinit_repairmb_rx = 0;
    next_substate             = DONE_HANDSHAKE;
    clock_to_test_enable      = 0;

    if (!substates_done && (o_timer_8ms || train_error_sweep)) begin
      o_train_error = 1;
      next_substate = INIT_HANDSHAKE;
    end else if (i_current_state == MBINIT_REPAIRMB) begin
      case (current_substate)

        INIT_HANDSHAKE: begin
          o_rx_encoding = 9'h38;
          if (!substates_done) begin
            o_rx_sb_rsp = ~done_ack;
            if (i_sb_rx_req && i_rx_decoding == 9'h38) begin
              clock_to_test_enable = 1;
              next_substate        = DATA_TO_CLOCK_TEST;
            end else next_substate = INIT_HANDSHAKE;
          end
        end

        DATA_TO_CLOCK_TEST: begin
          clock_to_test_enable = 1;
          o_rx_encoding        = o_rx_encoding_sweep;
          o_rx_data            = o_rx_data_sweep;
          o_rx_info            = o_rx_info_sweep;
          o_rx_sb_req          = o_rx_sb_req_sweep;
          o_rx_sb_rsp          = o_rx_sb_rsp_sweep;
          if (!substates_done) begin
            if (clock_to_test_done) next_substate = WAIT_FOR_DEGRADE_REQ;
            else next_substate = DATA_TO_CLOCK_TEST;
          end
        end

        WAIT_FOR_DEGRADE_REQ: begin
          o_rx_encoding = 9'h3A;
          if (!substates_done) begin
            if (i_sb_rx_req && i_rx_decoding == 9'h3C) begin
              if (w_extracted_lane_map == r_lane_map) next_substate = SEND_RESP;
              else next_substate = DEGRADE;
            end else next_substate = WAIT_FOR_DEGRADE_REQ;
          end
        end

        DEGRADE: begin
          o_rx_encoding = 9'h3B;
          if (!substates_done) begin
            if (i_rx_done) next_substate = DATA_TO_CLOCK_TEST;
            else next_substate = DEGRADE;
          end
        end

        SEND_RESP: begin
          o_rx_encoding = 9'h3C;
          if (!substates_done) begin
            o_rx_sb_rsp = 1'b1;
            if (i_sb_rx_done) next_substate = DONE_HANDSHAKE;
            else next_substate = SEND_RESP;
          end else next_substate = SEND_RESP;
        end

        DONE_HANDSHAKE: begin
          o_rx_encoding = 9'h3D;
          if (!substates_done) begin
            o_rx_sb_rsp = ~done_ack;
            if (i_sb_rx_req && i_rx_decoding == 9'h3D) begin
              o_done_mbinit_repairmb_rx = 1;
              next_substate             = DONE_HANDSHAKE;
            end else next_substate = DONE_HANDSHAKE;
          end
        end

        default: next_substate = INIT_HANDSHAKE;
      endcase
    end
  end
  /*
`ifdef SIM

    property enc_check(substate, logic [8:0] enc);
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms || train_error_sweep)
        (i_current_state == MBINIT_REPAIRMB && current_substate == substate)
        |-> o_rx_encoding == enc;
    endproperty

    ENC_INIT_HANDSHAKE       : assert property (enc_check(INIT_HANDSHAKE,       9'h38)) else $error("ASSERT FAIL [ENC_INIT_HANDSHAKE]");
    ENC_WAIT_FOR_DEGRADE_REQ : assert property (enc_check(WAIT_FOR_DEGRADE_REQ, 9'h3A)) else $error("ASSERT FAIL [ENC_WAIT_FOR_DEGRADE_REQ]");
    ENC_DEGRADE              : assert property (enc_check(DEGRADE,              9'h3A)) else $error("ASSERT FAIL [ENC_DEGRADE]");
    ENC_SEND_RESP            : assert property (enc_check(SEND_RESP,            9'h3A)) else $error("ASSERT FAIL [ENC_SEND_RESP]");
    ENC_DONE_HANDSHAKE       : assert property (enc_check(DONE_HANDSHAKE,       9'h3B)) else $error("ASSERT FAIL [ENC_DONE_HANDSHAKE]");

    property timeout_error;
        @(posedge i_clk) disable iff (i_reset)
        (o_timer_8ms || train_error_sweep) |-> o_train_error;
    endproperty
    TIMEOUT_TRAIN_ERROR : assert property (timeout_error) else $error("ASSERT FAIL [TIMEOUT_TRAIN_ERROR]");

    property timeout_reset_sub;
        @(posedge i_clk) disable iff (i_reset)
        (o_timer_8ms || train_error_sweep) |=> current_substate == INIT_HANDSHAKE;
    endproperty
    TIMEOUT_RESETS_SUBSTATE : assert property (timeout_reset_sub) else $error("ASSERT FAIL [TIMEOUT_RESETS_SUBSTATE]");

    property match_to_send_resp;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRMB && current_substate == WAIT_FOR_DEGRADE_REQ &&
         i_sb_rx_req && i_rx_decoding == 9'h3A && w_extracted_lane_map == r_lane_map)
        |=> current_substate == SEND_RESP;
    endproperty
    MATCH_TO_SEND_RESP : assert property (match_to_send_resp) else $error("ASSERT FAIL [MATCH_TO_SEND_RESP]");

    property mismatch_to_degrade;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRMB && current_substate == WAIT_FOR_DEGRADE_REQ &&
         i_sb_rx_req && i_rx_decoding == 9'h3A && w_extracted_lane_map != r_lane_map)
        |=> current_substate == DEGRADE;
    endproperty
    MISMATCH_TO_DEGRADE : assert property (mismatch_to_degrade) else $error("ASSERT FAIL [MISMATCH_TO_DEGRADE]");

    property degrade_reruns_sweep;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRMB && current_substate == DEGRADE && i_rx_done)
        |=> current_substate == DATA_TO_CLOCK_TEST;
    endproperty
    DEGRADE_RERUNS : assert property (degrade_reruns_sweep) else $error("ASSERT FAIL [DEGRADE_RERUNS]");

    property done_on_req;
        @(posedge i_clk) disable iff (i_reset || o_timer_8ms)
        (i_current_state == MBINIT_REPAIRMB && current_substate == DONE_HANDSHAKE &&
         i_sb_rx_req && i_rx_decoding == 9'h3B)
        |-> o_done_mbinit_repairmb_rx;
    endproperty
    DONE_REPAIRMB_RX : assert property (done_on_req) else $error("ASSERT FAIL [DONE_REPAIRMB_RX]");

    property done_only_in_state;
        @(posedge i_clk) disable iff (i_reset)
        i_current_state != MBINIT_REPAIRMB |-> !o_done_mbinit_repairmb_rx;
    endproperty
    DONE_ONLY_IN_STATE : assert property (done_only_in_state) else $error("ASSERT FAIL [DONE_ONLY_IN_STATE]");

`endif
*/
endmodule
