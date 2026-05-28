// =============================================================================
// TX Controller Reference Model — Static Task (for scoreboard use)
// UCIe 3.0 Physical Layer — Tx Controller FDS v1
//
// Packaged as a static task to be called once per clock cycle from a
// scoreboard.  Internal state (parent context, done counter) is kept in
// static variables that persist across calls.
//
// Usage:
//   import tx_controller_modelling_pkg::*;
//   // call once per posedge clk:
//   tx_controller_modelling(!i_reset, i_tx_encoding, i_lane_map_code,
//                           o_tx_lfsr_enable, o_tx_lfsr_load, o_tx_lfsr_train,
//                           o_per_lane_id_gen_enable, o_tx_reverse, o_tx_done);
//
// SPEC-vs-TABLE CONTRADICTIONS (spec takes priority):
//
//   [C1] Done-cycle counts — spec §4.2.2 gives cycle counts in small integers;
//        the HTML table gives counts as N×128 clock-cycles.  These are
//        inconsistent.  Values used here follow the spec text literally
//        (clock cycles = the spec integer):
//          REPAIRCLK  (0x021): spec 48   vs table (16+8)×128 = 3072
//          REPAIRVAL  (0x029): spec 16   vs table (4+4)×128  = 1024
//          REVERSALMB (0x032): spec 32   vs table 128
//          REPAIRMB   (0x182/ctx=REPAIRMB): spec 32 vs table 128
//          LFSR pat-gen states:  spec 31  vs table 1×128 = 128
//        If the intent is that "cycle" in the spec means a 64-clock-cycle
//        frame, then multiply all DONE_* localparams below by 64 to match
//        the table.
//
//   [C2] Per-lane ID generation substate encoding — spec §4.2.1.h and §4.2.2.f
//        both write "(0x34)" when describing "TX Per Lane ID generation", but
//        0x034 is the Apply Reversal substate (which rightly asserts tx_reverse
//        per spec §4.2.3.a).  The Per Lane ID generation is at 0x032 per the
//        table.  This is a spec typo; the table is followed for these two
//        distinct substates (0x032 → per_lane_id_gen_enable, 0x034 → tx_reverse).
//
//   [C3] LINKINIT (0x100) lfsr_train — spec §4.2.1.e only says "seed values
//        must be loaded" here; §4.2.1.f says train is enabled only for states
//        "using the lfsr pattern for data lanes" (LINKINIT is not one of them).
//        The table confirms lfsr_train=0 at 0x100.
//
//   [C4] Seed loading at 0x181 for REPAIRMB (per-lane ID) context — spec
//        §4.2.1.c says seeds must be loaded regardless of pattern type.
//        The table shows lfsr_load=0 here.  Spec takes priority: lfsr_load=1.
// =============================================================================

