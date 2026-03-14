`define SIM
`timescale 1ns/1ps

// =============================================================================
//  Testbench : ucie_ltsm_init_fsm_tb
//
//  Simple walk-through of every FSM inside the top-level main FSM.
//  Driving style mirrors the individual TX / RX TBs you provided:
//    TX sub-FSMs  : i_sb_tx_done pulses the done_ack latch,
//                   i_sb_tx_rsp + i_tx_decoding advances state / fires done
//    RX sub-FSMs  : i_sb_rx_done pulses the done_ack latch,
//                   i_sb_rx_req  + i_rx_decoding advances state / fires done
//  TX and RX are driven independently on separate wires.
//
//  Test plan:
//    T1  - Hard reset  → state=RESET, encodings=0x00
//    T2  - RESET       → SBINIT      (pll+supply+4ms)
//    T3  - SBINIT      → MBINIT_PARAM
//    T4  - MBINIT_PARAM → MBINIT_CAL
//    T5  - MBINIT_CAL  → MBINIT_REPAIRCLK
//    T6  - MBINIT_REPAIRCLK → MBINIT_REPAIRVAL
//    T7  - MBINIT_REPAIRVAL → MBINIT_REVERSAL
//    T8  - MBINIT_REVERSAL  → MBINIT_REPAIRMB
//    T9  - MBINIT_REPAIRMB  → o_init_train_en=1 (parked)
//    T10 - 8ms timeout in MBINIT_CAL → TRAINERROR  (mux=0x40)
//    T11 - TRAINERROR done HS → RESET5
//    T12 - RESET restarts cleanly → SBINIT
// =============================================================================

