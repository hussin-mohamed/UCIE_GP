`timescale 1ns/1ps

module tb_tx_LFSR_top;

    // =========================================================
    // Parameters (must match DUT defaults)
    // =========================================================
    parameter int pDATA_WIDTH = 64;
    parameter int pNUM_LANES  = 16;
    parameter real CLK_PERIOD = 10.0; // 100 MHz

    parameter logic [pNUM_LANES-1:0][22:0] pLANE_ID_SEED = {
        23'h1BB807, 23'h0277CE, 23'h19CFC9, 23'h010F12,
        23'h18C0DB, 23'h1EC760, 23'h0607BB, 23'h1DBFBC,
        23'h1BB807, 23'h0277CE, 23'h19CFC9, 23'h010F12,
        23'h18C0DB, 23'h1EC760, 23'h0607BB, 23'h1DBFBC
    };

    // =========================================================
    // DUT Ports
    // =========================================================
    logic                                       i_clk;
    logic                                       i_load;
    logic                                       i_train;
    logic [pNUM_LANES-1:0]                      i_enable;
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0]     i_data_in;
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0]     o_data_out;

    // =========================================================
    // DUT Instantiation
    // =========================================================
    tx_LFSR_top #(
        .pDATA_WIDTH   (pDATA_WIDTH),
        .pNUM_LANES    (pNUM_LANES),
        .pLANE_ID_SEED (pLANE_ID_SEED)
    ) dut (
        .i_clk      (i_clk),
        .i_load     (i_load),
        .i_train    (i_train),
        .i_enable   (i_enable),
        .i_data_in  (i_data_in),
        .o_data_out (o_data_out)
    );

    // =========================================================
    // Clock
    // =========================================================
    initial i_clk = 0;
    always #(CLK_PERIOD / 2.0) i_clk = ~i_clk;

    // =========================================================
    // Helper Tasks
    // =========================================================

    // Wait for N posedges then add a small delta settle time
    task automatic clk_cycle(input int n = 1);
        repeat(n) @(posedge i_clk);
        #1;
    endtask

    // Pulse i_load for one clock cycle (driven on negedge to be
    // stable well before the subsequent posedge)
    task automatic load_seed();
        @(negedge i_clk); i_load = 1'b1;
        clk_cycle(1);
        @(negedge i_clk); i_load = 1'b0;
    endtask

    // =========================================================
    // Scoreboard storage
    // =========================================================
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] snap_a, snap_b;
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] train_snap [0:7];
    int pass_count, fail_count;

    // =========================================================
    // Test Sequence
    // =========================================================
    initial begin
        // ---- Init ----
        i_load    = 0;
        i_train   = 0;
        i_enable  = '0;
        i_data_in = '0;
        pass_count = 0;
        fail_count = 0;

        $display("=======================================================");
        $display("  tb_tx_LFSR_top  —  %0d lanes x %0d-bit", pNUM_LANES, pDATA_WIDTH);
        $display("=======================================================");

        // =========================================================
        // TEST 1 – All lanes enabled, load seed, training mode
        //          Verify every lane produces a non-zero pattern.
        // =========================================================
        $display("\n[TEST 1] Seed load: all lanes non-zero in training mode");
        @(negedge i_clk); i_enable = '1;
        load_seed();
        i_train = 1'b1;
        clk_cycle(1);
        begin
            int zero_lanes = 0;
            for (int l = 0; l < pNUM_LANES; l++) begin
                if (o_data_out[l] === '0) begin
                    $display("  FAIL lane %0d: all-zero output immediately after load", l);
                    zero_lanes++;
                    fail_count++;
                end
            end
            if (zero_lanes == 0) begin
                $display("  PASS: all lanes non-zero after load");
                pass_count++;
            end
        end

        // =========================================================
        // TEST 2 – Each lane has a UNIQUE pattern (distinct seeds)
        //          Lanes 0-7 share the same seeds as lanes 8-15, so
        //          pairs (0,8),(1,9),...,(7,15) will match — that is
        //          the expected DUT behaviour and is flagged as INFO.
        // =========================================================
        $display("\n[TEST 2] Lane uniqueness check");
        snap_a = o_data_out;
        begin
            int unique_fails = 0;
            for (int a = 0; a < pNUM_LANES; a++) begin
                for (int b = a+1; b < pNUM_LANES; b++) begin
                    // pairs (a, a+8) share seeds by design — skip them
                    if (b == a + 8) begin
                        if (snap_a[a] === snap_a[b])
                            $display("  INFO: lane %0d and %0d share seed (expected match)", a, b);
                        else begin
                            $display("  FAIL: lane %0d and %0d share seed but outputs differ!", a, b);
                            unique_fails++;
                            fail_count++;
                        end
                    end else begin
                        if (snap_a[a] !== snap_a[b]) begin
                            // expected
                        end else begin
                            $display("  FAIL: lane %0d and %0d unexpectedly match (0x%016h)", a, b, snap_a[a]);
                            unique_fails++;
                            fail_count++;
                        end
                    end
                end
            end
            if (unique_fails == 0) begin
                $display("  PASS: lane outputs are unique (seed-pair matches as expected)");
                pass_count++;
            end
        end

        // =========================================================
        // TEST 3 – LFSR advances every cycle (no stall)
        // =========================================================
        $display("\n[TEST 3] LFSR advances each clock cycle");
        begin
            logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] prev, curr;
            int stall_count = 0;
            prev = o_data_out;
            for (int c = 0; c < 8; c++) begin
                clk_cycle(1);
                curr = o_data_out;
                for (int l = 0; l < pNUM_LANES; l++) begin
                    if (curr[l] === prev[l]) begin
                        $display("  FAIL lane %0d: output unchanged at cycle %0d", l, c);
                        stall_count++;
                        fail_count++;
                    end
                end
                prev = curr;
                train_snap[c] = curr; // save for later replay check
            end
            if (stall_count == 0) begin
                $display("  PASS: all lanes advance each cycle over 8 cycles");
                pass_count++;
            end
        end

        // =========================================================
        // TEST 4 – Deterministic replay: reload seed, re-run,
        //          compare against snapshots from TEST 3.
        // =========================================================
        $display("\n[TEST 4] Deterministic replay after seed reload");
        load_seed();
        clk_cycle(1); // cycle 0 after load (matches train_snap[0] base)
        begin
            int replay_fails = 0;
            for (int c = 0; c < 8; c++) begin
                clk_cycle(1);
                for (int l = 0; l < pNUM_LANES; l++) begin
                    if (o_data_out[l] !== train_snap[c][l]) begin
                        $display("  FAIL lane %0d cycle %0d: expected 0x%016h got 0x%016h",
                                 l, c, train_snap[c][l], o_data_out[l]);
                        replay_fails++;
                        fail_count++;
                    end
                end
            end
            if (replay_fails == 0) begin
                $display("  PASS: all lanes replay identically after seed reload");
                pass_count++;
            end
        end

        // =========================================================
        // TEST 5 – Scramble mode: o_data_out = pattern XOR i_data_in
        // =========================================================
        $display("\n[TEST 5] Scramble mode correctness");
        begin
            logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] raw, scrambled, expected;

            // Capture raw pattern (train mode)
            load_seed();
            i_train = 1'b1;
            clk_cycle(1);
            raw = o_data_out;

            // Set up unique per-lane data patterns
            for (int l = 0; l < pNUM_LANES; l++)
                i_data_in[l] = 64'(l * 64'hA5A5A5A5_A5A5A5A5 + 64'h1234_5678_9ABC_DEF0);

            // Capture scrambled output (same seed, same cycle offset)
            load_seed();
            i_train = 1'b0;
            clk_cycle(1);
            scrambled = o_data_out;

            // Verify
            begin
                int scr_fails = 0;
                for (int l = 0; l < pNUM_LANES; l++) begin
                    expected[l] = raw[l] ^ i_data_in[l];
                    if (scrambled[l] !== expected[l]) begin
                        $display("  FAIL lane %0d: expected 0x%016h got 0x%016h",
                                 l, expected[l], scrambled[l]);
                        scr_fails++;
                        fail_count++;
                    end
                end
                if (scr_fails == 0) begin
                    $display("  PASS: scramble output = pattern XOR data_in on all lanes");
                    pass_count++;
                end
            end
        end

        // =========================================================
        // TEST 6 – Per-lane clock gate: disable individual lanes,
        //          their output must freeze; other lanes must keep
        //          advancing.
        // =========================================================
        $display("\n[TEST 6] Per-lane clock gate isolation");
        begin
            logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] frozen_snap, live_snap;
            // Use training mode for visibility
            load_seed();
            i_train   = 1'b1;
            i_enable  = '1;
            clk_cycle(2);

            // Disable even lanes, keep odd lanes running
            @(negedge i_clk); i_enable = 16'hAAAA; // odd lanes only
            clk_cycle(1);
            frozen_snap = o_data_out; // snapshot while even lanes just froze

            clk_cycle(4); // let odd lanes advance 4 more times
            live_snap = o_data_out;

            begin
                int gate_fails = 0;
                for (int l = 0; l < pNUM_LANES; l++) begin
                    if (l % 2 == 0) begin
                        // even lane — should be frozen
                        if (live_snap[l] !== frozen_snap[l]) begin
                            $display("  FAIL lane %0d (disabled): output changed 0x%016h -> 0x%016h",
                                     l, frozen_snap[l], live_snap[l]);
                            gate_fails++;
                            fail_count++;
                        end
                    end else begin
                        // odd lane — should have advanced
                        if (live_snap[l] === frozen_snap[l]) begin
                            $display("  FAIL lane %0d (enabled): output frozen unexpectedly", l);
                            gate_fails++;
                            fail_count++;
                        end
                    end
                end
                if (gate_fails == 0) begin
                    $display("  PASS: disabled lanes frozen, enabled lanes advanced");
                    pass_count++;
                end
            end
        end

        // =========================================================
        // TEST 7 – Re-enable frozen lanes; verify they resume
        // =========================================================
        $display("\n[TEST 7] Re-enable frozen lanes — verify they resume");
        begin
            logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] before_reenable;
            before_reenable = o_data_out;

            @(negedge i_clk); i_enable = '1; // re-enable all
            clk_cycle(1);

            begin
                int resume_fails = 0;
                for (int l = 0; l < pNUM_LANES; l++) begin
                    if (l % 2 == 0) begin // previously frozen lanes
                        if (o_data_out[l] === before_reenable[l]) begin
                            $display("  FAIL lane %0d: did not advance after re-enable", l);
                            resume_fails++;
                            fail_count++;
                        end
                    end
                end
                if (resume_fails == 0) begin
                    $display("  PASS: all previously frozen lanes resumed after re-enable");
                    pass_count++;
                end
            end
        end

        // =========================================================
        // TEST 8 – Long run stability: no lane produces all-zero
        //          output over 256 consecutive cycles
        // =========================================================
        $display("\n[TEST 8] Long-run stability — no all-zero outputs (256 cycles)");
        load_seed();
        i_train  = 1'b1;
        i_enable = '1;
        begin
            int zero_hits = 0;
            for (int c = 0; c < 256; c++) begin
                clk_cycle(1);
                for (int l = 0; l < pNUM_LANES; l++) begin
                    if (o_data_out[l] === '0) begin
                        $display("  FAIL lane %0d: all-zero at cycle %0d", l, c);
                        zero_hits++;
                        fail_count++;
                    end
                end
            end
            if (zero_hits == 0) begin
                $display("  PASS: no all-zero output on any lane over 256 cycles");
                pass_count++;
            end
        end

        // =========================================================
        // Summary
        // =========================================================
        $display("\n=======================================================");
        $display("  RESULTS: %0d PASS  |  %0d FAIL", pass_count, fail_count);
        $display("=======================================================");
        if (fail_count == 0)
            $display("  ALL TESTS PASSED");
        else
            $display("  SOME TESTS FAILED — review log above");

        $finish;
    end

    // =========================================================
    // Watchdog
    // =========================================================
    initial begin
        #1_000_000;
        $display("TIMEOUT: simulation exceeded limit");
        $finish;
    end

endmodule