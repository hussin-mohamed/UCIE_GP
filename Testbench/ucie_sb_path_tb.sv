`define SIM
`timescale 1ns/1ps

// =============================================================================
//  Testbench : ucie_sb_path_tb
//
//  Covers TX (ucie_sb_tx_path) and RX (ucie_sb_rx_path) in two independent
//  DUT sections. All tests are sequential inside a single initial block.
//
//  Clock topology (both from same PLL source, therefore phase-aligned):
//    i_clk   : 10 ns period  (100 MHz)  — TX FSM / control
//    i_s_clk :  1.25 ns period (800 MHz) — TX SerDes output (8× i_clk)
//    i_rx_sb_clk : driven manually inside each RX test
//
//  TX test plan:
//    T1 - Pattern correctness on i_s_clk
//         • First bit = 1 (ui_counter=0 → ~0=1)
//         • Alternates every i_s_clk cycle for 64 UIs
//         • Bits 64-95 are 0 (32-UI quiet period)
//    T2 - i_rx_done mid-iteration: waits for ui_counter==95 then → EXTRA_ITERS
//         (state must NOT jump to EXTRA_ITERS before current iteration ends)
//    T3 - 1ms timer in CYCLING mid-iteration:
//         • Pattern stops immediately (o_tx_sb_data/clk → 0)
//         • ui_counter resets to 0 in the CYCLING OFF phase
//         • ON phase resumes a fresh iteration starting at bit 0
//    T4 - 1ms timer in EXTRA_ITERS:
//         • r_1ms_active does NOT toggle (toggle condition requires CYCLING)
//         • Pattern generation continues uninterrupted through the timer pulse
//    T5 - Clock domain verification:
//         • o_tx_sb_data changes at i_s_clk edges (not at i_clk-only edges)
//         • o_stop changes at i_clk edges when state becomes DONE
//
//  RX test plan:
//    T6 - Clean 2 full iterations → detection exactly at last bit of iter 2
//    T7 - Detection starting mid-iteration:
//         Start at bit 41 (24 bits left of iter 1) → 24 + 64 + 40 = 128
//         Verify o_done fires partway through iteration 3
//    T8 - Pattern break mid-count resets counter → must accumulate 128 fresh
// =============================================================================

