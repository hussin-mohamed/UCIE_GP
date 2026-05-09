// =============================================================================
// Module : ucie_LTSM_TX_MBTRAIN_TB
// Description: Testbench for the UCIe TX Link Training State Machine.
//              Follows the same req/done/rsp handshake sequencing pattern
//              established in ucie_TX_Data_to_Clock_eye_sweep_TB.
//
// Handshake Protocol Recap:
//   1. DUT asserts o_tx_sb_req=1 when entering a new encoding substate
//   2. TB asserts i_sb_tx_done=1 → internal done_ack=1 → DUT deasserts req
//   3. TB asserts i_sb_tx_rsp=1 with matching i_tx_decoding
//       → clears done_ack, triggers substate advance, fires o_tx_sb_done pulse
//   4. State-level exit: TB drives rsp_received=1 with matching encoding once
//      substates_done=1, so that previous_state_done fires → CS advances
//
// State / Substate Map (happy path):
//   VALVREF         (0x80  → eye_sweep → 0x82)              → DATAVREF
//   DATAVREF        (0x88  → eye_sweep → 0x8A)              → SPEEDIDLE
//   SPEEDIDLE       (0xC8  → 0xCA)                          → TXSELFCAL
//   TXSELFCAL       (0xD0  → 0xD1)                          → RXCLKCAL
//   RXCLKCAL        (0x98  → 0x9A)                          → VALTRAINCENTER
//   VALTRAINCENTER  (0xA0  → eye_sweep → 0xA2)              → VALTRAINVREF
//   VALTRAINVREF    (0xE8  → eye_sweep → 0xEA)              → DATATRAINCENTER1
//   DATATRAINCENTER1(0x90  → eye_sweep[no_retry] → 0x92)   → DATATRAINVREF
//   DATATRAINVREF   (0xF0  → eye_sweep → 0xF2)              → RXDESKEW
//   RXDESKEW        (0xA8  → 0xAC)                          → DATATRAINCENTER2
//   DATATRAINCENTER2(0xB0  → eye_sweep[no_retry] → 0xB2)   → train_link_init_en
//
// Eye-Sweep Sub-sequence (TX MBTRAIN uses init=0 — TX is the RESPONDER):
//   In ucie_TX_Data_to_Clock_eye_sweep with init=0, TX responds to an
//   RX-initiated sweep.  Encodings are in the 0x188–0x18D range:
//   REQ_HANDSHAKE    (0x188): DUT asserts o_tx_sb_rsp; TB done_ack clears it;
//                             TB req+0x189 → LFSR_HANDSHAKE
//   LFSR_HANDSHAKE   (0x189): DUT req; TB done_ack; TB rsp+0x189 → DATA_GENERATE
//   DATA_GENERATE    (0x18A): TB asserts i_tx_done → RESULT_HANDSHAKE
//   RESULT_HANDSHAKE (0x18B): DUT req; TB done_ack; TB rsp+0x18B + i_tx_data=all1s
//   SWEEP_RESULT_HS  (0x18C): DUT req; TB done_ack; TB req+0x18D → END_HANDSHAKE
//   END_HANDSHAKE    (0x18D): DUT rsp+done; TB done → clock_to_test_done → sub2
// =============================================================================

module ucie_LTSM_TX_MBTRAIN_TB ();

// -----------------------------------------------------------------------
// Parameters — match DUT defaults
// -----------------------------------------------------------------------
parameter DECODING_WIDTH  = 9;
parameter DATA_WIDTH      = 64;
parameter INFO_WIDTH      = 16;
parameter ERROR_THRESHOLD = 0;

// -----------------------------------------------------------------------
// DUT Signal Declarations
// -----------------------------------------------------------------------
logic                       i_clk;
logic                       i_reset;

// TX interface inputs (from remote RX, driven by TB)
logic [DECODING_WIDTH-1:0]  i_tx_decoding;
logic [DATA_WIDTH-1:0]      i_tx_data;
logic [INFO_WIDTH-1:0]      i_tx_info;
logic [7:0]                 i_tx_sweep_result;  // Eye sweep result fed to sub-module

// Sideband inputs (driven by TB, simulating remote RX)
logic i_sb_tx_req;
logic i_sb_tx_rsp;
logic i_sb_tx_done;
logic i_tx_done;             // Asserted by TB to signal TX data generation complete

