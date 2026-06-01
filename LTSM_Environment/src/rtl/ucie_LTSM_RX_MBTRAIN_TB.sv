// =============================================================================
// Module : ucie_LTSM_RX_MBTRAIN_TB
// Description: Testbench for the UCIe RX Link Training State Machine.
//              Mirrors the req/done/rsp handshake methodology from the TX TB,
//              adapted for the RX side where the DUT responds to incoming
//              requests driven by the testbench (simulating the remote TX).
//
// Handshake Protocol Recap (RX side — DUT is the RESPONDER):
//
//   Substate-0 (req-triggered rsp — VALVREF only):
//     1. TB asserts i_sb_rx_req=1 → DUT asserts o_rx_sb_rsp=1
//     2. TB asserts i_sb_rx_done=1 → done_ack → DUT clears rsp → sub1
//
//   Substate-0 (immediate rsp — most states):
//     1. DUT asserts o_rx_sb_rsp=1 immediately on state entry
//     2. TB asserts i_sb_rx_done=1 → DUT advances to sub1
//
//   Substate-2 (completion):
//     1. TB asserts i_tx_done=1 & i_rx_done=1 → DUT asserts o_rx_sb_rsp=1
//     2. TB asserts i_sb_rx_done=1 → substates_done → DUT clears rsp
//
//   State-level exit (req_received path — most states):
//     TB asserts i_sb_rx_req=1 with specific i_rx_decoding → req_received
//     latch captures it → CS advances next cycle
//
//   State-level exit (previous_state_done path — DATAVREF only):
//     TB drives rsp_sent=1 + rsp_received=1 with matching encoding
//     → previous_state_done fires → CS advances
//
// Eye-Sweep Sub-sequence (RX MBTRAIN uses init=1 — RX is the INITIATOR):
//   In ucie_RX_Data_to_Clock_eye_sweep with init=1, encodings are 0x188–0x18D:
//   REQ_HANDSHAKE    (0x188): DUT req; TB done_ack; TB req+0x189 → LFSR_HS
//   LFSR_HANDSHAKE   (0x189): DUT rsp immediately; TB done_ack; TB done → DATA
//   DATA_DETECTION   (0x18A): TB req+0x18B → RESULT_HANDSHAKE
//   RESULT_HANDSHAKE (0x18B): DUT rsp; TB done_ack; TB req+0x18C → SWEEP_HS
//   SWEEP_RESULT_HS  (0x18D): immediate NS=END_HANDSHAKE (no wait needed)
//   END_HANDSHAKE    (0x18D): DUT req; TB done_ack; TB rsp+0x18D → done
//
// State / Substate Map (happy path):
//   VALVREF         sub0(req→rsp→done) sub1(eye_sweep) sub2(txrx→rsp→done)
//                   → exit: req+0x88 → DATAVREF
//   DATAVREF        sub0(imm_rsp→done) sub1(eye_sweep) sub2(txrx→rsp→done)
//                   → exit: prev_state_done(0x8A) → SPEEDIDLE
//   SPEEDIDLE       sub0(req+0xCA) sub1(txrx→rsp→done)
//                   → exit: req+0xD0 → TXSELFCAL
//   TXSELFCAL       sub0(txrx→rsp→done)
//                   → exit: req+0x98 → RXCLKCAL
//   RXCLKCAL        sub0(imm_rsp→done) sub1(txrx→rsp→done)
//                   → exit: req+0xA0 → VALTRAINCENTER
//   VALTRAINCENTER  sub0(imm_rsp→done) sub1(eye_sweep) sub2(txrx→rsp→done)
//                   → exit: req+0xE8 → VALTRAINVREF
//   VALTRAINVREF    sub0(imm_rsp→done) sub1(eye_sweep) sub2(txrx→rsp→done)
//                   → exit: req+0x90 → DATATRAINCENTER1
//   DATATRAINCENTER1 sub0(imm_rsp→done) sub1(eye_sweep[no_retry]) sub2(txrx→rsp→done)
//                   → exit: req+0xF0 → DATATRAINVREF
//   DATATRAINVREF   sub0(imm_rsp→done) sub1(eye_sweep) sub2(txrx→rsp→done)
//                   → exit: req+0xA8 → RXDESKEW
//   RXDESKEW        sub0(imm_rsp→req+0xAC) sub1(txrx→rsp→done)
//                   → exit: req+0xB0 → DATATRAINCENTER2
//   DATATRAINCENTER2 sub0(imm_rsp→done) sub1(eye_sweep[no_retry]) sub2(txrx→rsp→done)
//                   → done: train_link_init_en=1
// =============================================================================

module ucie_LTSM_RX_MBTRAIN_TB ();

// -----------------------------------------------------------------------
// Parameters — match DUT defaults
// -----------------------------------------------------------------------
parameter DECODING_WIDTH  = 9;
parameter DATA_WIDTH      = 64;
parameter INFO_WIDTH      = 16;
parameter ERROR_THRESHOLD = 1;

