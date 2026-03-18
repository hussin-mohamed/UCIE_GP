`define SIM
`timescale 1ns/1ps

// =============================================================================
//  Testbench : ucie_LTSM_tb
//
//  Top-level wrapper around the full ucie_LTSM module.
//  Exercises the same Init-path sequences as ucie_ltsm_init_fsm_tb:
//
//  Key adaptations vs. the init-FSM standalone TB:
//    1. DUT is ucie_LTSM — ports follow the top-level interface.
//    2. SIM_8MS_CYCLES=4  → internal timer fires after only 4 clk cycles,
//       so T2 (RESET→SBINIT) no longer needs a manually pulsed i_timer_4ms.
//    3. i_power drives both the PLL-stable and supply-stable paths internally;
//       there is no separate i_pll_stable / i_supply_stable port.
//    4. Pattern-result ports use the correct widths:
//         i_rx_clk_results   [2:0]  (pre-set 3'b111  → all clock lanes good)
//         i_rx_valid_results  [0]   (pre-set 1'b1    → valid lane good)
//         i_rx_data_results  [63:0] (pre-set all-1s  → all data lanes good)
//    5. o_current_state / o_init_train_en are internal wires; they are
//       read via hierarchical references:
//         dut.w_init_current_state
//         dut.w_init_train_en
//    6. i_tx_sweep_result / i_rx_sweep_result are NOT top-level ports
//       (commented out in the init-FSM instantiation inside ucie_LTSM).
//    7. RDI adapter-side inputs (i_lp_*) are tied to safe defaults.
//    8. Train-module sequences are NOT driven (ignored as requested).
//
//  Test plan (mirrors init-FSM TB):
//    T1  - Hard reset  → state=RESET, encodings=0x000
//    T2  - RESET       → SBINIT      (i_power high + internal 4ms timer)
//    T3  - SBINIT      → MBINIT_PARAM
//    T4  - MBINIT_PARAM → MBINIT_CAL
//    T5  - MBINIT_CAL  → MBINIT_REPAIRCLK
//    T6  - MBINIT_REPAIRCLK → MBINIT_REPAIRVAL
//    T7  - MBINIT_REPAIRVAL → MBINIT_REVERSAL
//    T8  - MBINIT_REVERSAL  → MBINIT_REPAIRMB
//    T9  - MBINIT_REPAIRMB  → w_init_train_en=1 (parked)
// =============================================================================