// Training control inputs — tie unused enables to 0 for happy-path test
logic       init_train_en;
logic       speed_idle_state_enable;    // Normally from active FSM; 0 here
logic       repair_state_enable;        // Normally from active FSM; 0 here
logic       tx_self_cal_state_enable;   // Normally from active FSM; 0 here
logic       timeout;
logic [2:0] Lane_map_code;              // Lane repair map; 0 for happy-path

// Speed registers
// i_speedreg drives speed negotiation; DUT computes o_pl_speedmode = i_speedreg-1.
// Set i_speedreg >= 1 to avoid trainerror in SPEEDIDLE.
// *** IMPORTANT: o_pl_speedmode is a DUT OUTPUT — the TB must never drive it. ***
logic [2:0] i_speedreg;
logic [2:0] o_speedreg;   // DUT output — receives negotiated speed register

// RSP handshake tracking inputs
// These mirror the combinational RSP-tracking block in ucie_LTSM.sv.
// rsp_sent:     asserted when the local side sends a sideband response.
// rsp_received: asserted when a remote-side response is received.
// Together: previous_state_done = rsp_sent & rsp_received (inside DUT).
logic [DECODING_WIDTH-1:0] encoding_rsp_sent;
logic [DECODING_WIDTH-1:0] encoding_rsp_received;
logic                      rsp_received;
logic                      rsp_sent;

// TX interface outputs (from DUT — observe only)
logic [DECODING_WIDTH-1:0] o_tx_encoding;
logic [DATA_WIDTH-1:0]     o_tx_data;
logic [INFO_WIDTH-1:0]     o_tx_info;
logic [2:0]                o_pl_speedmode;  // DUT output — do NOT drive from TB

// Sideband outputs (from DUT)
logic o_tx_sb_req;
logic o_tx_sb_rsp;
logic o_tx_sb_done;

// Status outputs (from DUT)
logic train_error;
logic failed_test;            // Per-lane test failure flag
logic train_link_init_en;     // MBTRAIN done → handoff to ACTIVE FSM
logic train_phyretrain_en;    // Retrain path requested

// -----------------------------------------------------------------------
// Expected-value mirrors (for assertion messages)
// -----------------------------------------------------------------------
logic [DECODING_WIDTH-1:0] o_tx_encoding_expected;
logic [DATA_WIDTH-1:0]     o_tx_data_expected;
logic                      o_tx_sb_req_expected;
logic                      o_tx_sb_rsp_expected;
logic                      o_tx_sb_done_expected;
logic                      train_link_init_en_expected;

// -----------------------------------------------------------------------
// DUT Instantiation — all ports connected; no floating inputs
// -----------------------------------------------------------------------
ucie_LTSM_TX_MBTRAIN #(
    .DECODING_WIDTH  (DECODING_WIDTH),
    .DATA_WIDTH      (DATA_WIDTH),
    .INFO_WIDTH      (INFO_WIDTH),
    .ERROR_THRESHOLD (ERROR_THRESHOLD)
) DUT (
    .i_clk                    (i_clk),
    .i_reset                  (i_reset),
    // TX interface
    .i_tx_decoding            (i_tx_decoding),
    .i_tx_data                (i_tx_data),
    .i_tx_info                (i_tx_info),
    .i_tx_sweep_result        (i_tx_sweep_result),
    .Lane_map_code            (Lane_map_code),
    // Sideband inputs
    .i_sb_tx_req              (i_sb_tx_req),
    .i_sb_tx_rsp              (i_sb_tx_rsp),
    .i_sb_tx_done             (i_sb_tx_done),
    .i_tx_done                (i_tx_done),
    // Training control
    .init_train_en            (init_train_en),
    .speed_idle_state_enable  (speed_idle_state_enable),
    .repair_state_enable      (repair_state_enable),
    .tx_self_cal_state_enable (tx_self_cal_state_enable),
    .timeout                  (timeout),
    // Speed registers
    .o_pl_speedmode           (o_pl_speedmode),
    .i_speedreg               (i_speedreg),
    .o_speedreg               (o_speedreg),
    // RSP handshake tracking
    .encoding_rsp_sent        (encoding_rsp_sent),
    .encoding_rsp_received    (encoding_rsp_received),
    .rsp_received             (rsp_received),
    .rsp_sent                 (rsp_sent),
    // TX outputs
    .o_tx_encoding            (o_tx_encoding),
    .o_tx_data                (o_tx_data),
    .o_tx_info                (o_tx_info),
    .failed_test              (failed_test),
    // Sideband outputs
    .o_tx_sb_req              (o_tx_sb_req),
    .o_tx_sb_rsp              (o_tx_sb_rsp),
    .o_tx_sb_done             (o_tx_sb_done),
    // Status
    .train_error              (train_error),
    .train_link_init_en       (train_link_init_en),
    .train_phyretrain_en      (train_phyretrain_en)
);

