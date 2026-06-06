`timescale 1ns/1ps

module tb_tx_path;

    // =========================================================
    // Parameters (must match DUT defaults)
    // =========================================================
    parameter int pDATA_WIDTH   = 64;
    parameter int pNUM_LANES    = 16;
    parameter int pRDI_IN_WIDTH = 2048;
    
    parameter real CLK_L_PERIOD = 10.0;   // 100 MHz for i_clk_l
    parameter real DCLK_PERIOD  = 5.0;    // 200 MHz for i_dclk
    parameter real TIMEOUT_NS   = 100000; // 100 us timeout

    // =========================================================
    // DUT Ports - Clock and Reset
    // =========================================================
    logic                      i_clk_l;
    logic                      i_reset;
    logic                      i_dclk;

    // =========================================================
    // DUT Ports - Control
    // =========================================================
    logic                      i_halfrate;
    logic                      i_lp_irdy;
    logic                      i_lp_valid;
    logic [8:0]                i_tx_encoding;
    logic [2:0]                i_lane_map_code;

    // =========================================================
    // DUT Ports - Data Input
    // =========================================================
    logic [pRDI_IN_WIDTH-1:0]  i_lp_data;

    // =========================================================
    // DUT Ports - Outputs
    // =========================================================
    logic                      o_pl_trdy;
    logic                      o_tx_done;
    logic [pNUM_LANES-1:0]     o_data_out;
    logic                      o_clk_p;
    logic                      o_clk_n;
    logic                      o_track;
    logic                      o_valid;

    // =========================================================
    // LTSM State Encoding 
    // =========================================================
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



    // =========================================================
    // DUT Instantiation
    // =========================================================
    tx_path #(
        .pDATA_WIDTH   (pDATA_WIDTH),
        .pNUM_LANES    (pNUM_LANES),
        .pRDI_IN_WIDTH (pRDI_IN_WIDTH)
    ) dut (
        // Clock and reset
        .i_clk_l         (i_clk_l),
        .i_reset         (i_reset),
        .i_dclk          (i_dclk),
        // Control
        .i_halfrate      (i_halfrate),
        .i_lp_irdy       (i_lp_irdy),
        .i_lp_valid      (i_lp_valid),
        .i_tx_encoding   (i_tx_encoding),
        .i_lane_map_code (i_lane_map_code),
        // Data
        .i_lp_data       (i_lp_data),
        // Outputs
        .o_pl_trdy       (o_pl_trdy),
        .o_tx_done       (o_tx_done),
        .o_data_out      (o_data_out),
        .o_clk_p         (o_clk_p),
        .o_clk_n         (o_clk_n),
        .o_track         (o_track),
        .o_valid         (o_valid)
    );

    // =========================================================
    // Clock Generation
    // =========================================================
    initial begin
        i_clk_l = 1'b0;
        forever #(CLK_L_PERIOD / 2.0) i_clk_l = ~i_clk_l;
    end

    initial begin
        i_dclk = 1'b0;
        forever #(DCLK_PERIOD / 2.0) i_dclk = ~i_dclk;
    end


    // =========================================================
    // Test Counter
    // =========================================================
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;
   
    // =========================================================
    // Helper Tasks
    // =========================================================

    // Wait for N posedges on i_clk_l then add a small delta settle time
    task automatic clk_l_cycle(input int n = 1);
        repeat(n) @(posedge i_clk_l);
        #1;
    endtask

    // Wait for N posedges on i_dclk then add a small delta settle time
    task automatic dclk_cycle(input int n = 1);
        repeat(n) @(posedge i_dclk);
        #1;
    endtask

    // Wait for both clocks to be in a stable state
    task automatic wait_both_clks(input int n = 1);
        repeat(n) begin
            @(posedge i_clk_l);
            @(posedge i_dclk);
        end
        #1;
    endtask

    // Print test header
    task automatic print_test_header(input string test_name);
        $display("\n================================================");
        $display("  TEST: %s", test_name);
        $display("================================================");
    endtask

    // Check if scalar signal matches expected value
    task automatic check_signal(
        input string signal_name,
        input logic actual,
        input logic expected
    );
        test_count++;
        if (actual === expected) begin
            pass_count++;
            $display("[PASS] %s = %b (expected %b)", signal_name, actual, expected);
        end else begin
            fail_count++;
            $display("[FAIL] %s = %b (expected %b)", signal_name, actual, expected);
        end
    endtask

    // Check if vector signal matches expected value
    task automatic check_signal_vec(
        input string signal_name,
        input logic [pNUM_LANES-1:0] actual,
        input logic [pNUM_LANES-1:0] expected
    );
        test_count++;
        if (actual === expected) begin
            pass_count++;
            $display("[PASS] %s = 0x%h (expected 0x%h)", signal_name, actual, expected);
        end else begin
            fail_count++;
            $display("[FAIL] %s = 0x%h (expected 0x%h)", signal_name, actual, expected);
        end
    endtask


    // =========================================================
    // Test Sequence
    // =========================================================
    initial begin
        i_lane_map_code = 3'b011; // all lanes are functional
        // reset test 
        print_test_header("Reset Behavior");
         i_reset = 1'b1;
        repeat(5)@(negedge i_clk_l);

        check_signal("o_pl_trdy", o_pl_trdy, 1'bx);
        check_signal("o_tx_done", o_tx_done, 1'b1);
        check_signal_vec("o_data_out", o_data_out, {pNUM_LANES{1'bz}});
        check_signal("o_clk_p", o_clk_p, 1'bz);
        check_signal("o_clk_n", o_clk_n, 1'bz);
        check_signal("o_track", o_track, 1'bz);
        check_signal("o_valid", o_valid, 1'bz);

        i_reset = 1'b0;

        repeat(5)@(negedge i_clk_l);

        // lfsr_pattern test(RX_init_eye_sweep)
        print_test_header("LFSR Patterns");
        @(negedge i_clk_l);
        i_tx_encoding = ENC_MBTRAIN_DATAVREF;
        @(negedge i_clk_l);
        i_tx_encoding = ENC_RX_EYE_LFSR_CLEAR;
        @(negedge i_clk_l);
        i_tx_encoding = ENC_RX_EYE_PAT_GEN;        // Example encoding for LFSR pattern.
        repeat(32) @(negedge i_clk_l); // Wait for pattern to propagate.
        check_signal("o_tx_done", o_tx_done, 1'b1);

        repeat(5)@(negedge i_clk_l);

        // per-lane id pattern test
        print_test_header("Per-Lane ID Patterns");
        @(negedge i_clk_l);
        i_tx_encoding = ENC_MBINIT_REVERSAL_PER_LANE;
        repeat(33)@(negedge i_clk_l); // Wait for pattern to propagate.
        check_signal("o_tx_done", o_tx_done, 1'b1);

        repeat(5)@(negedge i_clk_l);

        // clock pattern test
        print_test_header("clock Pattern Generation");
        @(negedge i_clk_l);
        i_tx_encoding = ENC_MBINIT_REPAIRCLK_PAT_GEN;
        repeat(95)@(negedge i_clk_l); // Wait for pattern to propagate.
        check_signal("o_tx_done", o_tx_done, 1'b1);


        repeat(5)@(negedge i_clk_l);

        // valid pattern test (init)
        print_test_header("valid Pattern Generation_init");
        i_tx_encoding = ENC_MBINIT_REPAIRVAL;
        @(negedge i_clk_l);
        i_tx_encoding = ENC_MBINIT_REPAIRVAL_PAT_GEN;
        repeat(15)@(negedge i_clk_l); // Wait for pattern to propagate.
        check_signal("o_tx_done", o_tx_done, 1'b1);


        repeat(5)@(negedge i_clk_l);

        // valid pattern test (init)
        print_test_header("valid Pattern Generation_train");
        i_tx_encoding = ENC_MBTRAIN_VALVREF;
        @(negedge i_clk_l);
        i_tx_encoding = ENC_RX_EYE_LFSR_CLEAR; // Clear LFSR to known state before training pattern
        @(negedge i_clk_l);
        i_tx_encoding =ENC_RX_EYE_PAT_GEN ;
        repeat(15)@(negedge i_clk_l); // Wait for pattern to propagate.
        check_signal("o_tx_done", o_tx_done, 1'b1);

        repeat(5)@(negedge i_clk_l);

        // per-lane id pattern test(TX_init_eye_sweep)
        print_test_header("Per-Lane ID Patterns_TX_init_eye_sweep");
        @(negedge i_clk_l);
        i_tx_encoding = ENC_MBINIT_REPAIRMB;
        @(negedge i_clk_l);
        i_tx_encoding = ENC_TX_EYE_LFSR_CLEAR;
        @(negedge i_clk_l);
        i_tx_encoding = ENC_TX_EYE_PAT_GEN;        // Example encoding for per-lane ID pattern.
        repeat(33)@(negedge i_clk_l); // Wait for pattern to propagate.
        check_signal("o_tx_done", o_tx_done, 1'b1);

        // width degradation test 
        print_test_header("Width Degradation test");
        @(negedge i_clk_l);
        i_tx_encoding = ENC_MBINIT_REPAIRMB; 
        @(negedge i_clk_l);
        i_lane_map_code = 3'b001; // lanes 0-7 are functional, 8-15 are degraded
        @(negedge i_clk_l);
        i_tx_encoding = ENC_MBINIT_REPAIRMB_APPLY_DEGRADE;
        @(negedge i_clk_l);
        test_count++;
        if (o_data_out[15:8] === 8'bz) begin
            pass_count++;
            $display("[PASS] Width Degradation applied correctly. o_data_out[15:8] = %b (expected 8'bz)", o_data_out[15:8]);
        end else begin
            fail_count++;
            $display("[FAIL] Width Degradation not applied correctly. o_data_out[15:8] = %b (expected 8'bz)", o_data_out[15:8]);
        end

        
        
        // Summary
        $display("\n================================================");
        $display("  TEST SUMMARY");
        $display("================================================");
        $display("  Total checks : %0d", test_count);
        $display("  Passed       : %0d", pass_count);
        $display("  Failed       : %0d", fail_count);
        $display("================================================");
        if (fail_count > 0) begin
            $display("[SUMMARY] Some checks failed.");
        end else begin
            $display("[SUMMARY] All checks passed.");
        end

        #100;
        $stop;

    end

endmodule
