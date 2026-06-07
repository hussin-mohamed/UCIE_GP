module tx_controller #(
    parameter int unsigned MB_LANES = 16
) (
    input  logic                  i_clk,
    input  logic                  i_reset,
    input  logic [8:0]            i_tx_encoding,
    input  logic [2:0]            i_lane_map_code,
    //input  logic                  i_lp_irdy,
    input  logic                  i_lp_valid,
    input  logic                  i_pl_tready,
    output logic[MB_LANES-1:0]    o_tx_lfsr_enable,
    output logic                  o_tx_lfsr_load,
    output logic                  o_tx_lfsr_train,
    output logic                  o_tx_path_reset,
    output logic                  o_data_pattern_type,
    output logic [1:0]            o_pattern_type,
    output logic                  o_tx_done,
    output logic                  o_per_lane_id_gen_enable,
    output logic                  o_tx_reverse,
   // output logic                  o_pl_trdy,
    output logic                  o_b2l_enable,
    output logic                  mb_clk_p_en,
    output logic                  mb_clk_n_en,
    output logic                  mb_valid_en,
    output logic                  mb_track_en,
    output logic [MB_LANES-1:0]   mb_lanes_en,

    output logic [MB_LANES-1:0]   fifo_wr_en
);

    // Encodings observed on i_tx_encoding from the LTSM TX FSM.
    // These values are used to drive datapath mode selects and AFE enables.
    typedef enum logic [8:0] {
        ENC_RESET                    = 9'h000,
        ENC_SBINIT                   = 9'h008,
        ENC_MBINIT_PARAM             = 9'h010,
        ENC_MBINIT_CAL               = 9'h018,
        ENC_MBINIT_REPAIRCLK         = 9'h020,
        ENC_MBINIT_REPAIRCLK_PAT_GEN = 9'h021,
        ENC_MBINIT_REPAIRVAL         = 9'h028,
        ENC_MBINIT_REPAIRVAL_PAT_GEN = 9'h029,
        ENC_MBINIT_REVERSAL          = 9'h030,
        ENC_MBINIT_REVERSAL_PER_LANE = 9'h032,
        ENC_MBINIT_REVERSAL_APPLY    = 9'h034,
        ENC_MBINIT_REPAIRMB          = 9'h038,
        //ENC_MBINIT_REPAIRMB_PAT_GEN  = 9'h039,
        ENC_MBINIT_REPAIRMB_APPLY_DEGRADE = 9'h03A,
        ENC_MBTRAIN_VALVREF          = 9'h080,
        ENC_MBTRAIN_DATAVREF         = 9'h088,
        ENC_MBTRAIN_DTC1             = 9'h090,
        ENC_MBTRAIN_RXCLKCAL         = 9'h098,
        ENC_MBTRAIN_VALTRAINVREF     = 9'h0E8,
        ENC_MBTRAIN_RXDESKEW         = 9'h0A8,
        ENC_MBTRAIN_DTC2             = 9'h0B0,
        ENC_MBTRAIN_LINKSPEED        = 9'h0B8,
        ENC_MBTRAIN_REPAIR           = 9'h0C0,
        ENC_MBTRAIN_SPEEDIDLE        = 9'h0C8,
        ENC_MBTRAIN_TXSELFCAL        = 9'h0D0,
        ENC_PHYRETRAIN               = 9'h0D8,
        ENC_TRAINERROR               = 9'h040,
        ENC_MBTRAIN_VALTRAINCENTER   = 9'h0A0,
        ENC_MBTRAIN_DATATRAINVREF    = 9'h0F0,
        ENC_LINKINIT                 = 9'h100,
        ENC_ACTIVE                   = 9'h108,
        ENC_L1                       = 9'h110,
        ENC_TX_EYE_LFSR_CLEAR        = 9'h181,
        ENC_TX_EYE_PAT_GEN           = 9'h182,
        ENC_RX_EYE_LFSR_CLEAR        = 9'h189,
        ENC_RX_EYE_PAT_GEN           = 9'h18A
    } ltsm_states_e;

    // Pattern generator mode selection:
    // - NONE: hold pattern path idle
    // - CLOCK_ONLY: MBINIT.REPAIRCLK waveform
    // - DATA: LFSR-based or valid-data-based pattern depending on context
    // - ACTIVE_DATA: valid/data/track active patterning
    localparam logic [1:0] PATTERN_NONE              = 2'b00;
    localparam logic [1:0] PATTERN_CLOCK_ONLY        = 2'b01;
    localparam logic [1:0] PATTERN_DATA              = 2'b10;
    localparam logic [1:0] PATTERN_ACTIVE_DATA       = 2'b11;


    // Required pattern durations (in TX controller clock cycles) before asserting o_tx_done.
    localparam int unsigned DONE_CYCLES_LFSR       = 31; // 2000 clk form the fast clk , 31 from mine
    localparam int unsigned DONE_CYCLES_VALID      = 14;
    localparam int unsigned DONE_CYCLES_CLOCK      = 94;
    localparam int unsigned DONE_CYCLES_PER_LANEID = 32;

    // Registered copy of the previous encoding is used to detect state entry
    // and restart the done counter for each new pattern-generation state.
    ltsm_states_e enc_q;
    ltsm_states_e ltsm_current_state_q;
    logic [MB_LANES-1:0] lane_mask_q;
    logic [MB_LANES-1:0] lane_mask_from_code;
    logic                lane_map_code_valid;
    logic                eye_tx_uses_lfsr;
    logic                eye_rx_uses_lfsr;
    logic                eye_uses_per_lane_id;
    logic                eye_uses_valid_pattern;
    logic                o_tx_reverse_q;
    logic                i_lp_valid_d1;
    logic                i_lp_valid_d2;
    logic                i_lp_valid_d3;
    logic                i_lp_valid_d4;
    logic                i_pl_tready_d1;
    logic                i_pl_tready_d2;
    logic                i_pl_tready_d3;
    logic                i_pl_tready_d4;
    logic [11:0] done_cnt_q;
    logic [11:0] done_target;
    logic        done_state;

    // One-hot-like flags derived from the main state field i_tx_encoding[8:3].
    // They simplify AFE policy selection in the control comb block.
    logic is_main_reset_like;
    logic is_main_repairclk;
    logic is_main_repairval;
    logic is_main_reversal;
    logic is_main_repairmb;
    logic is_main_mbtrain;
    logic is_main_linkinit;
    logic is_main_active;
    logic is_main_phyretrain;
    logic is_main_trainerror;
    logic is_main_l1;

    // Decode lane_map_code into a contiguous "LSB-active" lane mask.
    // This mapping is used after width degradation to enable only functional lanes.
    always_comb begin
        lane_mask_from_code = lane_mask_q;
        lane_map_code_valid = 1'b0;
        case (i_lane_map_code)
            // 3'b000 from LTSM means "degrade not possible": keep last valid mask.
            3'b001: begin lane_mask_from_code = 16'h00FF; lane_map_code_valid = 1'b1; end // logical lanes 0-7
            3'b010: begin lane_mask_from_code = 16'hFF00; lane_map_code_valid = 1'b1; end // logical lanes 8-15
            3'b011: begin lane_mask_from_code = 16'hFFFF; lane_map_code_valid = 1'b1; end // logical lanes 0-15
            3'b100: begin lane_mask_from_code = 16'h000F; lane_map_code_valid = 1'b1; end // logical lanes 0-3
            3'b101: begin lane_mask_from_code = 16'h00F0; lane_map_code_valid = 1'b1; end // logical lanes 4-7
            default: begin
                // default to all lanes enabled
                lane_mask_from_code = 16'hFFFF; 
             end 
        endcase
    end

    // Decode top-level TX main state from the 9-bit encoding.
    // Substate bits [2:0] are handled separately where needed.
    always_comb begin
        is_main_reset_like = 1'b0;
        is_main_repairclk  = 1'b0;
        is_main_repairval  = 1'b0;
        is_main_reversal   = 1'b0;
        is_main_repairmb   = 1'b0;
        is_main_mbtrain    = 1'b0;
        is_main_linkinit   = 1'b0;
        is_main_active     = 1'b0;
        is_main_phyretrain = 1'b0;
        is_main_trainerror = 1'b0;
        is_main_l1         = 1'b0;

        // When in a shared D2C eye-pattern state (encoding 0x18X), decode the
        // parent state stored in ltsm_current_state_q so AFE enables persist.
        case ( (i_tx_encoding[8:7] == 2'b11) ? ltsm_current_state_q[8:3] : i_tx_encoding[8:3] )
            6'h00, 6'h01, 6'h02, 6'h03: is_main_reset_like = 1'b1; // RESET/SBINIT/MBINIT.PARAM/CAL
            6'h04: is_main_repairclk = 1'b1; // MBINIT.REPAIRCLK
            6'h05: is_main_repairval = 1'b1; // MBINIT.REPAIRVAL
            6'h06: is_main_reversal  = 1'b1; // MBINIT.REVERSAL
            6'h07: is_main_repairmb  = 1'b1; // MBINIT.REPAIRMB
            6'h10, 6'h11, 6'h12, 6'h13, 6'h14, 6'h15, 6'h16, 6'h17, 6'h18, 6'h19, 6'h1A, 6'h1D, 6'h1E:
                is_main_mbtrain = 1'b1;       // MBTRAIN.* (includes VALTRAINCENTER and DATATRAINVREF)
            6'h1B: is_main_phyretrain = 1'b1; // PHYRETRAIN
            6'h1C: is_main_trainerror = 1'b1; // TRAINERROR
            6'h20: is_main_linkinit = 1'b1;   // LINKINIT
            6'h21: is_main_active = 1'b1;     // ACTIVE
            6'h22: is_main_l1 = 1'b1;         // L1/Exit HS
            default: begin
                is_main_reset_like = 1'b0;
            end
        endcase
    end

    // Eye-sweep encodings 0x182 (TX) and 0x18A (RX) are reused across many training
    // subflows. Which datapath to drive depends on the parent main state (NOT on the
    // eye substate value alone), per LTSM and tx_controller.
    always_comb begin
        eye_tx_uses_lfsr      = 1'b0;
        eye_rx_uses_lfsr      = 1'b0;
        eye_uses_per_lane_id  = 1'b0;
        eye_uses_valid_pattern = 1'b0;

        if (i_tx_encoding == ENC_TX_EYE_PAT_GEN || i_tx_encoding == ENC_RX_EYE_PAT_GEN) begin
            case (ltsm_current_state_q)

                ENC_MBINIT_REPAIRMB: eye_uses_per_lane_id = 1'b1;
                
                // RX-initiated eye pattern in valid-related train states.
                ENC_MBTRAIN_VALVREF,ENC_MBTRAIN_VALTRAINVREF,ENC_MBTRAIN_VALTRAINCENTER: begin
                    eye_uses_valid_pattern = 1'b1;
                    eye_rx_uses_lfsr = 1'b0;
                    eye_tx_uses_lfsr = 1'b0;
                end

                // Other RX-initiated eye-pattern contexts are treated as LFSR-based.
                default: begin
                    eye_rx_uses_lfsr = 1'b1;
                    eye_tx_uses_lfsr = 1'b1;
                    eye_uses_valid_pattern = 1'b0;
                end 
            endcase
        end
    end

    // Main control decode:
    // 1) Generate datapath control outputs (LFSR/per-lane/reversal/pattern type)
    // 2) Select AFE tri-state enables according to current LTSM state/substate
    // 3) Program done counter behavior (enable + target cycles)
    always_comb begin
        o_tx_lfsr_enable         = 'b0;
        fifo_wr_en               = 'b0;
        o_tx_lfsr_load           = 1'b0;
        o_tx_lfsr_train          = 1'b0;
        o_data_pattern_type      = 1'b0;
        o_pattern_type           = PATTERN_NONE;
        o_per_lane_id_gen_enable = 1'b0;

        mb_clk_p_en = 1'b0;
        mb_clk_n_en = 1'b0;
        mb_valid_en = 1'b0;
        mb_track_en = 1'b0;
        mb_lanes_en = '0;

        done_state  = 1'b0;
        done_target = 12'd0;
        o_b2l_enable = 1'b0;

        // LFSR pattern generation for eye sweep pattern-generation substates.
        if (eye_tx_uses_lfsr || eye_rx_uses_lfsr) begin
            o_tx_lfsr_enable    = '1;
            // activate the wr_en
            fifo_wr_en          = '1;
            o_tx_lfsr_train     = 1'b1;
            o_data_pattern_type = 1'b1;
            o_pattern_type      = PATTERN_ACTIVE_DATA;
            done_state          = 1'b1;
            done_target         = DONE_CYCLES_LFSR[11:0];
        end

        // Reload LFSR seed during explicit clear substate and on LINKINIT entry behavior.
        if ((i_tx_encoding == ENC_TX_EYE_LFSR_CLEAR) || (i_tx_encoding == ENC_RX_EYE_LFSR_CLEAR) || (i_tx_encoding == ENC_LINKINIT)) begin
            o_tx_lfsr_load = 1'b1;
            o_tx_lfsr_enable = '1;
        end

        // ACTIVE keeps LFSR enabled for scrambling but disables train mode.
        if (i_tx_encoding == ENC_ACTIVE) begin
            // o_tx_lfsr_enable must be a 2 cycle delayed version of the valid
            if (i_lane_map_code == 'b11) begin
                o_tx_lfsr_enable = ({MB_LANES{i_lp_valid_d1}} & {MB_LANES{i_pl_tready_d1}}) | ({MB_LANES{i_lp_valid_d2}} & {MB_LANES{i_pl_tready_d2}});
                fifo_wr_en = ({MB_LANES{i_lp_valid_d1}} & {MB_LANES{i_pl_tready_d1}}) | ({MB_LANES{i_lp_valid_d2}} & {MB_LANES{i_pl_tready_d2}});
            end else begin
                o_tx_lfsr_enable = ({MB_LANES{i_lp_valid_d1}} & {MB_LANES{i_pl_tready_d1}}) | ({MB_LANES{i_lp_valid_d2}} & {MB_LANES{i_pl_tready_d2}} | {MB_LANES{i_lp_valid_d3}} & {MB_LANES{i_pl_tready_d3}}) | ({MB_LANES{i_lp_valid_d4}} & {MB_LANES{i_pl_tready_d4}});
                fifo_wr_en = ({MB_LANES{i_lp_valid_d1}} & {MB_LANES{i_pl_tready_d1}}) | ({MB_LANES{i_lp_valid_d2}} & {MB_LANES{i_pl_tready_d2}} | {MB_LANES{i_lp_valid_d3}} & {MB_LANES{i_pl_tready_d3}}) | ({MB_LANES{i_lp_valid_d4}} & {MB_LANES{i_pl_tready_d4}});
            end
            
            // wr_en the same as o_tx_lfsr_enable
            
            o_tx_lfsr_train  = 1'b0;

            o_data_pattern_type = 1'b1;


            // Pattern type in ACTIVE depends on RDI inputs
            o_pattern_type = PATTERN_ACTIVE_DATA;
        end

        // Per-lane ID generation used in reversal/repairmb pattern substates.
        if ((i_tx_encoding == ENC_MBINIT_REVERSAL_PER_LANE) || eye_uses_per_lane_id) begin
            o_per_lane_id_gen_enable = 1'b1;
            fifo_wr_en               = '1;
            o_data_pattern_type      = 1'b0;
            o_pattern_type           = PATTERN_ACTIVE_DATA;
            done_state               = 1'b1;
            done_target              = DONE_CYCLES_PER_LANEID[11:0];
        end

        // REPAIRCLK pattern substate drives clock-only generator profile.
        if (i_tx_encoding == ENC_MBINIT_REPAIRCLK_PAT_GEN) begin
            o_pattern_type = PATTERN_CLOCK_ONLY;
            done_state     = 1'b1;
            done_target    = DONE_CYCLES_CLOCK[11:0];
        end

        // REPAIRVAL and eye-sweep pattern states use active/data pattern profile.
        if ((i_tx_encoding == ENC_MBINIT_REPAIRVAL_PAT_GEN) || eye_uses_valid_pattern) begin
            o_pattern_type = PATTERN_DATA;
            done_state  = 1'b1;
            done_target = DONE_CYCLES_VALID[11:0];
        end

        if(is_main_active)begin
            o_b2l_enable = 1'b1;
        end
    
        // AFE enable policy by main state family.
        if (is_main_reset_like || is_main_trainerror || is_main_l1) begin
            mb_clk_p_en = 1'b0;
            mb_clk_n_en = 1'b0;
            mb_valid_en = 1'b0;
            mb_track_en = 1'b0;
            mb_lanes_en = '0;
        end else if (is_main_repairclk) begin
            mb_clk_p_en = 1'b1;
            mb_clk_n_en = 1'b1;
            mb_valid_en = 1'b0;
            mb_track_en = 1'b1;
            mb_lanes_en = '0;
        end else if (is_main_repairval) begin
            mb_clk_p_en = 1'b1;
            mb_clk_n_en = 1'b1;
            mb_track_en = 1'b1;
            mb_lanes_en = lane_mask_q;
            if (i_tx_encoding == ENC_MBINIT_REPAIRVAL_PAT_GEN) begin
                mb_valid_en = 1'b1;
            end
        end else if (is_main_reversal || is_main_repairmb) begin
            mb_clk_p_en = 1'b1;
            mb_clk_n_en = 1'b1;
            mb_valid_en = 1'b1;
            mb_track_en = 1'b1;
            mb_lanes_en = lane_mask_q;
        end else if (is_main_mbtrain) begin
            if (i_tx_encoding != ENC_MBTRAIN_TXSELFCAL) begin
                mb_clk_p_en = 1'b1;
                mb_clk_n_en = 1'b1;
                mb_valid_en = 1'b1;
                mb_track_en = 1'b1;
                mb_lanes_en = lane_mask_q;
            end
        end else if (is_main_linkinit || is_main_active || is_main_phyretrain) begin
            mb_clk_p_en = 1'b1;
            mb_clk_n_en = 1'b1;
            mb_valid_en = 1'b1;
            mb_track_en = 1'b1;
            mb_lanes_en = lane_mask_q;
        end
    end

    logic o_tx_done_reg;

    // Done pulse generation:
    // - Counter resets on encoding change
    // - Counter runs only in pattern states (done_state=1)
    // - o_tx_done pulses high for one cycle when done_target is reached
    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            enc_q               <= ENC_RESET;
            ltsm_current_state_q <= ENC_RESET;
            lane_mask_q <= {MB_LANES{1'b1}};
            done_cnt_q <= 12'd0;
            o_tx_done_reg  <= 1'b0;
            o_tx_reverse_q <= 1'b0;
            o_tx_reverse <= 1'b0;
            i_lp_valid_d1 <= 1'b0;
            i_lp_valid_d2 <= 1'b0;
            // o_pl_trdy  <= 1'b0;
        end else begin
            enc_q     <= ltsm_states_e'(i_tx_encoding);
            o_tx_done_reg <= 1'b0;

            i_lp_valid_d1 <= i_lp_valid;
            i_lp_valid_d2 <= i_lp_valid_d1;
            i_lp_valid_d3 <= i_lp_valid_d2;
            i_lp_valid_d4 <= i_lp_valid_d3;
            i_pl_tready_d1 <= i_pl_tready;
            i_pl_tready_d2 <= i_pl_tready_d1;
            i_pl_tready_d3 <= i_pl_tready_d2;
            i_pl_tready_d4 <= i_pl_tready_d3;

            // Track parent main-state context (substate 000) except module 11 eye-test encodings.
            if ((i_tx_encoding[8:7] != 2'b11) && (i_tx_encoding[2:0] == 3'b000)) begin
                ltsm_current_state_q <= ltsm_states_e'(i_tx_encoding);
            end

            if(enc_q == ENC_RESET) begin
                o_tx_reverse <= 1'b0;
                o_tx_path_reset <= 1'b1;
            end
            else begin
                o_tx_path_reset <= 1'b0;
            end

            // Per LTSM MBINIT.REPAIRMB sequence, sample lane map code during
            // TX_Apply_Degrade_Hnd substate (encoding 0x3A).
            if ((i_tx_encoding == ENC_MBINIT_REPAIRMB_APPLY_DEGRADE) && lane_map_code_valid) begin
                lane_mask_q <= lane_mask_from_code;
            end

            // Reset counter on encoding change to detect new state entry
            if (i_tx_encoding != enc_q) begin
                done_cnt_q <= 12'd0;
            end else if (done_state) begin
                // In pattern generation states, increment counter each cycle
                if (done_cnt_q == (done_target - 12'd1)) begin
                    // Target duration reached: reset counter and assert done pulse for one cycle
                    done_cnt_q <= 12'd0;
                    o_tx_done_reg  <= 1'b1;
                end else begin
                    done_cnt_q <= done_cnt_q + 12'd1;
                end
            end else begin
                // Not in a pattern state: hold counter at zero
                done_cnt_q <= 12'd0;
            end

            // Update reversal register only on apply-reversal state entry.
            if (i_tx_encoding == ENC_MBINIT_REVERSAL_APPLY) begin
                o_tx_reverse <= 1'b1;
            end
        end
    end

    always_comb begin
        if (done_state) begin
            o_tx_done = o_tx_done_reg;
        end else begin
            o_tx_done = 1;
        end
    end

endmodule


// notes 
// pattern type : 10 in case of valid/data pattern 
//                11 incase the active.  

// lfsr pattern length checking  expected(4k).

// reversal register update on reversal apply state entry.