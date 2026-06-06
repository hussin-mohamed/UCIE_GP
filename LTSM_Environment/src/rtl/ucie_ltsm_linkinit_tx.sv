`ifdef SIM
`timescale 1ns / 1ps
`endif

// =============================================================================
//  Module  : ucie_ltsm_linkinit_tx
//
//  Purpose : TX side of the LINKINIT state.
//            Performs the RDI bring-up handshake sequence so the Adapter can
//            transition the link from Reset to Active on RDI.
//
//  Sub-states (3-bit internal, all share encoding base 0x1xx):
//    CLK_REQ_HS   (0x100) — assert pl_clk_req + pl_inband_pres, wait for
//                           lp_clk_ack to rise then fall (full handshake).
//    WAKE_REQ_HS  (0x101) — respond to Adapter's lp_wake_req with pl_wake_ack,
//                           wait until lp_state_req == Active.
//    STATE_REQ_HS (0x102) — TX sends {LinkMgmt.RDI.Req.Active} sideband msg.
//                           REQ active until done_ack (i_sb_tx_done) latches;
//                           done fires when i_sb_tx_rsp + decoding=0x102.
//
//  RDI signal roles (see UCIe spec Table 10-1):
//    pl_clk_req  : PL→Adapter, request Adapter to ungate its clocks.
//    lp_clk_ack  : Adapter→PL, confirms clock ungating (async from Adapter).
//    pl_inband_pres : PL→Adapter, link training complete; stays asserted for
//                     the lifetime of link operation once raised.
//    lp_wake_req : Adapter→PL, request PL to ungate its clocks.
//    pl_wake_ack : PL→Adapter, confirms clock ungating (sync to lclk).
//    lp_state_req: Adapter→PL, requested RDI state change.
// =============================================================================

module ucie_ltsm_linkinit_tx (
    input logic i_clk,
    input logic i_reset,

    // RDI interface — inputs from Adapter
    input logic       i_lp_clk_ack,   // Adapter ack to pl_clk_req
    input logic       i_lp_wake_req,  // Adapter wake request
    input logic [3:0] i_lp_state_req, // Adapter state request

    // Sideband TX interface
    input logic [8:0] i_tx_decoding,  // far-end decoding seen on sideband
    input logic       i_sb_tx_req,    // sideband REQ input
    input logic       i_sb_tx_rsp,    // sideband RSP input (advances done)
    input logic       i_sb_tx_done,   // sideband done — latches done_ack

    // Control
    input logic [3:0] i_current_state,  // from ucie_ltsm_active_fsm
    input logic       o_timer_8ms,      // 8ms timeout (shared, from top)

    // TX encoding output
    output logic [8:0] o_tx_encoding,

    // Sideband TX outputs
    output logic o_tx_sb_req,
    output logic o_tx_sb_rsp,
    output logic o_tx_sb_done,

    // RDI outputs — to Adapter
    output logic o_pl_clk_req,      // request Adapter to ungate clocks
    output logic o_pl_inband_pres,  // link training done; stays 1
    output logic o_pl_wake_ack,     // PL ack to Adapter lp_wake_req

    // Status
    output logic o_train_error,
    output logic o_done_linkinit_tx
);

  // -------------------------------------------------------------------------
  // Localparams
  // -------------------------------------------------------------------------
  // Active FSM state that owns this sub-FSM
  localparam logic [3:0] LINKINIT = 4'b0000;

  // lp_state_req encoding for Active
  localparam logic [3:0] LP_STATE_ACTIVE = 4'b0001;

  // Sub-states
  localparam logic [2:0] CLK_REQ_HS = 3'b000;
  localparam logic [2:0] WAKE_REQ_HS = 3'b001;
  localparam logic [2:0] STATE_REQ_HS = 3'b010;

  // -------------------------------------------------------------------------
  // Internal registers
  // -------------------------------------------------------------------------
  logic [2:0] current_substate;
  logic [2:0] next_substate;
  logic       substates_done;
  logic       done_ack;
  logic       i_lp_wake_req_reg;
  // Tracks that lp_clk_ack has risen so we know when to de-assert pl_clk_req
  logic       clk_ack_seen;
  logic       sb_tx_rsp_d;


  always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) done_ack <= 0;
    else if (i_sb_tx_done) begin
      done_ack <= 1;
    end else if (i_sb_tx_rsp || i_sb_tx_req) begin
      done_ack <= 0;
    end
  end

  always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) sb_tx_rsp_d <= 1'b0;
    else sb_tx_rsp_d <= i_sb_tx_rsp;
  end

  // -------------------------------------------------------------------------
  // Sequential block — state, latches, flags
  // -------------------------------------------------------------------------
  always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
      current_substate  <= CLK_REQ_HS;
      substates_done    <= 1'b0;
      // done_ack          <= 1'b0;
      clk_ack_seen      <= 1'b0;
      i_lp_wake_req_reg <= 1'b0;
    end else if (i_current_state != LINKINIT) begin
      // Leaving LINKINIT — clear everything for a clean re-entry
      current_substate  <= CLK_REQ_HS;
      substates_done    <= 1'b0;
      // done_ack          <= 1'b0;
      clk_ack_seen      <= 1'b0;
      i_lp_wake_req_reg <= 1'b0;

    end else begin
      current_substate <= next_substate;

      // // done_ack handshake: set on i_sb_tx_done, clear on i_sb_tx_rsp
      // if (i_sb_tx_done) done_ack <= 1'b1;
      // else if (i_sb_tx_rsp) done_ack <= 1'b0;

      // clk_ack_seen: latch the rising edge of lp_clk_ack while in CLK_REQ_HS
      // so we can de-assert pl_clk_req and then wait for ack to fall
      if (current_substate == CLK_REQ_HS && i_lp_clk_ack) clk_ack_seen <= 1'b1;


      i_lp_wake_req_reg <= i_lp_wake_req;


      // substates_done: set once the final done fires; blocks case re-entry
      if (o_done_linkinit_tx) substates_done <= 1'b1;
    end
  end

  // -------------------------------------------------------------------------
  // Combinational block — next state and all outputs
  // -------------------------------------------------------------------------
  always_comb begin
    // Defaults
    next_substate      = current_substate;
    o_tx_encoding      = 9'h000;
    o_tx_sb_req        = 1'b0;
    o_tx_sb_rsp        = 1'b0;
    o_tx_sb_done       = 1'b0;
    o_pl_clk_req       = 1'b0;
    o_pl_inband_pres   = 1'b0;
    o_pl_wake_ack      = 1'b0;
    o_train_error      = 1'b0;
    o_done_linkinit_tx = 1'b0;

    if (i_current_state == LINKINIT) begin

      if (!substates_done && o_timer_8ms) begin
        // 8ms timeout — assert train error, restart from CLK_REQ_HS
        o_train_error = 1'b1;
        next_substate = CLK_REQ_HS;

      end else begin
        case (current_substate)

          // ----------------------------------------------------------
          // CLK_REQ_HS (0x100)
          //   Assert pl_clk_req and pl_inband_pres to initiate the
          //   pl_clk_req/lp_clk_ack handshake with the Adapter.
          //   Phase 1 : pl_clk_req = 1, wait for lp_clk_ack to rise
          //             (clk_ack_seen latches this in always_ff).
          //   Phase 2 : pl_clk_req = 0 (de-assert), wait for lp_clk_ack
          //             to fall, then advance to WAKE_REQ_HS.
          //   pl_inband_pres stays 1 from here for the lifetime of the link.
          // ----------------------------------------------------------
          CLK_REQ_HS: begin
            o_tx_encoding    = 9'h100;
            o_pl_inband_pres = 1'b1;
            if (!substates_done) begin
              // Assert pl_clk_req only until ack has been observed
              o_pl_clk_req = ~clk_ack_seen;
              // Advance once ack has risen then fallen (full 4-way HS done)
              if (clk_ack_seen && !i_lp_clk_ack) next_substate = WAKE_REQ_HS;
            end
          end

          // ----------------------------------------------------------
          // WAKE_REQ_HS (0x101)
          //   Adapter asserts lp_wake_req; PL responds with pl_wake_ack
          //   (synchronous to lclk — at least one cycle bubble is
          //   satisfied by the registered path above).
          //   Mirror lp_wake_req → pl_wake_ack so the ack naturally
          //   de-asserts after the req de-asserts (spec requirement).
          //   Advance when Adapter has set lp_state_req = Active.
          // ----------------------------------------------------------
          WAKE_REQ_HS: begin
            o_tx_encoding    = 9'h101;
            o_pl_inband_pres = 1'b1;
            if (!substates_done) begin
              o_pl_wake_ack = i_lp_wake_req_reg;  // mirrors req; deasserts after req
              if (i_lp_state_req == LP_STATE_ACTIVE && i_lp_wake_req_reg)
                next_substate = STATE_REQ_HS;
            end
          end

          // ----------------------------------------------------------
          // STATE_REQ_HS (0x102)
          //   TX sends {LinkMgmt.RDI.Req.Active} sideband message.
          //   o_tx_sb_req active until done_ack latches (i_sb_tx_done).
          //   Done fires when i_sb_tx_rsp arrives with decoding 0x102
          //   and done_ack is set (same pattern as all other HS states).
          // ----------------------------------------------------------
          STATE_REQ_HS: begin
            o_tx_encoding    = 9'h102;
            o_pl_inband_pres = 1'b1;
            if (!substates_done) begin
              // TX Sending REQ Handshake
              if (done_ack) begin
                o_tx_sb_req = 0;
              end else begin
                o_tx_sb_req = 1;
              end
              // Pulse done for one cycle on RSP detection.
              o_tx_sb_done = i_sb_tx_rsp && !sb_tx_rsp_d;
              if (i_sb_tx_rsp && i_tx_decoding == 9'h102) o_done_linkinit_tx = 1'b1;
            end
          end

          default: next_substate = CLK_REQ_HS;
        endcase
      end
    end
  end

endmodule