module ucie_sb_path_tb;

    // =========================================================================
    // Clocks
    // =========================================================================
    logic i_clk    = 0;
    logic i_s_clk = 0;     // 800 MHz SerDes clock (8× i_clk)
    logic i_rx_sb_clk = 0; // manually controlled per RX test
 
    always #5  i_clk   = ~i_clk;          // 10 ns period
 
    // i_s_clk = 800 MHz (1.25 ns period = 0.625 ns half-period)
    // 8× faster than i_clk; both derived from the same PLL source
    always #0.625 i_s_clk = ~i_s_clk;

    // =========================================================================
    // TX DUT signals
    // =========================================================================
    logic       tx_reset;
    logic       tx_sb_init_start;
    logic       tx_timer_1ms;
    logic       tx_rx_done;
    logic       tx_o_sb_data;
    logic       tx_o_sb_clk;
    logic       tx_o_stop;

    ucie_sb_tx_path tx_dut (
        .i_clk          (i_clk),
        .i_s_clk        (i_s_clk),
        .i_reset        (tx_reset),
        .i_sb_init_start(tx_sb_init_start),
        .i_timer_1ms    (tx_timer_1ms),
        .i_rx_done      (tx_rx_done),
        .o_tx_sb_data   (tx_o_sb_data),
        .o_tx_sb_clk    (tx_o_sb_clk),
        .o_stop         (tx_o_stop)
    );

    // =========================================================================
    // RX DUT signals
    // =========================================================================
    logic rx_reset;
    logic rx_sb_init_start;
    logic rx_i_sb_data;
    logic rx_o_done;

    ucie_sb_rx_path rx_dut (
        .i_rx_sb_clk    (i_rx_sb_clk),
        .i_reset        (rx_reset),
        .i_sb_init_start(rx_sb_init_start),
        .i_rx_sb_data   (rx_i_sb_data),
        .o_done         (rx_o_done)
    );

    // =========================================================================
    // Pass / fail tracking
    // =========================================================================
    int pass_count = 0;
    int fail_count = 0;

    task automatic check(input string label, input logic ok);
        if (ok) begin $display("  [PASS] %s", label); pass_count++; end
        else    begin $display("  [FAIL] %s  @ time=%0t", label, $time); fail_count++; end
    endtask

    // =========================================================================
    // TX helper tasks
    // =========================================================================

    // Advance exactly N SerDes (i_s_clk) cycles
    task automatic sclk(input int n);
        repeat (n) @(posedge i_s_clk);
    endtask

    // Advance exactly N system (i_clk) cycles
    task automatic clk(input int n);
        repeat (n) @(posedge i_clk);
    endtask

    // Run TX DUT through one complete 96-UI iteration on i_s_clk and verify
    // the alternating pattern (first bit relative to ui_counter=0 context).
    // Call this task when ui_counter is already 0 at entry.
    task automatic verify_one_iteration(input string tag);
        // The output registered on i_s_clk shows the w_gen value from the
        // previous cycle (non-blocking assignment lag of one cycle).
        // ui_counter was 0 at the previous edge, so first output = ~0[0] = 1.
        int expected;
        for (int i = 0; i < 64; i++) begin
            // After posedge i_s_clk, output reflects ~(i mod 2)
            @(posedge i_s_clk); // tiny settle after edge
            expected = (i % 2 == 0) ? 1 : 0; // bit 0 (counter=0) → 1, bit 1 → 0 …
            check($sformatf("%s: bit[%0d] data=%0d clk=%0d",
                            tag, i, expected, expected),
                  tx_o_sb_data === logic'(expected) && tx_o_sb_clk === logic'(expected));
        end
        // 32 quiet UIs
        for (int i = 0; i < 32; i++) begin
            @(posedge i_s_clk);
            check($sformatf("%s: quiet UI[%0d] data=0 clk=0", tag, 64+i),
                  tx_o_sb_data === 1'b0 && tx_o_sb_clk === 1'b0);
        end
    endtask

    // =========================================================================
    // RX helper tasks
    // =========================================================================

    // Generate one posedge of i_rx_sb_clk with data_val on the input.
    // The RX DUT samples on posedge i_rx_sb_clk.
    task automatic rx_bit(input logic data_val);
        i_rx_sb_clk  = 0;
        rx_i_sb_data = data_val;
        #5;  // half period low
        i_rx_sb_clk  = 1; // posedge — RX DUT samples here
        #5;  // half period high
    endtask

    // Drive N alternating clock+data pulses starting with start_val.
    task automatic rx_alt(input int n, input logic start_val);
        logic v;
        v = start_val;
        for (int i = 0; i < n; i++) begin
            rx_bit(v);
            v = ~v;
        end
    endtask

    // Drive N 'gap' ticks: no clock (i_rx_sb_clk stays 0), data doesn't matter.
    // Simulates the 32-UI low section where the TX sends no clock.
    task automatic rx_gap(input int n);
        repeat (n) #10;   // just wait; no clock edge
    endtask

    // =========================================================================
    // MAIN
    // =========================================================================
    initial begin

        logic saved_data;

        // Defaults
        tx_reset         = 1;
        tx_sb_init_start = 0;
        tx_timer_1ms     = 0;
        tx_rx_done       = 0;
        rx_reset         = 1;
        rx_sb_init_start = 0;
        rx_i_sb_data     = 0;

        $display("\n========== ucie_sb_path_tb ==========\n");

        // =====================================================================
        // T1 — Pattern correctness on i_s_clk
        //   After init_start, CYCLING begins on the next i_clk edge.
        //   Outputs are registered on i_s_clk, so the first correct output
        //   appears at the i_s_clk edge immediately after w_pattern_running
        //   goes high.  The expected sequence: 1,0,1,0 … (64 bits) then 32×0.
        // =====================================================================
        $display("\n--- T1: Pattern correctness on SerDes clock ---");

        clk(3);
        tx_reset = 0;

        // Start pattern generation
        @(negedge i_clk); tx_sb_init_start = 1;
        clk(1);  // state → CYCLING on this i_clk posedge; w_pattern_running rises

        // Verify one full 96-UI iteration
        // The task advances 96 i_s_clk posedges internally and checks each bit
        verify_one_iteration("T1");

        // After the iteration the pattern wraps — confirm next bit is 1 again
        @(posedge i_s_clk);
        check("T1: wraps to 1 at start of iteration 2", tx_o_sb_data === 1'b1);

        // =====================================================================
        // T2 — i_rx_done mid-iteration: waits for ui_counter==95
        //   Assert i_rx_done while ui_counter is somewhere mid-iteration.
        //   The state machine must stay in CYCLING until the current iteration
        //   completes (ui_counter reaches 95), then jump to EXTRA_ITERS.
        // =====================================================================
        $display("\n--- T2: rx_done mid-iteration waits for iteration end ---");

        // Advance to bit 40 of the current iteration (~40 i_s_clk cycles)
        sclk(40);
        check("T2: still in CYCLING mid-iteration",
              tx_dut.current_state === 2'b01); // CYCLING

        // Assert rx_done now (mid-iteration)
        @(negedge i_clk); tx_rx_done = 1;

        // State must still be CYCLING (ui_counter != 95)
        @(negedge i_clk);
        check("T2: state stays CYCLING when rx_done fires mid-iteration",
              tx_dut.current_state === 2'b01);

        // Run to the end of the current iteration (remaining bits: 95-40=55 more)
        sclk(55);
        // At ui_counter == 95 the combinational next_state will become EXTRA_ITERS
        // and be registered at the next i_clk posedge
        @(posedge i_clk);
        check("T2: transitions to EXTRA_ITERS after iteration ends",
              tx_dut.current_state === 2'b10); // EXTRA_ITERS
        check("T2: iter_counter starts at 0",
              tx_dut.iter_counter === 3'd0);

        @(negedge i_clk); tx_rx_done = 0;


        // =====================================================================
        // T3 — 1ms timer in CYCLING mid-iteration
        //   Reset the DUT so we can re-enter CYCLING cleanly.
        //   After a few bits fire i_timer_1ms while in CYCLING.
        //   • r_1ms_active must toggle to 0
        //   • w_pattern_running drops → o_tx_sb_data/clk go to 0
        //   • ui_counter resets to 0 (CYCLING OFF branch)
        //   When i_timer_1ms fires again:
        //   • r_1ms_active toggles back to 1
        //   • A fresh iteration starts at bit 0 (not where we stopped)
        // =====================================================================
        $display("\n--- T3: 1ms timer in CYCLING mid-iteration ---");

        @(negedge i_clk); tx_reset = 1;
        clk(3);
        @(negedge i_clk); tx_reset = 0;
        @(negedge i_clk); tx_sb_init_start = 1;
        clk(1); // → CYCLING

        // Advance 30 i_s_clk cycles into the iteration
        sclk(30);
        check("T3 setup: in CYCLING with bits running",
              tx_dut.current_state === 2'b01 && tx_dut.r_1ms_active === 1'b1);

        // Fire 1ms timer (one i_clk cycle pulse)
        @(negedge i_clk); tx_timer_1ms = 1;
        @(negedge i_clk); tx_timer_1ms = 0;
        // r_1ms_active should now be 0 (toggled on the pulse edge)
        check("T3: r_1ms_active toggled to 0 after timer pulse",
              tx_dut.r_1ms_active === 1'b0);

        // Wait a couple i_s_clk cycles so the output register updates
        sclk(2); #1;
        check("T3: o_tx_sb_data = 0 during OFF period",   tx_o_sb_data === 1'b0);
        check("T3: o_tx_sb_clk  = 0 during OFF period",   tx_o_sb_clk  === 1'b0);

        // Wait one more i_s_clk cycle to confirm ui_counter was reset to 0
        @(posedge i_s_clk); #1;
        check("T3: ui_counter resets to 0 in CYCLING OFF",
              tx_dut.ui_counter === 7'd0);

        // Fire timer again to re-enable generation
        @(negedge i_clk); tx_timer_1ms = 1;
        @(negedge i_clk); tx_timer_1ms = 0;
        check("T3: r_1ms_active back to 1 after second timer pulse",
              tx_dut.r_1ms_active === 1'b1);

        // First i_s_clk edge after re-enable should output bit 0 of a fresh iteration
        sclk(1);
        check("T3: fresh iteration starts — first output bit is 1 (counter=0)",
              tx_o_sb_data === 1'b1);

        // =====================================================================
        // T4 — 1ms timer in EXTRA_ITERS has no effect
        //   r_1ms_active only toggles when current_state == CYCLING.
        //   Once in EXTRA_ITERS, firing the timer must not stop the pattern.
        // =====================================================================
        $display("\n--- T4: 1ms timer in EXTRA_ITERS has no effect ---");

        // Get into EXTRA_ITERS: assert rx_done at end of the ongoing iteration
        // Wait until we are near the end of an iteration then assert rx_done
        // (we need ui_counter == 95 simultaneously with the rx_done check)
        @(negedge i_clk); tx_rx_done = 1;
        begin : t4_wait_loop
            int watchdog;
            watchdog = 0;
            while (tx_dut.ui_counter !== 7'd95) begin
                @(posedge i_s_clk);
                watchdog = watchdog + 1;
                if (watchdog > 200) begin
                    $display("  [TIMEOUT] T4 setup could not find ui_counter=95");
                    break;
                end
            end
        end
        @(negedge i_clk); tx_rx_done = 0;
        @(posedge i_clk);
        check("T4 setup: in EXTRA_ITERS",
              tx_dut.current_state === 2'b10); // EXTRA_ITERS

        // Advance a few bits into the first extra iteration
        sclk(20);
        saved_data = tx_o_sb_data;

        // Fire 1ms timer while in EXTRA_ITERS
        @(negedge i_clk); tx_timer_1ms = 1;
        @(negedge i_clk); tx_timer_1ms = 0;
        check("T4: r_1ms_active unchanged (still 1) after timer in EXTRA_ITERS",
              tx_dut.r_1ms_active === 1'b1);

        // Pattern must continue — data must still be generated (not all zeros)
        sclk(2); 
        check("T4: o_tx_sb_data still active (non-zero pattern) after timer",
              tx_dut.w_pattern_running === 1'b1);

        // Let 4 iterations complete so state reaches DONE
        begin : t4_done_wait
            int watchdog2;
            watchdog2 = 0;
            while (tx_dut.current_state !== 2'b11) begin
                sclk(1);
                watchdog2 = watchdog2 + 1;
                if (watchdog2 > 600) begin
                    $display("  [TIMEOUT] T4: waited too long for DONE");
                    break;
                end
            end
        end
        check("T4: reached DONE after 4 extra iterations",
              tx_dut.current_state === 2'b11); // DONE

        // =====================================================================
        // T5 — Clock domain verification
        //   o_tx_sb_data must change at i_s_clk edges, not at i_clk-only edges.
        //   o_stop must change at i_clk edges when state becomes DONE.
        //
        //   i_s_clk runs at 800 MHz (0.625 ns half-period); i_clk at 100 MHz
        //   (5 ns half-period).  Between any two consecutive i_clk posedges
        //   there are exactly 8 i_s_clk posedges.
        //   At an i_clk-only observation point (between two i_s_clk edges)
        //   o_tx_sb_data has NOT changed — it only changes on i_s_clk posedges.
        // =====================================================================

        $display("\n--- T5: Clock domain verification ---");

        // o_stop — should be high now (we are in DONE)
        #1; // settle
        check("T5: o_stop=1 combinationally from i_clk domain state=DONE",
              tx_o_stop === 1'b1);

        // Reload DUT to get back into CYCLING for data-clock domain check
        @(negedge i_clk); tx_reset = 1;
        clk(3); tx_reset = 0;
        @(negedge i_clk); tx_sb_init_start = 1;
        clk(1); // → CYCLING, w_pattern_running=1

        // Wait for i_clk posedge (NOT i_s_clk posedge)
        // At this point in time (i_clk posedge + 1 ns), i_s_clk has NOT fired,
        // so o_tx_sb_data should NOT have changed yet.
        begin
            logic data_before_sclk;
            @(posedge i_clk);               // sample just after i_clk edge
            data_before_sclk = tx_o_sb_data;

            @(posedge i_s_clk); #1;             // now sample after i_s_clk edge
            // o_tx_sb_data should have CHANGED (registered on i_s_clk)
            check("T5: o_tx_sb_data updates at i_s_clk edge, not i_clk edge",
                  tx_o_sb_data !== data_before_sclk ||
                  (data_before_sclk === 1'b0 && tx_o_sb_data === 1'b1));
                  // Note: on the very first cycle the transition from 0→1 is enough.
        end

        // Verify o_stop changes at i_clk edge: disable init, push through DONE again
        @(negedge i_clk); tx_sb_init_start = 0; // next IDLE entry
        // Confirm o_stop follows state (currently CYCLING/IDLE, so 0)
        #1;
        check("T5: o_stop=0 when state is not DONE", tx_o_stop === 1'b0);

        // =====================================================================
        // =====================================================================
        // RX TESTS
        // =====================================================================
        // =====================================================================

        // Release RX reset and start init
        @(negedge i_clk); rx_reset = 1;
        clk(3);           rx_reset = 0;
        @(negedge i_clk); rx_sb_init_start = 1;
        rx_i_sb_data = 0;
        i_rx_sb_clk  = 0;

        // =====================================================================
        // T6 — Clean 2 full iterations → detection
        //   TX sends 96 UIs per iteration: 64 alternating + 32 no-clock.
        //   RX samples only on posedge i_rx_sb_clk (gated during quiet period).
        //   64 transitions per iteration × 2 = 128 total → detection exactly
        //   at the last bit of iteration 2.
        //
        //   RX pattern_cnt trace:
        //     Transition 1   (iter1, bit0, 1≠0)  → cnt=1
        //     …
        //     Transition 64  (iter1, bit63, 0≠1) → cnt=64
        //     [32 UI gap — no clock — cnt stays 64]
        //     Transition 65  (iter2, bit0, 1≠0)  → cnt=65
        //     …
        //     Transition 127 (iter2, bit62, 1≠0) → cnt=127
        //     Transition 128 (iter2, bit63, 0≠1) → cnt=128 AND flag set
        // =====================================================================
        $display("\n--- T6: Clean 2 full iterations -> detection ---");

        // Feed iteration 1: 64 alternating bits starting with 1
        rx_alt(64, 1'b1);
        check("T6 after iter 1: o_done still 0 (only 64/128 transitions seen)",
              rx_o_done === 1'b0);
        check("T6 after iter 1: pattern_cnt = 64",
              rx_dut.pattern_cnt === 8'd64);

        // Simulate 32-UI quiet period: no clock pulses, data irrelevant
        rx_gap(32);
        check("T6 after gap: pattern_cnt unchanged at 64",
              rx_dut.pattern_cnt === 8'd64);

        // Feed iteration 2: 64 more alternating bits
        // First bit must continue the alternation: last bit of iter1 was 0 (bit63)
        // so next bit must be 1 to create a transition
        rx_alt(63, 1'b1); // first 63 bits (transitions 65-127)
        check("T6: o_done still 0 after 127 transitions",
              rx_o_done === 1'b0);
        check("T6: pattern_cnt = 127 after 127 transitions",
              rx_dut.pattern_cnt === 8'd127);

        // 128th transition — detection fires on this posedge
        rx_bit(1'b0); // last bit of iter2 (counter was at 1, this is a 0)
        check("T6: o_done = 1 after exactly 128 transitions", rx_o_done === 1'b1);
        check("T6: detected_flag latched",                    rx_dut.r_detected_flag === 1'b1);

        // =====================================================================
        // T7 — Detection starting mid-iteration (spanning 3 partial iterations)
        //   Start feeding from bit 41 of iteration 1 (24 bits remaining).
        //   After 128 consecutive transitions we need:
        //     24 (tail of iter1) + 64 (full iter2) + 40 (head of iter3) = 128
        //   Verification:
        //     After tail of iter1: cnt = 24
        //     After gap1:          cnt = 24 (no change)
        //     After iter2:         cnt = 88
        //     After gap2:          cnt = 88
        //     After 39 bits of iter3: cnt = 127
        //     After 40th bit:      cnt = 128, flag = 1
        // =====================================================================
        $display("\n--- T7: Detection mid-iteration spanning 3 partial iters ---");

        // Reset RX for a clean state
        rx_reset = 1; i_rx_sb_clk = 0;
        clk(3); rx_reset = 0;
        rx_sb_init_start = 1;
        rx_i_sb_data = 0;

        // Simulate: we are at bit 41 of iteration 1.
        // Bit 40 (0-indexed) = ui_counter=40 = ~40[0] = ~0 = 1
        // Bit 41 = ui_counter=41 = ~41[0] = ~1 = 0 → first bit we drive = 0
        // prev_data = 0 (reset), so first driven bit (0) is NOT a transition.
        // We actually want to start at a point where the first bit IS a transition.
        // Bit 40: data=1, transitions from prev=0 ✓
        // So feed 24 bits starting with 1 (bits 40..63 of iter1).
        rx_alt(24, 1'b1); // bits 40-63 of iter1 → 24 transitions
        check("T7: cnt = 24 after tail of iter1",
              rx_dut.pattern_cnt === 8'd24);

        // 32-UI gap (no clock)
        rx_gap(32);
        check("T7: cnt unchanged at 24 after gap",
              rx_dut.pattern_cnt === 8'd24);
        check("T7: o_done still 0", rx_o_done === 1'b0);

        // Full iter2: 64 bits starting with 1 (bit63 of iter1 was 0)
        rx_alt(64, 1'b1); // → 24+64 = 88 transitions
        check("T7: cnt = 88 after iter2",
              rx_dut.pattern_cnt === 8'd88);
        check("T7: o_done still 0 after iter2", rx_o_done === 1'b0);

        // 32-UI gap
        rx_gap(32);
        check("T7: cnt unchanged at 88 after second gap",
              rx_dut.pattern_cnt === 8'd88);

        // First 39 bits of iter3
        rx_alt(39, 1'b1); // → 88+39 = 127
        check("T7: cnt = 127 after 39 bits of iter3",
              rx_dut.pattern_cnt === 8'd127);
        check("T7: o_done still 0 at cnt=127", rx_o_done === 1'b0);

        // 40th bit of iter3 → 128th transition → detection
        rx_bit(1'b0);
        check("T7: o_done = 1 at bit 40 of iter3 (128 total)", rx_o_done === 1'b1);

        // =====================================================================
        // T8 — Pattern break mid-count resets counter
        //   Feed 60 valid alternating bits → cnt=60.
        //   Then drive two identical bits in a row → transition fails → cnt=0.
        //   Then feed 128 fresh transitions → detection.
        // =====================================================================
        $display("\n--- T8: Pattern break resets counter; needs 128 fresh transitions ---");

        // Reset RX
        rx_reset = 1; i_rx_sb_clk = 0;
        clk(3); rx_reset = 0;
        rx_sb_init_start = 1;
        rx_i_sb_data = 0;

        // Feed 60 valid alternating bits (cnt → 60)
        rx_alt(60, 1'b1);
        check("T8: cnt = 60 after 60 valid transitions",
              rx_dut.pattern_cnt === 8'd60);

        // Break the pattern: drive same bit twice (no transition)
        // Last bit was bit59 = ~59[0] = ~1 = 0; drive 0 again → no transition
        rx_bit(1'b0); // same as prev → cnt resets to 0
        check("T8: cnt resets to 0 after pattern break",
              rx_dut.pattern_cnt === 8'd0);
        check("T8: o_done still 0 after break",
              rx_o_done === 1'b0);

        // Now feed 128 fresh alternating bits across two iterations
        // Iteration A: 64 bits
        rx_alt(64, 1'b1); // First bit (1) transitions from prev=0 → cnt=64
        rx_gap(32);
        // Iteration B: 64 bits → total 128 → detection
        rx_alt(63, 1'b1);
        check("T8: cnt = 127 before final transition",
              rx_dut.pattern_cnt === 8'd127);
        rx_bit(1'b0); // 128th fresh transition
        check("T8: o_done = 1 after 128 fresh consecutive transitions",
              rx_o_done === 1'b1);

        // =====================================================================
        // Summary
        // =====================================================================
        $display("\n====================================================");
        $display("  RESULTS: %0d passed,  %0d failed", pass_count, fail_count);
        $display("====================================================\n");
        if (fail_count == 0) $display("  ALL TESTS PASSED\n");
        else                  $display("  SOME TESTS FAILED — review log above\n");
        $finish;
    end

    // =========================================================================
    // Watchdog
    // =========================================================================
    initial begin
        #500_000;
        $display("[WATCHDOG] Simulation timed out");
        $finish;
    end

    // =========================================================================
    // Waveform dump
    // =========================================================================
    initial begin
        $dumpfile("ucie_sb_path_tb.vcd");
        $dumpvars(0, ucie_sb_path_tb);
    end

endmodule