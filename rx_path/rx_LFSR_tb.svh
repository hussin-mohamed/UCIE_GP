`timescale 1ns/1ps

// =============================================================================
//  tb_rx_LFSR_top
//
//  Hierarchy under test
//  rx_LFSR_top
//    └─ rx_LFSR  (×16)
//         ├─ LFSR_pattern_generator
//         └─ rx_LFSR_detection
//
//  Design notes (from reading the RTL):
//   • pclk  = i_clk & p_enable   where p_enable is latched on negedge i_clk
//             p_enable = i_enable & o_lane_success
//   • lclk  = pclk  & l_enable   where l_enable is latched on negedge pclk
//             l_enable = i_train
//   • In training mode  (i_train=1): pattern_tobechecked = pattern XOR i_data_in
//                                    o_data_out = 0
//   • In data mode      (i_train=0): o_data_out = pattern XOR i_data_in
//                                    pattern_tobechecked = 0  → counter stalls
//   • rx_LFSR_detection counter increments on posedge lclk when any bit of
//     pattern_tobechecked is high (enable = |pattern_tobechecked).
//   • o_lane_success = (counter <= i_error_threshhold)
//   • Because p_enable depends on o_lane_success, once the counter exceeds the
//     threshold the clock to the LFSR is also gated off.
// =============================================================================

module tb_rx_LFSR_top;

    // =========================================================================
    // Parameters
    // =========================================================================
    parameter int  pDATA_WIDTH = 64;
    parameter int  pNUM_LANES  = 16;
    parameter real CLK_PERIOD  = 10.0;   // 100 MHz

    parameter logic [pNUM_LANES-1:0][22:0] pLANE_ID_SEED = {
        23'h1BB807, 23'h0277CE, 23'h19CFC9, 23'h010F12,
        23'h18C0DB, 23'h1EC760, 23'h0607BB, 23'h1DBFBC,
        23'h1BB807, 23'h0277CE, 23'h19CFC9, 23'h010F12,
        23'h18C0DB, 23'h1EC760, 23'h0607BB, 23'h1DBFBC
    };

    // =========================================================================
    // DUT ports
    // =========================================================================
    logic                                       i_clk;
    logic                                       i_reset;
    logic                                       i_load;
    logic                                       i_train;
    logic [pNUM_LANES-1:0]                      i_enable;
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0]     i_data_in;
    logic [15:0]                                i_error_threshhold;
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0]     o_data_out;
    logic [pNUM_LANES-1:0]                      o_lane_success;

    // =========================================================================
    // DUT
    // =========================================================================
    rx_LFSR_top #(
        .pDATA_WIDTH   (pDATA_WIDTH),
        .pNUM_LANES    (pNUM_LANES),
        .pLANE_ID_SEED (pLANE_ID_SEED)
    ) dut (
        .i_clk              (i_clk),
        .i_reset            (i_reset),
        .i_load             (i_load),
        .i_train            (i_train),
        .i_enable           (i_enable),
        .i_data_in          (i_data_in),
        .i_error_threshhold (i_error_threshhold),
        .o_data_out         (o_data_out),
        .o_lane_success     (o_lane_success)
    );

    // =========================================================================
    // Reference model — mirrors LFSR_pattern_generator combinational logic
    // =========================================================================
    function automatic logic [22:0] lfsr_next (input logic [22:0] s);
        lfsr_next = {s[21], s[22]^s[20], s[19:16], s[22]^s[15],
                     s[14:8], s[22]^s[7], s[6:5], s[22]^s[4],
                     s[3:2], s[22]^s[1], s[0], s[22]};
    endfunction

    // Advance the reference LFSR pDATA_WIDTH steps and return MSB stream
    function automatic logic [pDATA_WIDTH-1:0] lfsr_pattern
        (input logic [22:0] seed);
        logic [22:0] st;
        st = seed;
        for (int b = 0; b < pDATA_WIDTH; b++) begin
            lfsr_pattern[b] = st[22];
            st = lfsr_next(st);
        end
    endfunction

    // =========================================================================
    // Clock
    // =========================================================================
    initial i_clk = 0;
    always #(CLK_PERIOD / 2.0) i_clk = ~i_clk;

    // =========================================================================
    // Tasks
    // =========================================================================
    task automatic clk_cycle(input int n = 1);
        repeat(n) @(posedge i_clk); #1;
    endtask

    task automatic do_reset();
        @(negedge i_clk); i_reset = 1'b1;
        clk_cycle(2);
        @(negedge i_clk); i_reset = 1'b0;
    endtask

    task automatic load_seed();
        @(negedge i_clk); i_load = 1'b1;
        clk_cycle(1);
        @(negedge i_clk); i_load = 1'b0;
    endtask

    // =========================================================================
    // Score keeping
    // =========================================================================
    int pass_count, fail_count;

    // =========================================================================
    // Test sequence
    // =========================================================================
    initial begin
        // ---- defaults ----
        i_reset            = 0;
        i_load             = 0;
        i_train            = 0;
        i_enable           = '0;
        i_data_in          = '0;
        i_error_threshhold = 16'hFFFF;   // very permissive — success by default
        pass_count = 0; fail_count = 0;

        $display("=======================================================");
        $display("  tb_rx_LFSR_top  —  %0d lanes x %0d-bit", pNUM_LANES, pDATA_WIDTH);
        $display("=======================================================");

        // =====================================================================
        // TEST 1 – Reset clears detection counter → o_lane_success asserted
        // =====================================================================
        $display("\n[TEST 1] Reset: o_lane_success asserted on all lanes after reset");
        i_enable  = '1;
        do_reset();
        clk_cycle(1);
        if (o_lane_success === '1) begin
            $display("  PASS: all lanes report success after reset");
            pass_count++;
        end else begin
            $display("  FAIL: o_lane_success = 0x%04h (expected 0xFFFF)", o_lane_success);
            fail_count++;
        end

        // =====================================================================
        // TEST 2 – Spec req 4.5.3: counter stays idle when there are no errors.
        //
        //  "No error" means i_data_in equals the locally generated pattern, so
        //  pattern_tobechecked = pattern XOR i_data_in = 0 → detection enable=0
        //  → counter never increments.
        //
        //  Strategy:
        //   1. Run training mode for one cycle to capture each lane's pattern.
        //   2. Feed that captured pattern back as i_data_in (perfect match).
        //   3. Reload and run 16 cycles — counter must stay at 0 on every lane.
        //   4. Directly read counter via hierarchical path to confirm value=0.
        //   5. Also confirm lane_success remains asserted.
        // =====================================================================
        $display("\n[TEST 2] counter stays idle with no errors");
        begin
            // Strategy: use a reference model to pre-compute the pattern for
            // every cycle, drive it as i_data_in one cycle ahead so that
            // pattern_tobechecked = pattern XOR i_data_in = 0 every cycle.
            //
            // The LFSR state after load is pLANE_ID_SEED. On each posedge it
            // advances pDATA_WIDTH steps. So cycle N produces:
            //   pattern[N] = lfsr_pattern( seed advanced by N*pDATA_WIDTH steps )
            // We pre-drive i_data_in = pattern[N] before that posedge.
            int idle_fails;
            idle_fails = 0;

            i_error_threshhold = 16'hFFFF;
            i_train            = 1'b1;
            i_enable           = '1;
            do_reset();

            // Timing insight:
            //   lclk = pclk & l_enable  (fires at posedge i_clk when enabled)
            //   pattern_tobechecked is combinational: pattern_out XOR i_data_in
            //   The detection counter samples pattern_tobechecked at posedge lclk.
            //
            // To get XOR=0 at posedge lclk, i_data_in must equal pattern_out
            // BEFORE the posedge. We drive i_data_in on negedge i_clk (half
            // cycle before the posedge), which is the same approach used
            // throughout this TB for all signal changes.
            //
            // Cycle N pattern_out = lfsr_pattern( seed advanced N*pDATA_WIDTH steps )
            //   N=0 : right after load_seed posedge  → seed itself (no advance)
            //   N=1 : after first free-running posedge → seed + 1*pDATA_WIDTH
            //   etc.
            //
            // Drive sequence on negedge:
            //   negedge before load posedge  → i_data_in = pattern[0] = lfsr_pattern(seed)
            //   load posedge fires           → LFSR=seed, lclk fires, XOR=0
            //   negedge after load posedge   → i_data_in = pattern[1]
            //   next posedge fires           → LFSR advances, lclk fires, XOR=0
            //   ... repeat for 16 cycles

            // --- drive i_data_in = pattern[0] on negedge before load posedge ---
            @(posedge i_clk);
            begin
                logic [22:0] ref_st;
                for (int l = 0; l < pNUM_LANES; l++)
                    i_data_in[l] = lfsr_pattern(pLANE_ID_SEED[l]);
            end
            i_load = 1'b1;
            @(posedge i_clk);  // load posedge: LFSR=seed, lclk fires, XOR=0
            
             i_load = 1'b0;
             @(posedge i_clk);

            // --- cycles 1..16: update i_data_in on each negedge then cross posedge ---
            for (int cyc = 1; cyc <= 16; cyc++) begin
                // negedge: drive pattern[cyc] so it's stable before next posedge
                begin
                    logic [22:0] ref_st;
                    for (int l = 0; l < pNUM_LANES; l++) begin
                        ref_st = pLANE_ID_SEED[l];
                        for (int b = 0; b < cyc * pDATA_WIDTH; b++)
                            ref_st = lfsr_next(ref_st);
                        i_data_in[l] = lfsr_pattern(ref_st);
                    end
                end
                @(posedge i_clk); #1;  // posedge: LFSR advances, lclk fires, XOR=0
                if (cyc < 16) @(negedge i_clk);  // prep next negedge (skip after last)
            end

            // --- Step 4: verify counter = 0 on every lane via hierarchical path ---
            // Generate blocks require a constant index at elaboration time, so a
            // macro is used to check each lane individually with a fixed index.
            `define CHECK_COUNTER(IDX) \
                if (dut.lane_gen[IDX].u_LFSR.det.counter !== 16'h0) begin \
                    $display("  FAIL lane %0d: counter = %0d (expected 0)", \
                             IDX, dut.lane_gen[IDX].u_LFSR.det.counter); \
                    idle_fails++; \
                    fail_count++; \
                end

            `CHECK_COUNTER( 0) `CHECK_COUNTER( 1) `CHECK_COUNTER( 2) `CHECK_COUNTER( 3)
            `CHECK_COUNTER( 4) `CHECK_COUNTER( 5) `CHECK_COUNTER( 6) `CHECK_COUNTER( 7)
            `CHECK_COUNTER( 8) `CHECK_COUNTER( 9) `CHECK_COUNTER(10) `CHECK_COUNTER(11)
            `CHECK_COUNTER(12) `CHECK_COUNTER(13) `CHECK_COUNTER(14) `CHECK_COUNTER(15)
            `undef CHECK_COUNTER

            if (idle_fails == 0) begin
                $display("  PASS: counter = 0 on all lanes after 16 perfect-match cycles");
                pass_count++;
            end

            // --- Step 5: lane_success must still be asserted ---
            if (o_lane_success === '1) begin
                $display("  PASS: lane_success remains high (no errors counted)");
                pass_count++;
            end else begin
                $display("  FAIL: lane_success unexpectedly deasserted: 0x%04h", o_lane_success);
                fail_count++;
            end
        end

        // =====================================================================
        // TEST 3 – Threshold trip: set threshold = 0 → counter immediately
        //          exceeds it on first non-zero pattern_tobechecked pulse
        //          → o_lane_success must deassert.
        // =====================================================================
        $display("\n[TEST 3] Threshold=0: lane_success deasserts when counter > 0");
        begin
            i_error_threshhold = 16'h0000;
            do_reset();
            load_seed();
            i_train   = 1'b1;
            i_data_in = '0;
            clk_cycle(4);   // give counter a few cycles to increment past 0
            // o_lane_success = (counter <= 0) → false once counter reaches 1
            if (o_lane_success === '0) begin
                $display("  PASS: all lanes deasserted with threshold=0");
                pass_count++;
            end else begin
                $display("  FAIL: o_lane_success = 0x%04h (expected 0x0000)", o_lane_success);
                fail_count++;
            end
            // Restore threshold
            i_error_threshhold = 16'hFFFF;
        end

        // =====================================================================
        // TEST 4 – Reset restores lane_success after threshold trip
        // =====================================================================
        $display("\n[TEST 4] Reset restores lane_success after deassert");
        begin
            do_reset();
            clk_cycle(1);
            if (o_lane_success === '1) begin
                $display("  PASS: lane_success restored after reset");
                pass_count++;
            end else begin
                $display("  FAIL: lane_success = 0x%04h after reset", o_lane_success);
                fail_count++;
            end
        end

        // =====================================================================
        // TEST 5 – Data mode: o_data_out = pattern XOR i_data_in
        //          Verified using the reference model.
        //
        //  Timing note:
        //   • load_seed() pulses i_load on a posedge → LFSR registers the seed.
        //   • On the NEXT posedge the LFSR advances by pDATA_WIDTH steps
        //     (next[pDATA_WIDTH]) and the combinational pattern output reflects
        //     that new state.
        //   • Therefore the reference must also advance pDATA_WIDTH steps from
        //     the seed before extracting the MSB stream for cycle 1.
        // =====================================================================
        $display("\n[TEST 5] Data mode: o_data_out = pattern XOR i_data_in");
        begin
            logic [22:0] ref_state;
            logic [pDATA_WIDTH-1:0] ref_pattern, expected_out;
            int data_fails;

            data_fails = 0;

            // Set unique data per lane
            for (int l = 0; l < pNUM_LANES; l++)
                i_data_in[l] = 64'(l * 64'hFEDCBA9876543210 + 64'h0123456789ABCDEF);

            i_error_threshhold = 16'hFFFF;
            do_reset();
            load_seed();
            i_train = 1'b0;    // data mode
            clk_cycle(1);

            // Reference: advance seed by pDATA_WIDTH steps (= one LFSR word clock),
            // then read the MSB stream for that next word.
            for (int l = 0; l < pNUM_LANES; l++) begin
                ref_state = pLANE_ID_SEED[l];
                // Advance pDATA_WIDTH steps — mirrors next[pDATA_WIDTH] in RTL
                for (int b = 0; b < pDATA_WIDTH; b++)
                    ref_state = lfsr_next(ref_state);
                ref_pattern  = lfsr_pattern(ref_state);
                expected_out = ref_pattern ^ i_data_in[l];
                if (o_data_out[l] !== expected_out) begin
                    $display("  FAIL lane %0d: expected 0x%016h got 0x%016h",
                             l, expected_out, o_data_out[l]);
                    data_fails++;
                    fail_count++;
                end
            end
            if (data_fails == 0) begin
                $display("  PASS: descrambled output matches reference on all lanes");
                pass_count++;
            end
        end

        // =====================================================================
        // TEST 6 – Data mode: o_data_out = 0 when i_data_in = pattern
        //          (self-scramble check: receiving own LFSR output gives zero)
        // =====================================================================
        $display("\n[TEST 6] Data mode: receiving own pattern gives all-zero output");
        begin
            logic [pDATA_WIDTH-1:0] ref_pat;
            int self_fails;
            self_fails = 0;

            do_reset();
            load_seed();
            i_train = 1'b0;
            // Feed the cycle-1 pattern (seed advanced pDATA_WIDTH steps) so XOR = 0
            for (int l = 0; l < pNUM_LANES; l++) begin
                logic [22:0] st;
                st = pLANE_ID_SEED[l];
                for (int b = 0; b < pDATA_WIDTH; b++)
                    st = lfsr_next(st);
                i_data_in[l] = lfsr_pattern(st);
            end
            clk_cycle(1);

            for (int l = 0; l < pNUM_LANES; l++) begin
                if (o_data_out[l] !== '0) begin
                    $display("  FAIL lane %0d: expected 0x0 got 0x%016h", l, o_data_out[l]);
                    self_fails++;
                    fail_count++;
                end
            end
            if (self_fails == 0) begin
                $display("  PASS: self-scramble produces all-zero on all lanes");
                pass_count++;
            end
        end

        // =====================================================================
        // TEST 7 – Per-lane enable: disabled lanes must not change state.
        //          Use data mode (i_train=0): o_data_out = pattern XOR i_data_in.
        //          With i_data_in=0, o_data_out == raw pattern, so LFSR advance
        //          is visible.  In training mode o_data_out is hardwired to 0
        //          making advance detection impossible.
        //          Data mode also keeps pattern_tobechecked=0 so the detection
        //          counter never increments and lane_success stays high.
        // =====================================================================
        $display("\n[TEST 7] Per-lane enable: disabled lanes freeze");
        begin
            logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] snap_before, snap_after;
            int freeze_fails;

            i_error_threshhold = 16'hFFFF;
            i_data_in          = '0;
            i_train            = 1'b0;   // data mode: o_data_out = pattern XOR 0 = pattern
            do_reset();
            i_enable = '1;
            load_seed();
            clk_cycle(2);               // let all lanes settle with lane_success=1

            // Disable even lanes
            @(negedge i_clk); i_enable = 16'hAAAA;
            clk_cycle(1);
            snap_before = o_data_out;
            clk_cycle(4);
            snap_after = o_data_out;

            freeze_fails = 0;
            for (int l = 0; l < pNUM_LANES; l++) begin
                if (l % 2 == 0) begin
                    // even — disabled — should freeze
                    if (snap_after[l] !== snap_before[l]) begin
                        $display("  FAIL lane %0d (disabled): output changed", l);
                        freeze_fails++;
                        fail_count++;
                    end
                end else begin
                    // odd — enabled — should advance
                    if (snap_after[l] === snap_before[l]) begin
                        $display("  FAIL lane %0d (enabled): output frozen", l);
                        freeze_fails++;
                        fail_count++;
                    end
                end
            end
            if (freeze_fails == 0) begin
                $display("  PASS: disabled lanes frozen, enabled lanes advanced");
                pass_count++;
            end
        end

        // =====================================================================
        // TEST 8 – lane_success gates pclk: after threshold trip on one lane
        //          that lane's LFSR must freeze (pclk gated off).
        // =====================================================================
        $display("\n[TEST 8] lane_success gate: LFSR freezes after threshold trip");
        begin
            logic [pDATA_WIDTH-1:0] snap_tripped, snap_later;
            int gate_fails;

            // Use a very low threshold so lane 0 trips quickly
            i_error_threshhold = 16'h0002;
            i_data_in          = '0;
            i_train            = 1'b1;
            i_enable           = '1;
            do_reset();
            load_seed();

            // Wait enough cycles for counter to exceed threshold=2
            clk_cycle(6);

            // All lanes should have tripped (threshold=2, counter increments
            // each lclk while pattern_tobechecked != 0)
            if (o_lane_success === '0) begin
                $display("  PASS: all lanes deasserted (threshold=2, counter>2)");
                pass_count++;
            end else begin
                $display("  FAIL: o_lane_success = 0x%04h, expected 0x0000", o_lane_success);
                fail_count++;
            end

            // After trip, output must not change even if clock keeps running
            snap_tripped = o_data_out;
            clk_cycle(4);
            snap_later = o_data_out;

            gate_fails = 0;
            for (int l = 0; l < pNUM_LANES; l++) begin
                if (snap_later[l] !== snap_tripped[l]) begin
                    $display("  FAIL lane %0d: output changed after pclk gate", l);
                    gate_fails++;
                    fail_count++;
                end
            end
            if (gate_fails == 0) begin
                $display("  PASS: all lane outputs frozen after lane_success=0");
                pass_count++;
            end

            // Restore
            i_error_threshhold = 16'hFFFF;
        end

        // =====================================================================
        // TEST 9 – Consecutive reloads produce identical pattern sequences
        // =====================================================================
        $display("\n[TEST 9] Deterministic replay: two seed loads produce same sequence");
        begin
            logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] seq_a [0:7];
            logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] seq_b [0:7];
            int replay_fails;

            i_error_threshhold = 16'hFFFF;
            i_train            = 1'b0;
            i_data_in          = '0;
            i_enable           = '1;

            // Run A
            do_reset(); load_seed();
            for (int c = 0; c < 8; c++) begin
                clk_cycle(1); seq_a[c] = o_data_out;
            end

            // Run B
            do_reset(); load_seed();
            for (int c = 0; c < 8; c++) begin
                clk_cycle(1); seq_b[c] = o_data_out;
            end

            replay_fails = 0;
            for (int c = 0; c < 8; c++) begin
                for (int l = 0; l < pNUM_LANES; l++) begin
                    if (seq_a[c][l] !== seq_b[c][l]) begin
                        $display("  FAIL lane %0d cycle %0d: A=0x%016h B=0x%016h",
                                 l, c, seq_a[c][l], seq_b[c][l]);
                        replay_fails++;
                        fail_count++;
                    end
                end
            end
            if (replay_fails == 0) begin
                $display("  PASS: both runs produce identical 8-cycle sequences");
                pass_count++;
            end
        end

        // =====================================================================
        // TEST 10 – Long-run: o_data_out never all-zero in data mode with
        //           non-trivial input (confirms LFSR never locks up)
        // =====================================================================
        $display("\n[TEST 10] Long-run stability in data mode (128 cycles)");
        begin
            int zero_hits;
            zero_hits = 0;

            i_error_threshhold = 16'hFFFF;
            i_train            = 1'b0;
            i_enable           = '1;
            for (int l = 0; l < pNUM_LANES; l++)
                i_data_in[l] = 64'hDEAD_BEEF_CAFE_1234;

            do_reset(); load_seed();
            for (int c = 0; c < 128; c++) begin
                clk_cycle(1);
                for (int l = 0; l < pNUM_LANES; l++) begin
                    if (o_data_out[l] === '0) begin
                        $display("  FAIL lane %0d: all-zero output at cycle %0d", l, c);
                        zero_hits++;
                        fail_count++;
                    end
                end
            end
            if (zero_hits == 0) begin
                $display("  PASS: no all-zero outputs over 128 cycles");
                pass_count++;
            end
        end

        // =====================================================================
        // Summary
        // =====================================================================
        $display("\n=======================================================");
        $display("  RESULTS: %0d PASS  |  %0d FAIL", pass_count, fail_count);
        $display("=======================================================");
        if (fail_count == 0)
            $display("  ALL TESTS PASSED");
        else
            $display("  SOME TESTS FAILED — review log above");

        $finish;
    end

    // =========================================================================
    // Watchdog
    // =========================================================================
    initial begin
        #2_000_000;
        $display("TIMEOUT: simulation exceeded limit");
        $finish;
    end

endmodule