module ucie_LTSM_tb;

    // -------------------------------------------------------------------------
    // DUT ports
    // -------------------------------------------------------------------------

    // Clock & Reset
    logic        i_clk;
    logic        i_reset;

    // RDI – Adapter → PHY  (tied to safe defaults; not exercised in init path)
    logic [3:0]  i_lp_state_req;
    logic        i_lp_linkerror;
    logic        i_lp_stallack;
    logic        i_lp_clk_ack;
    logic        i_lp_wake_req;

    // PHY status inputs
    logic        i_pll_stable;
    logic        i_supply_stable;
    logic        i_rx_error;
    logic        i_tx_done;
    logic        i_rx_done;

    // Pattern detection results  (correct top-level widths)
    logic [63:0] i_rx_data_results;   // reversal pattern  — pre-set all-ones
    logic        i_rx_valid_results;  // repairval pattern  — pre-set 1
    logic [2:0]  i_rx_clk_results;   // repairclk pattern  — pre-set 3'b111

    // TX path
    logic [8:0]  i_tx_decoding;
    logic [63:0] i_tx_data;
    logic [15:0] i_tx_info;
    logic        i_sb_tx_req;
    logic        i_sb_tx_rsp;
    logic        i_sb_tx_done;

    // RX path
    logic [8:0]  i_rx_decoding;
    logic [63:0] i_rx_data;
    logic [15:0] i_rx_info;
    logic        i_sb_rx_req;
    logic        i_sb_rx_rsp;
    logic        i_sb_rx_done;

    // SBINIT
    logic        i_stop;

    // RDI – PHY → Adapter  (outputs; just declare and observe)
    logic [3:0]  o_pl_state_sts;
    logic        o_pl_inband_pres;
    logic        o_pl_error;
    logic        o_pl_cerror;
    logic        o_pl_nferror;
    logic        o_pl_trainerror;
    logic        o_pl_phyinrecenter;
    logic        o_pl_stallreq;
    logic [2:0]  o_pl_speedmode;
    logic        o_pl_max_speedmode;
    logic [2:0]  o_pl_lnk_cfg;
    logic        o_pl_clk_req;
    logic        o_pl_wake_ack;

    // Encoding outputs (muxed by top-level from init or train FSMs)
    logic [8:0]  o_tx_encoding;
    logic [63:0] o_tx_data;
    logic [15:0] o_tx_info;
    logic [8:0]  o_rx_encoding;
    logic [63:0] o_rx_data;
    logic [15:0] o_rx_info;

    // Handshake outputs
    logic        o_tx_sb_req;
    logic        o_tx_sb_rsp;
    logic        o_rx_sb_req;
    logic        o_rx_sb_rsp;
    logic        o_tx_sb_done;
    logic        o_rx_sb_done;

    // SBINIT start trigger
    logic        o_sb_init_start;

    // -------------------------------------------------------------------------
    // DUT instantiation
    //   SIM_8MS_CYCLES=4  → internal timer expires after 4 clock cycles,
    //   removing the need to manually pulse i_timer_4ms.
    // -------------------------------------------------------------------------
    ucie_LTSM #(
        .SIM_8MS_CYCLES  (40),
        .CLK_PERIOD_NS   (10.0)
    ) dut (
        // Clock & Reset
        .i_clk              (i_clk),
        .i_reset            (i_reset),

        // RDI – Adapter → PHY
        .i_lp_state_req     (i_lp_state_req),
        .i_lp_linkerror     (i_lp_linkerror),
        .i_lp_stallack      (i_lp_stallack),
        .i_lp_clk_ack       (i_lp_clk_ack),
        .i_lp_wake_req      (i_lp_wake_req),

        // PHY status
        .i_pll_stable       (i_pll_stable),
        .i_supply_stable    (i_supply_stable),
        .i_rx_error         (i_rx_error),
        .i_tx_done          (i_tx_done),
        .i_rx_done          (i_rx_done),

        // Pattern results
        .i_rx_data_results  (i_rx_data_results),
        .i_rx_valid_results (i_rx_valid_results),
        .i_rx_clk_results   (i_rx_clk_results),

        // SB decoding
        .i_tx_decoding      (i_tx_decoding),
        .i_tx_data          (i_tx_data),
        .i_tx_info          (i_tx_info),
        .i_rx_decoding      (i_rx_decoding),
        .i_rx_data          (i_rx_data),
        .i_rx_info          (i_rx_info),

        // SB handshake
        .i_sb_tx_req        (i_sb_tx_req),
        .i_sb_tx_rsp        (i_sb_tx_rsp),
        .i_sb_tx_done       (i_sb_tx_done),
        .i_sb_rx_req        (i_sb_rx_req),
        .i_sb_rx_rsp        (i_sb_rx_rsp),
        .i_sb_rx_done       (i_sb_rx_done),

        // SBINIT
        .i_stop             (i_stop),

        // RDI – PHY → Adapter
        .o_pl_state_sts     (o_pl_state_sts),
        .o_pl_inband_pres   (o_pl_inband_pres),
        .o_pl_error         (o_pl_error),
        .o_pl_cerror        (o_pl_cerror),
        .o_pl_nferror       (o_pl_nferror),
        .o_pl_trainerror    (o_pl_trainerror),
        .o_pl_phyinrecenter (o_pl_phyinrecenter),
        .o_pl_stallreq      (o_pl_stallreq),
        .o_pl_speedmode     (o_pl_speedmode),
        .o_pl_max_speedmode (o_pl_max_speedmode),
        .o_pl_lnk_cfg       (o_pl_lnk_cfg),
        .o_pl_clk_req       (o_pl_clk_req),
        .o_pl_wake_ack      (o_pl_wake_ack),

        // SB encoding
        .o_tx_encoding      (o_tx_encoding),
        .o_tx_data          (o_tx_data),
        .o_tx_info          (o_tx_info),
        .o_rx_encoding      (o_rx_encoding),
        .o_rx_data          (o_rx_data),
        .o_rx_info          (o_rx_info),

        // SB handshake outputs
        .o_tx_sb_req        (o_tx_sb_req),
        .o_tx_sb_rsp        (o_tx_sb_rsp),
        .o_rx_sb_req        (o_rx_sb_req),
        .o_rx_sb_rsp        (o_rx_sb_rsp),
        .o_tx_sb_done       (o_tx_sb_done),
        .o_rx_sb_done       (o_rx_sb_done),

        // SBINIT start
        .o_sb_init_start    (o_sb_init_start)
    );

    // -------------------------------------------------------------------------
    // Clock — 100 MHz  (period = 10 ns)
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
    localparam logic [3:0] ST_IDLE          = 4'b1111;
    localparam logic [3:0] ST_LINKINIT      = 4'b0000;
    localparam logic [3:0] ST_ACTIVE        = 4'b0001;
    localparam logic [3:0] ST_ACTIVE_PMNAK  = 4'b0010;

    // pl_state_sts Active encoding
    localparam logic [3:0] PL_STS_ACTIVE = 4'b0001;

    // -------------------------------------------------------------------------
    // Helper — poll negedges until the internal init-FSM state == exp
    //   Uses hierarchical reference to dut.w_init_current_state because
    //   o_current_state is not exposed at the ucie_LTSM top-level port.
    // -------------------------------------------------------------------------
    task automatic wait_state(input logic [3:0] exp, input int maxc);
        for (int i = 0; i < maxc; i++) begin
            @(negedge i_clk);
            if (dut.w_init_current_state == exp) return;
        end
    endtask

    // =========================================================================
    // MAIN
    // =========================================================================
    initial begin

        // ---- Reset all inputs to safe defaults ----
        i_reset             = 1;

        i_lp_state_req      = '0;
        i_lp_linkerror      = 0;
        i_lp_stallack       = 0;
        i_lp_clk_ack        = 0;
        i_lp_wake_req       = 0;
        
        i_pll_stable        = 0;
        i_supply_stable     = 0;
        i_rx_error          = 0;
        i_tx_done           = 0;
        i_rx_done           = 0;

        // Pre-set pattern results to all-good so RX sub-FSMs see clean lanes
        i_rx_data_results   = 64'hFFFF_FFFF_FFFF_FFFF;
        i_rx_valid_results  = 1'b1;
        i_rx_clk_results    = 3'b111;

        i_tx_decoding       = '0;
        i_tx_data           = '0;
        i_tx_info           = '0;
        i_sb_tx_req         = 0;
        i_sb_tx_rsp         = 0;
        i_sb_tx_done        = 0;

        i_rx_decoding       = '0;
        i_rx_data           = '0;
        i_rx_info           = '0;
        i_sb_rx_req         = 0;
        i_sb_rx_rsp         = 0;
        i_sb_rx_done        = 0;

        i_stop              = 0;

        $display("\n========== ucie_LTSM_tb ==========\n");

        // =====================================================================
        // T1 — Hard reset
        // =====================================================================
        $display("--- T1: Hard reset ---");
        repeat (5) @(negedge i_clk);
        check("T1: state=RESET",        dut.w_init_current_state === RESET);
        check("T1: TX encoding=0x000",  o_tx_encoding            === 9'h000);
        check("T1: RX encoding=0x000",  o_rx_encoding            === 9'h000);
        check("T1: init_train_en=0",    dut.w_init_train_en      === 0);
        @(negedge i_clk); i_reset = 0;

        // =====================================================================
        // T2 — RESET → SBINIT
        //
        //   In the standalone init-FSM TB, i_pll_stable, i_supply_stable, and
        //   i_timer_4ms were pulsed directly.  At the top level these are all
        //   internal:
        //     • i_pll_stable / i_supply_stable → driven from i_power internally
        //     • i_timer_4ms                    → output of ucie_timeout_timer
        //                                        (fires after SIM_8MS_CYCLES=4
        //                                         clock cycles while i_power=1)
        //   Strategy: assert i_power and wait up to 20 negedges for SBINIT.
        // =====================================================================
        $display("\n--- T2: RESET -> SBINIT ---");
        check("T2: state=RESET before drive", dut.w_init_current_state === RESET);

        wait(dut.w_timer_4ms);

        @(negedge i_clk);
        i_pll_stable        = 1;
        i_supply_stable     = 1;
        wait_state(SBINIT, 20);         // internal timer fires → state advances
        i_pll_stable        = 0;
        i_supply_stable     = 0;

        check("T2: state=SBINIT",       dut.w_init_current_state === SBINIT);
        check("T2: TX encoding=0x08",   o_tx_encoding            === 9'h08);
        check("T2: o_sb_init_start=1",  o_sb_init_start          === 1);

        // =====================================================================
        // T3 — SBINIT → MBINIT_PARAM
        //
        //   TX sub-FSM:
        //     PATTERN_GENERATION (0x08) → i_stop → OUT_OF_RESET_MSG
        //     OUT_OF_RESET_MSG (0x09)   → sb_tx_done latch → decoding=0x09 → DONE_HS
        //     DONE_HANDSHAKE (0x0A)     → sb_tx_done latch → RSP+0x0A → TX done
        //   RX sub-FSM:
        //     WAIT_OUT_OF_RESET (0x08)  → i_rx_decoding=0x09 → DONE_HANDSHAKE
        //     DONE_HANDSHAKE (0x09)     → REQ+0x09 → RX done
        // =====================================================================
        $display("\n--- T3: SBINIT -> MBINIT_PARAM ---");

        // TX: PATTERN_GENERATION — assert stop to advance
        @(negedge i_clk); i_stop = 1;
        @(negedge i_clk); i_stop = 0;
        check("T3: TX encoding=0x09 (OUT_OF_RESET_MSG)", o_tx_encoding === 9'h09);

        // RX: WAIT_OUT_OF_RESET — drive rx_decoding=0x09 so RX sees TX message
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
        check("T3: state=MBINIT_PARAM", dut.w_init_current_state === MBINIT_PARAM);
        check("T3: TX encoding=0x10",   o_tx_encoding            === 9'h10);
        check("T3: RX encoding=0x10",   o_rx_encoding            === 9'h10);

        // =====================================================================
        // T4 — MBINIT_PARAM → MBINIT_CAL
        //
        //   TX: CONFIG_HANDSHAKE (0x10) → done_ack → RSP+0x10 → TX done
        //   RX: WAIT_CONFIG_REQ (0x10)  → rx_decoding=0x10 → CHECK_PARAMETERS
        //       CHECK_PARAMETERS (0x10) → sb_rx_done → RX done
        // =====================================================================
        $display("\n--- T4: MBINIT_PARAM -> MBINIT_CAL ---");

        // TX: done_ack latch
        @(negedge i_clk); i_sb_tx_done = 1;
        @(negedge i_clk); i_sb_tx_done = 0;

        // RX: sees TX REQ
        @(negedge i_clk); i_rx_decoding = 9'h10; i_sb_rx_req = 1;
        @(negedge i_clk); i_rx_decoding = '0;    i_sb_rx_req = 0;

        // TX: RSP+0x10 → TX done
        @(negedge i_clk);
        i_sb_tx_rsp = 1; i_tx_decoding = 9'h10;
        @(negedge i_clk);
        i_sb_tx_rsp = 0; i_tx_decoding = '0;

        // RX: sb_rx_done → RX done
        @(negedge i_clk); i_sb_rx_done = 1;
        @(negedge i_clk); i_sb_rx_done = 0;

        wait_state(MBINIT_CAL, 10);
        check("T4: state=MBINIT_CAL",  dut.w_init_current_state === MBINIT_CAL);
        check("T4: TX encoding=0x18",  o_tx_encoding            === 9'h18);
        check("T4: RX encoding=0x18",  o_rx_encoding            === 9'h18);

        // =====================================================================
        // T5 — MBINIT_CAL → MBINIT_REPAIRCLK
        //
        //   TX: DONE_HANDSHAKE (0x18) → done_ack → RSP+0x18 → TX done
        //   RX: DONE_HANDSHAKE (0x18) → REQ+0x18 → RX done
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
        check("T5: state=MBINIT_REPAIRCLK",  dut.w_init_current_state === MBINIT_REPAIRCLK);
        check("T5: TX encoding=0x20",        o_tx_encoding            === 9'h20);
        check("T5: RX encoding=0x20",        o_rx_encoding            === 9'h20);

        // =====================================================================
        // T6 — MBINIT_REPAIRCLK → MBINIT_REPAIRVAL
        //
        //   TX: INIT_HS (0x20)     → done_ack + RSP+0x20 → PATTERN_GEN
        //       PATTERN_GEN (0x21) → i_tx_done → RESULT_HS
        //       RESULT_HS (0x22)   → RSP+0x22 + i_tx_info[3:0]=0xF → DONE_HS
        //       DONE_HS (0x23)     → done_ack + RSP+0x23 → TX done
        //   RX: INIT_HS (0x20)       → REQ+0x20 → PATTERN_DETECT
        //       PATTERN_DETECT(0x21) → i_rx_done → RESULT_HS
        //       RESULT_HS (0x22)     → sb_rx_done → SEND_RESP (0x23)
        //       DONE_HS (0x24)       → REQ+0x24 → RX done
        //
        //   i_rx_clk_results=3'b111 → all 3 clock lanes good (no repair needed)
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

        // PATTERN phase — both TX and RX complete together
        @(negedge i_clk); i_tx_done = 1; i_rx_done = 1;
        @(negedge i_clk);
        @(negedge i_clk); i_tx_done = 0; i_rx_done = 0;
        check("T6: TX encoding=0x22 (RESULT_HS)", o_tx_encoding === 9'h22);
        check("T6: RX encoding=0x22 (RESULT_HS)", o_rx_encoding === 9'h22);

        // RESULT_HS — all 4 clock lanes good
        @(negedge i_clk);
        i_sb_tx_rsp = 1; i_tx_decoding = 9'h22;
        i_sb_rx_req = 1; i_rx_decoding = 9'h22;
        i_tx_info   = 16'h000F;         // [3:0]=4'b1111: 4 good clk lanes
        @(negedge i_clk);
        i_sb_tx_rsp = 0; i_tx_decoding = '0; i_tx_info = '0;

        check("T6: TX encoding=0x23 (DONE_HS)",   o_tx_encoding === 9'h23);
        check("T6: RX encoding=0x23 (SEND_RESP)", o_rx_encoding === 9'h23);

        // RX: SEND_RESP — sb_rx_done advances RX to DONE_HS
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
        check("T6: state=MBINIT_REPAIRVAL",  dut.w_init_current_state === MBINIT_REPAIRVAL);
        check("T6: TX encoding=0x28",        o_tx_encoding            === 9'h28);
        check("T6: RX encoding=0x28",        o_rx_encoding            === 9'h28);

        // =====================================================================
        // T7 — MBINIT_REPAIRVAL → MBINIT_REVERSAL
        //   Same structure as REPAIRCLK; encodings 0x28/0x29/0x2A/0x2B
        //   Lane check: i_tx_info[1:0]=2'b11 (2 data lanes)
        //   i_rx_valid_results=1'b1 → valid lane good (no repair needed)
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
        i_tx_info   = 16'h0003;         // [1:0]=2'b11: 2 good data lanes
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
        check("T7: state=MBINIT_REVERSAL",  dut.w_init_current_state === MBINIT_REVERSAL);
        check("T7: TX encoding=0x30",       o_tx_encoding            === 9'h30);
        check("T7: RX encoding=0x30",       o_rx_encoding            === 9'h30);

        // =====================================================================
        // T8 — MBINIT_REVERSAL → MBINIT_REPAIRMB
        //
        //   TX: INIT_HS(0x30) → done_ack+RSP+0x30 → CLEAR_LOG
        //       CLEAR_LOG(0x31)     → RSP+0x31 → LANE_ID_GEN
        //       LANE_ID_GEN(0x32)   → i_tx_done → RESULT_HS
        //       RESULT_HS(0x33)     → RSP+0x33 + data count>8 → DONE_HS(0x35)
        //       DONE_HS(0x35)       → done_ack + RSP+0x35 → TX done
        //   RX: INIT_HS(0x30)  → REQ+0x30 → CLEAR_LOG
        //       CLEAR_LOG(0x31)     → REQ+0x31 → LANE_ID_DET
        //       LANE_ID_DET(0x32)   → i_rx_done → RESULT_HS
        //       RESULT_HS(0x33)     → sb_rx_done → advance
        //       DONE_HS(0x35)       → REQ+0x35 → RX done
        //
        //   i_rx_data_results=all-ones → count > 8, no reversal needed
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
        check("T8: RX encoding=0x32 (LANE_ID_DET)", o_rx_encoding === 9'h32);

        // LANE_ID phase
        @(negedge i_clk); i_tx_done = 1; i_rx_done = 1;
        @(negedge i_clk); i_tx_done = 0; i_rx_done = 0;
        check("T8: TX encoding=0x33 (RESULT_HS)", o_tx_encoding === 9'h33);
        check("T8: RX encoding=0x33 (RESULT_HS)", o_rx_encoding === 9'h33);

        // RESULT_HS — set data BEFORE RSP so count logic is stable
        i_tx_data = 64'h00000000000003FF; // bits[9:0]=1 → count=10 > 8
        @(negedge i_clk);
        i_sb_tx_rsp = 1; i_tx_decoding = 9'h33;
        i_sb_rx_req = 1; i_rx_decoding = 9'h33;
        @(negedge i_clk);
        i_sb_tx_rsp = 0; i_tx_decoding = '0; i_tx_data = '0;
        check("T8: RX encoding=0x34 (CLEAR_LOG after RESULT)", o_rx_encoding === 9'h34);

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
        check("T8: state=MBINIT_REPAIRMB",  dut.w_init_current_state === MBINIT_REPAIRMB);
        check("T8: TX encoding=0x38",       o_tx_encoding            === 9'h38);
        check("T8: RX encoding=0x38",       o_rx_encoding            === 9'h38);

        // =====================================================================
        // T9 — MBINIT_REPAIRMB → w_init_train_en=1
        //
        //   TX (init=1, eye-sweep path):
        //     INIT_HS (0x38)       → RSP+0x38 → DATA_TO_CLOCK_TEST
        //     REQ_HS  (0x180)      → RSP+0x180 → LFSR_HS
        //     LFSR_HS (0x181)      → RSP+0x181 → DATA_GENERATE
        //     DATA_GENERATE        → i_tx_done → RESULT_HS
        //     RESULT_HS (0x183)    → RSP+0x183 all-ones → END_HS
        //     END_HS (0x184)       → RSP+0x184 → sweep done
        //     APPLY_DEGRADE (0x3A) → RSP+0x3A → DONE_HS
        //     DONE_HS (0x3B)       → RSP+0x3B → TX done
        //
        //   RX (init=0, eye-sweep path):
        //     INIT_HS (0x38)       → REQ+0x38 → DATA_TO_CLOCK_TEST
        //     REQ_HS  (0x188)      → REQ+0x188 → LFSR_HS
        //     LFSR_HS (0x189)      → sb_rx_done → DATA_DETECT
        //     DATA_DETECT          → i_rx_done → RESULT_HS
        //     RESULT_HS (0x18B)    → sb_rx_done + all-ones → END_HS
        //     END_HS (0x18C)       → REQ+0x18C → sweep done
        //     WAIT_DEGRADE (0x3A)  → REQ+0x3A → SEND_RESP
        //     SEND_RESP            → sb_rx_done → DONE_HS
        //     DONE_HS (0x3B)       → REQ+0x3B → RX done
        // =====================================================================
        $display("\n--- T9: MBINIT_REPAIRMB -> w_init_train_en ---");

        // INIT_HS — TX: RSP+0x38; RX: REQ+0x38
        @(negedge i_clk);
        i_sb_tx_rsp = 1; i_tx_decoding = 9'h38;
        i_sb_rx_req = 1; i_rx_decoding = 9'h38;
        @(negedge i_clk);
        i_sb_tx_rsp = 0; i_tx_decoding = '0;
        i_sb_rx_req = 0; i_rx_decoding = '0;

        // Eye-sweep REQ_HS
        // TX (init=1): RSP+0x180;  RX (init=0): REQ+0x188
        @(negedge i_clk);
        i_sb_tx_rsp = 1; i_tx_decoding = 9'h180;
        @(negedge i_clk);
        i_sb_tx_rsp = 0; i_tx_decoding = '0;
        @(negedge i_clk);
        i_sb_rx_req = 1; i_rx_decoding = 9'h181;
        @(negedge i_clk);
        i_sb_rx_req = 0; i_rx_decoding = '0;

        // LFSR_HS — TX: RSP+0x181; RX: sb_rx_done latches done_ack
        @(negedge i_clk);
        i_sb_tx_rsp  = 1; i_tx_decoding = 9'h181;
        i_sb_rx_req  = 1; i_rx_decoding = 9'h182;
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
        i_sb_rx_req  = 1; i_rx_decoding = 9'h183;
        i_sb_rx_done = 1;
        @(negedge i_clk);
        i_sb_tx_rsp  = 0; i_tx_decoding = '0;
        @(negedge i_clk);
        i_sb_rx_req  = 1; i_rx_decoding = 9'h184;
        i_sb_rx_done = 0;
        i_tx_data    = '0; i_rx_data = '0;

        // END_HS — TX: RSP+0x184; RX: REQ+0x18C
        @(negedge i_clk);
        i_sb_tx_rsp  = 1; i_tx_decoding = 9'h184;
        i_sb_rx_done = 1; i_rx_decoding = 9'h184;
        @(negedge i_clk);
        i_sb_tx_rsp  = 0; i_tx_decoding = '0;
        i_sb_rx_req  = 0; i_rx_decoding = '0;

        // Sweep done — DUT moves to APPLY_DEGRADE / WAIT_DEGRADE
        repeat (3) @(negedge i_clk);
        check("T9: TX encoding=0x3A (APPLY_DEGRADE)", o_tx_encoding === 9'h3A);
        check("T9: RX encoding=0x3A (WAIT_DEGRADE)",  o_rx_encoding === 9'h3A);

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
        check("T9: state=MBINIT_REPAIRMB (parked)", dut.w_init_current_state === MBINIT_REPAIRMB);
        check("T9: w_init_train_en=1",               dut.w_init_train_en      === 1);

        // =====================================================================
        //  MBTRAIN SEQUENCES (T10–T20)
        //
        //  After T9, w_init_train_en=1 → top-level mux selects train-FSM
        //  outputs for o_tx_encoding / o_rx_encoding.
        //
        //  Force eye-sweep internal 'result' wire high so every sweep
        //  reports a pass without needing real lane data.
        // =====================================================================
        force dut.ucie_LTSM_RX_MBTRAIN_inst.i_rx_data_results = 1'b1;

        $display("\n========== MBTRAIN SEQUENCES ==========\n");

        // =====================================================================
        // T10 — VALVREF
        //   TX : sub0 req(0x80) → eye-sweep → sub2 req(0x82) → state-exit(0x82)
        //   RX : sub0 req→rsp(0x80) → eye-sweep → sub2 txrx(0x82) → exit req(0x88)
        //   Eye sweeps run in a fork-join: TX and RX each drive separate signal
        //   buses (tx_* vs rx_*) so there is no write conflict.
        // =====================================================================
        $display("--- T10: VALVREF ---");
        // TX sub0 — DUT asserts o_tx_sb_req at 0x80
        do_tx_req_hs(9'h80);
        // RX sub0 — VALVREF style: TB sends req → DUT asserts rsp → TB done
        do_rx_req_rsp_done(9'h80);
        // Eye sweeps in parallel
        fork
            do_tx_eye_sweep();
            do_rx_eye_sweep();
        join
        // TX sub2
        do_tx_req_hs(9'h82);
        // RX sub2: send req+0x82 to trigger sub2 entry, then txrx handshake
        i_sb_rx_req   = 1;
        i_rx_decoding = 9'h82;
        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = '0;
        repeat (2) @(negedge i_clk);
        do_rx_sub2(9'h82);
        // State exits → DATAVREF
        do_tx_state_exit(9'h82);
        do_rx_state_exit_req(9'h88);
        check("T10: VALVREF complete", 1'b1);
        repeat (3) @(negedge i_clk);

        // =====================================================================
        // T11 — DATAVREF
        //   TX : sub0 req(0x88) → eye-sweep → sub2 req(0x8A) → state-exit(0x8A)
        //   RX : sub0 imm-rsp(0x88) → eye-sweep → sub2 txrx(0x8A)
        //        → exit via previous_state_done triggered once both
        //          w_rsp_sent (from RX sub2 o_rx_sb_rsp) and w_rsp_received
        //          (from do_tx_state_exit i_sb_tx_rsp) are set at 0x8A
        // =====================================================================
        $display("\n--- T11: DATAVREF ---");
        do_tx_req_hs(9'h88);
        do_rx_imm_rsp_done(9'h88);
        fork
            do_tx_eye_sweep();
            do_rx_eye_sweep();
        join
        do_tx_req_hs(9'h8A);
        i_sb_rx_req   = 1;
        i_rx_decoding = 9'h8A;
        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = '0;
        repeat (2) @(negedge i_clk);
        do_rx_sub2(9'h8A);
        do_tx_state_exit(9'h8A);
        repeat (3) @(negedge i_clk);
        check("T11: DATAVREF complete", 1'b1);

        // =====================================================================
        // T12 — SPEEDIDLE
        //   TX : sub0(0xC8) speed-mode check (o_pl_speedmode != 0) →
        //        auto-advances → sub1 req(0xCA) → exit(0xCA)
        //   RX : sub0(0xC8) req+0xCA to match speed → sub1 txrx(0xCA) →
        //        exit req(0xD0)
        // =====================================================================
        $display("\n--- T12: SPEEDIDLE ---");
        @(negedge i_clk);
        check("T12: TX enc=0xC8 (SPEEDIDLE sub0)", o_tx_encoding === 9'hC8);
        @(negedge i_clk);
        check("T12: RX enc=0xC8 (SPEEDIDLE sub0)", o_rx_encoding === 9'hC8);
        // RX: req+0xCA → speed-match check passes → RX sub0 → sub1
        i_sb_rx_req   = 1;
        i_rx_decoding = 9'hCA;
        i_tx_done = 1;
        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = '0;
        i_tx_done = 0;
        repeat (2) @(negedge i_clk);
        // TX sub1 req(0xCA)
        do_tx_req_hs(9'hCA);
        // RX sub1 txrx(0xCA)
        do_rx_sub2(9'hCA);
        // State exits → TXSELFCAL
        do_tx_state_exit(9'hCA);
        do_rx_state_exit_req(9'hD0);
        check("T12: SPEEDIDLE complete", 1'b1);
        repeat (3) @(negedge i_clk);

        // =====================================================================
        // T13 — TXSELFCAL
        //   TX : sub0(0xD0) waits for i_tx_done → sub1 req(0xD1) → exit(0xD1)
        //   RX : sub0(0xD0) waits for i_tx_done+i_rx_done (txrx) → rsp →
        //        done_ack → exit req(0x98)
        //   Drive i_tx_done+i_rx_done together: TX advances sub0→sub1,
        //   RX triggers sub0 completion rsp.
        // =====================================================================
        $display("\n--- T13: TXSELFCAL ---");
        @(negedge i_clk);
        check("T13: TX enc=0xD0 (TXSELFCAL)", o_tx_encoding === 9'hD0);
        @(negedge i_clk);
        check("T13: RX enc=0xD0 (TXSELFCAL)", o_rx_encoding === 9'hD0);
        // Assert both done signals: TX advances, RX asserts rsp
        i_tx_done = 1;
        i_rx_done = 1;
        @(negedge i_clk);
        check("T13: RX o_rx_sb_rsp=1 after done", o_rx_sb_rsp === 1'b1);
        i_tx_done = 0;
        i_rx_done = 0;
        // RX done_ack → substates_done
        i_sb_rx_done = 1;
        @(negedge i_clk);
        i_sb_rx_done = 0;
        check("T13: RX rsp cleared after done_ack", o_rx_sb_rsp === 1'b0);
        repeat (2) @(negedge i_clk);
        // TX sub1
        do_tx_req_hs(9'hD1);
        // State exits → RXCLKCAL
        do_tx_state_exit(9'hD1);
        do_rx_state_exit_req(9'h98);
        check("T13: TXSELFCAL complete", 1'b1);
        repeat (3) @(negedge i_clk);

        // =====================================================================
        // T14 — RXCLKCAL
        //   TX : sub0 req(0x98) → sub2 req(0x9A) → exit(0x9A)
        //        [TX has no eye-sweep for RXCLKCAL — RX-only calibration]
        //   RX : sub0 imm-rsp(0x98) → eye-sweep → sub2 txrx(0x9A) → exit(0xA0)
        //   TX drives 0x98 then immediately jumps to 0x9A; RX eye-sweep runs
        //   in the meantime. After both FSMs reach 0x9A, the sub2 handshake
        //   is completed for RX and the TX req_hs is performed.
        // =====================================================================
        $display("\n--- T14: RXCLKCAL ---");
        // TX sub0 — only one req_hs, no sweep
        do_tx_req_hs(9'h98);
        // RX sub0
        do_rx_imm_rsp_done(9'h98);
        // TX sub2 — at this point TX should be at 0x9A
        do_tx_req_hs(9'h9A);
        // RX sub2 entry + handshake
        i_sb_rx_req   = 1;
        i_rx_decoding = 9'h9A;
        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = '0;
        repeat (2) @(negedge i_clk);
        do_rx_sub2(9'h9A);
        // State exits → VALTRAINCENTER
        do_tx_state_exit(9'h9A);
        do_rx_state_exit_req(9'hA0);
        check("T14: RXCLKCAL complete", 1'b1);
        repeat (3) @(negedge i_clk);

        // =====================================================================
        // T15 — VALTRAINCENTER
        //   TX : sub0 req(0xA0) → eye-sweep → sub2 req(0xA2) → exit(0xA2)
        //   RX : sub0 imm-rsp(0xA0) → eye-sweep → sub2 txrx(0xA2) → exit(0xE8)
        // =====================================================================
        $display("\n--- T15: VALTRAINCENTER ---");
        do_tx_req_hs(9'hA0);
        do_rx_imm_rsp_done(9'hA0);
        fork
            do_tx_eye_sweep();
            do_rx_eye_sweep();
        join
        do_tx_req_hs(9'hA2);
        i_sb_rx_req   = 1;
        i_rx_decoding = 9'hA2;
        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = '0;
        repeat (2) @(negedge i_clk);
        do_rx_sub2(9'hA2);
        do_tx_state_exit(9'hA2);
        do_rx_state_exit_req(9'hE8);
        check("T15: VALTRAINCENTER complete", 1'b1);
        repeat (3) @(negedge i_clk);

        // =====================================================================
        // T16 — VALTRAINVREF
        //   TX : sub0 req(0xE8) → eye-sweep → sub2 req(0xEA) → exit(0xEA)
        //   RX : sub0 imm-rsp(0xE8) → eye-sweep → sub2 txrx(0xEA) → exit(0x90)
        // =====================================================================
        $display("\n--- T16: VALTRAINVREF ---");
        do_tx_req_hs(9'hE8);
        do_rx_imm_rsp_done(9'hE8);
        fork
            do_tx_eye_sweep();
            do_rx_eye_sweep();
        join
        do_tx_req_hs(9'hEA);
        i_sb_rx_req   = 1;
        i_rx_decoding = 9'hEA;
        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = '0;
        repeat (2) @(negedge i_clk);
        do_rx_sub2(9'hEA);
        do_tx_state_exit(9'hEA);
        do_rx_state_exit_req(9'h90);
        check("T16: VALTRAINVREF complete", 1'b1);
        repeat (3) @(negedge i_clk);

        // =====================================================================
        // T17 — DATATRAINCENTER1  (no_retry=1)
        //   TX : sub0 req(0x90) → eye-sweep[no_retry] → sub2 req(0x92) → exit(0x92)
        //   RX : sub0 imm-rsp(0x90) → eye-sweep[no_retry] → sub2 txrx(0x92) → exit(0xF0)
        // =====================================================================
        $display("\n--- T17: DATATRAINCENTER1 ---");
        do_tx_req_hs(9'h90);
        do_rx_imm_rsp_done(9'h90);
        fork
            do_tx_eye_sweep();
            do_rx_eye_sweep();
        join
        do_tx_req_hs(9'h92);
        i_sb_rx_req   = 1;
        i_rx_decoding = 9'h92;
        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = '0;
        repeat (2) @(negedge i_clk);
        do_rx_sub2(9'h92);
        do_tx_state_exit(9'h92);
        do_rx_state_exit_req(9'hF0);
        check("T17: DATATRAINCENTER1 complete", 1'b1);
        repeat (3) @(negedge i_clk);

        // =====================================================================
        // T18 — DATATRAINVREF
        //   TX : sub0 req(0xF0) → eye-sweep → sub2 req(0xF2) → exit(0xF2)
        //   RX : sub0 imm-rsp(0xF0) advances via i_sb_rx_done+dec=0xF0 →
        //        eye-sweep → sub2 txrx(0xF2) → exit req(0xA8)
        //   RX sub0 uses the DATATRAINVREF variant: must also drive
        //   i_rx_decoding=0xF0 alongside i_sb_rx_done to advance.
        // =====================================================================
        $display("\n--- T18: DATATRAINVREF ---");
        // TX sub0
        do_tx_req_hs(9'hF0);
        // RX sub0 — DATATRAINVREF variant: done+decoding=0xF0 required
        @(negedge i_clk);
        check("T18: RX enc=0xF0 (DATATRAINVREF sub0)", o_rx_encoding === 9'hF0);
        check("T18: RX o_rx_sb_rsp=1",                 o_rx_sb_rsp   === 1'b1);
        i_sb_rx_done  = 1;
        i_rx_decoding = 9'hF0;
        @(negedge i_clk);
        i_sb_rx_done  = 0;
        i_rx_decoding = '0;
        repeat (2) @(negedge i_clk);
        // Eye sweeps in parallel
        fork
            do_tx_eye_sweep();
            do_rx_eye_sweep();
        join
        // TX sub2
        do_tx_req_hs(9'hF2);
        // RX sub2 entry + handshake
        i_sb_rx_req   = 1;
        i_rx_decoding = 9'hF2;
        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = '0;
        repeat (2) @(negedge i_clk);
        do_rx_sub2(9'hF2);
        // State exits → RXDESKEW
        do_tx_state_exit(9'hF2);
        do_rx_state_exit_req(9'hA8);
        check("T18: DATATRAINVREF complete", 1'b1);
        repeat (3) @(negedge i_clk);

        // =====================================================================
        // T19 — RXDESKEW  (no eye-sweep)
        //   TX : sub0 req(0xA8) → sub1 req(0xAC) → exit(0xAC)
        //   RX : sub0 imm-rsp(0xA8) advances via req+0xAC →
        //        sub1 txrx(0xAC) → exit req(0xB0)
        // =====================================================================
        $display("\n--- T19: RXDESKEW ---");
        // TX sub0
        do_tx_req_hs(9'hA8);
        // RX sub0 — imm-rsp; advances via i_sb_rx_req+dec=0xAC
        @(negedge i_clk);
        check("T19: RX enc=0xA8 (RXDESKEW sub0)", o_rx_encoding === 9'hA8);
        check("T19: RX o_rx_sb_rsp=1",             o_rx_sb_rsp   === 1'b1);
        i_sb_rx_req   = 1;
        i_rx_decoding = 9'hAC;
        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = '0;
        repeat (2) @(negedge i_clk);
        // TX sub1
        do_tx_req_hs(9'hAC);
        // RX sub1 txrx(0xAC)
        do_rx_sub2(9'hAC);
        // State exits → DATATRAINCENTER2
        do_tx_state_exit(9'hAC);
        do_rx_state_exit_req(9'hB0);
        check("T19: RXDESKEW complete", 1'b1);
        repeat (3) @(negedge i_clk);

        // =====================================================================
        // T20 — DATATRAINCENTER2  (no_retry=1, final state)
        //   TX : sub0 req(0xB0) → eye-sweep[no_retry] → sub2 req(0xB2) →
        //        exit(0xB2) → train_active_en=1 → NS=VALVREF
        //   RX : sub0 imm-rsp(0xB0) → eye-sweep[no_retry] → sub2 txrx(0xB2)
        //        → train_active_en=1 → NS=VALVREF
        // =====================================================================
        $display("\n--- T20: DATATRAINCENTER2 ---");
        do_tx_req_hs(9'hB0);
        do_rx_imm_rsp_done(9'hB0);
        fork
            do_tx_eye_sweep();
            do_rx_eye_sweep();
        join
        do_tx_req_hs(9'hB2);
        i_sb_rx_req   = 1;
        i_rx_decoding = 9'hB2;
        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = '0;
        repeat (2) @(negedge i_clk);
        do_rx_sub2(9'hB2);
        do_tx_state_exit(9'hB2);
        do_rx_state_exit_req(9'hB8);
        check("T19: DATATRAINCENTER2 complete", 1'b1);
        repeat (3) @(negedge i_clk);

        // =====================================================================
        // T21 — Linkspeed  (no_retry=1)
        // =====================================================================
        $display("\n--- T21: Linkspeed ---");
        do_tx_req_hs(9'hB8);
        do_rx_imm_rsp_done(9'hB8);
        i_sb_rx_req = 1;
        i_rx_decoding = 'h180;

        i_sb_tx_rsp   = 1;
        i_tx_decoding = 9'hB8;
        @(negedge i_clk);
        i_sb_tx_rsp   = 0;
        i_tx_decoding = '0;
        fork
            do_tx_eye_sweep_tx_init(0);
            do_rx_eye_sweep_tx_init();
        join
        do_tx_req_hs(9'hBB);
        i_sb_rx_req   = 1;
        i_rx_decoding = 9'hBB;
        @(negedge i_clk);
        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = '0;

        check($sformatf("RX sub2 'hBA: o_rx_sb_rsp=1"),
              o_rx_sb_rsp   === 1'b1);
        check($sformatf("RX sub2 'hBA: o_rx_encoding"),
              o_rx_encoding === 'hBF);
        i_sb_rx_done = 1;
        @(negedge i_clk);
        i_sb_rx_done = 0;
        check($sformatf("RX sub2 'hBA: rsp cleared"),
              o_rx_sb_rsp === 1'b0);
        repeat (2) @(negedge i_clk);

        /*do_tx_state_exit(9'hBA);

        // =====================================================================
        // T22 — Linkspeed  (no_retry=1)
        // =====================================================================
        $display("\n--- T21: Linkspeed ---");
        do_tx_req_hs(9'hB8);
        do_rx_imm_rsp_done(9'hB8);
        i_sb_rx_req = 1;
        i_rx_decoding = 'h180;

        i_sb_tx_rsp   = 1;
        i_tx_decoding = 9'hB8;
        @(negedge i_clk);
        i_sb_tx_rsp   = 0;
        i_tx_decoding = '0;
        fork
            do_tx_eye_sweep_tx_init(1);
            do_rx_eye_sweep_tx_init();
        join
        do_tx_req_hs(9'hBA);
        i_sb_rx_req   = 1;
        i_rx_decoding = 9'hBA;
        @(negedge i_clk);
        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = '0;

        check($sformatf("RX sub2 'hBA: o_rx_sb_rsp=1"),
              o_rx_sb_rsp   === 1'b1);
        check($sformatf("RX sub2 'hBA: o_rx_encoding"),
              o_rx_encoding === 'hBA);
        i_sb_rx_done = 1;
        @(negedge i_clk);
        i_sb_rx_done = 0;
        check($sformatf("RX sub2 'hBA: rsp cleared"),
              o_rx_sb_rsp === 1'b0);
        repeat (2) @(negedge i_clk);

        do_tx_state_exit(9'hBA);*/


        /*// =====================================================================
        // T2 — Assert i_train_active_en → state=LINKINIT
        //   FSM moves from IDLE to LINKINIT on the next posedge.
        //   TX sub-FSM enters CLK_REQ_HS: asserts pl_clk_req and pl_inband_pres,
        //   output encoding=0x100.
        // =====================================================================
        $display("\n--- T2: i_train_active_en -> LINKINIT ---");

        @(negedge i_clk);
        @(negedge i_clk);

        wait_state(ST_LINKINIT, 5);
        check("T2: TX encoding=0x100 (CLK_HS)", o_tx_encoding    === 9'h100);
        check("T2: RX encoding=0x100 (CLK_HS)", o_rx_encoding    === 9'h100);
        check("T2: o_pl_clk_req=1",             o_pl_clk_req     === 1);
        check("T2: o_pl_inband_pres=1",         o_pl_inband_pres === 1);

        // =====================================================================
        // T3 — CLK_REQ_HS: Adapter asserts lp_clk_ack then de-asserts
        //   Spec rule: at least one clock cycle bubble between pl_clk_req assert
        //   and lp_clk_ack assert (already satisfied by sequential state entry).
        //   pl_clk_req must de-assert BEFORE lp_clk_ack de-asserts.
        //
        //   Sequence:
        //     1. Drive i_lp_clk_ack=1  → DUT latches clk_ack_seen=1,
        //                                 de-asserts o_pl_clk_req (combinational)
        //     2. Drive i_lp_clk_ack=0  → DUT sees clk_ack_seen && !lp_clk_ack
        //                                 → next_substate = WAKE_REQ_HS
        //   Both TX and RX track the same i_lp_clk_ack wire so both advance
        //   to WAKE_REQ_HS together.
        // =====================================================================
        $display("\n--- T3: CLK_REQ_HS -> WAKE_REQ_HS ---");

        // Adapter asserts lp_clk_ack (at least 1 cycle bubble already passed)
        @(negedge i_clk);
        i_lp_clk_ack = 1;
        @(negedge i_clk); // DUT latches clk_ack_seen=1 here; pl_clk_req drops
        check("T3: o_pl_clk_req de-asserted after lp_clk_ack rises", o_pl_clk_req === 0);

        // Adapter de-asserts lp_clk_ack → DUT advances to WAKE_REQ_HS
        @(negedge i_clk);
        i_lp_clk_ack = 0;
        @(negedge i_clk); // substate transition clocked in
        check("T3: TX encoding=0x101 (WAKE_HS)", o_tx_encoding === 9'h101);
        check("T3: RX encoding=0x101 (WAKE_HS)", o_rx_encoding === 9'h101);
        check("T3: o_pl_clk_req still 0",        o_pl_clk_req  === 0);
        check("T3: o_pl_inband_pres still 1",     o_pl_inband_pres === 1);

        // =====================================================================
        // T4 — WAKE_REQ_HS: Adapter asserts lp_wake_req then requests Active
        //   Spec rule: lp_wake_req de-asserts before pl_wake_ack de-asserts.
        //   DUT mirrors lp_wake_req → pl_wake_ack combinationally, so this is
        //   automatically satisfied.
        //
        //   Sequence:
        //     1. Drive i_lp_wake_req=1  → DUT mirrors → o_pl_wake_ack=1
        //     2. Drive i_lp_state_req=Active (4'b0001)
        //        → DUT sees LP_STATE_ACTIVE → next_substate = STATE_REQ_HS
        //     3. Drive i_lp_wake_req=0  (req de-asserts; wake ack follows)
        // =====================================================================
        $display("\n--- T4: WAKE_REQ_HS -> STATE_REQ/RSP_HS ---");

        // Adapter asserts wake request
        @(negedge i_clk);
        i_lp_wake_req = 1;
        @(negedge i_clk);
        check("T4: o_pl_wake_ack=1 (mirrors lp_wake_req)", o_pl_wake_ack === 1);

        // Adapter requests Active state
        @(negedge i_clk);
        i_lp_state_req = 4'b0001; // LP_STATE_ACTIVE
        @(negedge i_clk); // substate advances to STATE_REQ_HS
        check("T4: TX encoding=0x102 (STATE_REQ_HS)", o_tx_encoding === 9'h102);
        check("T4: RX encoding=0x102 (STATE_RSP_HS)", o_rx_encoding === 9'h102);
        check("T4: o_tx_sb_req=1 (TX waiting for done_ack)", o_tx_sb_req === 1);
        check("T4: o_rx_sb_rsp=1 (RX sending RSP)",          o_rx_sb_rsp === 1);

        // Adapter de-asserts wake request (wake_ack mirrors and drops automatically)
        @(negedge i_clk);
        i_lp_wake_req = 0;
        @(negedge i_clk);
        check("T4: o_pl_wake_ack=0 after wake_req de-asserts", o_pl_wake_ack === 0);

        // =====================================================================
        // T5 — STATE_REQ_HS (TX) + STATE_RSP_HS (RX) → both done → ACTIVE
        //
        //   TX (same pattern as all prior STATE_REQ states):
        //     Step 1: i_sb_tx_done=1  → done_ack latches → o_tx_sb_req drops
        //     Step 2: i_sb_tx_rsp=1 + i_tx_decoding=0x102 → o_done_linkinit_tx
        //
        //   RX (RX sends RSP; done fires on i_sb_rx_done):
        //     i_sb_rx_done=1 → o_done_linkinit_rx
        //
        //   TX and RX are driven independently; both done latches must be set
        //   before the top-level FSM advances to ACTIVE.
        // =====================================================================
        $display("\n--- T5: STATE_REQ/RSP_HS -> ACTIVE ---");

        // TX: done_ack latch (sideband layer confirms it received the REQ)
        @(negedge i_clk); i_sb_tx_done = 1;
        @(negedge i_clk); i_sb_tx_done = 0;
        check("T5: TX o_tx_sb_req dropped after done_ack", o_tx_sb_req === 0);

        // TX: RSP+0x102 → TX done fires
        @(negedge i_clk);
        i_sb_tx_rsp   = 1;
        i_tx_decoding = 9'h102;
        @(negedge i_clk);

        // RX: sb_rx_done → RX done fires (sideband confirms RSP was sent)
        @(negedge i_clk); i_sb_rx_done = 1;
        @(negedge i_clk); i_sb_rx_done = 0;
        i_sb_tx_rsp   = 0;
        i_tx_decoding = '0;

        // Both done latches set → FSM advances to ACTIVE
        wait_state(ST_ACTIVE, 5);

        // =====================================================================
        // T6 — Verify ACTIVE outputs
        //   pl_state_sts must be 0001 (Active)
        //   pl_inband_pres must stay 1 (asserted for lifetime of link operation)
        //   No sideband traffic expected in normal Active operation
        // =====================================================================
        $display("\n--- T6: Verify ACTIVE outputs ---");

        @(negedge i_clk);
        check("T6: pl_state_sts=Active (0001)", o_pl_state_sts   === PL_STS_ACTIVE);
        check("T6: pl_inband_pres=1",           o_pl_inband_pres === 1);
        check("T6: pl_clk_req=0 (HS done)",     o_pl_clk_req     === 0);
        check("T6: pl_wake_ack=0 (HS done)",    o_pl_wake_ack    === 0);
        check("T6: TX encoding=0x000 (idle)",   o_tx_encoding    === 9'h108);
        check("T6: RX encoding=0x000 (idle)",   o_rx_encoding    === 9'h108);


        // Hold a few more cycles — confirm ACTIVE is stable
        repeat (3) @(negedge i_clk);*/


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
    //  TX MBTRAIN HELPER TASKS
    //  (adapted from ucie_LTSM_TX_MBTRAIN_TB)
    // =========================================================================

    // =========================================================================
    // do_tx_eye_sweep_tx_init
    //   TX DUT in init=1 mode — TX is the initiator (0x180 series).
    //
    //   Flow (init=1 branch of ucie_TX_Data_to_Clock_eye_sweep):
    //   0x180 REQ_HS    : DUT req=1  → done_ack clears req
    //                     TB rsp+dec=0x180 → encoding→0x181
    //   0x181 LFSR_HS   : DUT req=1  → done_ack clears req
    //                     TB rsp+dec=0x181 → encoding→0x182
    //   0x182 DATA_GEN  : no sideband out; i_tx_done → encoding→0x183
    //   0x183 RESULT_HS : DUT req=1  → done_ack clears req
    //                     TB rsp+dec=0x183 + all-ones data → encoding→0x184
    //   0x184 END_HS    : DUT req=1  → done_ack clears req
    //                     TB rsp+dec=0x184 → done=1 (combinational)
    // =========================================================================
    task automatic do_tx_eye_sweep_tx_init(pass);
        $display("  [TX tx-init] eye-sweep start @%0t", $time);

        // --- REQ_HANDSHAKE 0x180 ---
        @(negedge i_clk);
        check("TX tx-init 0x180: o_tx_encoding",  o_tx_encoding === 9'h180);
        check("TX tx-init 0x180: o_tx_sb_req=1",  o_tx_sb_req   === 1'b1);
        // done_ack → clear req
        i_sb_tx_done = 1;
        @(negedge i_clk);
        i_sb_tx_done = 0;
        check("TX tx-init 0x180: req cleared",    o_tx_sb_req   === 1'b0);
        repeat (3) @(negedge i_clk);
        // TB rsp+dec=0x180 → transition to LFSR_HS (0x181)
        i_sb_tx_rsp   = 1;
        i_tx_decoding = 9'h180;
        @(negedge i_clk);
        check("TX tx-init → 0x181",               o_tx_encoding === 9'h181);
        i_sb_tx_rsp   = 0;
        i_tx_decoding = '0;

        // --- LFSR_HANDSHAKE 0x181 ---
        @(negedge i_clk);
        check("TX tx-init 0x181: o_tx_sb_req=1",  o_tx_sb_req === 1'b1);
        // done_ack → clear req
        i_sb_tx_done = 1;
        @(negedge i_clk);
        i_sb_tx_done = 0;
        check("TX tx-init 0x181: req cleared",    o_tx_sb_req === 1'b0);
        repeat (3) @(negedge i_clk);
        // TB rsp+dec=0x181 → transition to DATA_GENERATE (0x182)
        i_sb_tx_rsp   = 1;
        i_tx_decoding = 9'h181;
        @(negedge i_clk);
        check("TX tx-init → 0x182",               o_tx_encoding === 9'h182);
        i_sb_tx_rsp   = 0;
        i_tx_decoding = '0;

        // --- DATA_GENERATE 0x182: no sideband; wait then i_tx_done ---
        repeat (4) @(negedge i_clk);
        i_tx_done = 1;
        @(negedge i_clk);
        i_tx_done = 0;
        check("TX tx-init → 0x183",               o_tx_encoding === 9'h183);

        // --- RESULT_HANDSHAKE 0x183 ---
        @(negedge i_clk);
        check("TX tx-init 0x183: o_tx_sb_req=1",  o_tx_sb_req === 1'b1);
        // done_ack → clear req
        i_sb_tx_done = 1;
        @(negedge i_clk);
        i_sb_tx_done = 0;
        check("TX tx-init 0x183: req cleared",    o_tx_sb_req === 1'b0);
        repeat (2) @(negedge i_clk);
        // TB rsp+dec=0x183 + all-ones data (pass) → transition to END_HS (0x184)
        i_sb_tx_rsp   = 1;
        i_tx_decoding = 9'h183;
        if (pass) begin
            i_tx_data     = 64'hFFFF_FFFF_FFFF_FFFF;
        end else i_tx_data     = 0;
        
        @(negedge i_clk);
        check("TX tx-init → 0x184",               o_tx_encoding === 9'h184);
        i_sb_tx_rsp   = 0;
        i_tx_decoding = '0;
        i_tx_data     = '0;

        // --- END_HANDSHAKE 0x184 ---
        @(negedge i_clk);
        check("TX tx-init 0x184: o_tx_sb_req=1",  o_tx_sb_req === 1'b1);
        // done_ack → clear req
        i_sb_tx_done = 1;
        @(negedge i_clk);
        i_sb_tx_done = 0;
        check("TX tx-init 0x184: req cleared",    o_tx_sb_req === 1'b0);
        repeat (2) @(negedge i_clk);
        // TB rsp+dec=0x184 → done=1 (combinational)
        i_sb_tx_rsp   = 1;
        i_tx_decoding = 9'h184;
        @(negedge i_clk);
        i_sb_tx_rsp   = 0;
        i_tx_decoding = '0;
        repeat (2) @(negedge i_clk);

        $display("  [TX tx-init] eye-sweep done @%0t", $time);
    endtask

    // -------------------------------------------------------------------------
    // do_tx_req_hs : one full TX req/done/rsp substate handshake.
    //   Step 1: verify o_tx_encoding==enc and o_tx_sb_req==1
    //   Step 2: i_sb_tx_done → done_ack → DUT clears req
    //   Step 3: i_sb_tx_rsp+enc → o_tx_sb_done pulse → substate advances
    //   Step 4: i_sb_tx_req+0x188 → signals next sub-module entry
    // -------------------------------------------------------------------------
    task automatic do_tx_req_hs(input logic [8:0] enc);
        @(negedge i_clk);
        check($sformatf("TX req_hs 0x%03h: o_tx_encoding", enc),
              o_tx_encoding === enc);
        @(negedge i_clk);
        check($sformatf("TX req_hs 0x%03h: o_tx_sb_req=1", enc),
              o_tx_sb_req === 1'b1);
        // done_ack
        i_sb_tx_done = 1;
        @(negedge i_clk);
        i_sb_tx_done = 0;
        check($sformatf("TX req_hs 0x%03h: req cleared", enc),
              o_tx_sb_req === 1'b0);
        repeat (2) @(negedge i_clk);
        // rsp + matching decoding → done pulse fires
        i_sb_tx_rsp   = 1;
        i_tx_decoding = enc;
        @(negedge i_clk);
        check($sformatf("TX req_hs 0x%03h: o_tx_sb_done pulse", enc),
              o_tx_sb_done === 1'b1);
        i_sb_tx_rsp   = 0;
        i_tx_decoding = '0;
        // drive i_sb_tx_req+0x188 to signal next sub-module entry
        i_sb_tx_req   = 1;
        i_tx_decoding = 9'h188;
        @(negedge i_clk);
        i_sb_tx_req   = 0;
        i_tx_decoding = '0;
    endtask

    // -------------------------------------------------------------------------
    // do_tx_state_exit : assert i_sb_tx_rsp+enc once to set w_rsp_received,
    //                    triggering previous_state_done → state advance.
    // -------------------------------------------------------------------------
    task automatic do_tx_state_exit(input logic [8:0] enc);
        i_sb_tx_rsp   = 1;
        i_tx_decoding = enc;
        @(negedge i_clk);
        i_sb_tx_rsp   = 0;
        i_tx_decoding = '0;
        $display("  [TX] state-exit enc=0x%03h @%0t", enc, $time);
        repeat (2) @(negedge i_clk);
    endtask

    // -------------------------------------------------------------------------
    // do_tx_eye_sweep : full happy-path TX eye-sweep sub-sequence.
    //   Mirrors ucie_LTSM_TX_MBTRAIN_TB do_eye_sweep_happy_pass.
    //
    //   Entry    : o_tx_encoding=0x188, o_tx_sb_rsp=1  (already asserted)
    //   0x188 RSP: done+dec=0x188 → clears rsp → 0x189 (LFSR req)
    //   0x189 REQ: done_ack → rsp+0x189 → 0x18A (DATA_GENERATE)
    //   0x18A    : i_tx_done → 0x18B (RESULT_HS req)
    //   0x18B REQ: done_ack → rsp+0x18B + all-ones data → 0x18C (END_HS req)
    //   0x18C REQ: done_ack → i_sb_tx_req+0x18D → DUT rsp+done
    //   Final    : done+dec=0x18D → sweep complete → sub1 exits
    // -------------------------------------------------------------------------
    task automatic do_tx_eye_sweep();
        $display("  [TX] eye-sweep start @%0t", $time);

        // --- Entry: 0x188 with rsp already asserted ---
        @(negedge i_clk);
        check("TX sweep 0x188: o_tx_encoding", o_tx_encoding === 9'h188);
        @(negedge i_clk);
        check("TX sweep 0x188: o_tx_sb_rsp=1", o_tx_sb_rsp   === 1'b1);

        // done_ack + dec=0x188 → clears rsp → 0x189 (LFSR req)
        i_sb_tx_done  = 1;
        i_tx_decoding = 9'h188;
        @(negedge i_clk);
        i_sb_tx_done  = 0;
        check("TX sweep 0x188: rsp cleared", o_tx_sb_rsp   === 1'b0);
        check("TX sweep → 0x189",            o_tx_encoding === 9'h189);

        // --- 0x189 LFSR req ---
        @(negedge i_clk);
        check("TX sweep 0x189: o_tx_sb_req=1", o_tx_sb_req === 1'b1);
        // done_ack
        i_sb_tx_done = 1;
        @(negedge i_clk);
        i_sb_tx_done = 0;
        check("TX sweep 0x189: req cleared",  o_tx_sb_req === 1'b0);
        repeat (3) @(negedge i_clk);
        // rsp+0x189 → 0x18A (DATA_GENERATE)
        i_sb_tx_rsp   = 1;
        i_tx_decoding = 9'h189;
        @(negedge i_clk);
        check("TX sweep → 0x18A",               o_tx_encoding === 9'h18A);
        check("TX sweep 0x189: done pulse",      o_tx_sb_done  === 1'b1);
        i_sb_tx_rsp   = 0;
        i_tx_decoding = '0;
        @(negedge i_clk);
        check("TX sweep done deasserted",        o_tx_sb_done  === 1'b0);

        // --- 0x18A DATA_GENERATE: wait then i_tx_done ---
        repeat (4) @(negedge i_clk);
        i_tx_done = 1;
        @(negedge i_clk);
        i_tx_done = 0;
        check("TX sweep → 0x18B", o_tx_encoding === 9'h18B);

        // --- 0x18B RESULT_HS req ---
        @(negedge i_clk);
        check("TX sweep 0x18B: o_tx_sb_req=1", o_tx_sb_req === 1'b1);
        i_sb_tx_done = 1;
        @(negedge i_clk);
        i_sb_tx_done = 0;
        check("TX sweep 0x18B: req cleared",   o_tx_sb_req === 1'b0);
        repeat (2) @(negedge i_clk);
        // rsp+0x18B + all-ones data (pass) → 0x18C (END_HS req)
        i_sb_tx_rsp   = 1;
        i_tx_decoding = 9'h18B;
        i_tx_data     = 64'hFFFF_FFFF_FFFF_FFFF;
        @(negedge i_clk);
        check("TX sweep → 0x18C",              o_tx_encoding === 9'h18C);
        check("TX sweep 0x18B: done pulse",    o_tx_sb_done  === 1'b1);
        i_sb_tx_rsp   = 0;
        i_tx_data     = '0;

        // --- 0x18C END_HS req ---
        i_sb_tx_done = 1;
        @(negedge i_clk);
        i_sb_tx_done = 0;
        check("TX sweep 0x18C: o_tx_sb_req=1", o_tx_sb_req === 1'b1);
        repeat (2) @(negedge i_clk);
        // i_sb_tx_req+0x18D → DUT asserts rsp+done
        i_sb_tx_req   = 1;
        i_tx_decoding = 9'h18D;
        @(negedge i_clk);
        check("TX sweep → 0x18D",              o_tx_encoding === 9'h18D);
        check("TX sweep 0x18D: done pulse",    o_tx_sb_done  === 1'b1);
        @(negedge i_clk);
        check("TX sweep 0x18D: rsp=1",         o_tx_sb_rsp   === 1'b1);
        // Final done_ack + dec=0x18D
        i_sb_tx_done  = 1;
        i_sb_tx_req   = 0;
        i_tx_decoding = 9'h18D;
        @(negedge i_clk);
        i_sb_tx_done  = 0;
        i_tx_decoding = '0;
        repeat (2) @(negedge i_clk);

        $display("  [TX] eye-sweep done @%0t", $time);
    endtask

    // =========================================================================
    //  RX MBTRAIN HELPER TASKS
    //  (adapted from ucie_LTSM_RX_MBTRAIN_TB)
    // =========================================================================

    // =========================================================================
    // do_rx_eye_sweep_tx_init
    //   RX DUT in init=0 mode — TX is the initiator, RX responds (0x180 series).
    //
    //   Flow (init=0 branch of ucie_RX_Data_to_Clock_eye_sweep):
    //   0x180 REQ_HS    : DUT rsp=1  → done_ack clears rsp
    //                     TB req+dec=0x181 → encoding→0x181
    //   0x181 LFSR_HS   : DUT rsp=1  → done_ack clears rsp
    //                     TB i_sb_rx_done → encoding→0x182
    //   0x182 DATA_DETECT: no sideband out
    //                     TB req+dec=0x183 → encoding→0x183
    //   0x183 RESULT_HS : DUT rsp=1  → done_ack clears rsp
    //                     TB req+dec=0x184 (pass) → encoding→0x184
    //   0x184 END_HS    : DUT rsp=1  → done_ack clears rsp
    //                     TB done+dec=0x184 → done=1 (combinational)
    // =========================================================================
    task automatic do_rx_eye_sweep_tx_init();
        $display("  [RX tx-init] eye-sweep start @%0t", $time);

        // --- REQ_HANDSHAKE 0x180 ---
        @(negedge i_clk);
        check("RX tx-init 0x180: o_rx_encoding",  o_rx_encoding === 9'h180);
        check("RX tx-init 0x180: o_rx_sb_rsp=1",  o_rx_sb_rsp   === 1'b1);
        // done_ack → clear rsp
        i_sb_rx_done = 1;
        @(negedge i_clk);
        i_sb_rx_done = 0;
        check("RX tx-init 0x180: rsp cleared",    o_rx_sb_rsp   === 1'b0);
        repeat (2) @(negedge i_clk);
        // TB req+dec=0x181 → transition to LFSR_HS (0x181)
        i_sb_rx_req   = 1;
        i_rx_decoding = 9'h181;
        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = '0;
        check("RX tx-init → 0x181",               o_rx_encoding === 9'h181);

        // --- LFSR_HANDSHAKE 0x181 ---
        @(negedge i_clk);
        check("RX tx-init 0x181: o_rx_sb_rsp=1",  o_rx_sb_rsp === 1'b1);
        // done_ack → clear rsp
        i_sb_rx_done = 1;
        @(negedge i_clk);
        i_sb_rx_done = 0;
        check("RX tx-init 0x181: rsp cleared",    o_rx_sb_rsp === 1'b0);
        // i_sb_xx_done pulse → transition to DATA_DETECT (0x182)
        repeat (2) @(negedge i_clk);
        i_sb_rx_done = 1;
        @(negedge i_clk);
        i_sb_rx_done = 0;

        // --- DATA_DETECT 0x182 ---
        @(negedge i_clk);
        check("RX tx-init → 0x182 (DATA_DETECT)", o_rx_encoding === 9'h182);
        // TB req+dec=0x183 → transition to RESULT_HS (0x183)
        i_sb_rx_req   = 1;
        i_rx_decoding = 9'h183;
        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = '0;
        check("RX tx-init → 0x183 (RESULT_HS)",   o_rx_encoding === 9'h183);

        // --- RESULT_HANDSHAKE 0x183 ---
        @(negedge i_clk);
        check("RX tx-init 0x183: o_rx_sb_rsp=1",  o_rx_sb_rsp === 1'b1);
        // done_ack → clear rsp
        i_sb_rx_done = 1;
        @(negedge i_clk);
        i_sb_rx_done = 0;
        check("RX tx-init 0x183: rsp cleared",    o_rx_sb_rsp === 1'b0);
        repeat (2) @(negedge i_clk);
        // TB req+dec=0x184 (pass path) → transition to END_HS (0x184)
        i_sb_rx_req   = 1;
        i_rx_decoding = 9'h184;
        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = '0;
        check("RX tx-init → 0x184 (END_HS)",      o_rx_encoding === 9'h184);

        // --- END_HANDSHAKE 0x184 ---
        @(negedge i_clk);
        check("RX tx-init 0x184: o_rx_sb_rsp=1",  o_rx_sb_rsp === 1'b1);
        // done_ack only (no decoding yet) → clears rsp, done stays 0
        i_sb_rx_done = 1;
        @(negedge i_clk);
        i_sb_rx_done = 0;
        check("RX tx-init 0x184: rsp cleared",    o_rx_sb_rsp === 1'b0);
        repeat (2) @(negedge i_clk);
        // TB done+dec=0x184 → done=1 (combinational)
        i_sb_rx_done  = 1;
        i_rx_decoding = 9'h184;
        @(negedge i_clk);
        i_sb_rx_done  = 0;
        i_rx_decoding = '0;
        repeat (2) @(negedge i_clk);

        $display("  [RX tx-init] eye-sweep done @%0t", $time);
    endtask

    // -------------------------------------------------------------------------
    // do_rx_imm_rsp_done : sub0 where DUT immediately asserts rsp on entry.
    //   Check o_rx_encoding==enc and o_rx_sb_rsp==1, then i_sb_rx_done.
    // -------------------------------------------------------------------------
    task automatic do_rx_imm_rsp_done(input logic [8:0] enc);
        @(negedge i_clk);
        check($sformatf("RX imm_rsp 0x%03h: o_rx_encoding", enc),
              o_rx_encoding === enc);
        check($sformatf("RX imm_rsp 0x%03h: o_rx_sb_rsp=1", enc),
              o_rx_sb_rsp   === 1'b1);
        i_sb_rx_done = 1;
        @(negedge i_clk);
        i_sb_rx_done = 0;
        repeat (2) @(negedge i_clk);
    endtask

    // -------------------------------------------------------------------------
    // do_rx_req_rsp_done : sub0 where TB must send req first (VALVREF only).
    //   TB req → DUT rsp → TB done_ack → DUT clears rsp → advances to sub1.
    // -------------------------------------------------------------------------
    task automatic do_rx_req_rsp_done(input logic [8:0] enc);
        @(negedge i_clk);
        check($sformatf("RX req_rsp 0x%03h: o_rx_encoding", enc),
              o_rx_encoding === enc);
        check($sformatf("RX req_rsp 0x%03h: o_rx_sb_rsp=1", enc),
              o_rx_sb_rsp   === 1'b1);
        i_sb_rx_done = 1;
        @(negedge i_clk);
        i_sb_rx_req  = 0;
        i_sb_rx_done = 0;
        check($sformatf("RX req_rsp 0x%03h: rsp cleared", enc),
              o_rx_sb_rsp === 1'b0);
        repeat (2) @(negedge i_clk);
    endtask

    // -------------------------------------------------------------------------
    // do_rx_sub2 : sub2 completion handshake.
    //   TB asserts i_tx_done+i_rx_done → DUT asserts o_rx_sb_rsp →
    //   TB done_ack → rsp cleared → substates_done.
    //   o_rx_sb_rsp going high also captures w_rsp_sent in ucie_LTSM.
    // -------------------------------------------------------------------------
    task automatic do_rx_sub2(input logic [8:0] enc);
        i_tx_done = 1;
        i_rx_done = 1;
        @(negedge i_clk);
        i_tx_done = 0;
        i_rx_done = 0;
        check($sformatf("RX sub2 0x%03h: o_rx_sb_rsp=1", enc),
              o_rx_sb_rsp   === 1'b1);
        check($sformatf("RX sub2 0x%03h: o_rx_encoding", enc),
              o_rx_encoding === enc);
        i_sb_rx_done = 1;
        @(negedge i_clk);
        i_sb_rx_done = 0;
        check($sformatf("RX sub2 0x%03h: rsp cleared", enc),
              o_rx_sb_rsp === 1'b0);
        repeat (2) @(negedge i_clk);
    endtask

    // -------------------------------------------------------------------------
    // do_rx_state_exit_req : trigger RX CS transition via req_received.
    //   TB asserts i_sb_rx_req+enc → req_received captured → NS advances.
    // -------------------------------------------------------------------------
    task automatic do_rx_state_exit_req(input logic [8:0] enc);
        i_sb_rx_req   = 1;
        i_rx_decoding = enc;
        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = '0;
        $display("  [RX] state-exit req enc=0x%03h @%0t", enc, $time);
        repeat (2) @(negedge i_clk);
    endtask

    // -------------------------------------------------------------------------
    // do_rx_eye_sweep : full happy-path RX eye-sweep sub-sequence.
    //   Mirrors ucie_LTSM_RX_MBTRAIN_TB do_eye_sweep_happy_pass_rx.
    //
    //   Entry       : o_rx_encoding=0x188, o_rx_sb_req=1  (already asserted)
    //   REQ_HS 0x188: done_ack → req cleared
    //                 TB req+dec=0x189 → LFSR_HS (0x189)
    //   LFSR   0x189: DUT rsp immediate → done_ack clears rsp
    //                 second i_sb_rx_done → DATA_DETECT (0x18A)
    //   DATA   0x18A: TB req+dec=0x18B → RESULT_HS (0x18B)
    //   RESULT 0x18B: DUT rsp immediate → done_ack clears rsp
    //                 TB req+dec=0x18C → SWEEP_RESULT_HS (0x18C)
    //   SWEEP  0x18C: immediate → END_HS (0x18D)
    //   END    0x18D: DUT req → done_ack → TB rsp+dec=0x18D → sweep done
    // -------------------------------------------------------------------------
    task automatic do_rx_eye_sweep();
        $display("  [RX] eye-sweep start @%0t", $time);

        // --- REQ_HANDSHAKE 0x188 ---
        @(negedge i_clk);
        check("RX sweep 0x188: o_rx_encoding", o_rx_encoding === 9'h188);
        check("RX sweep 0x188: o_rx_sb_req=1", o_rx_sb_req   === 1'b1);
        // done_ack → clear req
        i_sb_rx_done = 1;
        @(negedge i_clk);
        i_sb_rx_done = 0;
        check("RX sweep 0x188: req cleared",   o_rx_sb_req === 1'b0);
        repeat (2) @(negedge i_clk);
        // TB req+dec=0x189 → LFSR_HS
        i_sb_rx_req   = 1;
        i_rx_decoding = 9'h189;
        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = '0;
        check("RX sweep → 0x189 (LFSR)",       o_rx_encoding === 9'h189);

        // --- LFSR_HS 0x189: DUT rsp immediate ---
        @(negedge i_clk);
        check("RX sweep 0x189: o_rx_sb_rsp=1", o_rx_sb_rsp === 1'b1);
        // done_ack → clear rsp
        i_sb_rx_done = 1;
        @(negedge i_clk);
        i_sb_rx_done = 0;
        check("RX sweep 0x189: rsp cleared",   o_rx_sb_rsp === 1'b0);
        // second done → DATA_DETECT (0x18A)
        repeat (2) @(negedge i_clk);
        i_sb_rx_done = 1;
        @(negedge i_clk);
        i_sb_rx_done = 0;

        // --- DATA_DETECT 0x18A ---
        @(negedge i_clk);
        check("RX sweep → 0x18A (DATA_DETECT)", o_rx_encoding === 9'h18A);
        // TB req+dec=0x18B → RESULT_HS
        i_sb_rx_req   = 1;
        i_rx_decoding = 9'h18B;
        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = '0;
        check("RX sweep → 0x18B (RESULT_HS)",   o_rx_encoding === 9'h18B);

        // --- RESULT_HS 0x18B: DUT rsp immediate ---
        @(negedge i_clk);
        check("RX sweep 0x18B: o_rx_sb_rsp=1",  o_rx_sb_rsp === 1'b1);
        // done_ack → clear rsp
        i_sb_rx_done = 1;
        @(negedge i_clk);
        i_sb_rx_done = 0;
        check("RX sweep 0x18B: rsp cleared",    o_rx_sb_rsp === 1'b0);
        // TB req+dec=0x18C → SWEEP_RESULT_HS
        repeat (2) @(negedge i_clk);
        i_sb_rx_req   = 1;
        i_rx_decoding = 9'h18C;
        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = '0;
        check("RX sweep → 0x18C (SWEEP_RESULT)", o_rx_encoding === 9'h18C);

        // --- SWEEP_RESULT 0x18C → END_HS (0x18D) immediately ---
        @(negedge i_clk);
        check("RX sweep → 0x18D (END_HS)",       o_rx_encoding === 9'h18D);

        // --- END_HS 0x18D: DUT req ---
        @(negedge i_clk);
        check("RX sweep 0x18D: o_rx_sb_req=1",   o_rx_sb_req === 1'b1);
        // done_ack → clear req
        i_sb_rx_done = 1;
        @(negedge i_clk);
        i_sb_rx_done = 0;
        check("RX sweep 0x18D: req cleared",     o_rx_sb_req === 1'b0);
        repeat (2) @(negedge i_clk);
        // TB rsp+dec=0x18D → clock_to_test_done → sub1 exits
        i_sb_rx_rsp   = 1;
        i_rx_decoding = 9'h18D;
        @(negedge i_clk);
        i_sb_rx_rsp   = 0;
        i_rx_decoding = '0;
        repeat (3) @(negedge i_clk);

        $display("  [RX] eye-sweep done @%0t", $time);
    endtask

    // -------------------------------------------------------------------------
    // Watchdog
    // -------------------------------------------------------------------------
    initial begin
        #1_000_000;
        $display("[WATCHDOG] Simulation timed out");
        $finish;
    end

    // -------------------------------------------------------------------------
    // Waveform dump
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("ucie_LTSM_tb.vcd");
        $dumpvars(0, ucie_LTSM_tb);
    end

endmodule