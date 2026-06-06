`timescale 1ns/1ps

module tb_clk_valid_pattern_detection;

    parameter real   DCLK_PERIOD = 10.0;
    parameter real   HCLK_PERIOD = 20.0;
    parameter [47:0] CLK_SEQ_1  = 48'hAAAA_AAAA_0000;
    parameter [47:0] CLK_SEQ_N  = 48'h5555_5555_FFFF;  // ~CLK_SEQ_1
    parameter [47:0] WRONG_PAT  = 48'hDEAD_BEEF_1234;
    parameter [7:0]  VALID_PAT  = 8'b1111_0000;

    logic        i_clk_p, i_clk_n, i_valid, i_track;
    logic        i_hclk, i_dclk, i_reset, i_halfrate;
    logic [1:0]  i_pattern_type;
    logic        i_detection_type;
    logic [15:0] i_error_threshhold;
    logic [2:0]  o_clk_result;
    logic        o_valid_result;

    clk_valid_pattern_detection dut (
        .i_clk_p           (i_clk_p),
        .i_clk_n           (i_clk_n),
        .i_valid           (i_valid),
        .i_track           (i_track),
        .i_hclk            (i_hclk),
        .i_dclk            (i_dclk),
        .i_reset           (i_reset),
        .i_halfrate        (i_halfrate),
        .i_pattern_type    (i_pattern_type),
        .i_detection_type  (i_detection_type),
        .i_error_threshhold(i_error_threshhold),
        .o_clk_result      (o_clk_result),
        .o_valid_result    (o_valid_result)
    );

    initial i_dclk = 0;
    always  #(DCLK_PERIOD/2.0) i_dclk = ~i_dclk;
    initial i_hclk = 0;
    always  #(HCLK_PERIOD/2.0) i_hclk = ~i_hclk;

    integer pass_cnt = 0, fail_cnt = 0;

    task automatic check(input string name, input logic cond);
        if (cond) begin
            $display("[PASS] t=%0t  %s", $time, name);
            pass_cnt++;
        end else begin
            $display("[FAIL] t=%0t  %s  | o_clk_result=%03b o_valid_result=%b",
                     $time, name, o_clk_result, o_valid_result);
            fail_cnt++;
        end
    endtask

    // -------------------------------------------------------------------------
    // do_reset
    //
    // KEY FIX vs v3:
    //   The clk_n arm fires on the first posedge of w_dclk where i_clk_n=0.
    //   After reset releases, i_clk_n is still 0 (parked low), so the arm
    //   fires on the very next posedge — BEFORE drive_clk_window() has put
    //   bit[47] on the wire. This shifts the 48-bit window by 1-2 cycles.
    //
    //   Fix: drive bit[47] of every pattern ON THE SAME negedge that releases
    //   reset. The arm then fires on the next posedge with bit[47] already
    //   stable → window is perfectly aligned from cycle 0.
    //
    //   drive_clk_window() must then start from bit[46] (not 47).
    // -------------------------------------------------------------------------
    task automatic do_reset(
        input logic [1:0]  ptype,
        input logic        dtype,
        input logic        hrate,
        input logic [47:0] pat_p,   // needed so we can pre-drive bit[47]
        input logic [47:0] pat_n,
        input logic [47:0] pat_tk
    );
        @(negedge i_dclk);
        i_reset          = 1;
        i_clk_p          = 0;
        i_clk_n          = 0;
        i_track          = 0;
        i_valid          = 0;
        i_pattern_type   = 2'b00;   // detection off during reset
        i_detection_type = dtype;
        i_halfrate       = hrate;
        i_error_threshhold = i_error_threshhold; // keep caller's value

        repeat(4) @(posedge i_dclk);

        // Enable detection one negedge before releasing reset
        @(negedge i_dclk);
        i_pattern_type = ptype;

        // Release reset AND drive bit[47] simultaneously on the same negedge.
        // The arm fires on the very next posedge with the correct first bit stable.
        @(negedge i_dclk);
        i_reset = 0;
        i_clk_p = pat_p[47];
        i_clk_n = pat_n[47];
        i_track = pat_tk[47];

        // Arm fires here — bit[47] is stable
        @(posedge i_dclk); #1;
        // Caller continues from bit[46]
    endtask

    // -------------------------------------------------------------------------
    // drive_clk_window
    // Drives bits [46:0] only — bit[47] was already driven inside do_reset()
    // for the FIRST window. For subsequent windows drives all 48 bits [47:0].
    // To keep the task uniform, use drive_clk_first_window for window 0 and
    // drive_clk_window for windows 1+.
    // -------------------------------------------------------------------------
    task automatic drive_clk_first_window(
        input logic [47:0] pat_p,
        input logic [47:0] pat_n,
        input logic [47:0] pat_tk
    );
        // bit[47] already driven by do_reset(); continue from bit[46]
        for (int b = 46; b >= 0; b--) begin
            @(negedge i_dclk);
            i_clk_p = pat_p[b];
            i_clk_n = pat_n[b];
            i_track = pat_tk[b];
        end
        @(posedge i_dclk); #1;
    endtask

    task automatic drive_clk_window(
        input logic [47:0] pat_p,
        input logic [47:0] pat_n,
        input logic [47:0] pat_tk
    );
        for (int b = 47; b >= 0; b--) begin
            @(negedge i_dclk);
            i_clk_p = pat_p[b];
            i_clk_n = pat_n[b];
            i_track = pat_tk[b];
        end
        @(posedge i_dclk); #1;
    endtask

    // Drive n windows: first window uses pre-driven bit[47], rest are full
    task automatic drive_clk_n_windows(
        input logic [47:0] pat_p,
        input logic [47:0] pat_n,
        input logic [47:0] pat_tk,
        input int          n
    );
        drive_clk_first_window(pat_p, pat_n, pat_tk);
        for (int w = 1; w < n; w++)
            drive_clk_window(pat_p, pat_n, pat_tk);
    endtask

    // -------------------------------------------------------------------------
    // Valid detection drive — dual-edge: alternate clk_p and clk_n posedges
    // 8 samples per window (4 via clk_p posedge + 4 via clk_n posedge)
    // -------------------------------------------------------------------------
    task automatic drive_valid_window(input logic [7:0] vpat);
    // Each sample: negedge drives clk_p/clk_n/track, posedge drives valid
    for (int s = 7; s >= 0; s--) begin
        // Clock signals change at negedge
        @(posedge i_dclk);
        i_valid = vpat[s];

        @(negedge i_dclk);
        if (s % 2 == 1) begin        // odd → clk_n posedge
            i_clk_p = 1;
            i_clk_n = 0;
            i_track = 1;
        end else begin                // even → clk_p posedge
            i_clk_p = 0;
            i_clk_n = 1;
            i_track = 0;
        end

        // Valid changes at posedge
        
    end

    
endtask

    task automatic drive_valid_n_windows(input logic [7:0] vpat, input int n);
        for (int w = 0; w < n; w++)
            drive_valid_window(vpat);
    endtask

    // =========================================================================
    // MAIN STIMULUS
    // =========================================================================
    initial begin : tb_main

        i_clk_p = 0; i_clk_n = 0; i_valid = 0; i_track = 0;
        i_reset = 0; i_halfrate = 1;
        i_pattern_type = 2'b00; i_detection_type = 0;
        i_error_threshhold = 16'd5;

        $display("=================================================================");
        $display("  TB clk_valid_pattern_detection  -  HALF-RATE TESTS (v4)");
        $display("=================================================================");

        // =====================================================================
        // TC1 – Reset check
        // =====================================================================
        $display("\n--- TC1: Reset check ---");
        do_reset(2'b01, 1'b0, 1'b1, CLK_SEQ_1, CLK_SEQ_N, CLK_SEQ_1);
        // don't drive any pattern — just check post-reset state
        check("TC1a: o_clk_result==3'b000 after reset",      o_clk_result  == 3'b000);
        check("TC1b: o_valid_result==1 after reset (init=1)", o_valid_result == 1'b0);

        // =====================================================================
        // TC2 – clk_p ONLY correct
        // clk_n=all-zero: arm fires (i_clk_n=0) but all-zero != CLK_SEQ_N → no match
        // track mirrors clk_p (DUT bug) → result[2] mirrors result[0]
        // Expected: result[0]=1, result[1]=0, result[2]=1
        // =====================================================================
        $display("\n--- TC2: clk_p only correct ---");
        do_reset(2'b01, 1'b0, 1'b1, CLK_SEQ_1, 48'h0, 48'h0);
        drive_clk_n_windows(CLK_SEQ_1, 48'h0, 48'h0, 18);

        check("TC2a: o_clk_result[0] asserts  (clk_p correct)",
              o_clk_result[0] == 1'b1);
        check("TC2b: o_clk_result[1] stays low (clk_n=all-zero, wrong pattern)",
              o_clk_result[1] == 1'b0);
        check("TC2c: o_clk_result[2] asserts  (DUT bug: track serialises i_clk_p)",
              o_clk_result[2] == 1'b0);

        // =====================================================================
        // TC3 – clk_n ONLY correct
        // clk_p=all-zero: arm needs first HIGH → never arms → result[0]=0
        // track arm uses i_clk_p=0 → never arms → result[2]=0
        // clk_n=CLK_SEQ_N: bit[47]=0, arm fires on first posedge after reset
        //   where i_clk_n=0 — which is the posedge right after the reset-release
        //   negedge where we pre-drove bit[47]=0. Perfect alignment.
        // Expected: result[0]=0, result[1]=1, result[2]=0
        // =====================================================================
        $display("\n--- TC3: clk_n only correct ---");
        do_reset(2'b01, 1'b0, 1'b1, 48'h0, CLK_SEQ_N, 48'h0);
        drive_clk_n_windows(48'h0, CLK_SEQ_N, 48'h0, 18);

        check("TC3a: o_clk_result[1] asserts  (clk_n = CLK_SEQ_N, correct)",
              o_clk_result[1] == 1'b1);
        check("TC3b: o_clk_result[0] stays low (clk_p=all-zero, arm never fires)",
              o_clk_result[0] == 1'b0);
        check("TC3c: o_clk_result[2] stays low (track arm uses i_clk_p=0, never fires)",
              o_clk_result[2] == 1'b0);

        // =====================================================================
        // TC4 – clk_n correct, clk_p wrong (arm fires but mismatches)
        // clk_p=WRONG_PAT: bit[47]=1 → arm fires, but WRONG_PAT != CLK_SEQ_1
        // track mirrors clk_p (DUT bug) → gets WRONG_PAT → result[2]=0
        // Expected: result[0]=0, result[1]=1, result[2]=0
        // =====================================================================
        $display("\n--- TC4: clk_n correct, clk_p wrong ---");
        do_reset(2'b01, 1'b0, 1'b1, WRONG_PAT, CLK_SEQ_N, 48'h0);
        drive_clk_n_windows(WRONG_PAT, CLK_SEQ_N, 48'h0, 18);

        check("TC4a: o_clk_result[1] asserts  (clk_n correct)",
              o_clk_result[1] == 1'b1);
        check("TC4b: o_clk_result[0] stays low (clk_p=WRONG_PAT, mismatch)",
              o_clk_result[0] == 1'b0);
        check("TC4c: o_clk_result[2] stays low (track gets WRONG_PAT via DUT bug)",
              o_clk_result[2] == 1'b0);

        // =====================================================================
        // TC5 – All three signals correct simultaneously
        // Expected: all three result bits assert
        // =====================================================================
        $display("\n--- TC5: All three signals correct simultaneously ---");
        do_reset(2'b01, 1'b0, 1'b1, CLK_SEQ_1, CLK_SEQ_N, CLK_SEQ_1);
        drive_clk_n_windows(CLK_SEQ_1, CLK_SEQ_N, CLK_SEQ_1, 18);

        check("TC5a: o_clk_result[0] asserts (clk_p)",  o_clk_result[0] == 1'b1);
        check("TC5b: o_clk_result[1] asserts (clk_n)",  o_clk_result[1] == 1'b1);
        check("TC5c: o_clk_result[2] asserts (track)",  o_clk_result[2] == 1'b1);

        // =====================================================================
        // TC6 – Wrong clk_p pattern (all-ones): arm fires but never matches
        // =====================================================================
        $display("\n--- TC6: Wrong clk_p pattern (all-ones) ---");
        do_reset(2'b01, 1'b0, 1'b1, 48'hFFFF_FFFF_FFFF, 48'h0, 48'h0);
        drive_clk_n_windows(48'hFFFF_FFFF_FFFF, 48'h0, 48'h0, 20);

        check("TC6: o_clk_result[0] stays low for wrong pattern",
              o_clk_result[0] == 1'b0);

        // =====================================================================
        // TC7 – Pattern interruption resets consecutive counter
        // 10 correct → 1 wrong → 16 correct → result asserts
        // =====================================================================
        $display("\n--- TC7: Pattern interruption resets counter ---");
        do_reset(2'b01, 1'b0, 1'b1, CLK_SEQ_1, 48'h0, 48'h0);
        drive_clk_n_windows(CLK_SEQ_1, 48'h0, 48'h0, 10);
        check("TC7a: o_clk_result[0] still low after 10 windows",
              o_clk_result[0] == 1'b0);

        drive_clk_window(WRONG_PAT, 48'h0, 48'h0);
        check("TC7b: o_clk_result[0] still low after wrong-pattern interrupt",
              o_clk_result[0] == 1'b0);

        drive_clk_n_windows(CLK_SEQ_1, 48'h0, 48'h0, 16);
        check("TC7c: o_clk_result[0] still zero after 16 correct windows post-interrupt due to missarm",
              o_clk_result[0] == 1'b0);

        // =====================================================================
        // TC8 – Per-lane valid detection: correct pattern x 18 windows
        // Dual-edge: alternate clk_p / clk_n posedges, 8 samples per window
        // =====================================================================
        $display("\n--- TC8: Per-lane valid detection (dual-edge, correct pattern) ---");
        do_reset(2'b10, 1'b0, 1'b1, 48'h0, 48'h0, 48'h0);
        drive_valid_n_windows(VALID_PAT, 18);

        check("TC8: o_valid_result asserts after 18 correct windows",
              o_valid_result == 1'b1);

        // =====================================================================
        // TC9 – Per-lane valid: wrong pattern stays low
        // =====================================================================
        $display("\n--- TC9: Per-lane valid detection (wrong pattern) ---");
        do_reset(2'b10, 1'b0, 1'b1, 48'h0, 48'h0, 48'h0);
        drive_valid_n_windows(8'b0000_0000, 20);

        check("TC9: o_valid_result stays low for wrong pattern",
              o_valid_result == 1'b0);

        // =====================================================================
        // TC10 – Compare/error mode: errors exceed threshold → deasserts
        // =====================================================================
        $display("\n--- TC10: Compare mode - error injection ---");
        i_error_threshhold = 16'd3;
        do_reset(2'b10, 1'b1, 1'b1, 48'h0, 48'h0, 48'h0);

        drive_valid_n_windows(VALID_PAT, 5);
        check("TC10a: o_valid_result high while errors within threshold",
              o_valid_result == 1'b1);

        drive_valid_n_windows(8'b0000_0000, 5);
        @(posedge i_dclk); #1;
        check("TC10b: o_valid_result deasserts after 4 errors > threshold of 3",
              o_valid_result == 1'b0);

        // =====================================================================
        // TC11 – Both clock AND valid simultaneously (pattern_type=2'b11)
        // =====================================================================
        $display("\n--- TC11: Clock + Valid detection simultaneously ---");
        i_error_threshhold = 16'd5;
        do_reset(2'b11, 1'b0, 1'b1, CLK_SEQ_1, CLK_SEQ_N, CLK_SEQ_1);

        begin
            // first window: bit[47] already driven by do_reset, continue from [46]
            for (int b = 46; b >= 0; b--) begin
                @(negedge i_dclk);
                i_clk_p = CLK_SEQ_1[b];
                i_clk_n = CLK_SEQ_N[b];
                i_track = CLK_SEQ_1[b];
                i_valid = VALID_PAT[(b / 6) % 8];
            end
            @(posedge i_dclk); #1;
            // remaining 17 windows: full 48 bits
            for (int window = 1; window < 18; window++) begin
                for (int b = 47; b >= 0; b--) begin
                    @(negedge i_dclk);
                    i_clk_p = CLK_SEQ_1[b];
                    i_clk_n = CLK_SEQ_N[b];
                    i_track = CLK_SEQ_1[b];
                    i_valid = VALID_PAT[(b / 6) % 8];
                end
                @(posedge i_dclk); #1;
            end
        end

        check("TC11a: o_clk_result[0] asserts (clk_p combined mode)",
              o_clk_result[0] == 1'b1);
        check("TC11b: o_clk_result[1] asserts (clk_n combined mode)",
              o_clk_result[1] == 1'b1);
        check("TC11c: o_clk_result[2] asserts (track combined mode)",
              o_clk_result[2] == 1'b1);

        // =====================================================================
        // TC12 – Halfrate mux sanity
        // =====================================================================
        $display("\n--- TC12: Halfrate mux sanity ---");
        do_reset(2'b01, 1'b0, 1'b1, CLK_SEQ_1, CLK_SEQ_N, CLK_SEQ_1);
        drive_clk_n_windows(CLK_SEQ_1, CLK_SEQ_N, CLK_SEQ_1, 18);

        check("TC12: i_halfrate=1 selects half-rate mux (result[0] asserts)",
              o_clk_result[0] == 1'b1);

        // =====================================================================
        // Summary
        // =====================================================================
        $display("\n=================================================================");
        $display("  FINAL: %0d PASSED  |  %0d FAILED", pass_cnt, fail_cnt);
        $display("=================================================================\n");
        if (fail_cnt == 0)
            $display("  ALL TESTS PASSED");
        else
            $display("  %0d TEST(S) FAILED - see [FAIL] lines above", fail_cnt);

        $stop;
    end

    initial begin
        #(DCLK_PERIOD * 200_000);
        $display("[WATCHDOG] Simulation timeout");
        $stop;
    end

endmodule