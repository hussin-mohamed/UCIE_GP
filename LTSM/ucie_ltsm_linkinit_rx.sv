`ifdef SIM
`timescale 1ns / 1ps
`endif

// =============================================================================
//  Module  : ucie_ltsm_linkinit_rx
//
//  Purpose : RX side of the LINKINIT state.
//            Mirrors the TX RDI bring-up handshake sequence.  RX tracks the
//            same RDI inputs as TX for phasing (CLK_REQ and WAKE_REQ share
//            physical RDI wires), then handles the sideband RSP for the
//            Active state request/response exchange.
//
//  Sub-states (3-bit internal, all share encoding base 0x1xx):
//    CLK_REQ_HS   (0x100) — track lp_clk_ack, wait for full handshake to
//                           complete (RDI signals are shared with TX).
//    WAKE_REQ_HS  (0x101) — track lp_wake_req / lp_state_req, advance when
//                           lp_state_req == Active.
//    STATE_RSP_HS (0x102) — RX sends {LinkMgmt.RDI.Rsp.Active} sideband msg.
//                           Asserts o_rx_sb_rsp; done when i_sb_rx_done fires.
//
//  Note: pl_clk_req, pl_inband_pres, and pl_wake_ack are physical PL→Adapter
//        signals driven by ucie_ltsm_linkinit_tx (single logical driver).
//        RX tracks the same RDI inputs only for sub-state sequencing.
// =============================================================================

module ucie_ltsm_linkinit_rx (
    input logic i_clk,
    input logic i_reset,

    // RDI interface — inputs from Adapter (shared with TX path)
    input logic       i_lp_clk_ack,   // Adapter ack to pl_clk_req
    input logic       i_lp_wake_req,  // Adapter wake request
    input logic [3:0] i_lp_state_req, // Adapter state request

    // Sideband RX interface
    input logic [8:0] i_rx_decoding,  // far-end decoding seen on sideband
    input logic       i_sb_rx_req,    // sideband REQ input
    input logic       i_sb_rx_rsp,    // sideband RSP input
    input logic       i_sb_rx_done,   // sideband done — fires when RSP sent

    // Control
    input logic [3:0] i_current_state,  // from ucie_ltsm_active_fsm
    input logic       o_timer_8ms,      // 8ms timeout (shared, from top)

    // RX encoding output
    output logic [8:0] o_rx_encoding,

    // Sideband RX outputs
    output logic o_rx_sb_req,
    output logic o_rx_sb_rsp,
    output logic o_rx_sb_done,

    // Status
    output logic o_train_error,
    output logic o_done_linkinit_rx
);

  // -------------------------------------------------------------------------
  // Localparams
  // -------------------------------------------------------------------------
  localparam logic [3:0] LINKINIT = 4'b0000;
  localparam logic [3:0] LP_STATE_ACTIVE = 4'b0001;

  localparam logic [2:0] CLK_REQ_HS = 3'b000;
  localparam logic [2:0] WAKE_REQ_HS = 3'b001;
  localparam logic [2:0] STATE_RSP_HS = 3'b010;

  // -------------------------------------------------------------------------
  // Internal registers
  // -------------------------------------------------------------------------
  logic [2:0] current_substate;
  logic [2:0] next_substate;
  logic       substates_done;
  logic       clk_ack_seen;  // mirrors TX tracking; same RDI ack wire
  logic       done_ack;
  logic       sb_rx_req_d;


  always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) done_ack <= 1;
    else if (i_sb_rx_done) done_ack <= 1;
    else if (i_sb_rx_req) done_ack <= 0;
  end

  always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) sb_rx_req_d <= 1'b0;
    else sb_rx_req_d <= i_sb_rx_req;
  end
  // -------------------------------------------------------------------------
  // Sequential block
  // -------------------------------------------------------------------------
  always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
      current_substate <= CLK_REQ_HS;
      substates_done   <= 1'b0;
      clk_ack_seen     <= 1'b0;
    end else if (i_current_state != LINKINIT) begin
      current_substate <= CLK_REQ_HS;
      substates_done   <= 1'b0;
      clk_ack_seen     <= 1'b0;
    end else begin
      current_substate <= next_substate;

      // clk_ack_seen: track same lp_clk_ack rising edge as TX
      if (current_substate == CLK_REQ_HS && i_lp_clk_ack) clk_ack_seen <= 1'b1;

      if (o_done_linkinit_rx) substates_done <= 1'b1;
    end
  end

  // -------------------------------------------------------------------------
  // Combinational block
  // -------------------------------------------------------------------------
  always_comb begin
    next_substate      = current_substate;
    o_rx_encoding      = 9'h000;
    o_rx_sb_req        = 1'b0;
    o_rx_sb_rsp        = 1'b0;
    o_rx_sb_done       = 1'b0;
    o_train_error      = 1'b0;
    o_done_linkinit_rx = 1'b0;

    if (i_current_state == LINKINIT) begin

      if (!substates_done && o_timer_8ms) begin
        o_train_error = 1'b1;
        next_substate = CLK_REQ_HS;

      end else begin
        case (current_substate)

          // ----------------------------------------------------------
          // CLK_REQ_HS (0x100)
          //   Track the pl_clk_req/lp_clk_ack handshake progress via
          //   the shared lp_clk_ack input (RDI signal is a single wire;
          //   TX drives pl_clk_req).  Advance when ack has risen and
          //   then fallen (same condition as TX so both advance together).
          // ----------------------------------------------------------
          CLK_REQ_HS: begin
            o_rx_encoding = 9'h100;
            if (!substates_done) begin
              if (clk_ack_seen && !i_lp_clk_ack) next_substate = WAKE_REQ_HS;
            end
          end

          // ----------------------------------------------------------
          // WAKE_REQ_HS (0x101)
          //   Track lp_state_req.  Advance when Adapter has set
          //   lp_state_req = Active (same condition as TX).
          // ----------------------------------------------------------
          WAKE_REQ_HS: begin
            o_rx_encoding = 9'h101;
            if (!substates_done) begin
              if (i_lp_state_req == LP_STATE_ACTIVE) next_substate = STATE_RSP_HS;
            end
          end

          // ----------------------------------------------------------
          // STATE_RSP_HS (0x102)
          //   RX responds to TX's {LinkMgmt.RDI.Req.Active} with
          //   {LinkMgmt.RDI.Rsp.Active} sideband message.
          //   Assert o_rx_sb_rsp; done fires when i_sb_rx_done confirms
          //   the sideband layer has transmitted the RSP message.
          // ----------------------------------------------------------
          STATE_RSP_HS: begin
            o_rx_encoding = 9'h102;
            if (!substates_done) begin
              o_rx_sb_rsp  = done_ack ? 0 : 1;
              // Pulse done for one cycle on REQ detection.
              o_rx_sb_done = i_sb_rx_req && !sb_rx_req_d;
              if (i_sb_rx_done) o_done_linkinit_rx = 1'b1;
            end
          end

          default: next_substate = CLK_REQ_HS;
        endcase
      end
    end
  end

endmodule