package tx_controller_modelling_pkg;

    // =========================================================================
    // Full 9-bit encoding localparams
    // =========================================================================

    // --- 00: INITIALIZATION PHASE ---
    localparam logic [8:0] ENC_RESET              = 9'h000;

    // SBINIT
    localparam logic [8:0] ENC_SBINIT_PAT         = 9'h008;
    localparam logic [8:0] ENC_SBINIT_OUT_RST     = 9'h009;
    localparam logic [8:0] ENC_SBINIT_DONE        = 9'h00A;

    // MBINIT.PARAM / CAL
    localparam logic [8:0] ENC_MBPARAM            = 9'h010;
    localparam logic [8:0] ENC_MBCAL              = 9'h018;

    // MBINIT.REPAIRCLK
    localparam logic [8:0] ENC_REPCLK_INIT        = 9'h020;
    localparam logic [8:0] ENC_REPCLK_PAT         = 9'h021; // clock-only pattern gen
    localparam logic [8:0] ENC_REPCLK_RESULT      = 9'h022;
    localparam logic [8:0] ENC_REPCLK_DONE        = 9'h023;

    // MBINIT.REPAIRVAL
    localparam logic [8:0] ENC_REPVAL_INIT        = 9'h028;
    localparam logic [8:0] ENC_REPVAL_PAT         = 9'h029; // valid pattern gen
    localparam logic [8:0] ENC_REPVAL_RESULT      = 9'h02A;
    localparam logic [8:0] ENC_REPVAL_DONE        = 9'h02B;

    // MBINIT.REVERSALMB
    localparam logic [8:0] ENC_REVERSAL_INIT      = 9'h030;
    localparam logic [8:0] ENC_REVERSAL_CLR_LOG   = 9'h031;
    localparam logic [8:0] ENC_REVERSAL_PERLANE   = 9'h032; // per-lane ID gen  [C2]
    localparam logic [8:0] ENC_REVERSAL_RESULT    = 9'h033;
    localparam logic [8:0] ENC_REVERSAL_APPLY     = 9'h034; // apply reversal   [C2]
    localparam logic [8:0] ENC_REVERSAL_DONE_SHK  = 9'h035;

    // MBINIT.REPAIRMB
    localparam logic [8:0] ENC_REPAIRMB_INIT      = 9'h038;
    localparam logic [8:0] ENC_REPAIRMB_D2C       = 9'h039;
    localparam logic [8:0] ENC_REPAIRMB_APPLY_DEG = 9'h03A;
    localparam logic [8:0] ENC_REPAIRMB_DONE      = 9'h03B;

    // TRAINERROR
    localparam logic [8:0] ENC_TRAINERR_SHK       = 9'h040;
    localparam logic [8:0] ENC_TRAINERR_WAIT      = 9'h041;
    localparam logic [8:0] ENC_TRAINERR_RESET     = 9'h042;

    // --- 01: TRAIN PHASE ---

    // MBTRAIN.VALVREF
    localparam logic [8:0] ENC_VALVREF_START      = 9'h080;
    localparam logic [8:0] ENC_VALVREF_END        = 9'h082;

    // MBTRAIN.DATAVREF
    localparam logic [8:0] ENC_DATAVREF_START     = 9'h088;
    localparam logic [8:0] ENC_DATAVREF_END       = 9'h08A;

    // MBTRAIN.DTC1 (DATATRAINCENTER1)
    localparam logic [8:0] ENC_DTC1_START         = 9'h090;
    localparam logic [8:0] ENC_DTC1_END           = 9'h092;

    // MBTRAIN.RXCLKCAL
    localparam logic [8:0] ENC_RXCLKCAL_START     = 9'h098;
    localparam logic [8:0] ENC_RXCLKCAL_CLK_SHIFT = 9'h099;
    localparam logic [8:0] ENC_RXCLKCAL_END       = 9'h09A;

    // MBTRAIN.VALTRAINCENTER
    localparam logic [8:0] ENC_VALTC_START        = 9'h0A0;
    localparam logic [8:0] ENC_VALTC_END          = 9'h0A2;

    // MBTRAIN.RXDESKEW
    localparam logic [8:0] ENC_RXDESKEW_START     = 9'h0A8;
    localparam logic [8:0] ENC_RXDESKEW_EQ_PRESET = 9'h0A9;
    localparam logic [8:0] ENC_RXDESKEW_OP        = 9'h0AA;
    localparam logic [8:0] ENC_RXDESKEW_DATACENTER= 9'h0AB;
    localparam logic [8:0] ENC_RXDESKEW_END       = 9'h0AC;
    localparam logic [8:0] ENC_RXDESKEW_TRAIN_ERR = 9'h0AD;

    // MBTRAIN.DTC2 (DATATRAINCENTER2)
    localparam logic [8:0] ENC_DTC2_START         = 9'h0B0;
    localparam logic [8:0] ENC_DTC2_END           = 9'h0B2;

    // MBTRAIN.LINKSPEED
    localparam logic [8:0] ENC_LINKSPD_START      = 9'h0B8;
    localparam logic [8:0] ENC_LINKSPD_DONE       = 9'h0BA;
    localparam logic [8:0] ENC_LINKSPD_ERR_REQ    = 9'h0BB;
    localparam logic [8:0] ENC_LINKSPD_PHYRETRAIN = 9'h0BC;
    localparam logic [8:0] ENC_LINKSPD_EXIT_REPAIR= 9'h0BD;
    localparam logic [8:0] ENC_LINKSPD_SPD_DEGRADE= 9'h0BE;

    // MBTRAIN.REPAIR
    localparam logic [8:0] ENC_REPAIR_START       = 9'h0C0;
    localparam logic [8:0] ENC_REPAIR_APPLY_DEG   = 9'h0C1;
    localparam logic [8:0] ENC_REPAIR_END         = 9'h0C2;

    // MBTRAIN.SPEEDIDLE
    localparam logic [8:0] ENC_SPEEDIDLE_TRANS    = 9'h0C8;
    localparam logic [8:0] ENC_SPEEDIDLE_END      = 9'h0C9;

    // MBTRAIN.TXSELFCAL
    localparam logic [8:0] ENC_TXSELFCAL_CAL      = 9'h0D0;
    localparam logic [8:0] ENC_TXSELFCAL_END      = 9'h0D1;

    // PHYRETRAIN
    localparam logic [8:0] ENC_PHYRETRAIN_STALL   = 9'h0D8;
    localparam logic [8:0] ENC_PHYRETRAIN_RETRAIN = 9'h0D9;
    localparam logic [8:0] ENC_PHYRETRAIN_START   = 9'h0DA;

    // MBTRAIN.VALTRAINVREF
    localparam logic [8:0] ENC_VALTVREF_START     = 9'h0E8;
    localparam logic [8:0] ENC_VALTVREF_END       = 9'h0EA;

    // MBTRAIN.DATATRAINVREF
    localparam logic [8:0] ENC_DATAVREF2_START    = 9'h0F0;
    localparam logic [8:0] ENC_DATAVREF2_END      = 9'h0F2;

    // --- 10: ACTIVE PHASE ---

    // LINKINIT
    localparam logic [8:0] ENC_LINKINIT_CLK_REQ   = 9'h100;
    localparam logic [8:0] ENC_LINKINIT_WAKE_REQ  = 9'h101;
    localparam logic [8:0] ENC_LINKINIT_STATE_REQ = 9'h102;

    // ACTIVE
    localparam logic [8:0] ENC_ACTIVE             = 9'h108;

    // L1 / Exit HS
    localparam logic [8:0] ENC_L1_HANDSHAKE       = 9'h110;
    localparam logic [8:0] ENC_L1_STATE           = 9'h111;
    localparam logic [8:0] ENC_EXIT_HS            = 9'h11A;

    // --- 11: EYE SWEEP (context-sensitive, shared encodings) ---
    // TX-initiated (11_0000_xxx)
    localparam logic [8:0] ENC_EYE_TX_INIT        = 9'h180;
    localparam logic [8:0] ENC_EYE_TX_LFSR_CLR    = 9'h181;
    localparam logic [8:0] ENC_EYE_TX_PAT_GEN     = 9'h182;
    localparam logic [8:0] ENC_EYE_TX_RESULT      = 9'h183;
    localparam logic [8:0] ENC_EYE_TX_END         = 9'h184;
    // RX-initiated (11_0001_xxx)
    localparam logic [8:0] ENC_EYE_RX_INIT        = 9'h188;
    localparam logic [8:0] ENC_EYE_RX_LFSR_CLR    = 9'h189;
    localparam logic [8:0] ENC_EYE_RX_PAT_GEN     = 9'h18A;
    localparam logic [8:0] ENC_EYE_RX_RESULT      = 9'h18B;
    localparam logic [8:0] ENC_EYE_RX_SWEEP_RES   = 9'h18C;
    localparam logic [8:0] ENC_EYE_RX_END         = 9'h18D;

    // =========================================================================
    // Done-cycle targets — spec §4.2.1.d / §4.2.2 (see contradiction [C1])
    // =========================================================================
    localparam int DONE_REPAIRCLK      = 48;  // spec §2a
    localparam int DONE_REPAIRVAL      = 16;  // spec §2b
    localparam int DONE_REVERSALMB_PAT = 32;  // spec §2f
    localparam int DONE_REPAIRMB_PAT   = 32;  // spec §2g
    localparam int DONE_VALID_EYE      = 16;  // spec §2c-e
    localparam int DONE_LFSR           = 31;  // spec §1d

    // =========================================================================
    // Parent-state enum for context-sensitive eye-sweep decoding
    // =========================================================================
    typedef enum logic [3:0] {
        PAR_NONE      = 4'd0,
        PAR_VALVREF   = 4'd1,
        PAR_DATAVREF  = 4'd2,
        PAR_DTC1      = 4'd3,
        PAR_VALTC     = 4'd4,
        PAR_VALTVREF  = 4'd5,
        PAR_DATAVREF2 = 4'd6,
        PAR_RXDESKEW  = 4'd7,
        PAR_DTC2      = 4'd8,
        PAR_LINKSPEED = 4'd9,
        PAR_REPAIRMB  = 4'd10
    } parent_e;

    // =========================================================================
    // State structure for maintaining FSM state across calls
    // =========================================================================
    typedef struct packed {
        parent_e  parent_q;
        logic [7:0] done_cnt_q;
        logic       done_prev;
    } tx_controller_state_t;

    // =========================================================================
    // Initialize state structure
    // =========================================================================
    function automatic void tx_controller_state_init(ref tx_controller_state_t state);
        state.parent_q    = PAR_NONE;
        state.done_cnt_q  = 8'd0;
        state.done_prev   = 1'b0;
    endfunction

    // =========================================================================
    // Task — call once per posedge clk from the scoreboard
    // State is maintained via the state_ref parameter (must persist across calls)
    // =========================================================================
    task automatic tx_controller_modelling (
        ref tx_controller_state_t state_ref,
        input  logic        i_reset,
        input  logic [8:0]  i_tx_encoding,
        input  logic [2:0]  i_lane_map_code,
        output logic        o_tx_lfsr_enable,
        output logic        o_tx_lfsr_load,
        output logic        o_tx_lfsr_train,
        output logic        o_per_lane_id_gen_enable,
        output logic        b2l_enable,
        output logic        o_tx_reverse,
        output logic        o_tx_done
    );

        // ----- local temporaries -----
        logic is_eye_sweep;
        logic ctx_lfsr_rx, ctx_lfsr_tx, ctx_valid, ctx_perlane;
        logic [7:0] done_target;
        logic       count_en;
        logic       done_state;

        // =================================================================
        // Reset handling
        // =================================================================
        if (!i_reset) begin
            state_ref.parent_q    = PAR_NONE;
            state_ref.done_cnt_q  = 8'd0;
            state_ref.done_prev   = 1'b0;

            o_tx_lfsr_enable         = 1'b0;
            o_tx_lfsr_load           = 1'b0;
            o_tx_lfsr_train          = 1'b0;
            o_per_lane_id_gen_enable = 1'b0;
            o_tx_reverse             = 1'b0;
            b2l_enable               = 1'b0;
            o_tx_done                = 1'b0;
            return;
        end

        // =================================================================
        // Eye-sweep detection
        // =================================================================
        is_eye_sweep = (i_tx_encoding[8:7] == 2'b11);

        // =================================================================
        // Context flags (valid only during eye sweep)
        // =================================================================
        ctx_lfsr_rx = 1'b0;
        ctx_lfsr_tx = 1'b0;
        ctx_valid   = 1'b0;
        ctx_perlane = 1'b0;

        if (is_eye_sweep) begin
            case (state_ref.parent_q)
                PAR_DATAVREF,
                PAR_DTC1,
                PAR_DATAVREF2,
                PAR_RXDESKEW:   ctx_lfsr_rx = 1'b1;

                PAR_DTC2,
                PAR_LINKSPEED:  ctx_lfsr_tx = 1'b1;

                PAR_VALVREF,
                PAR_VALTC,
                PAR_VALTVREF:   ctx_valid   = 1'b1;

                PAR_REPAIRMB:   ctx_perlane = 1'b1;

                default: ;
            endcase
        end

        // =================================================================
        // Done counter logic
        // =================================================================
        done_target = 8'd0;
        count_en    = 1'b0;

        case (i_tx_encoding)
            ENC_REPCLK_PAT: begin
                done_target = DONE_REPAIRCLK[7:0];
                count_en    = 1'b1;
            end
            ENC_REPVAL_PAT: begin
                done_target = DONE_REPAIRVAL[7:0];
                count_en    = 1'b1;
            end
            ENC_REVERSAL_PERLANE: begin
                done_target = DONE_REVERSALMB_PAT[7:0];
                count_en    = 1'b1;
            end
            ENC_EYE_TX_PAT_GEN: begin
                count_en = 1'b1;
                if      (ctx_lfsr_tx) done_target = DONE_LFSR[7:0];
                else if (ctx_valid)   done_target = DONE_VALID_EYE[7:0];
                else if (ctx_perlane) done_target = DONE_REPAIRMB_PAT[7:0];
            end
            ENC_EYE_RX_PAT_GEN: begin
                count_en = 1'b1;
                if      (ctx_lfsr_rx) done_target = DONE_LFSR[7:0];
                else if (ctx_valid)   done_target = DONE_VALID_EYE[7:0];
            end
            default: ;
        endcase

        done_state = count_en && (state_ref.done_cnt_q >= done_target);

        // o_tx_done is registered (one-cycle latency), use previous done_state
        o_tx_done = state_ref.done_prev;

        // =================================================================
        // Main output decoder (combinational)
        // =================================================================
        o_tx_lfsr_enable         = 1'b0;
        o_tx_lfsr_load           = 1'b0;
        o_tx_lfsr_train          = 1'b0;
        o_per_lane_id_gen_enable = 1'b0;
        o_tx_reverse             = 1'b0;
        b2l_enable               = 1'b0;

        case (i_tx_encoding)

            // LINKINIT — seed loaded (spec §4.2.1.e), train OFF (spec §4.2.1.f) [C3]
            ENC_LINKINIT_CLK_REQ: begin
                o_tx_lfsr_load = 1'b1;
            end

            // MBINIT.REVERSALMB per-lane ID generation (0x032) [C2]
            ENC_REVERSAL_PERLANE: begin
                o_per_lane_id_gen_enable = 1'b1;
            end

            // MBINIT.REVERSALMB apply reversal (0x034) — spec §4.2.3.a
            ENC_REVERSAL_APPLY: begin
                o_tx_reverse = 1'b1;
            end

            // Eye-sweep TX-initiated: LFSR clear (0x181)
            ENC_EYE_TX_LFSR_CLR: begin
                if (ctx_lfsr_tx) begin
                    o_tx_lfsr_load  = 1'b1;
                    o_tx_lfsr_train = 1'b1;
                end else if (ctx_perlane) begin
                    // Spec §4.2.1.c: seed values must be loaded at 0x181
                    // regardless of per-lane ID or LFSR pattern context [C4].
                    // lfsr_train remains 0 (train is only for LFSR states).
                    o_tx_lfsr_load  = 1'b1;
                end
                // ctx_valid (VALTRAINCENTER): no LFSR seed needed
            end

            // Eye-sweep TX-initiated: pattern generation (0x182)
            ENC_EYE_TX_PAT_GEN: begin
                if (ctx_lfsr_tx) begin
                    o_tx_lfsr_enable = 1'b1;
                    o_tx_lfsr_train  = 1'b1;
                end else if (ctx_perlane) begin
                    o_per_lane_id_gen_enable = 1'b1;
                end
                // ctx_valid: valid pattern — no lfsr / per-lane signals needed
            end

            // Eye-sweep RX-initiated: LFSR clear (0x189)
            ENC_EYE_RX_LFSR_CLR: begin
                if (ctx_lfsr_rx) begin
                    o_tx_lfsr_load  = 1'b1;
                    o_tx_lfsr_train = 1'b1;
                end
                // ctx_valid (VALVREF, VALTRAINVREF): no LFSR seed needed
            end

            // Eye-sweep RX-initiated: pattern generation (0x18A)
            ENC_EYE_RX_PAT_GEN: begin
                if (ctx_lfsr_rx) begin
                    o_tx_lfsr_enable = 1'b1;
                    o_tx_lfsr_train  = 1'b1;
                end
            end

            ENC_ACTIVE: begin
                o_tx_lfsr_enable = 1'b1;
                b2l_enable = 1'b1;
            end

            // All other states: defaults (all 0)
            default: ;

        endcase

        // =================================================================
        // Sequential state update (happens at end — models posedge behaviour)
        // =================================================================

        // --- Update parent_q (only when NOT in eye-sweep) ---
        if (!is_eye_sweep) begin
            case (i_tx_encoding)
                ENC_VALVREF_START,
                ENC_VALVREF_END:                                      state_ref.parent_q = PAR_VALVREF;

                ENC_DATAVREF_START,
                ENC_DATAVREF_END:                                     state_ref.parent_q = PAR_DATAVREF;

                ENC_DTC1_START,
                ENC_DTC1_END:                                         state_ref.parent_q = PAR_DTC1;

                ENC_VALTC_START,
                ENC_VALTC_END:                                        state_ref.parent_q = PAR_VALTC;

                ENC_VALTVREF_START,
                ENC_VALTVREF_END:                                     state_ref.parent_q = PAR_VALTVREF;

                ENC_DATAVREF2_START,
                ENC_DATAVREF2_END:                                    state_ref.parent_q = PAR_DATAVREF2;

                ENC_RXDESKEW_START, ENC_RXDESKEW_EQ_PRESET,
                ENC_RXDESKEW_OP,    ENC_RXDESKEW_DATACENTER,
                ENC_RXDESKEW_END,   ENC_RXDESKEW_TRAIN_ERR:          state_ref.parent_q = PAR_RXDESKEW;

                ENC_DTC2_START,
                ENC_DTC2_END:                                         state_ref.parent_q = PAR_DTC2;

                ENC_LINKSPD_START,  ENC_LINKSPD_DONE,
                ENC_LINKSPD_ERR_REQ, ENC_LINKSPD_PHYRETRAIN,
                ENC_LINKSPD_EXIT_REPAIR, ENC_LINKSPD_SPD_DEGRADE:    state_ref.parent_q = PAR_LINKSPEED;

                ENC_REPAIRMB_INIT,  ENC_REPAIRMB_D2C,
                ENC_REPAIRMB_APPLY_DEG, ENC_REPAIRMB_DONE:           state_ref.parent_q = PAR_REPAIRMB;

                default: ; // preserve state_ref.parent_q
            endcase
        end

        // --- Update done counter ---
        if (!count_en) begin
            state_ref.done_cnt_q = 8'd0;
        end else if (!done_state) begin
            state_ref.done_cnt_q = state_ref.done_cnt_q + 8'd1;
        end
        // when done_state: hold (counter saturates)

        // --- Register done_state for next cycle's o_tx_done ---
        state_ref.done_prev = done_state;

    endtask

endpackage