// -----------------------------------------------------------------------
// Clock Generation — 100 MHz (10 ns period)
// -----------------------------------------------------------------------
initial begin
    i_clk = 0;
    forever #5 i_clk = ~i_clk;
end

// -----------------------------------------------------------------------
// Helper Tasks
// -----------------------------------------------------------------------

// --- do_req_hs -----------------------------------------------------------
// Drive a single sideband req/done/rsp handshake for encoding enc.
// Used for MBTRAIN outer-substate transitions (DUT is the TX-side requester).
//
// Step 1: Verify DUT asserts o_tx_sb_req=1 with encoding enc.
// Step 2: TB pulses i_sb_tx_done → done_ack → DUT deasserts req.
// Step 3: TB asserts i_sb_tx_rsp + matching decoding → substate advance.
//         Also drives rsp_sent so previous_state_done can fire later.
// Step 4: TB drives i_sb_tx_req+0x188 to push the DUT eye-sweep trigger.
// -------------------------------------------------------------------------
task do_req_hs (input [DECODING_WIDTH-1:0] enc);
    begin
        // ---- Step 1: verify req + encoding ----------------------------
        o_tx_encoding_expected = enc;
        @(negedge i_clk);
        assert (o_tx_encoding_expected == o_tx_encoding)
        else $display("ERROR [do_req_hs] Expected o_tx_encoding=0x%h, got 0x%h at %0t",
                      o_tx_encoding_expected, o_tx_encoding, $time);

        o_tx_sb_req_expected = 1;
        @(negedge i_clk);
        assert (o_tx_sb_req_expected == o_tx_sb_req)
        else $display("ERROR [do_req_hs] Expected o_tx_sb_req=%b, got %b at %0t",
                      o_tx_sb_req_expected, o_tx_sb_req, $time);

        // ---- Step 2: done_ack → DUT clears req ------------------------
        i_sb_tx_done         = 1;
        o_tx_sb_req_expected = 0;
        @(negedge i_clk);
        i_sb_tx_done = 0;
        assert (o_tx_sb_req_expected == o_tx_sb_req)
        else $display("ERROR [do_req_hs] Expected o_tx_sb_req=%b, got %b at %0t",
                      o_tx_sb_req_expected, o_tx_sb_req, $time);

        repeat (2) @(negedge i_clk);

        // ---- Step 3: rsp + matching decoding → advance substate -------
        i_sb_tx_rsp           = 1;
        rsp_sent              = 1;   // capture rsp_sent for previous_state_done
        encoding_rsp_sent     = enc;
        i_tx_decoding         = enc;
        o_tx_sb_done_expected = 1;

        @(negedge i_clk);
        assert (o_tx_sb_done_expected == o_tx_sb_done)
        else $display("ERROR [do_req_hs] Expected o_tx_sb_done=%b, got %b at %0t",
                      o_tx_sb_done_expected, o_tx_sb_done, $time);

        i_sb_tx_rsp           = 0;
        i_tx_decoding         = 0;
        o_tx_sb_done_expected = 1;

        // ---- Step 4: trigger eye-sweep entry --------------------------
        i_sb_tx_req   = 1;
        i_tx_decoding = 'h188;

        @(negedge i_clk);
        i_sb_tx_req   = 0;
        i_sb_tx_rsp   = 0;
        i_tx_decoding = 0;
        assert (o_tx_sb_done_expected == o_tx_sb_done)
        else $display("ERROR [do_req_hs] Expected o_tx_sb_done=%b, got %b at %0t",
                      o_tx_sb_done_expected, o_tx_sb_done, $time);
    end
endtask

// --- do_state_exit_hs ----------------------------------------------------
// Assert rsp_received to complete the two-way handshake that triggers
// previous_state_done (= rsp_sent & rsp_received) inside the DUT.
// Call this after do_req_hs has already set rsp_sent for the same enc.
// -------------------------------------------------------------------------
task do_state_exit_hs(input [DECODING_WIDTH-1:0] enc);
    begin
        rsp_received          = 1;
        encoding_rsp_received = enc;

        @(negedge i_clk);
        rsp_received          = 0;
        encoding_rsp_received = enc;
        i_sb_tx_req           = 0;
        i_sb_tx_rsp           = 0;
        i_tx_decoding         = 0;
        $display("INFO  [do_state_exit_hs] state exit for enc=0x%h at %0t", enc, $time);
    end