// -----------------------------------------------------------------------
// DUT Signal Declarations
// -----------------------------------------------------------------------
logic                       i_clk;
logic                       i_reset;

// RX interface inputs (from remote TX, driven by TB)
logic [DECODING_WIDTH-1:0]  i_rx_decoding;
logic [DATA_WIDTH-1:0]      i_rx_data;
logic [INFO_WIDTH-1:0]      i_rx_info;
logic [DATA_WIDTH-1:0]      i_rx_data_results;   // Per-lane eye-sweep pattern results
logic                       i_rx_valid_results;  // Valid strobe for i_rx_data_results
logic [2:0]                 Lane_map_code;       // Lane repair map; 0 for happy-path

// Sideband inputs (driven by TB, simulating remote TX sideband)
logic i_sb_rx_req;
logic i_sb_rx_rsp;
logic i_sb_rx_done;
logic i_rx_done;
logic i_tx_done;
logic i_tx_error;    // TX error flag; 0 for happy-path

// Training control inputs — tie unused enables to 0
logic       init_train_en;
logic       speed_idle_state_enable;    // Normally from active FSM; 0 here
logic       tx_self_cal_state_enable;   // Normally from active FSM; 0 here
logic       timeout;

// o_pl_speedmode is an INPUT on the RX MBTRAIN (unlike TX where it is an output).
// The TB drives it to non-zero so SPEEDIDLE does not generate a trainerror.
logic [2:0] o_pl_speedmode;

// RSP handshake tracking inputs — mirror the top-level RSP tracker in ucie_LTSM
logic [DECODING_WIDTH-1:0] encoding_rsp_sent;
logic [DECODING_WIDTH-1:0] encoding_rsp_received;
logic                      rsp_received;
logic                      rsp_sent;

// RX interface outputs (from DUT — observe only)
logic [DECODING_WIDTH-1:0] o_rx_encoding;
logic [DATA_WIDTH-1:0]     o_rx_data;
logic [INFO_WIDTH-1:0]     o_rx_info;

// Sideband outputs (from DUT)
logic o_rx_sb_req;
logic o_rx_sb_rsp;
logic o_rx_sb_done;

// Status outputs (from DUT)
logic train_error;
logic train_link_init_en;   // MBTRAIN done → handoff to active FSM
logic train_phyretrain_en;  // Retrain path requested

// -----------------------------------------------------------------------
// Expected-value mirrors (for assertion messages)
// -----------------------------------------------------------------------
logic [DECODING_WIDTH-1:0] o_rx_encoding_expected;
logic                      o_rx_sb_req_expected;
logic                      o_rx_sb_rsp_expected;
logic                      o_rx_sb_done_expected;
logic                      train_link_init_en_expected;

// -----------------------------------------------------------------------
// DUT Instantiation — all ports connected; no floating inputs
// -----------------------------------------------------------------------
ucie_LTSM_RX_MBTRAIN #(
    .DECODING_WIDTH  (DECODING_WIDTH),
    .DATA_WIDTH      (DATA_WIDTH),
    .INFO_WIDTH      (INFO_WIDTH),
    .ERROR_THRESHOLD (ERROR_THRESHOLD)
) DUT (
    .i_clk                 (i_clk),
    .i_reset               (i_reset),
    .i_rx_decoding         (i_rx_decoding),
    .i_rx_data             (i_rx_data),
    .i_rx_info             (i_rx_info),
    .i_rx_data_results     (i_rx_data_results),
    .i_rx_valid_results    (i_rx_valid_results),
    .Lane_map_code         (Lane_map_code),
    .i_sb_rx_req           (i_sb_rx_req),
    .i_sb_rx_rsp           (i_sb_rx_rsp),
    .i_sb_rx_done          (i_sb_rx_done),
    .i_rx_done             (i_rx_done),
    .i_tx_done             (i_tx_done),
    .i_tx_error            (i_tx_error),
    .init_train_en         (init_train_en),
    .speed_idle_state_enable (speed_idle_state_enable),
    .tx_self_cal_state_enable(tx_self_cal_state_enable),
    .timeout               (timeout),
    .o_pl_speedmode        (o_pl_speedmode),
    .encoding_rsp_sent     (encoding_rsp_sent),
    .encoding_rsp_received (encoding_rsp_received),
    .rsp_received          (rsp_received),
    .rsp_sent              (rsp_sent),
    .o_rx_encoding         (o_rx_encoding),
    .o_rx_data             (o_rx_data),
    .o_rx_info             (o_rx_info),
    .o_rx_sb_req           (o_rx_sb_req),
    .o_rx_sb_rsp           (o_rx_sb_rsp),
    .o_rx_sb_done          (o_rx_sb_done),
    .train_error           (train_error),
    .train_link_init_en    (train_link_init_en),
    .train_phyretrain_en   (train_phyretrain_en)
);

