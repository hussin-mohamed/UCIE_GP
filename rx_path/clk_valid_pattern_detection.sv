// =============================================================================
// Module      : clk_valid_pattern_detection
// Description : Detects clock and valid signal patterns for both half-rate
//               (single-ended clk_p) and quadrature-rate (differential clk_p/n)
//               operation modes. Supports two detection types:
//                 - Per-lane  : consecutive correct pattern count threshold
//                 - Compare   : accumulated error count threshold
//
// Clock result output is 3 bits wide:
//   [2] = track signal pattern matched
//   [1] = clk_n pattern matched (~p_CLK_SEQ_1 in half-rate, p_CLK_SEQ_1 in quad)
//   [0] = clk_p pattern matched
//
// Inputs:
//   i_clk_p           : Positive clock input (used in both modes)
//   i_clk_n           : Negative clock input (used in quadrature mode only)
//   i_valid           : Valid signal to detect pattern on
//   i_track           : Track signal cross-verified against p_CLK_SEQ_1
//   i_hclk            : Half-rate reference clock (used in quadrature clock detect)
//   i_dclk            : Full-rate reference clock (used in half-rate clock detect)
//   i_reset           : Asynchronous reset (active high)
//   i_halfrate        : Selects half-rate (1) or quadrature-rate (0)
//   i_pattern_type    : [1] enables valid detection | [0] enables clock detection
//   i_detection_type  : Selects per-lane (0) or compare/error (1) detection
//   i_error_threshhold: Max allowed errors before compare result goes low
//
// Outputs:
//   o_clk_result  [2:0] : Clock pattern detection result (per-bit as above)
//   o_valid_result      : Valid pattern detection result
// =============================================================================

