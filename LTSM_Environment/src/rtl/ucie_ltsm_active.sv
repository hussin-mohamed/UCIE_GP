`ifdef SIM
`endif
 
// =============================================================================
//  Module  : ucie_ltsm_active
//
//  Purpose : Monitors the RDI interface while the link is in normal operation
//            (ACTIVE or ACTIVE_PMNAK state) and signals the top-level active
//            FSM when a state transition is requested by the Adapter.
//
//  ACTIVE state rules (UCIe spec §10.3.3.2):
//    ? Retrain   : lp_state_req == Retrain  (allowed in both ACTIVE and PMNAK)
//    ? L1        : lp_state_req == L1       (ACTIVE only; ignored in PMNAK)
//    ? LinkReset : lp_state_req == LinkReset (allowed in both)
//    ? LinkError : lp_linkerror == 1         (highest priority; both states)
//    L2 is not supported by this implementation.
//
//  ACTIVE_PMNAK: entered when returning from L1 with a PMNAK response.
//    Identical to ACTIVE except L1 state change requests are silently ignored
//    (spec: no scenario where PMNAK ? L1 is allowed).
//
//  pl_state_sts encodings (PL ? Adapter, UCIe spec Table 10-1):
//    0001b : Active
//    0011b : Active.PMNAK
//
//  This module is purely combinational.  The top-level ucie_ltsm_active_fsm
//  owns the state register and drives i_current_state; this module decodes it
//  and produces the appropriate outputs without any additional flip-flops.
// =============================================================================

