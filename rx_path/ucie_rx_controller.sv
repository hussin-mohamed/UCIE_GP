module ucie_rx_controller #(
    parameter int unsigned MB_LANES = 16
) (
    input  logic                  i_clk,
    input  logic                  i_reset,
    input  logic [8:0]            i_rx_encoding,
    input  logic [2:0]            i_lane_map_code,
    input  logic [MB_LANES-1:0] i_rx_LFSR_results,
    input  logic [MB_LANES-1:0] i_rx_lane_id_results,
    input  logic [2:0]            i_clk_results,
    input  logic                  i_valid_results,
    input  logic [15:0]           i_fifo_empty,
    input  logic [15:0]           i_error_threshold,
    output logic [63:0]           o_rx_data_results,
    output logic                  o_rx_path_reset,
    output logic                  o_rx_error,
    output logic [2:0]            o_clk_results,
    output logic                  o_valid_results,
    output logic [15:0]           o_error_threshold,                   
    output logic [15:0]           o_rx_lfsr_enable,
    output logic                  o_rx_lfsr_load,
    output logic                  o_rx_lfsr_train,
    output logic                  o_detection_type,
    output logic                  o_data_det_type,
    output logic [1:0]            o_pattern_type,
    output logic                  o_rx_done,
    output logic [15:0]           o_per_lane_id_det_enable,
    output logic                  o_l2b_enable,
    output logic                  o_mb_clk_p_en,
    output logic                  o_mb_clk_n_en,
    output logic                  o_mb_valid_en,
    output logic [15:0]           o_fifo_rd_en,
    output logic                  o_mb_track_en,
    output logic [MB_LANES-1:0]   o_mb_lanes_en
);

    typedef enum logic [8:0] {
        ENC_RESET                    = 9'h000,
        ENC_SBINIT                   = 9'h008,
        ENC_MBINIT_PARAM             = 9'h010,
        ENC_MBINIT_CAL               = 9'h018,
        ENC_MBINIT_REPAIRCLK         = 9'h020,
        ENC_MBINIT_REPAIRCLK_PAT_DET = 9'h021,
        ENC_MBINIT_REPAIRVAL         = 9'h028,
        ENC_MBINIT_REPAIRVAL_PAT_DET = 9'h029,
        ENC_MBINIT_REVERSAL          = 9'h030,
        ENC_MBINIT_REVERSAL_PER_LANE = 9'h032,
        ENC_MBINIT_REVERSAL_APPLY    = 9'h034,
        ENC_MBINIT_REPAIRMB          = 9'h038,
        ENC_MBINIT_REPAIRMB_PAT_DET  = 9'h039,
        ENC_MBINIT_REPAIRMB_APPLY_DEGRADE = 9'h03A,
        ENC_MBTRAIN_VALVREF          = 9'h080,
        ENC_MBTRAIN_DATAVREF         = 9'h088,
        ENC_MBTRAIN_DTC1             = 9'h090,
        ENC_MBTRAIN_RXCLKCAL         = 9'h098,
        ENC_MBTRAIN_VALTRAINVREF     = 9'h0A0,
        ENC_MBTRAIN_RXDESKEW         = 9'h0A8,
        ENC_MBTRAIN_DTC2             = 9'h0B0,
        ENC_MBTRAIN_LINKSPEED        = 9'h0B8,
        ENC_MBTRAIN_REPAIR           = 9'h0C0,
        ENC_MBTRAIN_SPEEDIDLE        = 9'h0C8,
        ENC_MBTRAIN_TXSELFCAL        = 9'h0D0,
        ENC_PHYRETRAIN               = 9'h0D8,
        ENC_TRAINERROR               = 9'h040,
        ENC_MBTRAIN_VALTRAINCENTER   = 9'h0E8,
        ENC_MBTRAIN_DATATRAINVREF    = 9'h0F0,
        ENC_LINKINIT                 = 9'h100,
        ENC_ACTIVE                   = 9'h108,
        ENC_L1                       = 9'h110,
        ENC_TX_EYE_LFSR_START        = 9'h180,
        ENC_TX_EYE_LFSR_CLEAR        = 9'h181,
        ENC_TX_EYE_PAT_DET           = 9'h182,
        ENC_TX_EYE_RES_HS            = 9'h183, 
        ENC_RX_EYE_LFSR_CLEAR        = 9'h188,
        ENC_RX_EYE_LFSR_START        = 9'h189,
        ENC_RX_EYE_PAT_DET           = 9'h18A,
        ENC_RX_EYE_RES_HS            = 9'h18B
    } ltsm_states_e;

    // Pattern generator mode selection:
    // - NONE: hold pattern path idle
    // - CLOCK_ONLY: MBINIT.REPAIRCLK waveform
    // - ACTIVE_DATA: valid/data/track active patterning
    localparam logic [1:0] PATTERN_NONE        = 2'b00;
    localparam logic [1:0] PATTERN_CLOCK_ONLY  = 2'b01;
    localparam logic [1:0] PATTERN_VALID_ONLY  = 2'b10;
    localparam logic [1:0] PATTERN_ACTIVE_DATA = 2'b11;

    // Required pattern durations (in TX controller clock cycles) before asserting o_tx_done.
    localparam int unsigned DONE_CYCLES_LFSR       = 128;
    localparam int unsigned DONE_CYCLES_VALID      = 8 * 128;
    localparam int unsigned DONE_CYCLES_CLOCK      = 24 * 128;
    localparam int unsigned DONE_CYCLES_PER_LANEID = 128;

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
    logic                eye_uses_active_data_pattern;
    logic [15:0] error_threshold_q;     // Registered version for sequential logic
    logic [15:0] error_threshold;       // Combinational version
    logic [15:0] rx_data_results;
    logic [2:0] clk_results;
    logic valid_results;

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
    logic [15:0] fifo_rd_en;

    // Encodings observed on i_rx_encoding from the LTSM RX FSM.
    // These values are used to drive datapath mode selects and AFE enables.
    assign o_rx_error = (&clk_results) && (valid_results) && (&rx_data_results);

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

        case (i_rx_encoding[8:3])
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
        eye_tx_uses_lfsr           = 1'b0;
        eye_rx_uses_lfsr           = 1'b0;
        eye_uses_per_lane_id       = 1'b0;
        eye_uses_valid_pattern     = 1'b0;
        eye_uses_active_data_pattern = 1'b0;

        if (i_rx_encoding == ENC_TX_EYE_PAT_DET) begin
            case (ltsm_current_state_q)
                // MBINIT.REPAIRMB uses per-lane ID pattern in its eye-pattern phase.
                ENC_MBINIT_REPAIRMB: eye_uses_per_lane_id = 1'b1;

                // MBTRAIN.VALTRAINCENTER uses active/data pattern per requirement d.
                ENC_MBTRAIN_VALTRAINCENTER: eye_uses_active_data_pattern = 1'b1;

                // Other TX-initiated eye-pattern contexts are treated as LFSR-based.
                default: eye_tx_uses_lfsr = 1'b1;
            endcase
        end

        if (i_rx_encoding == ENC_RX_EYE_PAT_DET) begin
            case (ltsm_current_state_q)
                // MBTRAIN.VALVREF uses valid-only pattern per requirement c.
                ENC_MBTRAIN_VALVREF: eye_uses_valid_pattern = 1'b1;

                // MBTRAIN.VALTRAINVREF uses active/data pattern per requirement e.
                ENC_MBTRAIN_VALTRAINVREF: eye_uses_active_data_pattern = 1'b1;

                // Other RX-initiated eye-pattern contexts are treated as LFSR-based.
                default: eye_rx_uses_lfsr = 1'b1;
            endcase
        end
    end

    // Main control decode:
    // 1) generate datapath control outputs (LFSR/per-lane/reversal/pattern type)
    // 2) Select AFE tri-state enables according to current LTSM state/substate
    // 3) Program done counter behavior (enable + target cycles)
    always_comb begin
        o_rx_lfsr_enable         = 'b0;
        o_rx_lfsr_load           = 1'b0;
        o_rx_lfsr_train          = 1'b0;
        o_pattern_type           = PATTERN_NONE;
        o_per_lane_id_det_enable = 16'h0000;
        o_detection_type         = 1'b0;
        o_mb_clk_p_en            = 1'b0;
        o_mb_clk_n_en            = 1'b0;
        o_mb_valid_en            = 1'b0;
        o_mb_track_en            = 1'b0;
        o_mb_lanes_en            = '0;
        o_error_threshold        = 16'd0;
        error_threshold          = error_threshold_q;  // Use registered value in combinational logic
        fifo_rd_en               = 16'h0000;
        o_data_det_type          = 1'b0;
        rx_data_results[15:0]    = o_rx_data_results[15:0]; // Default to all 1's (no errors) for LFSR and lane ID patterns
        clk_results              = o_clk_results; // Default to all 1's (no errors)
        valid_results            = o_valid_results;   // Default to 1 (no errors)
        // LFSR pattern generation for eye sweep pattern-generation substates.
        if (eye_tx_uses_lfsr || eye_rx_uses_lfsr) begin
            if(!i_fifo_empty )begin
            o_rx_lfsr_enable    = 'b1;
            fifo_rd_en        = 16'hffff; // Keep FIFO read enabled during LFSR-based eye patterns to feed data into the pattern generator
            end
            o_error_threshold   = error_threshold;
            o_rx_lfsr_train     = 1'b1;
            o_pattern_type      = PATTERN_ACTIVE_DATA;
            o_data_det_type     = 1'b1;
            case (i_lane_map_code)
            // 3'b000 from LTSM means "degrade not possible": keep last valid mask.
            3'b001: begin rx_data_results[15:8]=8'hff; rx_data_results[7:0]=i_rx_LFSR_results[7:0]; end // logical lanes 0-7
            3'b010: begin rx_data_results[7:0]=8'hff; rx_data_results[15:8]=i_rx_LFSR_results[15:8]; end // logical lanes 8-15
            3'b011: begin rx_data_results=i_rx_LFSR_results; end // logical lanes 0-15
            3'b100: begin rx_data_results[15:4]=8'hff; rx_data_results[3:0]=i_rx_LFSR_results[3:0]; end // logical lanes 0-3
            3'b101: begin rx_data_results[15:8]=8'hff; rx_data_results[7:04]=i_rx_LFSR_results[7:4]; rx_data_results[3:0]=4'hf; end // logical lanes 4-7
            default: begin
                // default to all lanes enabled
                rx_data_results = 16'hFFFF; 
             end 
        endcase
        end

        

        // Reload LFSR seed during explicit clear substate and on LINKINIT entry behavior.
        if ((i_rx_encoding == ENC_TX_EYE_LFSR_CLEAR) || (i_rx_encoding == ENC_RX_EYE_LFSR_CLEAR) || (i_rx_encoding == ENC_LINKINIT)) begin
            o_rx_lfsr_load = 1'b1;
        end

        // ACTIVE keeps LFSR enabled for scrambling but disables train mode.
         if (i_rx_encoding == ENC_ACTIVE) begin
            if(!i_fifo_empty )begin
            o_rx_lfsr_enable = 'b1;
            fifo_rd_en     = 16'hffff;
            end
            o_error_threshold = error_threshold;
            o_rx_lfsr_train  = 1'b0;
            valid_results   = i_valid_results; 
            // Pattern type in ACTIVE depends on RDI inputs
            o_pattern_type = PATTERN_ACTIVE_DATA;
            o_data_det_type = 1'b1;
        end

        // Per-lane ID generation used in reversal/repairmb pattern substates.
        if ((i_rx_encoding == ENC_MBINIT_REVERSAL_PER_LANE) || eye_uses_per_lane_id) begin
            if(!i_fifo_empty )begin
            fifo_rd_en        = 16'hffff; // Keep FIFO read enabled during LFSR-based eye patterns to feed data into the pattern generator
            end
            o_per_lane_id_det_enable = 16'hffff;
            o_data_det_type          = 1'b0;
            o_pattern_type           = PATTERN_ACTIVE_DATA;
            case (i_lane_map_code)
            // 3'b000 from LTSM means "degrade not possible": keep last valid mask.
            3'b001: begin rx_data_results[15:8]=8'hff; rx_data_results[7:0]=i_rx_lane_id_results[7:0]; end // logical lanes 0-7
            3'b010: begin rx_data_results[7:0]=8'hff; rx_data_results[15:8]=i_rx_lane_id_results[15:8]; end // logical lanes 8-15
            3'b011: begin rx_data_results=i_rx_lane_id_results; end // logical lanes 0-15
            3'b100: begin rx_data_results[15:4]=8'hff; rx_data_results[3:0]=i_rx_lane_id_results[3:0]; end // logical lanes 0-3
            3'b101: begin rx_data_results[15:8]=8'hff; rx_data_results[7:04]=i_rx_lane_id_results[7:4]; rx_data_results[3:0]=4'hf; end // logical lanes 4-7
            default: begin
                // default to all lanes enabled
                rx_data_results = 16'hFFFF; 
             end 
        endcase
        end


        // REPAIRCLK pattern substate drives clock-only detector profile.
        if (i_rx_encoding == ENC_MBINIT_REPAIRCLK_PAT_DET) begin
            o_pattern_type = PATTERN_CLOCK_ONLY;
            clk_results = i_clk_results;
        end

        // REPAIRVAL and eye-sweep pattern states use active/data pattern profile.
        if ((i_rx_encoding == ENC_MBINIT_REPAIRVAL_PAT_DET) || eye_uses_valid_pattern) begin
            o_pattern_type = PATTERN_VALID_ONLY;
            valid_results = i_valid_results;
        end

        // Active/data pattern states (eye sweeps and others).
        if (eye_uses_active_data_pattern) begin
            o_pattern_type = PATTERN_ACTIVE_DATA;
        end

        // AFE enable policy by main state family.
        if (is_main_reset_like || is_main_l1) begin
            o_mb_clk_p_en = 1'b0;
            o_mb_clk_n_en = 1'b0;
            o_mb_valid_en = 1'b0;
            o_mb_track_en = 1'b0;
            o_mb_lanes_en = '0;
        end 
        else if (is_main_repairclk) begin
            o_mb_clk_p_en = 1'b1;
            o_mb_clk_n_en = 1'b1;
            o_mb_valid_en = 1'b0;
            o_mb_track_en = 1'b1;
            o_mb_lanes_en = '0;
        end 
        else if (is_main_repairval) begin
            o_mb_clk_p_en  = 1'b1;
            o_mb_clk_n_en  = 1'b1;
            o_mb_track_en  = 1'b1;
            o_mb_lanes_en  = lane_mask_q;
            o_pattern_type = PATTERN_VALID_ONLY; // MBINIT.REPAIRVAL always drives valid-only pattern
            o_mb_valid_en = 1'b1;
            
        end 
        else if (is_main_reversal || is_main_repairmb) begin
            o_mb_clk_p_en = 1'b1;
            o_mb_clk_n_en = 1'b1;
            o_mb_valid_en = 1'b1;
            o_mb_track_en = 1'b1;
            o_mb_lanes_en = lane_mask_q;
        end 
        else if (is_main_mbtrain) begin
            o_mb_clk_p_en = 1'b1;
            o_mb_clk_n_en = 1'b1;
            o_mb_valid_en = 1'b1;
            o_mb_track_en = 1'b1;
            o_mb_lanes_en = lane_mask_q;
            // MBTRAIN.VALVREF always drives valid-only pattern
            if (i_rx_encoding == ENC_MBTRAIN_VALVREF) begin
                o_pattern_type = PATTERN_VALID_ONLY;
            end
        end 
        else if (is_main_linkinit || is_main_active || is_main_phyretrain || is_main_trainerror) begin
            o_mb_clk_p_en = 1'b1;
            o_mb_clk_n_en = 1'b1;
            o_mb_valid_en = 1'b1;
            o_mb_track_en = 1'b1;
            o_mb_lanes_en = lane_mask_q;
        end

        // o_detection_type assertion per requirements:
        // - Asserted in MBINIT.REPAIRCLK and MBINIT.REPAIRVAL
        // - NOT asserted in all other states
        if (is_main_repairclk || is_main_repairval) begin
            o_detection_type = 1'b0;
        end
        else begin
            o_detection_type = 1'b1;
        end
    end


   always_ff @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        enc_q                <= ENC_RESET;
        ltsm_current_state_q <= ENC_RESET;
        lane_mask_q          <= {MB_LANES{1'b1}};
        error_threshold_q    <= 16'h0000;
        o_rx_done            <= 1'b1;   // idle = 1
        o_l2b_enable         <= 1'b0;
        o_fifo_rd_en         <= 16'h0000;
        o_rx_data_results    <= 64'hFFFF_FFFF_FFFF_FFFF;
        o_clk_results        <= 3'b111;
        o_valid_results      <= 1'b1;
        o_rx_path_reset      <= 1'b1;
        end 
        else begin
        o_fifo_rd_en      <= fifo_rd_en;
        enc_q             <= ltsm_states_e'(i_rx_encoding);
        o_rx_data_results <= {48'hFFFF_FFFF_FFFF, rx_data_results};
        o_clk_results     <= clk_results;
        o_valid_results   <= valid_results;

        // Track parent main-state context
        if ((i_rx_encoding[8:7] != 2'b11) && (i_rx_encoding[2:0] == 3'b000)) begin
            ltsm_current_state_q <= ltsm_states_e'(i_rx_encoding);
        end

        // Sample lane map code during APPLY_DEGRADE substate
        if ((i_rx_encoding == ENC_MBINIT_REPAIRMB_APPLY_DEGRADE) && lane_map_code_valid) begin
            lane_mask_q <= lane_mask_from_code;
        end

        // Sample error threshold on LFSR start substates
        if ((i_rx_encoding == ENC_TX_EYE_LFSR_START) || (i_rx_encoding == ENC_RX_EYE_LFSR_START)) begin
            error_threshold_q <= i_error_threshold;
        end

       

        // Path reset on RESET state
        if (enc_q == ENC_RESET || enc_q == ENC_RX_EYE_LFSR_CLEAR || enc_q == ENC_TX_EYE_LFSR_CLEAR) begin
            o_rx_path_reset <= 1'b1;
        end else begin
            o_rx_path_reset <= 1'b0;
        end

        // RDI enable
        if (is_main_active) begin
            o_l2b_enable <= 1'b1;
        end else begin
            o_l2b_enable <= 1'b0;
        end

        // ----------------------------------------------------------------
        // o_rx_done control:
        //   - Deassert (0) on entry to any PAT_DET substate (encoding change)
        //   - Reassert (1) when the corresponding result input arrives
        //   - Default hold: keep previous value
        // ----------------------------------------------------------------

        // Detect entry into a PAT_DET state (encoding just changed to a det state)
        if (i_rx_encoding != enc_q) begin
            case (i_rx_encoding)
                ENC_MBINIT_REPAIRCLK_PAT_DET,
                ENC_MBINIT_REPAIRVAL_PAT_DET,
                ENC_TX_EYE_PAT_DET,
                ENC_RX_EYE_PAT_DET: begin
                    o_rx_done <= 1'b0;  // entering detection: deassert done
                end
                default: begin
                    o_rx_done <= 1'b1;  // non-detection state: idle
                end
            endcase
        end
    end
end

endmodule