module clk_valid_pattern_detection (
    input  logic        i_clk_p,
    input  logic        i_clk_n,
    input  logic        i_valid,
    input  logic        i_track,           
    input  logic        i_hclk,
    input  logic        i_dclk,
    input  logic        i_reset,
    input  logic        i_halfrate,
    input  logic [1:0]  i_pattern_type,
    input  logic        i_detection_type,
    input  logic [15:0] i_error_threshhold,
    output logic [2:0]  o_clk_result,
    output logic        o_valid_result
);

    // -------------------------------------------------------------------------
    // Clock/Valid Pattern Definition
    // 32-bit alternating 1010... pattern followed by 16 zeros (total 48 bits)
    // Binary : 1010_1010_..._1010_1010_0000_0000_0000_0000
    // Hex    : 0xAAAAAAAA_0000
    // -------------------------------------------------------------------------
    parameter [47:0] p_CLK_SEQ_1 = 48'hAAAA_AAAA_0000;
    parameter [47:0] p_CLK_SEQ_2 = 48'h5555_5555_0000;

    // =========================================================================
    // SECTION 0: Active VALID DETECTION
    // Samples i_valid on i_clk_p, checks for 8'b11110000 pattern, when valid is asserted
    // asserts the valid result accordingly.
    // =========================================================================
    // --- Active Detection Signals ---
    logic [7:0]  w_serialized_active_h;       // Shift register accumulating valid samples
    logic [3:0]  counter_v_active_h;          // Sample counter; triggers check at 8
    logic [3:0]  counter_correct_active_h;    // Consecutive correct 8-bit pattern count
    logic        w_clk_enable_valid_active_h; // Clock gate: disables after result asserts
    logic        w_valid_result_active_h;
    logic        enable_h;

    // Latch gate enable on low phase of clk_p; disable once result is asserted
    


    // Serialize i_valid into shift register; evaluate pattern every 8 samples
    always_ff @(i_clk_p or posedge i_reset) begin : valid_detector_active_h
        if (i_reset) begin
            w_serialized_active_h    <= 0;
            counter_v_active_h       <= 0;
            counter_correct_active_h <= 0;
            enable_h <= 0;
            w_valid_result_active_h <= 1;
        end
        else if (i_pattern_type != 2'b11) begin
            // Valid detection disabled by pattern_type
            w_serialized_active_h <= 0;
            counter_v_active_h    <= 0;
            enable_h <= 0;
        end
        else if (i_valid && !enable_h) begin
            enable_h <= 1;
            w_serialized_active_h <= {w_serialized_active_h[6:0], i_valid};
            counter_v_active_h    <= counter_v_active_h + 1;
        end
        else if (enable_h) begin
            // Continue shifting in valid samples
            w_serialized_active_h <= {w_serialized_active_h[6:0], i_valid};
            counter_v_active_h    <= counter_v_active_h + 1;
        end

        // Every 8 samples: compare window to expected pattern 11110000
        if (counter_v_active_h == 8) begin
            if (w_serialized_active_h != 8'b11110000)
                w_valid_result_active_h <= 0;
                if (i_valid) begin
                    counter_v_active_h <= 1;        
                end
                else begin
                    counter_v_active_h <= 0;
                    enable_h<=0;
                end
            
        end
    end

     // =========================================================================
    // SECTION 0: Active VALID DETECTION quadrature
    // Samples i_valid on i_clk_p, checks for 8'b11110000 pattern, when valid is asserted
    // asserts the valid result accordingly.
    // =========================================================================
    // --- Active Detection Signals ---
    logic [7:0]  w_serialized_active_q;       // Shift register accumulating valid samples
    logic [3:0]  counter_v_active_q;          // Sample counter; triggers check at 8
    logic [3:0]  counter_correct_active_q;    // Consecutive correct 8-bit pattern count
    logic        w_clk_enable_valid_active_q; // Clock gate: disables after result asserts
    logic        w_valid_result_active_q;
    logic        enable_q;

    // Latch gate enable on low phase of clk_p; disable once result is asserted
    


    // Serialize i_valid into shift register; evaluate pattern every 8 samples
    always_ff @(i_clk_p or i_clk_n or posedge i_reset) begin : valid_active_per_lane_q
        if (i_reset) begin
            w_serialized_active_q    <= 0;
            counter_v_active_q       <= 0;
            counter_correct_active_q <= 0;
            enable_q <= 0;
            w_valid_result_active_q <= 1;
        end
        else if (i_pattern_type != 2'b11) begin
            // Valid detection disabled by pattern_type
            w_serialized_active_q <= 0;
            counter_v_active_q    <= 0;
            enable_q <= 0;
        end
        else if (i_valid && !enable_q) begin
            enable_q <= 1;
            w_serialized_active_q <= {w_serialized_active_q[6:0], i_valid};
            counter_v_active_q    <= counter_v_active_q + 1;
        end
        else if (enable_q) begin
            // Continue shifting in valid samples
            w_serialized_active_q <= {w_serialized_active_q[6:0], i_valid};
            counter_v_active_q    <= counter_v_active_q + 1;
        end

        // Every 8 samples: compare window to expected pattern 11110000
        if (counter_v_active_q == 8) begin
            if (w_serialized_active_q != 8'b11110000)
                w_valid_result_active_q <= 0;
                if (i_valid) begin
                    counter_v_active_q <= 1;        
                end
                else begin
                    counter_v_active_q <= 0;
                    enable_q<=0;
                end
            
        end
    end

    // =========================================================================
    // SECTION 1: HALF-RATE VALID DETECTION
    // Samples i_valid on i_clk_p, checks for 8'b11110000 pattern,
    // and asserts result after 16 consecutive correct 8-bit windows.
    // =========================================================================

    // --- Per-Lane Detection Signals ---
    logic [7:0]  w_serialized_per_lane_h;       // Shift register accumulating valid samples
    logic [3:0]  counter_v_per_lane_h;          // Sample counter; triggers check at 8
    logic [3:0]  counter_correct_per_lane_h;    // Consecutive correct 8-bit pattern count
    logic        w_clk_enable_valid_per_lane_h; // Clock gate: disables after result asserts
    logic        w_clk_per_lane_h;              // Gated sampling clock
    logic        w_valid_result_per_lane_h;

    // Latch gate enable on low phase of clk_p; disable once result is asserted
    always @(*) begin
        if (!i_clk_p)
            w_clk_enable_valid_per_lane_h = !w_valid_result_per_lane_h;
    end

    assign w_clk_per_lane_h = i_clk_p & w_clk_enable_valid_per_lane_h;

    // Serialize i_valid into shift register; evaluate pattern every 8 samples
    always_ff @(w_clk_per_lane_h or posedge i_reset) begin : valid_detector_per_lane_h
        if (i_reset) begin
            w_serialized_per_lane_h    <= 0;
            counter_v_per_lane_h       <= 0;
            counter_correct_per_lane_h <= 0;
        end
        else if (!i_pattern_type[1]) begin
            // Valid detection disabled by pattern_type
            w_serialized_per_lane_h <= 0;
            counter_v_per_lane_h    <= 0;
        end
        
        else begin
            // Continue shifting in valid samples
            w_serialized_per_lane_h <= {w_serialized_per_lane_h[6:0], i_valid};
            counter_v_per_lane_h    <= counter_v_per_lane_h + 1;
        end

        // Every 8 samples: compare window to expected pattern 11110000
        if (counter_v_per_lane_h == 8) begin
            if (w_serialized_per_lane_h == 8'b11110000)
                counter_correct_per_lane_h <= counter_correct_per_lane_h + 1;
            else
                counter_correct_per_lane_h <= 0;
            counter_v_per_lane_h <= 1;
        end
    end

    
    // Result asserts after 16 consecutive correct 8-bit windows
    assign w_valid_result_per_lane_h = (counter_correct_per_lane_h == 'd15) ? 1 : 0;


    // --- Compare / Error-Count Detection Signals ---
    logic [7:0]  w_serialized_compare_h;       // Shift register accumulating valid samples
    logic [3:0]  counter_v_compare_h;          // Sample counter; triggers check at 8
    logic [15:0] counter_error_h;              // Cumulative mismatch counter
    logic        w_clk_enable_valid_compare_h; // Clock gate: enables once per-lane result is valid
    logic        w_clk_compare_h;              // Gated sampling clock
    logic        w_valid_result_compare_h;

    // Latch gate enable on low phase of clk_p; deasserts when the counter exceeds the error threshhold
    always @(*) begin
        if (!i_clk_p)
            w_clk_enable_valid_compare_h = w_valid_result_compare_h;
    end

    assign w_clk_compare_h = i_clk_p & w_clk_enable_valid_compare_h;

    // Serialize i_valid; increment error counter on mismatch every 8 samples
    always_ff @(w_clk_compare_h or posedge i_reset) begin : valid_detector_compare_h
        if (i_reset) begin
            w_serialized_compare_h <= 0;
            counter_v_compare_h    <= 0;
            counter_error_h        <= 0;
        end
        else if (!i_pattern_type[1]) begin
            // Valid detection disabled by pattern_type
            w_serialized_compare_h <= 0;
            counter_v_compare_h    <= 0;
            counter_error_h        <= 0;
        end
        
        else begin
            // Continue shifting (gated by per-lane enable flag)
            w_serialized_compare_h <= {w_serialized_compare_h[6:0], i_valid};
            counter_v_compare_h    <= counter_v_compare_h + 1;
        end

        // Every 8 samples: accumulate error on mismatch
        if (counter_v_compare_h == 8) begin
            if (w_serialized_compare_h != 8'b11110000)
                counter_error_h <= counter_error_h + 1;
            counter_v_compare_h <= 1;
        end
    end

    
    // Result stays high as long as cumulative errors remain within threshold
    assign w_valid_result_compare_h = (counter_error_h > i_error_threshhold) ? 0 : 1;


    // --- Half-Rate Valid Result Mux ---
    logic w_valid_result_h;
    always @(*) begin
        if (i_detection_type)
            w_valid_result_h = w_valid_result_compare_h;  // Error-threshold mode
        else
            w_valid_result_h = w_valid_result_per_lane_h; // Consecutive-correct mode
    end


    // =========================================================================
    // SECTION 2: QUADRATURE-RATE VALID DETECTION
    // Identical logic to Section 1 but samples on both clk_p and clk_n edges
    // to achieve double the sampling rate.
    // =========================================================================

    // --- Per-Lane Detection Signals ---
    logic [7:0]  w_serialized_per_lane_q;
    logic [3:0]  counter_v_per_lane_q;
    logic [3:0]  counter_correct_per_lane_q;
    logic        w_clk_p_enable_valid_per_lane_q; // Gate for clk_p in quad mode
    logic        w_clk_n_enable_valid_per_lane_q; // Gate for clk_n in quad mode
    logic        w_clk_p_per_lane_q;
    logic        w_clk_n_per_lane_q;
    logic        w_valid_result_per_lane_q;

    // pass both clk_p and clk_n while result is not yet asserted
    always @(*) begin
        if (!i_clk_p)
            w_clk_p_enable_valid_per_lane_q = !w_valid_result_per_lane_q;
        if (!i_clk_n)
            w_clk_n_enable_valid_per_lane_q = !w_valid_result_per_lane_q;
    end

    assign w_clk_p_per_lane_q = i_clk_p & w_clk_p_enable_valid_per_lane_q;
    assign w_clk_n_per_lane_q = i_clk_n & w_clk_n_enable_valid_per_lane_q;

    // Sample on both clk_p and clk_n edges for quadrature rate
    always_ff @(w_clk_p_per_lane_q or w_clk_n_per_lane_q or posedge i_reset) begin : valid_detector_per_lane_q
        if (i_reset) begin
            w_serialized_per_lane_q    <= 0;
            counter_v_per_lane_q       <= 0;
            counter_correct_per_lane_q <= 0;
        end
        else if (!i_pattern_type[1]) begin
            w_serialized_per_lane_q <= 0;
            counter_v_per_lane_q    <= 0;
        end
        else  begin
            w_serialized_per_lane_q <= {w_serialized_per_lane_q[6:0], i_valid};
            counter_v_per_lane_q    <= counter_v_per_lane_q + 1;
        end

        if (counter_v_per_lane_q == 8) begin
            if (w_serialized_per_lane_q == 8'b11110000)
                counter_correct_per_lane_q <= counter_correct_per_lane_q + 1;
            else
                counter_correct_per_lane_q <= 0;
            counter_v_per_lane_q <= 1;
        end
    end

    
    assign w_valid_result_per_lane_q = (counter_correct_per_lane_q == 'd15) ? 1 : 0;


    // --- Compare / Error-Count Detection Signals (Quadrature) ---
    logic [7:0]  w_serialized_compare_q;
    logic [3:0]  counter_v_compare_q;
    logic [15:0] counter_error_q;
    logic        w_clk_p_enable_valid_compare_q;
    logic        w_clk_n_enable_valid_compare_q;
    logic        w_clk_p_compare_q;
    logic        w_clk_n_compare_q;
    logic        w_valid_result_compare_q;

    // deasserts when the counter exceeds the error threshhold
    always @(*) begin
        if (!i_clk_p)
            w_clk_p_enable_valid_compare_q = w_valid_result_compare_q;
        if (!i_clk_n)
            w_clk_n_enable_valid_compare_q = w_valid_result_compare_q;
    end

    assign w_clk_p_compare_q = i_clk_p & w_clk_p_enable_valid_compare_q;
    assign w_clk_n_compare_q = i_clk_n & w_clk_n_enable_valid_compare_q;

    always_ff @(w_clk_p_compare_q or w_clk_n_compare_q or posedge i_reset) begin : valid_detector_compare_q
        if (i_reset) begin
            w_serialized_compare_q <= 0;
            counter_v_compare_q    <= 0;
            counter_error_q        <= 0;
        end
        else if (!i_pattern_type[1]) begin
            w_serialized_compare_q <= 0;
            counter_v_compare_q    <= 0;
            counter_error_q        <= 0;
        end
        else begin
            w_serialized_compare_q <= {w_serialized_compare_q[6:0], i_valid};
            counter_v_compare_q    <= counter_v_compare_q + 1;
        end

        if (counter_v_compare_q == 8) begin
            if (w_serialized_compare_q != 8'b11110000)
                counter_error_q <= counter_error_q + 1;
            counter_v_compare_q <= 1;
        end
    end

    
    assign w_valid_result_compare_q = (counter_error_q > i_error_threshhold) ? 0 : 1;


    // --- Quadrature Valid Result Mux ---
    logic w_valid_result_q;
    always @(*) begin
        if (i_detection_type)
            w_valid_result_q = w_valid_result_compare_q;
        else
            w_valid_result_q = w_valid_result_per_lane_q;
    end


    // =========================================================================
    // SECTION 3: HALF-RATE CLOCK DETECTION
    // Samples i_clk_p, i_clk_n, and i_track using gated i_dclk reference.
    // Checks each 48-bit serialized window independently:
    //   clk_p  must match  p_CLK_SEQ_1
    //   clk_n  must match ~p_CLK_SEQ_1  (inverted - differential pair)
    //   track  must match  p_CLK_SEQ_1
    // Each signal has its own consecutive-correct counter and result bit.
    // =========================================================================

    logic [47:0] w_serialized_clk_p_h;        // Serialized clk_p samples
    logic [47:0] w_serialized_clk_n_h;        // Serialized clk_n samples
    logic [47:0] w_serialized_track_h;        // Serialized track signal samples
    logic [5:0]  counter_clk_h;               // Sample counter; triggers check at 48
    logic        w_enable_h;                  // Latches high on first clk_p assertion
    logic [3:0]  counter_correct_p_h;         // Consecutive correct windows for clk_p
    logic [3:0]  counter_correct_n_h;         // Consecutive correct windows for clk_n
    logic [3:0]  counter_correct_track_h;     // Consecutive correct windows for track
    logic        w_enable_clk_h;              // Gate enable: disables after result asserts
    logic        w_dclk;                      // Gated dclk
    logic [2:0]  w_clk_result_h;

    // Gate dclk on its low phase; disable once all three clock results are asserted
    always @(*) begin
        if (!i_dclk)
            w_enable_clk_h = !(&w_clk_result_h); // Disable when all 3 bits are high
    end

    assign w_dclk = i_dclk & w_enable_clk_h;

    // Serialize clk_p, clk_n, and track on negedge of gated dclk;
    // evaluate each 48-bit window independently
    always_ff @(negedge w_dclk or posedge i_reset) begin : clock_detection_h
        if (i_reset) begin
            w_serialized_clk_p_h    <= 0;
            w_serialized_clk_n_h    <= 0;
            w_serialized_track_h    <= 0;
            counter_clk_h           <= 0;
            w_enable_h              <= 0;
            counter_correct_p_h     <= 0;
            counter_correct_n_h     <= 0;
            counter_correct_track_h <= 0;
        end
        else if (!i_pattern_type[0]) begin
            // Clock detection disabled by pattern_type
            w_serialized_clk_p_h <= 0;
            w_serialized_clk_n_h <= 0;
            w_serialized_track_h <= 0;
            counter_clk_h        <= 0;
            w_enable_h           <= 0;
        end
        else if (i_clk_p && !w_enable_h) begin
            // Arm capture on first clk_p high
            w_enable_h           <= 1;
            w_serialized_clk_p_h <= {w_serialized_clk_p_h[46:0], i_clk_p};
            w_serialized_clk_n_h <= {w_serialized_clk_n_h[46:0], i_clk_n};
            w_serialized_track_h <= {w_serialized_track_h[46:0], i_track};
            counter_clk_h        <= counter_clk_h + 1;
        end
        else if (w_enable_h) begin
            // Continue shifting all three signals
            w_serialized_clk_p_h <= {w_serialized_clk_p_h[46:0], i_clk_p};
            w_serialized_clk_n_h <= {w_serialized_clk_n_h[46:0], i_clk_n};
            w_serialized_track_h <= {w_serialized_track_h[46:0], i_track};
            counter_clk_h        <= counter_clk_h + 1;
        end

        // Every 48 samples: evaluate each signal independently
        if (counter_clk_h == 48) begin
            // clk_p counter: increment on match, reset on mismatch
            if (counter_correct_p_h != 15) begin
                if (w_serialized_clk_p_h == p_CLK_SEQ_1)
                counter_correct_p_h <= counter_correct_p_h + 1;
            else
                counter_correct_p_h <= 0;
            end
            

            // clk_n counter: expects inverted pattern (~p_CLK_SEQ_1)
            if (counter_correct_n_h != 15) begin
                if (w_serialized_clk_n_h == p_CLK_SEQ_2)
                counter_correct_n_h <= counter_correct_n_h + 1;
            else
                counter_correct_n_h <= 0;
            end
            

            // track counter: expects same pattern as clk_p
            if (counter_correct_track_h != 15) begin
                if (w_serialized_track_h == p_CLK_SEQ_1)
                counter_correct_track_h <= counter_correct_track_h + 1;
            else
                counter_correct_track_h <= 0;
            end
            

            counter_clk_h <= 1;
        end
    end

    
    // Each bit asserts independently after 16 consecutive correct 48-bit windows
    assign w_clk_result_h[0] = (counter_correct_p_h     == 15) ? 1 : 0; // clk_p
    assign w_clk_result_h[1] = (counter_correct_n_h     == 15) ? 1 : 0; // clk_n
    assign w_clk_result_h[2] = (counter_correct_track_h == 15) ? 1 : 0; // track


    // =========================================================================
    // SECTION 4: QUADRATURE-RATE CLOCK DETECTION
    // Uses gated i_hclk reference. clk_p and track are sampled on negedge;
    // clk_n is sampled on posedge. Each builds its own 48-bit window.
    // clk_n expected to match p_CLK_SEQ_1 (not inverted, unlike half-rate).
    // =========================================================================

    logic [47:0] w_serialized_clk_p_q;       // Serialized clk_p (negedge hclk path)
    logic [47:0] w_serialized_clk_n_q;       // Serialized clk_n (posedge hclk path)
    logic [47:0] w_serialized_track_q;       // Serialized track  (negedge hclk path)
    logic [5:0]  counter_clk_p_q;            // Sample counter for negedge path
    logic [5:0]  counter_clk_n_q;            // Sample counter for posedge path
    logic        w_enable_p_q;               // Latches high on first clk_p assertion
    logic        w_enable_n_q;               // Latches high on first clk_n assertion
    logic [3:0]  counter_correct_p_q;        // Consecutive correct windows for clk_p
    logic [3:0]  counter_correct_n_q;        // Consecutive correct windows for clk_n
    logic [3:0]  counter_correct_track_q;    // Consecutive correct windows for track
    logic        w_enable_clk_q;             // Gate enable: disables after result asserts
    logic        w_hclk;                     // Gated hclk
    logic [2:0]  w_clk_result_q;

    // Gate hclk on its low phase; disable once all three clock results are asserted
    always @(*) begin
        if (!i_hclk)
            w_enable_clk_q = !(&w_clk_result_q); // Disable when all 3 bits are high
    end

    assign w_hclk = i_hclk & w_enable_clk_q;

    // --- negedge path: serialize clk_p and track ---
    always_ff @(negedge w_hclk or posedge i_reset) begin : clock_detection_p_q
        if (i_reset) begin
            w_serialized_clk_p_q    <= 0;
            w_serialized_track_q    <= 0;
            counter_clk_p_q         <= 0;
            w_enable_p_q            <= 0;
            counter_correct_p_q     <= 0;
            counter_correct_track_q <= 0;
        end
        else if (!i_pattern_type[0]) begin
            // Clock detection disabled by pattern_type
            w_serialized_clk_p_q <= 0;
            w_serialized_track_q <= 0;
            counter_clk_p_q      <= 0;
            w_enable_p_q         <= 0;
        end
        else if (i_clk_p && !w_enable_p_q) begin
            // Arm capture on first clk_p high
            w_enable_p_q         <= 1;
            w_serialized_clk_p_q <= {w_serialized_clk_p_q[46:0], i_clk_p};
            w_serialized_track_q <= {w_serialized_track_q[46:0], i_track};
            counter_clk_p_q      <= counter_clk_p_q + 1;
        end
        else if (w_enable_p_q) begin
            w_serialized_clk_p_q <= {w_serialized_clk_p_q[46:0], i_clk_p};
            w_serialized_track_q <= {w_serialized_track_q[46:0], i_track};
            counter_clk_p_q      <= counter_clk_p_q + 1;
        end

        // Every 48 samples: evaluate clk_p and track independently
        if (counter_clk_p_q == 48) begin
            // clk_p counter
            if (counter_correct_p_q != 15) begin
                if (w_serialized_clk_p_q == p_CLK_SEQ_1)
                counter_correct_p_q <= counter_correct_p_q + 1;
            else
                counter_correct_p_q <= 0;
            end
            
            // track counter
            if (counter_correct_track_q !=15) begin
                if (w_serialized_track_q == p_CLK_SEQ_1)
                counter_correct_track_q <= counter_correct_track_q + 1;
            else
                counter_correct_track_q <= 0;
            end
            

            counter_clk_p_q <= 1;
        end
    end

    // --- posedge path: serialize clk_n only ---
    always_ff @(posedge w_hclk or posedge i_reset) begin : clock_detection_n_q
        if (i_reset) begin
            w_serialized_clk_n_q <= 0;
            counter_clk_n_q      <= 0;
            w_enable_n_q         <= 0;
            counter_correct_n_q  <= 0;
        end
        else if (!i_pattern_type[0]) begin
            // Clock detection disabled by pattern_type
            w_serialized_clk_n_q <= 0;
            counter_clk_n_q      <= 0;
            w_enable_n_q         <= 0;
        end
        else if (i_clk_n && !w_enable_n_q) begin
            // Arm capture on first clk_n high
            w_enable_n_q         <= 1;
            w_serialized_clk_n_q <= {w_serialized_clk_n_q[46:0], i_clk_n};
            counter_clk_n_q      <= counter_clk_n_q + 1;
        end
        else if (w_enable_n_q) begin
            w_serialized_clk_n_q <= {w_serialized_clk_n_q[46:0], i_clk_n};
            counter_clk_n_q      <= counter_clk_n_q + 1;
        end

        // Every 48 samples: evaluate clk_n
        if (counter_clk_n_q == 48) begin
            if (counter_correct_n_q != 15) begin
                if (w_serialized_clk_n_q == p_CLK_SEQ_1)
                counter_correct_n_q <= counter_correct_n_q + 1;
            else
                counter_correct_n_q <= 0;
            end
            
            counter_clk_n_q <= 1;
        end
    end

    
    // Each bit asserts independently after 16 consecutive correct 48-bit windows
    assign w_clk_result_q[0] = (counter_correct_p_q     == 15) ? 1 : 0; // clk_p
    assign w_clk_result_q[1] = (counter_correct_n_q     == 15) ? 1 : 0; // clk_n
    assign w_clk_result_q[2] = (counter_correct_track_q == 15) ? 1 : 0; // track


    // =========================================================================
    // SECTION 5: OUTPUT MUX
    // Select between half-rate and quadrature-rate results based on i_halfrate
    // =========================================================================
    always @(*) begin
        if (i_halfrate) begin
            o_valid_result = (i_pattern_type!=2'b11)? w_valid_result_h:w_valid_result_active_h; // Half-rate valid result
            o_clk_result   = w_clk_result_h;  // Half-rate clock result [track|n|p]
        end
        else begin
            o_valid_result = (i_pattern_type!=2'b11)?w_valid_result_q:w_valid_result_active_q; // Quadrature valid result
            o_clk_result   = w_clk_result_q;  // Quadrature clock result [track|n|p]
        end
    end

endmodule