module ucie_ltsm_active (
    input  logic        i_clk,          // unused; kept for consistency
    input  logic        i_reset,        // unused; kept for consistency

    // RDI interface — inputs from Adapter
    input  logic [3:0]  i_lp_state_req, // Adapter state change request
    input  logic        i_lp_linkerror, // Adapter link error indication
    input  logic        valid_error, // Adapter link error indication

    input  logic        i_sb_rx_req, // Adapter link error indication
    input  logic [8:0]  i_rx_decoding, // Adapter link error indication
    input  logic        o_timer_2us,

    // Control
    input  logic [3:0]  i_current_state, // from ucie_ltsm_active_fsm

    // RDI outputs — to Adapter
    output logic [3:0]  o_pl_state_sts,  // Physical Layer status indication
    output logic        o_pl_inband_pres, // Stays 1 for lifetime of link operation

    // Transition done flags (one-hot; asserted combinationally)
    output logic [8:0]  o_tx_sb_encoding,
    output logic [8:0]  o_rx_sb_encoding,
    output logic        o_done_active_retrain,
    output logic        o_done_active_l1_tx,
    output logic        o_done_active_l1_rx,
    output logic        o_done_active_linkreset,
    output logic        o_done_active_linkerror
);

    // -------------------------------------------------------------------------
    // Localparams
    // -------------------------------------------------------------------------
    // Active FSM states that this module handles
    localparam logic [3:0] ACTIVE       = 4'b0001;
    localparam logic [3:0] L1           = 4'b0011;
    localparam logic [3:0] ACTIVE_PMNAK = 4'b0010;

    // lp_state_req encodings (UCIe spec Table 10-1)
    localparam logic [3:0] LP_REQ_NOP       = 4'b0000;
    localparam logic [3:0] LP_REQ_ACTIVE    = 4'b0001;
    localparam logic [3:0] LP_REQ_L1        = 4'b0100;
    localparam logic [3:0] LP_REQ_L2        = 4'b1000; // not supported
    localparam logic [3:0] LP_REQ_LINKRESET = 4'b1001;
    localparam logic [3:0] LP_REQ_RETRAIN   = 4'b1011;

    // pl_state_sts encodings (UCIe spec Table 10-1)
    localparam logic [3:0] PL_STS_RESET  = 4'b0000;
    localparam logic [3:0] PL_STS_ACTIVE = 4'b0001;
    localparam logic [3:0] PL_STS_PMNAK  = 4'b0011;

    logic o_done_active_retrain_rdi;

    logic i_timer_2us_reg;
    logic o_done_active_l1_rx_old;

    // Logic for latching the 2us timer signal pulse
    always @(posedge i_clk or posedge i_reset) begin
        if(i_reset) begin 
            i_timer_2us_reg <= 0;
        end else if (i_current_state != ACTIVE_PMNAK) begin
            i_timer_2us_reg <= 0;
	end
	 else if(i_current_state == ACTIVE_PMNAK) begin 
            // latch the timer when reaching 2us
            if(o_timer_2us == 1)
                i_timer_2us_reg <= 1;

        end 
    end


    // -------------------------------------------------------------------------
    // Purely combinational output logic
    // -------------------------------------------------------------------------
    always_comb begin
            o_pl_state_sts          = PL_STS_RESET;
            o_pl_inband_pres        = 1'b0;
            o_done_active_retrain   = 1'b0;
            o_done_active_l1_tx     = 1'b0;
            o_done_active_l1_rx     = 1'b0;
            o_done_active_linkreset = 1'b0;
	    o_tx_sb_encoding = 0;
            o_rx_sb_encoding = 0;
            o_done_active_linkerror = 1'b0;
            o_done_active_retrain_rdi = 1'b0;
            if (i_current_state == ACTIVE || i_current_state == ACTIVE_PMNAK) begin

            // pl_inband_pres stays 1 for the entire lifetime of link operation
            o_pl_inband_pres = 1'b1;
            o_tx_sb_encoding      = 9'h108;
            o_rx_sb_encoding      = 9'h108;
            o_done_active_retrain = o_done_active_retrain_rdi || valid_error || (i_sb_rx_req && i_rx_decoding == 'hD8);
            o_done_active_l1_rx = o_done_active_l1_tx || (i_sb_rx_req && i_rx_decoding == 'h110);

            // Reflect current state to Adapter via pl_state_sts
            o_pl_state_sts = (i_current_state == ACTIVE_PMNAK) ? PL_STS_PMNAK
                                                                : PL_STS_ACTIVE;

            // lp_linkerror has highest priority (immediate action required)
            if (i_lp_linkerror) begin
                o_done_active_linkerror = 1'b1;
            end else begin
                case (i_lp_state_req)

                    LP_REQ_RETRAIN: begin
                        // Retrain is valid from both ACTIVE and ACTIVE_PMNAK
                        o_done_active_retrain_rdi = 1'b1;
                    end

                    LP_REQ_LINKRESET: begin
                        // LinkReset is valid from both ACTIVE and ACTIVE_PMNAK
                        o_done_active_linkreset = 1'b1;
                    end

                    LP_REQ_L1: begin
                        if (i_current_state == ACTIVE || (i_current_state == ACTIVE_PMNAK && i_timer_2us_reg)) begin
                            o_done_active_l1_tx = 1'b1;
                        end else begin
                            // L1 request is ignored in ACTIVE_PMNAK until 2us timer expires
                            o_done_active_l1_tx = 1'b0;
                        end
                    end

                    default: begin
                    end
                endcase
            end
            end else if (i_current_state == L1 && i_lp_state_req == LP_REQ_L1) begin
                o_done_active_l1_tx        = 1'b1;
                o_done_active_l1_rx       = (i_sb_rx_req && i_rx_decoding == 'h110) || o_done_active_l1_rx_old;
            end else if (i_current_state == 4'b1111) begin
                o_pl_state_sts          = PL_STS_RESET;
                o_pl_inband_pres        = 1'b0;
                o_done_active_retrain   = 1'b0;
                o_done_active_l1_tx        = 1'b0;
                o_done_active_l1_rx        = 1'b0;
                o_done_active_linkreset = 1'b0;
                o_done_active_linkerror = 1'b0;
                o_done_active_retrain_rdi = 1'b0;
            end 
    end



always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        o_done_active_l1_rx_old <= 0;
    end else begin
        o_done_active_l1_rx_old <= o_done_active_l1_rx;
    end
end


endmodule