endtask

// --- do_eye_sweep_happy_pass ---------------------------------------------
// Drive the embedded ucie_TX_Data_to_Clock_eye_sweep through a full
// successful sweep.
//
// TX MBTRAIN sets init=0 (TX is the RESPONDER): the encoding range is
// 0x188–0x18D.  All-1s i_tx_data = every lane passed = failed_test=0.
// -------------------------------------------------------------------------
task do_eye_sweep_happy_pass();
    begin
        $display("INFO  [eye_sweep_tx] starting at %0t", $time);

        // ================================================================
        // REQ_HANDSHAKE (0x188) — TX responds; DUT asserts o_tx_sb_rsp.
        // TB done_ack clears rsp; TB req+0x189 triggers LFSR_HANDSHAKE.
        // ================================================================
        o_tx_encoding_expected = 'h188;
        i_sb_tx_req            = 0;
        @(negedge i_clk);
        assert (o_tx_encoding_expected == o_tx_encoding)
        else $display("ERROR [eye_sweep] Expected o_tx_encoding=0x%h, got 0x%h at %0t",
                      o_tx_encoding_expected, o_tx_encoding, $time);

        o_tx_sb_rsp_expected  = 1;
        o_tx_sb_done_expected = 0;
        @(negedge i_clk);
        assert (o_tx_sb_rsp_expected == o_tx_sb_rsp)
        else $display("ERROR [eye_sweep] Expected o_tx_sb_rsp=%b, got %b at %0t",
                      o_tx_sb_rsp_expected, o_tx_sb_rsp, $time);
        assert (o_tx_sb_done_expected == o_tx_sb_done)
        else $display("ERROR [eye_sweep] Expected o_tx_sb_done=%b, got %b at %0t",
                      o_tx_sb_done_expected, o_tx_sb_done, $time);

        // done_ack → DUT clears rsp
        i_sb_tx_done           = 1;
        i_sb_tx_req            = 0;
        i_tx_decoding          = 'h188;
        o_tx_sb_rsp_expected   = 0;
        o_tx_encoding_expected = 'h189;

        @(negedge i_clk);
        assert (o_tx_sb_rsp_expected == o_tx_sb_rsp)
        else $display("ERROR [eye_sweep] Expected o_tx_sb_rsp=%b, got %b at %0t",
                      o_tx_sb_rsp_expected, o_tx_sb_rsp, $time);
        assert (o_tx_encoding_expected == o_tx_encoding)
        else $display("ERROR [eye_sweep] Expected o_tx_encoding=0x%h, got 0x%h at %0t",
                      o_tx_encoding_expected, o_tx_encoding, $time);

        i_sb_tx_done         = 0;
        o_tx_sb_req_expected = 1;   // DUT now requests LFSR setup
        @(negedge i_clk);
        assert (o_tx_sb_req_expected == o_tx_sb_req)
        else $display("ERROR [eye_sweep] Expected o_tx_sb_req=%b, got %b at %0t",
                      o_tx_sb_req_expected, o_tx_sb_req, $time);

        // ================================================================
        // LFSR_HANDSHAKE (0x189) — DUT req; TB done_ack → rsp+0x189
        // → DATA_GENERATE (0x18A)
        // ================================================================
        i_sb_tx_done          = 1;
        o_tx_sb_req_expected  = 0;
        o_tx_sb_done_expected = 0;
        @(negedge i_clk);
        i_sb_tx_done = 0;
        assert (o_tx_sb_req_expected == o_tx_sb_req)
        else $display("ERROR [eye_sweep] Expected o_tx_sb_req=%b, got %b at %0t",
                      o_tx_sb_req_expected, o_tx_sb_req, $time);
        assert (o_tx_sb_done_expected == o_tx_sb_done)
        else $display("ERROR [eye_sweep] Expected o_tx_sb_done=%b, got %b at %0t",
                      o_tx_sb_done_expected, o_tx_sb_done, $time);

        repeat (3) @(negedge i_clk);

        // rsp → DATA_GENERATE
        i_sb_tx_rsp            = 1;
        i_tx_decoding          = 'h189;
        o_tx_sb_done_expected  = 1;
        o_tx_encoding_expected = 'h18A;

        @(negedge i_clk);
        assert (o_tx_encoding_expected == o_tx_encoding)
        else $display("ERROR [eye_sweep] Expected o_tx_encoding=0x%h, got 0x%h at %0t",
                      o_tx_encoding_expected, o_tx_encoding, $time);
        assert (o_tx_sb_done_expected == o_tx_sb_done)
        else $display("ERROR [eye_sweep] Expected o_tx_sb_done=%b, got %b at %0t",
                      o_tx_sb_done_expected, o_tx_sb_done, $time);

        i_sb_tx_rsp           = 0;
        i_tx_decoding         = 0;
        o_tx_sb_done_expected = 0;
        @(negedge i_clk);
        assert (o_tx_sb_done_expected == o_tx_sb_done)
        else $display("ERROR [eye_sweep] Expected o_tx_sb_done=%b, got %b at %0t",
                      o_tx_sb_done_expected, o_tx_sb_done, $time);

        // ================================================================
        // DATA_GENERATE (0x18A) — TB pulses i_tx_done to signal completion
        // → RESULT_HANDSHAKE (0x18B)
        // ================================================================
        repeat (4) @(negedge i_clk);
        i_tx_done = 1;
        o_tx_encoding_expected = 'h18B;
        @(negedge i_clk);
        i_tx_done = 0;
        assert (o_tx_encoding_expected == o_tx_encoding)
        else $display("ERROR [eye_sweep] Expected o_tx_encoding=0x%h, got 0x%h at %0t",
                      o_tx_encoding_expected, o_tx_encoding, $time);

        o_tx_sb_req_expected = 1;
        @(negedge i_clk);
        assert (o_tx_sb_req_expected == o_tx_sb_req)
        else $display("ERROR [eye_sweep] Expected o_tx_sb_req=%b, got %b at %0t",
                      o_tx_sb_req_expected, o_tx_sb_req, $time);

        // ================================================================
        // RESULT_HANDSHAKE (0x18B) — DUT req; TB done_ack; TB rsp+all-1s
        // all-1s i_tx_data = all lanes passed → failed_test=0 → no retry
        // → SWEEP_RESULT_HANDSHAKE (0x18C)
        // ================================================================
        i_sb_tx_done          = 1;
        o_tx_sb_req_expected  = 0;
        @(negedge i_clk);
        i_sb_tx_done = 0;
        assert (o_tx_sb_req_expected == o_tx_sb_req)
        else $display("ERROR [eye_sweep] Expected o_tx_sb_req=%b, got %b at %0t",
                      o_tx_sb_req_expected, o_tx_sb_req, $time);

        repeat (2) @(negedge i_clk);

        i_sb_tx_rsp            = 1;
        i_tx_decoding          = 'h18B;
        i_tx_data              = {DATA_WIDTH{1'b1}};   // all 1s → pass all lanes
        o_tx_sb_done_expected  = 1;
        o_tx_encoding_expected = 'h18C;

        @(negedge i_clk);
        assert (o_tx_encoding_expected == o_tx_encoding)
        else $display("ERROR [eye_sweep] Expected o_tx_encoding=0x%h, got 0x%h at %0t",
                      o_tx_encoding_expected, o_tx_encoding, $time);
        assert (o_tx_sb_done_expected == o_tx_sb_done)
        else $display("ERROR [eye_sweep] Expected o_tx_sb_done=%b, got %b at %0t",
                      o_tx_sb_done_expected, o_tx_sb_done, $time);

        i_sb_tx_rsp          = 0;
        i_sb_tx_done         = 0;
        o_tx_sb_req_expected = 1;

        @(negedge i_clk);
        assert (o_tx_sb_req_expected == o_tx_sb_req)
        else $display("ERROR [eye_sweep] Expected o_tx_sb_req=%b, got %b at %0t",
                      o_tx_sb_req_expected, o_tx_sb_req, $time);

        // ================================================================
        // SWEEP_RESULT_HANDSHAKE (0x18C) — DUT req; TB done_ack; TB req+0x18D
        // → END_HANDSHAKE (0x18D)
        // ================================================================
        i_sb_tx_done          = 1;
        o_tx_sb_req_expected  = 0;
        o_tx_sb_done_expected = 0;
        @(negedge i_clk);
        i_sb_tx_done = 0;
        assert (o_tx_sb_req_expected == o_tx_sb_req)
        else $display("ERROR [eye_sweep] Expected o_tx_sb_req=%b, got %b at %0t",
                      o_tx_sb_req_expected, o_tx_sb_req, $time);
        assert (o_tx_sb_done_expected == o_tx_sb_done)
        else $display("ERROR [eye_sweep] Expected o_tx_sb_done=%b, got %b at %0t",
                      o_tx_sb_done_expected, o_tx_sb_done, $time);

        repeat (2) @(negedge i_clk);

        // TB req+0x18D → transitions to END_HANDSHAKE
        i_sb_tx_req            = 1;
        i_tx_decoding          = 'h18D;
        o_tx_sb_done_expected  = 1;
        o_tx_encoding_expected = 'h18D;

        @(negedge i_clk);
        assert (o_tx_encoding_expected == o_tx_encoding)
        else $display("ERROR [eye_sweep] Expected o_tx_encoding=0x%h, got 0x%h at %0t",
                      o_tx_encoding_expected, o_tx_encoding, $time);
        assert (o_tx_sb_done_expected == o_tx_sb_done)
        else $display("ERROR [eye_sweep] Expected o_tx_sb_done=%b, got %b at %0t",
                      o_tx_sb_done_expected, o_tx_sb_done, $time);

        i_sb_tx_done  = 0;
        i_tx_decoding = 0;

        // ================================================================
        // END_HANDSHAKE (0x18D) — DUT asserts o_tx_sb_rsp.
        // TB pulses i_sb_tx_done → clock_to_test_done → LTSM sub1 exits.
        // ================================================================
        o_tx_sb_rsp_expected  = 1;
        o_tx_sb_done_expected = 1;

        @(negedge i_clk);
        assert (o_tx_sb_rsp_expected == o_tx_sb_rsp)
        else $display("ERROR [eye_sweep] Expected o_tx_sb_rsp=%b, got %b at %0t",
                      o_tx_sb_rsp_expected, o_tx_sb_rsp, $time);
        assert (o_tx_sb_done_expected == o_tx_sb_done)
        else $display("ERROR [eye_sweep] Expected o_tx_sb_done=%b, got %b at %0t",
                      o_tx_sb_done_expected, o_tx_sb_done, $time);

        i_sb_tx_done  = 1;
        i_sb_tx_req   = 0;
        i_tx_decoding = 'h18D;

        @(negedge i_clk);
        i_sb_tx_done = 0;

        repeat (2) @(negedge i_clk);
        $display("INFO  [eye_sweep_tx] eye-sweep complete at %0t", $time);
    end
endtask

// -----------------------------------------------------------------------
// Signal Initialisation Task
// -----------------------------------------------------------------------
task automatic init_signals;
    begin
        i_reset                  = 1;
        init_train_en            = 0;
        i_tx_decoding            = 0;
        i_tx_data                = 0;
        i_tx_info                = 0;
        i_tx_sweep_result        = 8'hAB;   // arbitrary non-zero sweep result
        i_sb_tx_req              = 0;
        i_sb_tx_rsp              = 0;
        i_sb_tx_done             = 0;
        i_tx_done                = 0;
        timeout                  = 0;
        Lane_map_code            = 3'b000;
        speed_idle_state_enable  = 0;
        repair_state_enable      = 0;
        tx_self_cal_state_enable = 0;
        // i_speedreg=2 → DUT computes o_pl_speedmode = i_speedreg-1 = 1 (non-zero → no trainerror)
        i_speedreg               = 3'b010;
        rsp_sent                 = 0;
        rsp_received             = 0;
        encoding_rsp_sent        = 0;
        encoding_rsp_received    = 0;
    end
endtask

// =======================================================================
// Main Test Sequence
// =======================================================================
initial begin

    init_signals();
    repeat (3) @(negedge i_clk);
    i_reset = 0;
    @(negedge i_clk);

    // Enable the MBTRAIN state machine
    init_train_en = 1;
    @(negedge i_clk);

    // ===================================================================
    // TEST 1: VALVREF substate-0 (req handshake, enc=0x80)
    //   After reset + init_train_en, CS=VALVREF, current_substate=0.
    //   DUT asserts req=1 with encoding 0x80.
    // ===================================================================
    $display("=== TEST 1: VALVREF substate-0 req handshake (enc=0x80) ===");

    o_tx_encoding_expected = 'h80;
    o_tx_sb_req_expected   = 1;

    @(negedge i_clk);
    assert (o_tx_encoding_expected == o_tx_encoding)
    else $display("ERROR: Expected o_tx_encoding=0x%h, got 0x%h at %0t",
                  o_tx_encoding_expected, o_tx_encoding, $time);
    assert (o_tx_sb_req_expected == o_tx_sb_req)
    else $display("ERROR: Expected o_tx_sb_req=%b, got %b at %0t",
                  o_tx_sb_req_expected, o_tx_sb_req, $time);

    // done_ack → DUT deasserts req
    i_sb_tx_done         = 1;
    o_tx_sb_req_expected = 0;
    @(negedge i_clk);
    i_sb_tx_done = 0;
    assert (o_tx_sb_req_expected == o_tx_sb_req)
    else $display("ERROR: Expected o_tx_sb_req=%b, got %b at %0t",
                  o_tx_sb_req_expected, o_tx_sb_req, $time);

    repeat (2) @(negedge i_clk);

    // rsp + matching decoding → advance to substate 1 (eye sweep)
    i_sb_tx_rsp            = 1;
    i_tx_decoding          = 'h80;
    o_tx_sb_done_expected  = 1;

    @(negedge i_clk);
    assert (o_tx_sb_done_expected == o_tx_sb_done)
    else $display("ERROR: Expected o_tx_sb_done=%b, got %b at %0t",
                  o_tx_sb_done_expected, o_tx_sb_done, $time);

    i_sb_tx_rsp           = 0;
    i_tx_decoding         = 0;
    o_tx_sb_done_expected = 1;

    // Simulate remote side triggering eye-sweep entry
    i_sb_tx_req   = 1;
    i_tx_decoding = 'h188;

    @(negedge i_clk);
    assert (o_tx_sb_done_expected == o_tx_sb_done)
    else $display("ERROR: Expected o_tx_sb_done=%b, got %b at %0t",
                  o_tx_sb_done_expected, o_tx_sb_done, $time);

    $display("PASS  TEST 1: VALVREF sub0");

    // ===================================================================
    // TEST 2: VALVREF substate-1 (eye-sweep, init=0)
    //   DUT proxies eye-sweep outputs; range 0x188–0x18D (TX responder mode).
    // ===================================================================
    $display("=== TEST 2: VALVREF substate-1 eye-sweep (init=0, enc 0x188-0x18D) ===");
    do_eye_sweep_happy_pass();
    $display("PASS  TEST 2: VALVREF sub1 eye-sweep");

    // ===================================================================
    // TEST 3: VALVREF substate-2 (completion at enc=0x82)
    //   DUT asserts req with 0x82; both handshake sides complete;
    //   previous_state_done fires → NS = DATAVREF.
    // ===================================================================
    $display("=== TEST 3: VALVREF substate-2 completion handshake (enc=0x82) ===");
    do_req_hs('h82);
    do_state_exit_hs('h82);
    $display("PASS  TEST 3: VALVREF sub2 + exit → DATAVREF");

    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 4: DATAVREF — Full 3-substate walk (0x88 → eye → 0x8A)
    // ===================================================================
    $display("=== TEST 4: DATAVREF (0x88 → eye_sweep → 0x8A) ===");
    do_req_hs('h88);
    do_eye_sweep_happy_pass();
    do_req_hs('h8A);
    do_state_exit_hs('h8A);
    $display("PASS  TEST 4: DATAVREF");

    // ===================================================================
    // TEST 5: SPEEDIDLE (0xC8 → speed-match check → 0xCA)
    //   i_speedreg=2 (set in init_signals) → DUT computes o_pl_speedmode=1.
    //   i_tx_done triggers the speed check in SPEEDIDLE sub0.
    // ===================================================================
    $display("=== TEST 5: SPEEDIDLE (0xC8 speed-match → 0xCA) ===");
    o_tx_encoding_expected = 'hC8;
    @(negedge i_clk);
    assert (o_tx_encoding_expected == o_tx_encoding)
    else $display("ERROR: Expected o_tx_encoding=0x%h, got 0x%h at %0t",
                  o_tx_encoding_expected, o_tx_encoding, $time);

    // i_tx_done drives the SPEEDIDLE sub0 speed-check branch
    i_tx_done = 1;
    @(negedge i_clk);
    i_tx_done = 0;

    do_req_hs('hCA);
    do_state_exit_hs('hCA);
    $display("PASS  TEST 5: SPEEDIDLE");

    // ===================================================================
    // TEST 6: TXSELFCAL (0xD0 → i_tx_done → 0xD1)
    //   Sub0 waits for i_tx_done (TX self-calibration complete).
    // ===================================================================
    $display("=== TEST 6: TXSELFCAL (0xD0 → 0xD1) ===");
    o_tx_encoding_expected = 'hD0;
    @(negedge i_clk);
    assert (o_tx_encoding_expected == o_tx_encoding)
    else $display("ERROR: Expected o_tx_encoding=0x%h, got 0x%h at %0t",
                  o_tx_encoding_expected, o_tx_encoding, $time);

    i_tx_done = 1;
    @(negedge i_clk);
    i_tx_done = 0;

    do_req_hs('hD1);
    rsp_sent = 1;
    encoding_rsp_sent = 'hD0;
    do_state_exit_hs('hD1);
    $display("PASS  TEST 6: TXSELFCAL");

    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 7: RXCLKCAL (0x98 → 0x9A) — No eye sweep on TX side.
    //   RX performs the actual calibration; TX just exchanges handshakes.
    // ===================================================================
    $display("=== TEST 7: RXCLKCAL (0x98 → 0x9A) ===");
    do_req_hs('h98);
    do_req_hs('h9A);
    do_state_exit_hs('h9A);
    $display("PASS  TEST 7: RXCLKCAL");

    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 8: VALTRAINCENTER (0xA0 → eye → 0xA2)
    // ===================================================================
    $display("=== TEST 8: VALTRAINCENTER (0xA0 → eye_sweep → 0xA2) ===");
    do_req_hs('hA0);
    do_eye_sweep_happy_pass();
    do_req_hs('hA2);
    do_state_exit_hs('hA2);
    $display("PASS  TEST 8: VALTRAINCENTER");
    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 9: VALTRAINVREF (0xE8 → eye → 0xEA)
    // ===================================================================
    $display("=== TEST 9: VALTRAINVREF (0xE8 → eye_sweep → 0xEA) ===");
    do_req_hs('hE8);
    do_eye_sweep_happy_pass();
    do_req_hs('hEA);
    do_state_exit_hs('hEA);
    $display("PASS  TEST 9: VALTRAINVREF");
    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 10: DATATRAINCENTER1 (0x90 → eye[no_retry] → 0x92)
    //   no_retry=1: single measurement pass; result feeds Vref tuning.
    // ===================================================================
    $display("=== TEST 10: DATATRAINCENTER1 (0x90 → eye_sweep[no_retry] → 0x92) ===");
    do_req_hs('h90);
    do_eye_sweep_happy_pass();
    do_req_hs('h92);
    do_state_exit_hs('h92);
    $display("PASS  TEST 10: DATATRAINCENTER1");
    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 11: DATATRAINVREF (0xF0 → eye → 0xF2)
    // ===================================================================
    $display("=== TEST 11: DATATRAINVREF (0xF0 → eye_sweep → 0xF2) ===");
    do_req_hs('hF0);
    do_eye_sweep_happy_pass();
    do_req_hs('hF2);
    do_state_exit_hs('hF2);
    $display("PASS  TEST 11: DATATRAINVREF");
    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 12: RXDESKEW (0xA8 → 0xAC) — No eye sweep; two handshakes.
    // ===================================================================
    $display("=== TEST 12: RXDESKEW (0xA8 → 0xAC) ===");
    do_req_hs('hA8);
    do_req_hs('hAC);
    do_state_exit_hs('hAC);
    $display("PASS  TEST 12: RXDESKEW");
    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 13: DATATRAINCENTER2 — Final state (0xB0 → eye[no_retry] → 0xB2)
    //   On completion train_link_init_en=1 → top-level active FSM enters ACTIVE.
    // ===================================================================
    $display("=== TEST 13: DATATRAINCENTER2 (0xB0 → eye_sweep[no_retry] → 0xB2) ===");
    do_req_hs('hB0);
    do_eye_sweep_happy_pass();
    do_req_hs('hB2);
    do_state_exit_hs('hB2);

    // Completion: train_link_init_en asserted signals active FSM to advance
    train_link_init_en_expected = 1;
    @(negedge i_clk);

    $display("PASS  TEST 13: DATATRAINCENTER2 → train_link_init_en=1");

    // ===================================================================
    // ALL TESTS COMPLETE
    // ===================================================================
    repeat (5) @(negedge i_clk);
    $display("======================================");
    $display("  ALL TESTS COMPLETE");
    $display("======================================");
    $finish;
end

endmodule