module ucie_ltsm_init_fsm_tb;

    // -------------------------------------------------------------------------
    // DUT ports
    // -------------------------------------------------------------------------
    logic        i_clk;
    logic        i_reset;
    // TX path
    logic [8:0]  i_tx_decoding;
    logic [63:0] i_tx_data;
    logic [15:0] i_tx_info;
    logic        i_sb_tx_req;
    logic        i_sb_tx_rsp;
    logic        i_sb_tx_done;
    logic        i_tx_done;
    // RX path
    logic [8:0]  i_rx_decoding;
    logic [63:0] i_rx_data;
    logic [15:0] i_rx_info;
    logic        i_sb_rx_req;
    logic        i_sb_rx_rsp;
    logic        i_sb_rx_done;
    logic        i_rx_done;
    // RESET-specific
    logic        i_pll_stable;
    logic        i_supply_stable;
    logic        i_timer_4ms;
    // SBINIT-specific
    logic        i_stop;
    // Pattern results (pre-set to all-ones = all good)
    logic [63:0] i_rx_repairclk_pattern_results;
    logic [63:0] i_rx_repairval_pattern_results;
    logic [63:0] i_rx_reversal_pattern_results;
    // Eye sweep
    logic [7:0]  i_tx_sweep_result;
    logic [7:0]  i_rx_sweep_result;
    // Timeout / error
    logic        o_timer_8ms;
    logic        i_train_active_error;
    // Muxed outputs
    logic [8:0]  o_tx_encoding;
    logic [63:0] o_tx_data;
    logic [15:0] o_tx_info;
    logic        o_tx_sb_req;
    logic        o_tx_sb_rsp;
    logic        o_tx_sb_done;
    logic [8:0]  o_rx_encoding;
    logic [63:0] o_rx_data;
    logic [15:0] o_rx_info;
    logic        o_rx_sb_req;
    logic        o_rx_sb_rsp;
    logic        o_rx_sb_done;
    // Status
    logic        o_init_train_en;
    logic        o_sb_init_start;
    logic [3:0]  o_current_state;

    // -------------------------------------------------------------------------
    // DUT
    // -------------------------------------------------------------------------
    ucie_ltsm_init_fsm dut (
        .i_clk                         (i_clk),
        .i_reset                       (i_reset),
        .i_tx_decoding                 (i_tx_decoding),
        .i_tx_data                     (i_tx_data),
        .i_tx_info                     (i_tx_info),
        .i_sb_tx_req                   (i_sb_tx_req),
        .i_sb_tx_rsp                   (i_sb_tx_rsp),
        .i_sb_tx_done                  (i_sb_tx_done),
        .i_tx_done                     (i_tx_done),
        .i_rx_decoding                 (i_rx_decoding),
        .i_rx_data                     (i_rx_data),
        .i_rx_info                     (i_rx_info),
        .i_sb_rx_req                   (i_sb_rx_req),
        .i_sb_rx_rsp                   (i_sb_rx_rsp),
        .i_sb_rx_done                  (i_sb_rx_done),
        .i_rx_done                     (i_rx_done),
        .i_pll_stable                  (i_pll_stable),
        .i_supply_stable               (i_supply_stable),
        .i_timer_4ms                   (i_timer_4ms),
        .i_stop                        (i_stop),
        .i_rx_repairclk_pattern_results(i_rx_repairclk_pattern_results),
        .i_rx_repairval_pattern_results(i_rx_repairval_pattern_results),
        .i_rx_reversal_pattern_results (i_rx_reversal_pattern_results),
        .i_tx_sweep_result             (i_tx_sweep_result),
        .i_rx_sweep_result             (i_rx_sweep_result),
        .o_timer_8ms                   (o_timer_8ms),
        .i_train_active_error          (i_train_active_error),
        .o_tx_encoding                 (o_tx_encoding),
        .o_tx_data                     (o_tx_data),
        .o_tx_info                     (o_tx_info),
        .o_tx_sb_req                   (o_tx_sb_req),
        .o_tx_sb_rsp                   (o_tx_sb_rsp),
        .o_tx_sb_done                  (o_tx_sb_done),
        .o_rx_encoding                 (o_rx_encoding),
        .o_rx_data                     (o_rx_data),
        .o_rx_info                     (o_rx_info),
        .o_rx_sb_req                   (o_rx_sb_req),
        .o_rx_sb_rsp                   (o_rx_sb_rsp),
        .o_rx_sb_done                  (o_rx_sb_done),
        .o_init_train_en               (o_init_train_en),
        .o_sb_init_start               (o_sb_init_start),
        .o_current_state               (o_current_state)
    );

    // -------------------------------------------------------------------------
    // Clock — 100 MHz
    // -------------------------------------------------------------------------
    initial i_clk = 0;
    always #5 i_clk = ~i_clk;

    // -------------------------------------------------------------------------
    // Pass / fail tracking
    // -------------------------------------------------------------------------
    int pass_count = 0;
    int fail_count = 0;

    task automatic check(input string label, input logic ok);
        if (ok) begin $display("  [PASS] %s", label); pass_count++; end
        else    begin $display("  [FAIL] %s  @ time=%0t", label, $time); fail_count++; end
    endtask

    // -------------------------------------------------------------------------
    // State encoding — must match DUT localparams
    // -------------------------------------------------------------------------
    localparam logic [3:0] RESET            = 4'b0000;
    localparam logic [3:0] SBINIT           = 4'b0001;
    localparam logic [3:0] MBINIT_PARAM     = 4'b0010;
    localparam logic [3:0] MBINIT_CAL       = 4'b0011;
    localparam logic [3:0] MBINIT_REPAIRCLK = 4'b0100;
    localparam logic [3:0] MBINIT_REPAIRVAL = 4'b0101;
    localparam logic [3:0] MBINIT_REVERSAL  = 4'b0110;
    localparam logic [3:0] MBINIT_REPAIRMB  = 4'b0111;
    localparam logic [3:0] TRAINERROR       = 4'b1000;

    // -------------------------------------------------------------------------
    // Helper — poll negedges until state == exp or max_cycles reached
    // -------------------------------------------------------------------------
    task automatic wait_state(input logic [3:0] exp, input int maxc);
        for (int i = 0; i < maxc; i++) begin
            @(negedge i_clk);
            if (o_current_state == exp) return;
        end
    endtask

    // =========================================================================
    // MAIN
    // =========================================================================
    initial begin
        i_reset                        = 1;
        i_tx_decoding                  = '0;
        i_tx_data                      = '0;
        i_tx_info                      = '0;
        i_sb_tx_req                    = 0;
        i_sb_tx_rsp                    = 0;
        i_sb_tx_done                   = 0;
        i_tx_done                      = 0;
        i_rx_decoding                  = '0;
        i_rx_data                      = '0;
        i_rx_info                      = '0;
        i_sb_rx_req                    = 0;
        i_sb_rx_rsp                    = 0;
        i_sb_rx_done                   = 0;
        i_rx_done                      = 0;
        i_pll_stable                   = 0;
        i_supply_stable                = 0;
        i_timer_4ms                    = 0;
        i_stop                         = 0;
        // pre-set pattern results to all-ones so RX sub-FSMs see good lanes
        i_rx_repairclk_pattern_results = 64'hFFFF_FFFF_FFFF_FFFF;
        i_rx_repairval_pattern_results = 64'hFFFF_FFFF_FFFF_FFFF;
        i_rx_reversal_pattern_results  = 64'hFFFF_FFFF_FFFF_FFFF;
        i_tx_sweep_result              = 8'hFF;
        i_rx_sweep_result              = 8'hFF;
        o_timer_8ms                    = 0;
        i_train_active_error           = 0;

        $display("\n========== ucie_ltsm_init_fsm_tb ==========\n");

        // =====================================================================
        // T1 — Hard reset
        // =====================================================================
        $display("--- T1: Hard reset ---");
        repeat (5) @(negedge i_clk);
        check("T1: state=RESET",        o_current_state === RESET);
        check("T1: TX encoding=0x000",  o_tx_encoding   === 9'h000);
        check("T1: RX encoding=0x000",  o_rx_encoding   === 9'h000);
        check("T1: init_train_en=0",    o_init_train_en === 0);
        @(negedge i_clk); i_reset = 0;

        // =====================================================================
        // T2 — RESET → SBINIT
        //   Both TX and RX reset sub-FSMs latch pll, supply and timer_4ms.
        //   Drive all three together (ref: tx_reset_tb T2).
        // =====================================================================
        $display("\n--- T2: RESET -> SBINIT ---");
        check("T2: state=RESET before drive", o_current_state === RESET);

        @(negedge i_clk);
        i_pll_stable    = 1;
        i_supply_stable = 1;
        i_timer_4ms     = 1;
        @(negedge i_clk);
        i_pll_stable    = 0;
        i_supply_stable = 0;
        i_timer_4ms     = 0;
 
        wait_state(SBINIT, 10);
        check("T2: state=SBINIT",       o_current_state === SBINIT);
        check("T2: TX encoding=0x08",   o_tx_encoding   === 9'h08);
        check("T2: o_sb_init_start=1",  o_sb_init_start === 1);

        // =====================================================================
        // T3 — SBINIT → MBINIT_PARAM
        //
        //   TX sub-FSM (ref: tx_sbinit_tb):
        //     PATTERN_GENERATION (0x08)
        //       → i_stop → advance to OUT_OF_RESET_MSG
        //     OUT_OF_RESET_MSG (0x09)
        //       → i_sb_tx_done latches done_ack, REQ drops
        //       → i_tx_decoding=0x09 → advance to DONE_HANDSHAKE
        //     DONE_HANDSHAKE (0x0A)
        //       → i_sb_tx_done latches done_ack, REQ drops
        //       → i_sb_tx_rsp + i_tx_decoding=0x0A → TX done
        //
        //   RX sub-FSM:
        //     WAIT_OUT_OF_RESET (0x08)
        //       → i_rx_decoding=0x09 (sees TX message) → advance to DONE_HANDSHAKE
        //     DONE_HANDSHAKE (0x09)
        //       → i_sb_rx_req + i_rx_decoding=0x09 → RX done
        // =====================================================================
        $display("\n--- T3: SBINIT -> MBINIT_PARAM ---");

        // TX: PATTERN_GENERATION — assert stop
        @(negedge i_clk); i_stop = 1;
        @(negedge i_clk); i_stop = 0;
        check("T3: TX encoding=0x09 (OUT_OF_RESET_MSG)", o_tx_encoding === 9'h09);

        // RX: WAIT_OUT_OF_RESET — drive i_rx_decoding=0x09 so RX sees TX message
        @(negedge i_clk); i_rx_decoding = 9'h09;
        @(negedge i_clk); i_rx_decoding = '0;

        // TX: OUT_OF_RESET_MSG — done_ack latch, then far-end reflect 0x09
        @(negedge i_clk); i_sb_tx_done = 1;
        @(negedge i_clk); i_sb_tx_done = 0;
        @(negedge i_clk); i_tx_decoding = 9'h09;
        @(negedge i_clk); i_tx_decoding = '0;
        check("T3: TX encoding=0x0A (DONE_HANDSHAKE)", o_tx_encoding === 9'h0A);

        // TX: DONE_HANDSHAKE — done_ack latch, then RSP+0x0A → TX done
        @(negedge i_clk); i_sb_tx_done = 1;
        @(negedge i_clk); i_sb_tx_done = 0;
        @(negedge i_clk);
        i_sb_tx_rsp = 1; i_tx_decoding = 9'h0A;
        @(negedge i_clk);
        i_sb_tx_rsp = 0; i_tx_decoding = '0;

        // RX: DONE_HANDSHAKE — REQ+0x09 → RX done
        @(negedge i_clk);
        i_sb_rx_req = 1; i_rx_decoding = 9'h09;
        @(negedge i_clk);
        i_sb_rx_req = 0; i_rx_decoding = '0;
 
        wait_state(MBINIT_PARAM, 10);
        check("T3: state=MBINIT_PARAM", o_current_state === MBINIT_PARAM);
        check("T3: TX encoding=0x10",   o_tx_encoding   === 9'h10);
        check("T3: RX encoding=0x10",   o_rx_encoding   === 9'h10);

        // =====================================================================
        // T4 — MBINIT_PARAM → MBINIT_CAL
        //
        //   TX (ref: tx_mbinit_param_tb):
        //     CONFIG_HANDSHAKE (0x10)
        //       → done_ack latch → RSP+0x10 → TX done
        //   RX:
        //     WAIT_CONFIG_REQ (0x10)
        //       → i_rx_decoding=0x10 (sees TX REQ) → advance to CHECK_PARAMETERS
        //     CHECK_PARAMETERS (0x10)
        //       → i_sb_rx_done → RX done
        // =====================================================================
        $display("\n--- T4: MBINIT_PARAM -> MBINIT_CAL ---");

        // TX: done_ack latch
        @(negedge i_clk); i_sb_tx_done = 1;
        @(negedge i_clk); i_sb_tx_done = 0;

        // RX: sees TX REQ (drive i_rx_decoding=0x10)
        @(negedge i_clk); i_rx_decoding = 9'h10; i_sb_rx_req = 1;
        @(negedge i_clk); i_rx_decoding = '0; i_sb_rx_req = 0;

        // TX: RSP+0x10 → TX done
        @(negedge i_clk);
        i_sb_tx_rsp = 1; i_tx_decoding = 9'h10;
        @(negedge i_clk);
        i_sb_tx_rsp = 0; i_tx_decoding = '0;

        // RX: sb_rx_done → RX done
        @(negedge i_clk); i_sb_rx_done = 1;
        @(negedge i_clk); i_sb_rx_done = 0;

        wait_state(MBINIT_CAL, 10);
        check("T4: state=MBINIT_CAL",  o_current_state === MBINIT_CAL);
        check("T4: TX encoding=0x18",  o_tx_encoding   === 9'h18);
        check("T4: RX encoding=0x18",  o_rx_encoding   === 9'h18);

        // =====================================================================
        // T5 — MBINIT_CAL → MBINIT_REPAIRCLK
        //
        //   TX (ref: tx_mbinit_cal_tb):
        //     DONE_HANDSHAKE (0x18)
        //       → done_ack latch → RSP+0x18 → TX done
        //   RX:
        //     DONE_HANDSHAKE (0x18)
        //       → REQ+0x18 → RX done
        // =====================================================================
        $display("\n--- T5: MBINIT_CAL -> MBINIT_REPAIRCLK ---");

        // TX: done_ack latch
        @(negedge i_clk); i_sb_tx_done = 1;
        @(negedge i_clk); i_sb_tx_done = 0;

        // TX: RSP+0x18 → TX done
        @(negedge i_clk);
        i_sb_tx_rsp = 1; i_tx_decoding = 9'h18;
        @(negedge i_clk);
        i_sb_tx_rsp = 0; i_tx_decoding = '0;

        // RX: REQ+0x18 → RX done
        @(negedge i_clk);
        i_sb_rx_req = 1; i_rx_decoding = 9'h18;
        @(negedge i_clk);
        i_sb_rx_req = 0; i_rx_decoding = '0;

        wait_state(MBINIT_REPAIRCLK, 10);
        check("T5: state=MBINIT_REPAIRCLK",  o_current_state === MBINIT_REPAIRCLK);
        check("T5: TX encoding=0x20",        o_tx_encoding   === 9'h20);
        check("T5: RX encoding=0x20",        o_rx_encoding   === 9'h20);

        // =====================================================================
        // T6 — MBINIT_REPAIRCLK → MBINIT_REPAIRVAL
        //
        //   TX (ref: tx_mbinit_repairclk_tb):
        //     INIT_HS (0x20)        → done_ack + RSP+0x20 → advance
        //     PATTERN_GEN (0x21)    → i_tx_done → advance
        //     RESULT_HS (0x22)      → RSP+0x22 + i_tx_info[3:0]=0xF (4 clk lanes) → advance
        //     DONE_HS (0x23)        → done_ack + RSP+0x23 → TX done
        //   RX:
        //     INIT_HS (0x20)        → REQ+0x20 → advance
        //     PATTERN_DETECT (0x21) → i_rx_done → advance
        //     RESULT_HS (0x22)      → sb_rx_done → advance
        //     DONE_HS (0x23)        → REQ+0x23 → RX done 
        // =====================================================================
        $display("\n--- T6: MBINIT_REPAIRCLK -> MBINIT_REPAIRVAL ---");

        // INIT_HS
        @(negedge i_clk); i_sb_tx_done = 1;
        @(negedge i_clk); i_sb_tx_done = 0;
        @(negedge i_clk);
        i_sb_tx_rsp = 1; i_tx_decoding = 9'h20;
        i_sb_rx_req = 1; i_rx_decoding = 9'h20;
        @(negedge i_clk);
        i_sb_tx_rsp = 0; i_tx_decoding = '0;
        i_sb_rx_req = 0; i_rx_decoding = '0;
        check("T6: TX encoding=0x21 (PATTERN_GEN)",    o_tx_encoding === 9'h21);
        check("T6: RX encoding=0x21 (PATTERN_DETECT)", o_rx_encoding === 9'h21);

        // PATTERN phase
        @(negedge i_clk); i_tx_done = 1; i_rx_done = 1; 
        @(negedge i_clk); 
        @(negedge i_clk); i_tx_done = 0; i_rx_done = 0;
        check("T6: TX encoding=0x22 (RESULT_HS)", o_tx_encoding === 9'h22);
        check("T6: RX encoding=0x22 (RESULT_HS)", o_rx_encoding === 9'h22);

        // RESULT_HS — all 4 clk lanes good
        @(negedge i_clk);
        i_sb_tx_rsp = 1; i_tx_decoding = 9'h22;
        i_sb_rx_req = 1; i_rx_decoding = 9'h22;
        i_tx_info   = 16'h000F; // [3:0]=4'b1111
        @(negedge i_clk);
        i_sb_tx_rsp = 0; i_tx_decoding = '0; i_tx_info = '0;
        

        check("T6: TX encoding=0x23 (DONE_HS)", o_tx_encoding === 9'h23);
        check("T6: RX encoding=0x23 (SEND_RESP)", o_rx_encoding === 9'h23);
        @(negedge i_clk); i_sb_rx_done = 1;
        @(negedge i_clk); i_sb_rx_done = 0;
        check("T6: RX encoding=0x24 (DONE_HS)", o_rx_encoding === 9'h24);

        // DONE_HS
        @(negedge i_clk); i_sb_tx_done = 1;
        @(negedge i_clk); i_sb_tx_done = 0;
        @(negedge i_clk);
        i_sb_tx_rsp = 1; i_tx_decoding = 9'h23;
        i_sb_rx_req = 1; i_rx_decoding = 9'h24;
        @(negedge i_clk);
        i_sb_tx_rsp = 0; i_tx_decoding = '0;
        i_sb_rx_req = 0; i_rx_decoding = '0;

        wait_state(MBINIT_REPAIRVAL, 10);
        check("T6: state=MBINIT_REPAIRVAL",  o_current_state === MBINIT_REPAIRVAL);
        check("T6: TX encoding=0x28",        o_tx_encoding   === 9'h28);
        check("T6: RX encoding=0x28",        o_rx_encoding   === 9'h28);

        // =====================================================================
        // T7 — MBINIT_REPAIRVAL → MBINIT_REVERSAL
        //   Same structure as REPAIRCLK; encodings 0x28/0x29/0x2A/0x2B
        //   Lane check: i_tx_info[1:0]=2'b11 (2 data lanes)
        // =====================================================================
        $display("\n--- T7: MBINIT_REPAIRVAL -> MBINIT_REVERSAL ---");

        // INIT_HS
        @(negedge i_clk); i_sb_tx_done = 1;
        @(negedge i_clk); i_sb_tx_done = 0;
        @(negedge i_clk);
        i_sb_tx_rsp = 1; i_tx_decoding = 9'h28;
        i_sb_rx_req = 1; i_rx_decoding = 9'h28;
        @(negedge i_clk);
        i_sb_tx_rsp = 0; i_tx_decoding = '0;
        i_sb_rx_req = 0; i_rx_decoding = '0;

        // PATTERN phase
        @(negedge i_clk); i_tx_done = 1; i_rx_done = 1;
        @(negedge i_clk); i_tx_done = 0; i_rx_done = 0;

        // RESULT_HS — both data lanes good
        @(negedge i_clk);
        i_sb_tx_rsp = 1; i_tx_decoding = 9'h2A;
        i_sb_rx_req = 1; i_rx_decoding = 9'h2A;
        i_tx_info   = 16'h0003; // [1:0]=2'b11
        @(negedge i_clk);
        i_sb_tx_rsp = 0; i_tx_decoding = '0; i_tx_info = '0;
        @(negedge i_clk); i_sb_rx_done = 1;
        @(negedge i_clk); i_sb_rx_done = 0;

        // DONE_HS
        @(negedge i_clk); i_sb_tx_done = 1;
        @(negedge i_clk); i_sb_tx_done = 0;
        @(negedge i_clk);
        i_sb_tx_rsp = 1; i_tx_decoding = 9'h2B;
        i_sb_rx_req = 1; i_rx_decoding = 9'h2B;
        @(negedge i_clk);
        i_sb_tx_rsp = 0; i_tx_decoding = '0;
        i_sb_rx_req = 0; i_rx_decoding = '0;

        wait_state(MBINIT_REVERSAL, 10);
        check("T7: state=MBINIT_REVERSAL",  o_current_state === MBINIT_REVERSAL);
        check("T7: TX encoding=0x30",       o_tx_encoding   === 9'h30);
        check("T7: RX encoding=0x30",       o_rx_encoding   === 9'h30);

        // =====================================================================
        // T8 — MBINIT_REVERSAL → MBINIT_REPAIRMB
        //
        //   TX (ref: tx_mbinit_reversal_tb):
        //     INIT_HS     (0x30) → done_ack + RSP+0x30 → advance
        //     CLEAR_LOG   (0x31) → RSP+0x31 → advance
        //     LANE_ID_GEN (0x32) → i_tx_done → advance
        //     RESULT_HS   (0x33) → RSP+0x33 + i_tx_data count>8 → DONE_HS
        //     DONE_HS     (0x35) → done_ack + RSP+0x35 → TX done
        //   RX:
        //     INIT_HS     (0x30) → REQ+0x30 → advance
        //     CLEAR_LOG   (0x31) → REQ+0x31 → advance
        //     LANE_ID_DET (0x32) → i_rx_done → advance
        //     RESULT_HS   (0x33) → sb_rx_done → advance
        //     DONE_HS     (0x35) → REQ+0x35 → RX done
        //
        //   i_rx_reversal_pattern_results is all-ones, so RX also sees count>8.
        // =====================================================================
        $display("\n--- T8: MBINIT_REVERSAL -> MBINIT_REPAIRMB ---");

        // INIT_HS
        @(negedge i_clk); i_sb_tx_done = 1;
        @(negedge i_clk); i_sb_tx_done = 0;
        @(negedge i_clk);
        i_sb_tx_rsp = 1; i_tx_decoding = 9'h30;
        i_sb_rx_req = 1; i_rx_decoding = 9'h30;
        @(negedge i_clk);
        i_sb_tx_rsp = 0; i_tx_decoding = '0;
        i_sb_rx_req = 0; i_rx_decoding = '0;
        check("T8: TX encoding=0x31 (CLEAR_LOG)", o_tx_encoding === 9'h31);
        check("T8: RX encoding=0x31 (CLEAR_LOG)", o_rx_encoding === 9'h31);

        // CLEAR_LOG_HS
        @(negedge i_clk);
        i_sb_tx_rsp = 1; i_tx_decoding = 9'h31;
        i_sb_rx_req = 1; i_rx_decoding = 9'h31;
        @(negedge i_clk);
        i_sb_tx_rsp = 0; i_tx_decoding = '0;
        i_sb_rx_req = 0; i_rx_decoding = '0;
        check("T8: TX encoding=0x32 (LANE_ID_GEN)", o_tx_encoding === 9'h32);
        check("T8: RX encoding=0x31 (CLEAR_LOG)", o_rx_encoding === 9'h32);

        // LANE_ID phase
        @(negedge i_clk); i_tx_done = 1; i_rx_done = 1;
        @(negedge i_clk); i_tx_done = 0; i_rx_done = 0;
        check("T8: TX encoding=0x33 (RESULT_HS)", o_tx_encoding === 9'h33);
        check("T8: RX encoding=0x31 (CLEAR_LOG)", o_rx_encoding === 9'h33);

        // RESULT_HS — set data BEFORE RSP so count logic is stable
        i_tx_data = 64'h00000000000003FF; // bits[9:0]=1 → count=10 > 8
        @(negedge i_clk);
        i_sb_tx_rsp = 1; i_tx_decoding = 9'h33;
        i_sb_rx_req = 1; i_rx_decoding = 9'h33;
        @(negedge i_clk);
        i_sb_tx_rsp = 0; i_tx_decoding = '0; i_tx_data = '0;
        check("T8: RX encoding=0x34 (CLEAR_LOG)", o_rx_encoding === 9'h34);
        // RX: sb_rx_done advances RX past RESULT
        @(negedge i_clk); i_sb_rx_done = 1;
        @(negedge i_clk); i_sb_rx_done = 0;
        check("T8: TX encoding=0x35 (DONE_HS)", o_tx_encoding === 9'h35);

        // DONE_HS
        i_sb_rx_done = 1; i_rx_decoding = 9'h34;
        @(negedge i_clk); i_sb_tx_done = 1;
        @(negedge i_clk); i_sb_tx_done = 0;
        @(negedge i_clk);
        check("T8: RX encoding=0x35 (DONE_HS)", o_rx_encoding === 9'h35);

        @(negedge i_clk);
        i_sb_tx_rsp = 1; i_tx_decoding = 9'h35;
        i_sb_rx_req = 1; i_rx_decoding = 9'h35;
        @(negedge i_clk);
        i_sb_tx_rsp = 0; i_tx_decoding = '0;
        i_sb_rx_req = 0; i_rx_decoding = '0;

        wait_state(MBINIT_REPAIRMB, 10);
        check("T8: state=MBINIT_REPAIRMB",  o_current_state === MBINIT_REPAIRMB);
        check("T8: TX encoding=0x38",       o_tx_encoding   === 9'h38);
        check("T8: RX encoding=0x38",       o_rx_encoding   === 9'h38);

        // =====================================================================
        // T9 — MBINIT_REPAIRMB → o_init_train_en=1
        //
        //   TX (ref: tx_mbinit_repairmb_tb):
        //     INIT_HS (0x38)          → RSP+0x38 → DATA_TO_CLOCK_TEST
        //     Eye sweep (TX init=1):
        //       REQ_HS     (0x180)    → RSP+0x180 → LFSR_HS
        //       LFSR_HS    (0x181)    → RSP+0x181 → DATA_GENERATE
        //       DATA_GENERATE         → i_tx_done → RESULT_HS
        //       RESULT_HS  (0x183)    → RSP+0x183 all-ones → END_HS
        //       END_HS     (0x184)    → RSP+0x184 → sweep done
        //     APPLY_DEGRADE (0x3A)    → RSP+0x3A (maps match) → DONE_HS
        //     DONE_HS (0x3B)          → RSP+0x3B → TX done
        //
        //   RX (ref: rx_mbinit_repairmb_tb, init=0):
        //     INIT_HS (0x38)          → REQ+0x38 → DATA_TO_CLOCK_TEST
        //     Eye sweep (RX init=0):
        //       REQ_HS     (0x188)    → REQ+0x188 → LFSR_HS
        //       LFSR_HS    (0x189)    → sb_rx_done → DATA_DETECT
        //       DATA_DETECT           → i_rx_done → RESULT_HS
        //       RESULT_HS  (0x18B)    → sb_rx_done + all-ones → END_HS
        //       END_HS     (0x18C)    → REQ+0x18C → sweep done
        //     WAIT_DEGRADE (0x3A)     → REQ+0x3A → SEND_RESP
        //     SEND_RESP               → sb_rx_done → DONE_HS
        //     DONE_HS (0x3B)          → REQ+0x3B → RX done
        // =====================================================================
        $display("\n--- T9: MBINIT_REPAIRMB -> o_init_train_en ---");

        // INIT_HS — TX: RSP+0x38; RX: REQ+0x38
        @(negedge i_clk);
        i_sb_tx_rsp = 1; i_tx_decoding = 9'h38;
        i_sb_rx_req = 1; i_rx_decoding = 9'h38;
        @(negedge i_clk);
        i_sb_tx_rsp = 0; i_tx_decoding = '0;
        i_sb_rx_req = 0; i_rx_decoding = '0;

        // Eye sweep REQ_HS
        // TX (init=1): RSP+0x180; RX (init=0): REQ+0x188
        @(negedge i_clk);
        i_sb_tx_rsp = 1; i_tx_decoding = 9'h180;
        @(negedge i_clk);
        i_sb_tx_rsp = 0; i_tx_decoding = '0;
        @(negedge i_clk);
        i_sb_rx_req = 1; i_rx_decoding = 9'h181;
        @(negedge i_clk);
        i_sb_rx_req = 0; i_rx_decoding = '0;

        // LFSR_HS — TX: RSP+0x181; RX: sb_rx_done (latches done_ack)
        @(negedge i_clk);
        i_sb_tx_rsp  = 1; i_tx_decoding = 9'h181;
        i_sb_rx_req = 1; i_rx_decoding = 9'h182;

        i_sb_rx_done = 1;
        @(negedge i_clk);
        i_sb_tx_rsp  = 0; i_tx_decoding = '0;
        i_sb_rx_done = 0;

        // DATA phase — TX: i_tx_done; RX: i_rx_done
        @(negedge i_clk); i_tx_done = 1; i_rx_done = 1;
        @(negedge i_clk); i_tx_done = 0; i_rx_done = 0;

        // RESULT_HS — TX: RSP+0x183 all-ones; RX: sb_rx_done + all-ones data
        @(negedge i_clk);
        i_tx_data    = 64'hFFFF_FFFF_FFFF_FFFF;
        i_rx_data    = 64'hFFFF_FFFF_FFFF_FFFF;
        i_sb_tx_rsp  = 1; i_tx_decoding = 9'h183;
        i_sb_rx_req = 1; i_rx_decoding = 9'h183;

        i_sb_rx_done = 1;
        @(negedge i_clk);
        i_sb_tx_rsp  = 0; i_tx_decoding = '0;
        @(negedge i_clk);
        i_sb_rx_req = 1; i_rx_decoding = 9'h184;

        i_sb_rx_done = 0;
        i_tx_data    = '0; i_rx_data = '0;

        // END_HS — TX: RSP+0x184; RX: REQ+0x18C
        @(negedge i_clk);
        i_sb_tx_rsp = 1; i_tx_decoding = 9'h184;
        i_sb_rx_done = 1; i_rx_decoding = 9'h184;
        @(negedge i_clk);
        i_sb_tx_rsp = 0; i_tx_decoding = '0;
        i_sb_rx_req = 0; i_rx_decoding = '0;

        // Sweep done — DUT moves to APPLY_DEGRADE / WAIT_DEGRADE
        repeat (3) @(negedge i_clk);
        check("T8: TX encoding=0x3A -- WE FInished DATA TEST TX",       o_tx_encoding   === 9'h3A);
        check("T8: RX encoding=0x3A -- WE FInished DATA TEST RX",       o_rx_encoding   === 9'h3A);

        // APPLY_DEGRADE / WAIT_DEGRADE (0x3A)
        // TX: RSP+0x3A; RX: REQ+0x3A
        @(negedge i_clk);
        i_sb_tx_rsp = 1; i_tx_decoding = 9'h3A;
        i_sb_rx_req = 1; i_rx_decoding = 9'h3A;
        @(negedge i_clk);
        i_sb_tx_rsp = 0; i_tx_decoding = '0;
        i_sb_rx_req = 0; i_rx_decoding = '0;

        // RX SEND_RESP: sb_rx_done → DONE_HS
        @(negedge i_clk); i_sb_rx_done = 1;
        @(negedge i_clk); i_sb_rx_done = 0;

        // DONE_HS (0x3B) — TX: RSP+0x3B; RX: REQ+0x3B
        @(negedge i_clk);
        i_sb_tx_rsp = 1; i_tx_decoding = 9'h3B;
        i_sb_rx_req = 1; i_rx_decoding = 9'h3B;
        @(negedge i_clk);
        i_sb_tx_rsp = 0; i_tx_decoding = '0;
        i_sb_rx_req = 0; i_rx_decoding = '0;

        repeat (4) @(negedge i_clk);
        check("T9: state=MBINIT_REPAIRMB (parked)", o_current_state === MBINIT_REPAIRMB);
        check("T9: o_init_train_en=1",              o_init_train_en === 1);


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

    // -------------------------------------------------------------------------
    // Watchdog
    // -------------------------------------------------------------------------
    initial begin
        #500_000;
        $display("[WATCHDOG] Simulation timed out");
        $finish;
    end

    // -------------------------------------------------------------------------
    // Waveform dump
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("ucie_ltsm_init_fsm_tb.vcd");
        $dumpvars(0, ucie_ltsm_init_fsm_tb);
    end

endmodule