// -----------------------------------------------------------------------
// Clock Generation — 100 MHz (10 ns period)
// -----------------------------------------------------------------------
initial begin
    i_clk = 0;
    forever #5 i_clk = ~i_clk;
end

// -----------------------------------------------------------------------
// Force eye-sweep result bus to all-1s (every lane passes).
// Without this, failed_test may be X → indeterminate retry behavior
// in states with no_retry=0.
// NOTE: force width must match i_rx_data_results (DATA_WIDTH bits).
// -----------------------------------------------------------------------
initial begin
    force DUT.i_rx_data_results = {DATA_WIDTH{1'b1}};
end

// =======================================================================
// Helper Tasks
// =======================================================================

// --- do_rsp_hs -----------------------------------------------------------
// For VALVREF sub0 style: DUT waits for an incoming req before asserting rsp.
//   1. TB asserts i_sb_rx_req with encoding enc → DUT asserts o_rx_sb_rsp
//   2. TB asserts i_sb_rx_done → done_ack → DUT clears rsp → advances
// -------------------------------------------------------------------------
task do_rsp_hs (input [DECODING_WIDTH-1:0] enc);
    begin
        i_sb_rx_req            = 1;
        i_rx_decoding          = enc;
        o_rx_encoding_expected = enc;
        o_rx_sb_rsp_expected   = 1;

        @(negedge i_clk);
        assert (o_rx_encoding_expected == o_rx_encoding)
        else $display("ERROR [do_rsp_hs] Expected o_rx_encoding=0x%h, got 0x%h at %0t",
                      o_rx_encoding_expected, o_rx_encoding, $time);
        assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
        else $display("ERROR [do_rsp_hs] Expected o_rx_sb_rsp=%b, got %b at %0t",
                      o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

        // done_ack → DUT clears rsp and advances to next substate
        i_sb_rx_done         = 1;
        o_rx_sb_rsp_expected = 0;

        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_sb_rx_done  = 0;
        i_rx_decoding = 0;

        assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
        else $display("ERROR [do_rsp_hs] Expected o_rx_sb_rsp=%b, got %b at %0t",
                      o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

        repeat (2) @(negedge i_clk);
    end
endtask

// --- do_imm_rsp_done_hs --------------------------------------------------
// For sub0 states that assert rsp immediately on entry (no req trigger needed).
// Used by: DATAVREF, RXCLKCAL, VALTRAINCENTER, VALTRAINVREF,
//          DATATRAINCENTER1, DATATRAINCENTER2 sub0.
//   1. Verify DUT has o_rx_sb_rsp=1 with encoding enc
//   2. TB asserts i_sb_rx_done → DUT advances to sub1
// -------------------------------------------------------------------------
task do_imm_rsp_done_hs (input [DECODING_WIDTH-1:0] enc);
    begin
        o_rx_encoding_expected = enc;
        o_rx_sb_rsp_expected   = 1;

        @(negedge i_clk);
        assert (o_rx_encoding_expected == o_rx_encoding)
        else $display("ERROR [do_imm_rsp_done_hs] Expected o_rx_encoding=0x%h, got 0x%h at %0t",
                      o_rx_encoding_expected, o_rx_encoding, $time);
        assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
        else $display("ERROR [do_imm_rsp_done_hs] Expected o_rx_sb_rsp=%b, got %b at %0t",
                      o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

        i_sb_rx_done = 1;
        @(negedge i_clk);
        i_sb_rx_done = 0;

        repeat (2) @(negedge i_clk);
    end
endtask

// --- do_txrx_done_hs -----------------------------------------------------
// For sub2 (post-eye-sweep completion handshake):
//   1. TB asserts i_tx_done=1 & i_rx_done=1 → DUT asserts o_rx_sb_rsp=1
//   2. TB asserts i_sb_rx_done=1 → done_ack → DUT clears rsp → substates_done
// -------------------------------------------------------------------------
task do_txrx_done_hs (input [DECODING_WIDTH-1:0] enc);
    begin
        i_tx_done = 1;
        i_rx_done = 1;
        o_rx_encoding_expected = enc;
        o_rx_sb_rsp_expected   = 1;

        @(negedge i_clk);
        i_tx_done = 0;
        i_rx_done = 0;

        assert (o_rx_encoding_expected == o_rx_encoding)
        else $display("ERROR [do_txrx_done_hs] Expected o_rx_encoding=0x%h, got 0x%h at %0t",
                      o_rx_encoding_expected, o_rx_encoding, $time);
        assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
        else $display("ERROR [do_txrx_done_hs] Expected o_rx_sb_rsp=%b, got %b at %0t",
                      o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

        // done_ack → substates_done asserted
        i_sb_rx_done         = 1;
        o_rx_sb_rsp_expected = 0;

        @(negedge i_clk);
        i_sb_rx_done = 0;
        assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
        else $display("ERROR [do_txrx_done_hs] Expected o_rx_sb_rsp=%b, got %b at %0t",
                      o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

        repeat (2) @(negedge i_clk);
    end
endtask

// --- do_state_exit_req ---------------------------------------------------
// Trigger CS advance for states that use req_received (most states).
// TB asserts i_sb_rx_req + enc so encoding_req_received is latched;
// the FSM evaluates req_received on the next combinational pass.
// -------------------------------------------------------------------------
task do_state_exit_req (input [DECODING_WIDTH-1:0] enc);
    begin
        i_sb_rx_req   = 1;
        i_rx_decoding = enc;

        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = 0;

        $display("INFO  [do_state_exit_req] enc=0x%h at %0t", enc, $time);
        repeat (2) @(negedge i_clk);
    end
endtask

// --- do_state_exit_rsp ---------------------------------------------------
// Trigger CS advance for states that use previous_state_done (DATAVREF).
// TB drives rsp_sent=1 & rsp_received=1 with matching encoding so
// previous_state_done (= rsp_sent & rsp_received) fires inside the DUT.
// -------------------------------------------------------------------------
task do_state_exit_rsp (input [DECODING_WIDTH-1:0] enc);
    begin
        rsp_sent              = 1;
        encoding_rsp_sent     = enc;
        rsp_received          = 1;
        encoding_rsp_received = enc;

        @(negedge i_clk);
        rsp_sent              = 0;
        rsp_received          = 0;

        $display("INFO  [do_state_exit_rsp] enc=0x%h at %0t", enc, $time);
        repeat (2) @(negedge i_clk);
    end
endtask

// --- do_eye_sweep_happy_pass_rx ------------------------------------------
// Drive the embedded ucie_RX_Data_to_Clock_eye_sweep through a full
// successful sweep in init=1 mode (RX is the INITIATOR).
//
// Encodings are in the 0x188–0x18D range (init=1 / RX initiator):
//
//   REQ_HANDSHAKE    (0x188): DUT asserts o_rx_sb_req.
//                             TB done_ack; TB req+0x189 → LFSR_HANDSHAKE.
//
//   LFSR_HANDSHAKE   (0x189): DUT asserts o_rx_sb_rsp immediately.
//                             TB done_ack clears rsp.
//                             TB i_sb_rx_done → DATA_DETECTION.
//
//   DATA_DETECTION   (0x18A): TB req+0x18B → RESULT_HANDSHAKE.
//
//   RESULT_HANDSHAKE (0x18B): DUT asserts o_rx_sb_rsp immediately.
//                             TB done_ack clears rsp.
//                             TB req+0x18C → SWEEP_RESULT_HANDSHAKE.
//
//   SWEEP_RESULT_HS  (0x18D): Immediate NS=END_HANDSHAKE (no wait signal).
//                             DUT latches i_rx_data[7:0] as sweep result.
//
//   END_HANDSHAKE    (0x18D): DUT asserts o_rx_sb_req.
//                             TB done_ack; TB rsp+0x18D → done=1 → sub1 exits.
// -------------------------------------------------------------------------
task do_eye_sweep_happy_pass_rx ();
    begin
        $display("INFO  [eye_sweep_rx] starting at %0t", $time);

        // ================================================================
        // REQ_HANDSHAKE (0x188) — RX initiates; DUT asserts o_rx_sb_req
        // TB done_ack clears req; TB req+0x189 triggers REQ→LFSR transition
        // ================================================================
        o_rx_encoding_expected = 'h188;
        o_rx_sb_req_expected   = 1;

        @(negedge i_clk);
        assert (o_rx_encoding_expected == o_rx_encoding)
        else $display("ERROR [eye_sweep_rx] Expected o_rx_encoding=0x%h, got 0x%h at %0t",
                      o_rx_encoding_expected, o_rx_encoding, $time);
        assert (o_rx_sb_req_expected == o_rx_sb_req)
        else $display("ERROR [eye_sweep_rx] Expected o_rx_sb_req=%b, got %b at %0t",
                      o_rx_sb_req_expected, o_rx_sb_req, $time);

        // done_ack → DUT clears req
        i_sb_rx_done         = 1;
        o_rx_sb_req_expected = 0;

        @(negedge i_clk);
        i_sb_rx_done = 0;
        assert (o_rx_sb_req_expected == o_rx_sb_req)
        else $display("ERROR [eye_sweep_rx] Expected o_rx_sb_req=%b, got %b at %0t",
                      o_rx_sb_req_expected, o_rx_sb_req, $time);

        repeat (2) @(negedge i_clk);

        // TB req+0x189 → REQ→LFSR_HANDSHAKE transition
        i_sb_rx_req            = 1;
        i_rx_decoding          = 'h189;
        o_rx_encoding_expected = 'h189;

        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = 0;
        assert (o_rx_encoding_expected == o_rx_encoding)
        else $display("ERROR [eye_sweep_rx] Expected o_rx_encoding=0x%h, got 0x%h at %0t",
                      o_rx_encoding_expected, o_rx_encoding, $time);

        // ================================================================
        // LFSR_HANDSHAKE (0x189) — DUT asserts rsp immediately (init=1 mode).
        // TB done_ack clears rsp; TB i_sb_rx_done → LFSR→DATA_DETECTION.
        // ================================================================
        o_rx_sb_rsp_expected = 1;   // already asserted, no req needed

        @(negedge i_clk);
        assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
        else $display("ERROR [eye_sweep_rx] Expected o_rx_sb_rsp=%b, got %b at %0t",
                      o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

        // done_ack → DUT clears rsp
        i_sb_rx_done         = 1;
        o_rx_sb_rsp_expected = 0;

        @(negedge i_clk);
        i_sb_rx_done = 0;
        assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
        else $display("ERROR [eye_sweep_rx] Expected o_rx_sb_rsp=%b, got %b at %0t",
                      o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

        // i_sb_rx_done → LFSR→DATA_DETECTION
        repeat (2) @(negedge i_clk);
        i_sb_rx_done = 1;
        @(negedge i_clk);
        i_sb_rx_done = 0;

        // ================================================================
        // DATA_DETECTION (0x18A) — DUT holds 0x18A encoding.
        // TB req+0x18B → DATA→RESULT_HANDSHAKE transition.
        // ================================================================
        o_rx_encoding_expected = 'h18A;

        @(negedge i_clk);
        assert (o_rx_encoding_expected == o_rx_encoding)
        else $display("ERROR [eye_sweep_rx] Expected o_rx_encoding=0x%h, got 0x%h at %0t",
                      o_rx_encoding_expected, o_rx_encoding, $time);

        i_sb_rx_req            = 1;
        i_rx_decoding          = 'h18B;
        o_rx_encoding_expected = 'h18B;

        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = 0;
        assert (o_rx_encoding_expected == o_rx_encoding)
        else $display("ERROR [eye_sweep_rx] Expected o_rx_encoding=0x%h, got 0x%h at %0t",
                      o_rx_encoding_expected, o_rx_encoding, $time);

        // ================================================================
        // RESULT_HANDSHAKE (0x18B) — DUT asserts rsp immediately.
        // TB done_ack clears rsp; TB req+0x18C → RESULT→SWEEP_RESULT.
        // ================================================================
        o_rx_sb_rsp_expected = 1;

        @(negedge i_clk);
        assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
        else $display("ERROR [eye_sweep_rx] Expected o_rx_sb_rsp=%b, got %b at %0t",
                      o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

        // done_ack
        i_sb_rx_done         = 1;
        o_rx_sb_rsp_expected = 0;

        @(negedge i_clk);
        i_sb_rx_done = 0;
        assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
        else $display("ERROR [eye_sweep_rx] Expected o_rx_sb_rsp=%b, got %b at %0t",
                      o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

        // TB req+0x18C → RESULT→SWEEP_RESULT_HANDSHAKE
        repeat (2) @(negedge i_clk);
        i_sb_rx_req            = 1;
        i_rx_decoding          = 'h18C;

        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = 0;

        // ================================================================
        // SWEEP_RESULT_HANDSHAKE (0x18D) — immediate NS=END_HANDSHAKE.
        // DUT latches i_rx_data[7:0] as sweep result.
        // No wait signal required; END_HANDSHAKE starts next cycle.
        // ================================================================
        o_rx_encoding_expected = 'h18D;   // SWEEP_RESULT state outputs 0x18D

        @(negedge i_clk);
        assert (o_rx_encoding_expected == o_rx_encoding)
        else $display("ERROR [eye_sweep_rx] Expected o_rx_encoding=0x%h, got 0x%h at %0t",
                      o_rx_encoding_expected, o_rx_encoding, $time);

        // ================================================================
        // END_HANDSHAKE (0x18D) — DUT asserts o_rx_sb_req.
        // TB done_ack clears req; TB rsp+0x18D → done=1 → sub1 exits.
        // ================================================================
        o_rx_sb_req_expected = 1;

        @(negedge i_clk);
        assert (o_rx_sb_req_expected == o_rx_sb_req)
        else $display("ERROR [eye_sweep_rx] Expected o_rx_sb_req=%b, got %b at %0t",
                      o_rx_sb_req_expected, o_rx_sb_req, $time);

        // done_ack → DUT clears req
        i_sb_rx_done         = 1;
        o_rx_sb_req_expected = 0;

        @(negedge i_clk);
        i_sb_rx_done = 0;
        assert (o_rx_sb_req_expected == o_rx_sb_req)
        else $display("ERROR [eye_sweep_rx] Expected o_rx_sb_req=%b, got %b at %0t",
                      o_rx_sb_req_expected, o_rx_sb_req, $time);

        repeat (2) @(negedge i_clk);

        // TB rsp+0x18D → done=1 → clock_to_test_done → LTSM sub1 exits
        i_sb_rx_rsp   = 1;
        i_rx_decoding = 'h18D;

        @(negedge i_clk);
        i_sb_rx_rsp   = 0;
        i_rx_decoding = 0;

        repeat (3) @(negedge i_clk);
        $display("INFO  [eye_sweep_rx] complete at %0t", $time);
    end
endtask

// -----------------------------------------------------------------------
// Signal Initialisation Task
// -----------------------------------------------------------------------
task automatic init_signals;
    begin
        i_reset               = 1;
        init_train_en         = 0;
        i_rx_decoding         = 0;
        i_rx_data             = 0;
        i_rx_info             = 0;
        i_rx_data_results     = {DATA_WIDTH{1'b1}};  // all lanes pass by default
        i_rx_valid_results    = 1;
        i_sb_rx_req           = 0;
        i_sb_rx_rsp           = 0;
        i_sb_rx_done          = 0;
        i_rx_done             = 0;
        i_tx_done             = 0;
        i_tx_error            = 0;   // no TX error on happy path
        timeout               = 0;
        Lane_map_code         = 3'b000;
        speed_idle_state_enable  = 0;
        tx_self_cal_state_enable = 0;
        o_pl_speedmode        = 3'b001;   // non-zero → no trainerror in SPEEDIDLE
        rsp_sent              = 0;
        rsp_received          = 0;
        encoding_rsp_sent     = 0;
        encoding_rsp_received = 0;
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

    init_train_en = 1;
    @(negedge i_clk);

    // ===================================================================
    // TEST 1: VALVREF substate-0 (req-triggered rsp, enc=0x80)
    //   After reset + init_train_en, CS=VALVREF, current_substate=0.
    //   DUT waits at enc=0x80 for i_sb_rx_req before asserting rsp.
    // ===================================================================
    $display("=== TEST 1: VALVREF substate-0 rsp handshake (enc=0x80) ===");

    o_rx_encoding_expected = 'h80;
    @(negedge i_clk);
    assert (o_rx_encoding_expected == o_rx_encoding)
    else $display("ERROR: Expected o_rx_encoding=0x%h, got 0x%h at %0t",
                  o_rx_encoding_expected, o_rx_encoding, $time);

    // TB req → DUT asserts rsp
    i_sb_rx_req          = 1;
    o_rx_sb_rsp_expected = 1;

    @(negedge i_clk);
    assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
    else $display("ERROR: Expected o_rx_sb_rsp=%b, got %b at %0t",
                  o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

    // TB done → done_ack → DUT clears rsp → advances to sub1 (eye sweep)
    i_sb_rx_done         = 1;
    o_rx_sb_rsp_expected = 0;

    @(negedge i_clk);
    i_sb_rx_req  = 0;
    i_sb_rx_done = 0;
    assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
    else $display("ERROR: Expected o_rx_sb_rsp=%b, got %b at %0t",
                  o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

    $display("PASS  TEST 1: VALVREF sub0");

    // ===================================================================
    // TEST 2: VALVREF substate-1 (eye-sweep, init=1, enc range 0x188–0x18D)
    // ===================================================================
    $display("=== TEST 2: VALVREF substate-1 eye-sweep (init=1) ===");
    do_eye_sweep_happy_pass_rx();
    $display("PASS  TEST 2: VALVREF sub1 eye-sweep");

    // ===================================================================
    // TEST 3: VALVREF substate-2 (completion at enc=0x82)
    //   Sub2 starts when clock_to_test_done AND TB req+0x82 arrive.
    //   Then tx_done+rx_done → rsp → done → substates_done.
    //   State exit: req_received with 0x88 → NS=DATAVREF.
    // ===================================================================
    $display("=== TEST 3: VALVREF substate-2 (enc=0x82) + exit ===");

    // Trigger sub2 entry by sending req with decoding 0x82
    i_sb_rx_req   = 1;
    i_rx_decoding = 'h82;
    @(negedge i_clk);
    i_sb_rx_req   = 0;
    i_rx_decoding = 0;

    repeat (2) @(negedge i_clk);

    do_txrx_done_hs('h82);

    // State exit: req+0x88 → req_received → NS=DATAVREF
    do_state_exit_req('h88);

    $display("PASS  TEST 3: VALVREF sub2 + exit → DATAVREF");

    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 4: DATAVREF — Full 3-substate walk (0x88 → eye → 0x8A)
    //   Sub0: DUT immediately asserts rsp (no req needed); TB done → sub1.
    //   Sub1: eye-sweep (init=1).
    //   Sub2: tx_done+rx_done → rsp → done.
    //   Exit: previous_state_done with enc=0x8A → NS=SPEEDIDLE.
    // ===================================================================
    $display("=== TEST 4: DATAVREF (0x88 → eye_sweep → 0x8A) ===");

    do_imm_rsp_done_hs('h88);
    do_eye_sweep_happy_pass_rx();

    // Trigger sub2 entry: clock_to_test_done && req+0x8A
    i_sb_rx_req   = 1;
    i_rx_decoding = 'h8A;
    @(negedge i_clk);
    i_sb_rx_req   = 0;
    i_rx_decoding = 0;
    repeat (2) @(negedge i_clk);

    do_txrx_done_hs('h8A);

    // Exit via previous_state_done (DATAVREF uses this path, not req_received)
    do_state_exit_rsp('h8A);

    $display("PASS  TEST 4: DATAVREF");

    // ===================================================================
    // TEST 5: SPEEDIDLE (0xC8 → 0xCA)
    //   Sub0: DUT holds enc=0xC8 and waits for req+0xCA (speed-match signal).
    //         o_pl_speedmode=1 (set in init_signals) → no trainerror.
    //   Sub1: enc=0xCA; tx_done+rx_done → rsp → done.
    //   Exit: req+0xD0 → TXSELFCAL.
    // ===================================================================
    $display("=== TEST 5: SPEEDIDLE (0xC8 → 0xCA → exit 0xD0) ===");

    o_rx_encoding_expected = 'hC8;
    @(negedge i_clk);
    assert (o_rx_encoding_expected == o_rx_encoding)
    else $display("ERROR: Expected o_rx_encoding=0x%h, got 0x%h at %0t",
                  o_rx_encoding_expected, o_rx_encoding, $time);

    // TB req+0xCA → speed-match confirmed; sub0→sub1
    i_sb_rx_req   = 1;
    i_rx_decoding = 'hCA;
    @(negedge i_clk);
    i_sb_rx_req   = 0;
    i_rx_decoding = 0;
    repeat (2) @(negedge i_clk);

    do_txrx_done_hs('hCA);
    do_state_exit_req('hD0);

    $display("PASS  TEST 5: SPEEDIDLE");

    // ===================================================================
    // TEST 6: TXSELFCAL (0xD0 → single substate)
    //   Sub0: enc=0xD0; tx_done+rx_done → rsp → done → substates_done.
    //   Exit: req+0x98 → RXCLKCAL.
    // ===================================================================
    $display("=== TEST 6: TXSELFCAL (0xD0 → done) ===");

    o_rx_encoding_expected = 'hD0;
    @(negedge i_clk);
    assert (o_rx_encoding_expected == o_rx_encoding)
    else $display("ERROR: Expected o_rx_encoding=0x%h, got 0x%h at %0t",
                  o_rx_encoding_expected, o_rx_encoding, $time);

    do_txrx_done_hs('hD0);
    do_state_exit_req('h98);

    $display("PASS  TEST 6: TXSELFCAL");

    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 7: RXCLKCAL (0x98 → 0x9A)
    //   Sub0: imm rsp → done → sub1.
    //   Sub1: enc=0x9A; tx_done+rx_done → rsp → done.
    //   Exit: req+0xA0 → VALTRAINCENTER.
    // ===================================================================
    $display("=== TEST 7: RXCLKCAL (0x98 → 0x9A) ===");

    do_imm_rsp_done_hs('h98);

    // Trigger sub1 entry: req+0x9A
    i_sb_rx_req   = 1;
    i_rx_decoding = 'h9A;
    @(negedge i_clk);
    i_sb_rx_req   = 0;
    i_rx_decoding = 0;
    repeat (2) @(negedge i_clk);

    do_txrx_done_hs('h9A);
    do_state_exit_req('hA0);

    $display("PASS  TEST 7: RXCLKCAL");

    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 8: VALTRAINCENTER (0xA0 → eye → 0xA2)
    // ===================================================================
    $display("=== TEST 8: VALTRAINCENTER (0xA0 → eye_sweep → 0xA2) ===");

    do_imm_rsp_done_hs('hA0);
    do_eye_sweep_happy_pass_rx();

    i_sb_rx_req   = 1;
    i_rx_decoding = 'hA2;
    @(negedge i_clk);
    i_sb_rx_req   = 0;
    i_rx_decoding = 0;
    repeat (2) @(negedge i_clk);

    do_txrx_done_hs('hA2);
    do_state_exit_req('hE8);

    $display("PASS  TEST 8: VALTRAINCENTER");
    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 9: VALTRAINVREF (0xE8 → eye → 0xEA)
    // ===================================================================
    $display("=== TEST 9: VALTRAINVREF (0xE8 → eye_sweep → 0xEA) ===");

    do_imm_rsp_done_hs('hE8);
    do_eye_sweep_happy_pass_rx();

    i_sb_rx_req   = 1;
    i_rx_decoding = 'hEA;
    @(negedge i_clk);
    i_sb_rx_req   = 0;
    i_rx_decoding = 0;
    repeat (2) @(negedge i_clk);

    do_txrx_done_hs('hEA);
    do_state_exit_req('h90);

    $display("PASS  TEST 9: VALTRAINVREF");
    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 10: DATATRAINCENTER1 (0x90 → eye[no_retry] → 0x92)
    //   no_retry=1: single measurement pass; result feeds Vref tuning.
    // ===================================================================
    $display("=== TEST 10: DATATRAINCENTER1 (0x90 → eye[no_retry] → 0x92) ===");

    do_imm_rsp_done_hs('h90);
    do_eye_sweep_happy_pass_rx();

    i_sb_rx_req   = 1;
    i_rx_decoding = 'h92;
    @(negedge i_clk);
    i_sb_rx_req   = 0;
    i_rx_decoding = 0;
    repeat (2) @(negedge i_clk);

    do_txrx_done_hs('h92);
    do_state_exit_req('hF0);

    $display("PASS  TEST 10: DATATRAINCENTER1");
    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 11: DATATRAINVREF (0xF0 → eye → 0xF2)
    //   Sub0 advances via i_sb_rx_done with i_rx_decoding=0xF0.
    // ===================================================================
    $display("=== TEST 11: DATATRAINVREF (0xF0 → eye_sweep → 0xF2) ===");

    o_rx_encoding_expected = 'hF0;
    o_rx_sb_rsp_expected   = 1;
    @(negedge i_clk);
    assert (o_rx_encoding_expected == o_rx_encoding)
    else $display("ERROR: Expected o_rx_encoding=0x%h, got 0x%h at %0t",
                  o_rx_encoding_expected, o_rx_encoding, $time);
    assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
    else $display("ERROR: Expected o_rx_sb_rsp=%b, got %b at %0t",
                  o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

    // Advance sub0→sub1: done with matching decoding 0xF0
    i_sb_rx_done  = 1;
    i_rx_decoding = 'hF0;
    @(negedge i_clk);
    i_sb_rx_done  = 0;
    i_rx_decoding = 0;
    repeat (2) @(negedge i_clk);

    do_eye_sweep_happy_pass_rx();

    i_sb_rx_req   = 1;
    i_rx_decoding = 'hF2;
    @(negedge i_clk);
    i_sb_rx_req   = 0;
    i_rx_decoding = 0;
    repeat (2) @(negedge i_clk);

    do_txrx_done_hs('hF2);
    do_state_exit_req('hA8);

    $display("PASS  TEST 11: DATATRAINVREF");
    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 12: RXDESKEW (0xA8 → 0xAC) — No eye sweep.
    //   Sub0: DUT immediately asserts rsp at 0xA8; advances via req+0xAC.
    //   Sub1: enc=0xAC; tx_done+rx_done → rsp → done.
    //   Exit: req+0xB0 → DATATRAINCENTER2.
    // ===================================================================
    $display("=== TEST 12: RXDESKEW (0xA8 → 0xAC) ===");

    o_rx_encoding_expected = 'hA8;
    o_rx_sb_rsp_expected   = 1;
    @(negedge i_clk);
    assert (o_rx_encoding_expected == o_rx_encoding)
    else $display("ERROR: Expected o_rx_encoding=0x%h, got 0x%h at %0t",
                  o_rx_encoding_expected, o_rx_encoding, $time);
    assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
    else $display("ERROR: Expected o_rx_sb_rsp=%b, got %b at %0t",
                  o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

    // Advance sub0→sub1: req+0xAC
    i_sb_rx_req   = 1;
    i_rx_decoding = 'hAC;
    @(negedge i_clk);
    i_sb_rx_req   = 0;
    i_rx_decoding = 0;
    repeat (2) @(negedge i_clk);

    do_txrx_done_hs('hAC);
    do_state_exit_req('hB0);

    $display("PASS  TEST 12: RXDESKEW");
    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 13: DATATRAINCENTER2 — Final state (0xB0 → eye[no_retry] → 0xB2)
    //   On completion: train_link_init_en=1 → top-level active FSM advances.
    // ===================================================================
    $display("=== TEST 13: DATATRAINCENTER2 (0xB0 → eye[no_retry] → 0xB2) ===");

    do_imm_rsp_done_hs('hB0);
    do_eye_sweep_happy_pass_rx();

    i_sb_rx_req   = 1;
    i_rx_decoding = 'hB2;
    @(negedge i_clk);
    i_sb_rx_req   = 0;
    i_rx_decoding = 0;
    repeat (2) @(negedge i_clk);

    // Sub2: tx_done+rx_done → rsp; same i_sb_rx_done also sets train_link_init_en_reg
    do_txrx_done_hs('hB2);

    // Completion: train_link_init_en asserted → active FSM can enter ACTIVE
    train_link_init_en_expected = 1;
    repeat (3) @(negedge i_clk);
    assert (train_link_init_en_expected == train_link_init_en)
    else $display("ERROR: Expected train_link_init_en=%b, got %b at %0t",
                  train_link_init_en_expected, train_link_init_en, $time);

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