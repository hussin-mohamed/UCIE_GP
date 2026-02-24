// =============================================================================
// Module : ucie_LTSM_RX_MBTRAIN_TB
// Description: Testbench for the UCIe RX Link Training State Machine.
//              Mirrors the req/done/rsp handshake methodology from the TX TB,
//              adapted for the RX side where the DUT responds to incoming
//              requests driven by the testbench (simulating the remote TX).
//
// Handshake Protocol Recap (RX side, inverse of TX TB):
//   The RX DUT is the RESPONDER — it asserts o_rx_sb_rsp in reply to the
//   TB's i_sb_rx_req.  The TB drives done/req signals; the DUT drives rsp.
//
//   Substate-0 (req-triggered rsp variant — VALVREF):
//     1. TB asserts i_sb_rx_req=1  → DUT asserts o_rx_sb_rsp=1
//     2. TB asserts i_sb_rx_done=1 → done_ack → DUT deasserts rsp → sub1
//
//   Substate-0 (immediate-rsp variant — most other states):
//     1. DUT asserts o_rx_sb_rsp=1 immediately on state entry
//     2. TB asserts i_sb_rx_done=1 (or i_sb_rx_req with specific decoding)
//        → DUT advances to sub1
//
//   Substate-2 (completion):
//     1. TB asserts i_tx_done=1 && i_rx_done=1 → DUT asserts o_rx_sb_rsp=1
//     2. TB asserts i_sb_rx_done=1 → substates_done → DUT deasserts rsp
//
//   State-level exit (req_received path):
//     TB asserts i_sb_rx_req=1 with specific i_rx_decoding → req_received
//     captured inside DUT → CS advances
//
//   State-level exit (previous_state_done path — DATAVREF only):
//     TB drives rsp_sent=1 + rsp_received=1 with matching encoding
//     → previous_state_done fires → CS advances
//
// Eye-Sweep Sub-sequence (init=1 mode — RX always initiates):
//   REQ_HANDSHAKE      (0x185): DUT req → TB done_ack → TB rsp+0x185
//   LFSR_HANDSHAKE     (0x186): TB req+0x186 → DUT rsp → TB done+0x186
//   DATA_DETECTION     (0x187): TB asserts i_rx_done
//   RESULT_HS          (0x188): TB req+0x188 → DUT rsp → TB done+0x188 (pass)
//   SWEEP_RESULT_HS    (0x189): TB done+0x189
//   END_HANDSHAKE      (0x190): DUT req → TB done_ack → TB rsp+0x190 → done
//
// State / Substate Map (happy path):
//   VALVREF          sub0(req→rsp→done) sub1(eye_sweep) sub2(txrx→rsp→done)
//                    → exit: req+0x88 → DATAVREF
//   DATAVREF         sub0(imm_rsp→done) sub1(eye_sweep) sub2(txrx→rsp→done)
//                    → exit: prev_state_done(0x8A) → SPEEDIDLE
//   SPEEDIDLE        sub0(req+0xCA,speed_ok) sub1(txrx→rsp→done)
//                    → exit: req+0xD0 → TXSELFCAL
//   TXSELFCAL        sub0(txrx→rsp→done)
//                    → exit: req+0x98 → RXCLKCAL
//   RXCLKCAL         sub0(imm_rsp→done) sub1(eye_sweep) sub2(txrx→rsp→done)
//                    → exit: req+0xA0 → VALTRAINCENTER
//   VALTRAINCENTER   sub0(imm_rsp→done) sub1(eye_sweep) sub2(txrx→rsp→done)
//                    → exit: req+0xE8 → VALTRAINVREF
//   VALTRAINVREF     sub0(imm_rsp→done) sub1(eye_sweep) sub2(txrx→rsp→done)
//                    → exit: req+0x90 → DATATRAINCENTER1
//   DATATRAINCENTER1 sub0(imm_rsp→done) sub1(eye_sweep[no_retry]) sub2(txrx→rsp→done)
//                    → exit: req+0xF0 → DATATRAINVREF
//   DATATRAINVREF    sub0(imm_rsp→done+0xF0) sub1(eye_sweep) sub2(txrx→rsp→done)
//                    → exit: req+0xF2 → RXDESKEW
//   RXDESKEW         sub0(imm_rsp→req+0xAC) sub1(txrx→rsp→done)
//                    → exit: req+0xB0 → DATATRAINCENTER2
//   DATATRAINCENTER2 sub0(imm_rsp→done) sub1(eye_sweep[no_retry]) sub2(txrx→rsp→done)
//                    → done: train_active_en=1
// =============================================================================

module ucie_LTSM_RX_MBTRAIN_TB ();

// -----------------------------------------------------------------------
// Parameters
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

// RX interface inputs (data coming from remote TX, driven by TB)
logic [DECODING_WIDTH-1:0]  i_rx_decoding;
logic [DATA_WIDTH-1:0]      i_rx_data;
logic [DATA_WIDTH-1:0]      result;
logic [INFO_WIDTH-1:0]      i_rx_info;
logic [7:0]                 i_rx_sweep_result;

// Sideband inputs (driven by TB, simulating remote TX sideband)
logic i_sb_rx_req;
logic i_sb_rx_rsp;
logic i_sb_rx_done;
logic i_rx_done;
logic i_tx_done;

// Training control inputs
logic       init_train_en;
logic       timeout;
logic [2:0] o_pl_speedmode;

logic [DECODING_WIDTH-1:0] encoding_rsp_sent;
logic [DECODING_WIDTH-1:0] encoding_rsp_received;
logic                      rsp_received;
logic                      rsp_sent;

// RX interface outputs (from DUT)
logic [DECODING_WIDTH-1:0] o_rx_encoding;
logic [DATA_WIDTH-1:0]     o_rx_data;
logic [INFO_WIDTH-1:0]     o_rx_info;

// Sideband outputs (from DUT)
logic o_rx_sb_req;
logic o_rx_sb_rsp;
logic o_rx_sb_done;

// Status outputs
logic train_error;
logic train_active_en;

// -----------------------------------------------------------------------
// Expected-value mirrors (for assertion messages)
// -----------------------------------------------------------------------
logic [DECODING_WIDTH-1:0] o_rx_encoding_expected;
logic                      o_rx_sb_req_expected;
logic                      o_rx_sb_rsp_expected;
logic                      o_rx_sb_done_expected;
logic                      train_active_en_expected;

// -----------------------------------------------------------------------
// DUT Instantiation
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
    .result                (result),
    .i_rx_sweep_result     (i_rx_sweep_result),
    .i_sb_rx_req           (i_sb_rx_req),
    .i_sb_rx_rsp           (i_sb_rx_rsp),
    .i_sb_rx_done          (i_sb_rx_done),
    .i_rx_done             (i_rx_done),
    .i_tx_done             (i_tx_done),
    .init_train_en         (init_train_en),
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
    .train_active_en       (train_active_en)
);

// -----------------------------------------------------------------------
// Clock Generation  (100 MHz)
// -----------------------------------------------------------------------
initial begin
    i_clk = 0;
    forever #5 i_clk = ~i_clk;
end

// -----------------------------------------------------------------------
// Force internal 'result' wire high so eye-sweep always reports pass
// (result is an implicit unconnected wire inside DUT; without this,
//  failed_test would be X causing indeterminate retry behavior in init=1
//  states with no_retry=0)
// -----------------------------------------------------------------------

// =======================================================================
// Helper Tasks
// =======================================================================

// --- do_rsp_hs -----------------------------------------------------------
// For sub0 states that wait for an incoming req before asserting rsp
// (VALVREF sub0 style):
//   1. TB asserts i_sb_rx_req  → DUT asserts o_rx_sb_rsp with encoding enc
//   2. TB asserts i_sb_rx_done → done_ack → DUT deasserts rsp → advances
// -------------------------------------------------------------------------
task do_rsp_hs (input [DECODING_WIDTH-1:0] enc);
    begin
        // Step 1: TB drives request to trigger DUT response
        i_sb_rx_req   = 1;
        i_rx_decoding = enc;

        o_rx_encoding_expected = enc;
        o_rx_sb_rsp_expected   = 1;

        @(negedge i_clk);
        assert (o_rx_encoding_expected == o_rx_encoding)
        else $display("ERROR [do_rsp_hs] Expected o_rx_encoding=%h, got %h, time %0t",
                      o_rx_encoding_expected, o_rx_encoding, $time);
        assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
        else $display("ERROR [do_rsp_hs] Expected o_rx_sb_rsp=%h, got %h, time %0t",
                      o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

        // Step 2: TB done → done_ack → DUT clears rsp and advances
        i_sb_rx_done         = 1;
        o_rx_sb_rsp_expected = 0;

        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_sb_rx_done  = 0;
        i_rx_decoding = 0;

        assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
        else $display("ERROR [do_rsp_hs] Expected o_rx_sb_rsp=%h, got %h, time %0t",
                      o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

        repeat (2) @(negedge i_clk);
    end
endtask

// --- do_imm_rsp_done_hs --------------------------------------------------
// For sub0 states that assert rsp immediately on entry (no req needed),
// advancing via i_sb_rx_done only (RXCLKCAL, DATAVREF, VALTRAINCENTER,
// VALTRAINVREF, DATATRAINCENTER1, DATATRAINCENTER2 sub0 style):
//   1. Verify DUT already has o_rx_sb_rsp=1 with encoding enc
//   2. TB asserts i_sb_rx_done → DUT advances to sub1
// -------------------------------------------------------------------------
task do_imm_rsp_done_hs (input [DECODING_WIDTH-1:0] enc);
    begin
        o_rx_encoding_expected = enc;
        o_rx_sb_rsp_expected   = 1;

        @(negedge i_clk);
        assert (o_rx_encoding_expected == o_rx_encoding)
        else $display("ERROR [do_imm_rsp_done_hs] Expected o_rx_encoding=%h, got %h, time %0t",
                      o_rx_encoding_expected, o_rx_encoding, $time);
        assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
        else $display("ERROR [do_imm_rsp_done_hs] Expected o_rx_sb_rsp=%h, got %h, time %0t",
                      o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

        // TB done → advance to sub1
        i_sb_rx_done = 1;

        @(negedge i_clk);
        i_sb_rx_done = 0;

        repeat (2) @(negedge i_clk);
    end
endtask

// --- do_txrx_done_hs -----------------------------------------------------
// For sub2 states (post-eye-sweep completion handshake):
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
        else $display("ERROR [do_txrx_done_hs] Expected o_rx_encoding=%h, got %h, time %0t",
                      o_rx_encoding_expected, o_rx_encoding, $time);
        assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
        else $display("ERROR [do_txrx_done_hs] Expected o_rx_sb_rsp=%h, got %h, time %0t",
                      o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

        // TB done → done_ack → substates_done
        i_sb_rx_done         = 1;
        o_rx_sb_rsp_expected = 0;

        @(negedge i_clk);
        i_sb_rx_done = 0;

        assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
        else $display("ERROR [do_txrx_done_hs] Expected o_rx_sb_rsp=%h, got %h, time %0t",
                      o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

        repeat (2) @(negedge i_clk);
    end
endtask

// --- do_state_exit_req ---------------------------------------------------
// Trigger CS transition for states that use req_received:
//   TB asserts i_sb_rx_req=1 with enc so encoding_req_received is captured
//   and NS can advance on the next combinational evaluation.
// -------------------------------------------------------------------------
task do_state_exit_req (input [DECODING_WIDTH-1:0] enc);
    begin
        i_sb_rx_req   = 1;
        i_rx_decoding = enc;

        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_rx_decoding = 0;

        $display("INFO  [do_state_exit_req] exit req enc=%h at %0t", enc, $time);
        repeat (2) @(negedge i_clk);
    end
endtask

// --- do_state_exit_rsp ---------------------------------------------------
// Trigger CS transition for states that use previous_state_done:
//   Drive rsp_sent=1 & rsp_received=1 with matching encoding so that
//   previous_state_done (= rsp_sent & rsp_received) fires → NS advances.
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

        $display("INFO  [do_state_exit_rsp] exit rsp enc=%h at %0t", enc, $time);
        repeat (2) @(negedge i_clk);
    end
endtask

// --- do_eye_sweep_happy_pass_rx ------------------------------------------
// Drive the embedded ucie_RX_Data_to_Clock_eye_sweep through a full
// successful sweep in init=1 mode (RX is the initiator):
//
//   REQ_HANDSHAKE  (0x185): DUT asserts o_rx_sb_req
//                           TB done_ack  → DUT clears req
//                           TB rsp+0x185 → NS=LFSR_HANDSHAKE
//   LFSR_HANDSHAKE (0x186): TB req+0x186 → DUT asserts o_rx_sb_rsp
//                           TB done+0x186 → done_ack → NS=DATA_DETECTION
//   DATA_DETECTION (0x187): TB asserts i_rx_done → NS=RESULT_HANDSHAKE
//   RESULT_HS      (0x188): TB req+0x188 → DUT asserts o_rx_sb_rsp
//                           TB done+0x188 → done_ack → pass → SWEEP_RESULT_HS
//   SWEEP_RESULT_HS(0x189): TB done+0x189 → NS=END_HANDSHAKE
//   END_HANDSHAKE  (0x190): DUT asserts o_rx_sb_req
//                           TB done_ack → DUT clears req
//                           TB rsp+0x190 → done=1 → LTSM substate exits
// -------------------------------------------------------------------------
task do_eye_sweep_happy_pass_rx ();
    begin
        $display("INFO  [eye_sweep_rx] starting eye-sweep at %0t", $time);

        // ================================================================
        // REQ_HANDSHAKE (0x185) — DUT sends req, TB ack then rsp
        // ================================================================
        o_rx_encoding_expected = 'h185;
        o_rx_sb_req_expected   = 1;

        @(negedge i_clk);
        assert (o_rx_encoding_expected == o_rx_encoding)
        else $display("ERROR [eye_sweep] Expected o_rx_encoding=%h, got %h at %0t",
                      o_rx_encoding_expected, o_rx_encoding, $time);
        assert (o_rx_sb_req_expected == o_rx_sb_req)
        else $display("ERROR [eye_sweep] Expected o_rx_sb_req=%h, got %h at %0t",
                      o_rx_sb_req_expected, o_rx_sb_req, $time);

        // TB done_ack → DUT clears req
        i_sb_rx_done         = 1;
        o_rx_sb_req_expected = 0;

        @(negedge i_clk);
        i_sb_rx_done = 0;

        assert (o_rx_sb_req_expected == o_rx_sb_req)
        else $display("ERROR [eye_sweep] Expected o_rx_sb_req=%h, got %h at %0t",
                      o_rx_sb_req_expected, o_rx_sb_req, $time);

        repeat (2) @(negedge i_clk);

        // TB rsp + matching decoding → NS = LFSR_HANDSHAKE
        i_sb_rx_rsp   = 1;
        i_rx_decoding = 'h185;
        o_rx_encoding_expected = 'h186;

        @(negedge i_clk);
        assert (o_rx_encoding_expected == o_rx_encoding)
        else $display("ERROR [eye_sweep] Expected o_rx_encoding=%h, got %h at %0t",
                      o_rx_encoding_expected, o_rx_encoding, $time);

        i_sb_rx_rsp   = 0;
        i_rx_decoding = 0;

        // ================================================================
        // LFSR_HANDSHAKE (0x186) — TB req → DUT rsp → TB done+decoding
        // ================================================================
        repeat (2) @(negedge i_clk);

        i_sb_rx_req          = 1;
        i_rx_decoding        = 'h186;
        o_rx_sb_rsp_expected = 1;
        o_rx_encoding_expected = 'h186;

        @(negedge i_clk);
        assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
        else $display("ERROR [eye_sweep] Expected o_rx_sb_rsp=%h, got %h at %0t",
                      o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);
        assert (o_rx_encoding_expected == o_rx_encoding)
        else $display("ERROR [eye_sweep] Expected o_rx_encoding=%h, got %h at %0t",
                      o_rx_encoding_expected, o_rx_encoding, $time);

        // TB done + decoding → done_ack → NS = DATA_DETECTION
        i_sb_rx_done         = 1;
        o_rx_sb_rsp_expected = 0;

        @(negedge i_clk);
        i_sb_rx_req   = 0;
        i_sb_rx_done  = 0;
        i_rx_decoding = 0;

        assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
        else $display("ERROR [eye_sweep] Expected o_rx_sb_rsp=%h, got %h at %0t",
                      o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

        // ================================================================
        // DATA_DETECTION (0x187) — TB asserts i_rx_done
        // ================================================================
        repeat (3) @(negedge i_clk);

        o_rx_encoding_expected = 'h187;

        @(negedge i_clk);
        assert (o_rx_encoding_expected == o_rx_encoding)
        else $display("ERROR [eye_sweep] Expected o_rx_encoding=%h, got %h at %0t",
                      o_rx_encoding_expected, o_rx_encoding, $time);

        i_rx_done              = 1;
        o_rx_encoding_expected = 'h188;
        result = {DATA_WIDTH{1'b1}};

        @(negedge i_clk);
        i_rx_done = 0;

        assert (o_rx_encoding_expected == o_rx_encoding)
        else $display("ERROR [eye_sweep] Expected o_rx_encoding=%h, got %h at %0t",
                      o_rx_encoding_expected, o_rx_encoding, $time);

        // ================================================================
        // RESULT_HANDSHAKE (0x188) — TB req → DUT rsp → TB done+decoding
        // (result wire forced=1 → failed_test=0 → pass → SWEEP_RESULT_HS)
        // ================================================================
        i_sb_rx_req          = 1;
        i_rx_decoding        = 'h189;

        @(negedge i_clk);
        // TB done + decoding → done_ack → pass (result=1) → SWEEP_RESULT_HS
        i_sb_rx_done         = 1;
        o_rx_sb_rsp_expected = 0;

        i_sb_rx_req   = 0;
        i_sb_rx_done  = 0;
        i_rx_decoding = 0;

        @(negedge i_clk);
        assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
        else $display("ERROR [eye_sweep] Expected o_rx_sb_rsp=%h, got %h at %0t",
                      o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

        // ================================================================
        // SWEEP_RESULT_HANDSHAKE (0x189) — TB sends done+decoding
        // ================================================================
        i_sb_rx_req   = 1;
        i_rx_decoding = 'h189;
        o_rx_encoding_expected = 'h189;

        @(negedge i_clk);
        assert (o_rx_encoding_expected == o_rx_encoding)
        else $display("ERROR [eye_sweep] Expected o_rx_encoding=%h, got %h at %0t",
                      o_rx_encoding_expected, o_rx_encoding, $time);

        i_sb_rx_done           = 1;
        i_rx_decoding          = 'h189;
        o_rx_encoding_expected = 'h190;

        @(negedge i_clk);
        i_sb_rx_done  = 0;
        i_rx_decoding = 0;

        assert (o_rx_encoding_expected == o_rx_encoding)
        else $display("ERROR [eye_sweep] Expected o_rx_encoding=%h, got %h at %0t",
                      o_rx_encoding_expected, o_rx_encoding, $time);

        // ================================================================
        // END_HANDSHAKE (0x190) — DUT asserts req, TB ack then rsp → done=1
        // ================================================================
        o_rx_sb_req_expected = 1;

        @(negedge i_clk);
        assert (o_rx_sb_req_expected == o_rx_sb_req)
        else $display("ERROR [eye_sweep] Expected o_rx_sb_req=%h, got %h at %0t",
                      o_rx_sb_req_expected, o_rx_sb_req, $time);

        // TB done_ack → DUT clears req
        i_sb_rx_done         = 1;
        o_rx_sb_req_expected = 0;

        @(negedge i_clk);
        i_sb_rx_done = 0;

        assert (o_rx_sb_req_expected == o_rx_sb_req)
        else $display("ERROR [eye_sweep] Expected o_rx_sb_req=%h, got %h at %0t",
                      o_rx_sb_req_expected, o_rx_sb_req, $time);

        repeat (2) @(negedge i_clk);

        // TB rsp + matching decoding → done=1 → clock_to_test_done → LTSM exits sub1
        i_sb_rx_rsp   = 1;
        i_rx_decoding = 'h190;

        @(negedge i_clk);
        i_sb_rx_rsp   = 0;
        i_rx_decoding = 0;

        repeat (3) @(negedge i_clk);

        $display("INFO  [eye_sweep_rx] eye-sweep complete at %0t", $time);
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
        i_rx_sweep_result     = 0;
        i_sb_rx_req           = 0;
        i_sb_rx_rsp           = 0;
        i_sb_rx_done          = 0;
        i_rx_done             = 0;
        i_tx_done             = 0;
        timeout               = 0;
        o_pl_speedmode        = 3'b001;   // default non-zero speed mode
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

    // -------------------------------------------------------------------
    // RESET + INIT
    // -------------------------------------------------------------------
    init_signals();

    repeat (3) @(negedge i_clk);
    i_reset = 0;
    @(negedge i_clk);

    init_train_en = 1;
    @(negedge i_clk);

    // ===================================================================
    // TEST 1: VALVREF State — Substate 0
    //   DUT at enc=0x80 waits for i_sb_rx_req before asserting rsp.
    //   TB sends req → checks rsp → sends done → DUT advances to sub1.
    // ===================================================================
    $display("=== TEST 1: VALVREF substate-0 rsp handshake (enc=0x80) ===");

    o_rx_encoding_expected = 'h80;

    @(negedge i_clk);
    assert (o_rx_encoding_expected == o_rx_encoding)
    else $display("ERROR: Expected o_rx_encoding=%h, got %h at %0t",
                  o_rx_encoding_expected, o_rx_encoding, $time);

    // TB sends req → DUT should assert rsp
    i_sb_rx_req          = 1;

    @(negedge i_clk);
    o_rx_sb_rsp_expected = 1;

    assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
    else $display("ERROR: Expected o_rx_sb_rsp=%h, got %h at %0t",
                  o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

    // TB done → done_ack → DUT clears rsp → advances to sub1 (eye sweep)
    i_sb_rx_done         = 1;
    o_rx_sb_rsp_expected = 0;

    @(negedge i_clk);
    i_sb_rx_req  = 0;
    i_sb_rx_done = 0;

    assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
    else $display("ERROR: Expected o_rx_sb_rsp=%h, got %h at %0t",
                  o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

    $display("PASS  TEST 1: VALVREF sub0 handshake");

    // ===================================================================
    // TEST 2: VALVREF — Substate 1 (eye-sweep, init=1)
    // ===================================================================
    $display("=== TEST 2: VALVREF substate-1 eye-sweep (init=1) ===");

    do_eye_sweep_happy_pass_rx();

    $display("PASS  TEST 2: VALVREF sub1 eye-sweep");

    // ===================================================================
    // TEST 3: VALVREF — Substate 2 (completion handshake at enc=0x82)
    //   Eye-sweep done signal was captured; DUT advances to sub2 when
    //   it sees clock_to_test_done && i_sb_rx_req && i_rx_decoding==0x82.
    //   Then: TB asserts tx_done && rx_done → DUT asserts rsp
    //         TB done → substates_done.
    // ===================================================================
    $display("=== TEST 3: VALVREF substate-2 completion handshake (enc=0x82) ===");

    // Trigger sub2 entry by sending req with decoding 0x82
    i_sb_rx_req   = 1;
    i_rx_decoding = 'h82;

    @(negedge i_clk);
    i_sb_rx_req   = 0;
    i_rx_decoding = 0;

    repeat (2) @(negedge i_clk);

    do_txrx_done_hs('h82);

    $display("PASS  TEST 3: VALVREF sub2 completion handshake");

    // State-level exit: req_received with enc=0x88 → NS=DATAVREF
    do_state_exit_req('h88);

    $display("PASS  TEST 3b: VALVREF exit → DATAVREF");

    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 4: DATAVREF State — Full 3-substate walk
    //   Sub0: enc=0x88, DUT immediately asserts rsp, TB sends done → sub1
    //   Sub1: eye-sweep (init=1, no_retry=0)
    //   Sub2: enc=0x8A, tx_done+rx_done → rsp → done → substates_done
    //   Exit: previous_state_done (rsp_sent && rsp_received == 0x8A)
    // ===================================================================
    $display("=== TEST 4: DATAVREF full walk (0x88 → eye_sweep → 0x8A) ===");

    do_imm_rsp_done_hs('h88);
    do_eye_sweep_happy_pass_rx();

    // Trigger sub2 entry: clock_to_test_done && req+decoding 0x8A
    i_sb_rx_req   = 1;
    i_rx_decoding = 'h8A;

    @(negedge i_clk);
    i_sb_rx_req   = 0;
    i_rx_decoding = 0;

    repeat (2) @(negedge i_clk);

    do_txrx_done_hs('h8A);

    // Exit via previous_state_done: both rsp_sent & rsp_received for enc=0x8A
    do_state_exit_rsp('h8A);

    $display("PASS  TEST 4: DATAVREF");

    // ===================================================================
    // TEST 5: SPEEDIDLE State
    //   Sub0: DUT waits for i_sb_rx_req && i_rx_decoding==0xCA and
    //         o_pl_speedmode != 0 → advances to sub1
    //   Sub1: enc=0xCA, tx_done+rx_done → rsp → done → substates_done
    //   Exit: req+decoding 0xD0 → TXSELFCAL
    // ===================================================================
    $display("=== TEST 5: SPEEDIDLE (speed-match 0xCA → 0xCA → exit 0xD0) ===");

    o_rx_encoding_expected = 'hC8;
    o_pl_speedmode = 3'b001;   // ensure non-zero for speed match

    @(negedge i_clk);
    assert (o_rx_encoding_expected == o_rx_encoding)
    else $display("ERROR: Expected o_rx_encoding=%h, got %h at %0t",
                  o_rx_encoding_expected, o_rx_encoding, $time);

    // Sub0: send req with matching decoding 0xCA → advances to sub1
    i_sb_rx_req   = 1;
    i_rx_decoding = 'hCA;

    @(negedge i_clk);
    i_sb_rx_req   = 0;
    i_rx_decoding = 0;

    repeat (2) @(negedge i_clk);

    // Sub1: enc=0xCA, wait for tx_done+rx_done
    do_txrx_done_hs('hCA);

    // Exit → TXSELFCAL
    do_state_exit_req('hD0);

    $display("PASS  TEST 5: SPEEDIDLE");

    // ===================================================================
    // TEST 6: TXSELFCAL State — Single substate (no eye-sweep)
    //   Sub0: enc=0xD0, tx_done+rx_done → rsp → done → substates_done
    //   Exit: req+decoding 0x98 → RXCLKCAL
    // ===================================================================
    $display("=== TEST 6: TXSELFCAL (0xD0 → done) ===");

    o_rx_encoding_expected = 'hD0;

    @(negedge i_clk);
    assert (o_rx_encoding_expected == o_rx_encoding)
    else $display("ERROR: Expected o_rx_encoding=%h, got %h at %0t",
                  o_rx_encoding_expected, o_rx_encoding, $time);

    do_txrx_done_hs('hD0);

    // Exit → RXCLKCAL
    do_state_exit_req('h98);

    $display("PASS  TEST 6: TXSELFCAL");

    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 7: RXCLKCAL State — 3 substates
    //   Sub0: enc=0x98, DUT immediately asserts rsp, TB done → sub1
    //   Sub1: eye-sweep (init=1, no_retry=0)
    //   Sub2: enc=0x9A, tx_done+rx_done → rsp → done → substates_done
    //   Exit: req+decoding 0xA0 → VALTRAINCENTER
    // ===================================================================
    $display("=== TEST 7: RXCLKCAL (0x98 → eye_sweep → 0x9A) ===");

    do_imm_rsp_done_hs('h98);
    do_eye_sweep_happy_pass_rx();

    // Trigger sub2 entry: clock_to_test_done && req+decoding 0x9A
    i_sb_rx_req   = 1;
    i_rx_decoding = 'h9A;

    @(negedge i_clk);
    i_sb_rx_req   = 0;
    i_rx_decoding = 0;

    repeat (2) @(negedge i_clk);

    do_txrx_done_hs('h9A);

    // Exit → VALTRAINCENTER
    do_state_exit_req('hA0);

    $display("PASS  TEST 7: RXCLKCAL");

    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 8: VALTRAINCENTER State — Full 3-substate walk
    //   Sub0: enc=0xA0, imm rsp → done → sub1
    //   Sub1: eye-sweep (init=1, no_retry=0)
    //   Sub2: enc=0xA2, tx_done+rx_done → rsp → done
    //   Exit: req+decoding 0xE8 → VALTRAINVREF
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
    // TEST 9: VALTRAINVREF State — Full 3-substate walk
    //   Sub0: enc=0xE8, imm rsp → done → sub1
    //   Sub1: eye-sweep (init=1, no_retry=0)
    //   Sub2: enc=0xEA, tx_done+rx_done → rsp → done
    //   Exit: req+decoding 0x90 → DATATRAINCENTER1
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
    // TEST 10: DATATRAINCENTER1 State — Full 3-substate walk (no_retry=1)
    //   Sub0: enc=0x90, imm rsp → done → sub1
    //   Sub1: eye-sweep (init=1, no_retry=1)
    //   Sub2: enc=0x92, tx_done+rx_done → rsp → done
    //   Exit: req+decoding 0xF0 → DATATRAINVREF
    // ===================================================================
    $display("=== TEST 10: DATATRAINCENTER1 (0x90 → eye_sweep[no_retry] → 0x92) ===");

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
    // TEST 11: DATATRAINVREF State — Full 3-substate walk
    //   Sub0: enc=0xF0, imm rsp, advances via i_sb_rx_done && decoding==0xF0
    //   Sub1: eye-sweep (init=1, no_retry=0)
    //   Sub2: enc=0xF2, tx_done+rx_done → rsp → done
    //   Exit: req+decoding 0xF2 → RXDESKEW
    // ===================================================================
    $display("=== TEST 11: DATATRAINVREF (0xF0 → eye_sweep → 0xF2) ===");

    // Sub0: DUT immediately asserts rsp at enc=0xF0;
    //       advances when i_sb_rx_done=1 AND i_rx_decoding=='hF0
    o_rx_encoding_expected = 'hF0;
    o_rx_sb_rsp_expected   = 1;

    @(negedge i_clk);
    assert (o_rx_encoding_expected == o_rx_encoding)
    else $display("ERROR: Expected o_rx_encoding=%h, got %h at %0t",
                  o_rx_encoding_expected, o_rx_encoding, $time);
    assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
    else $display("ERROR: Expected o_rx_sb_rsp=%h, got %h at %0t",
                  o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

    // Assert done with decoding 0xF0 to advance to sub1
    i_sb_rx_done  = 1;
    i_rx_decoding = 'hF0;

    @(negedge i_clk);
    i_sb_rx_done  = 0;
    i_rx_decoding = 0;

    repeat (2) @(negedge i_clk);

    do_eye_sweep_happy_pass_rx();

    // Trigger sub2 entry: clock_to_test_done && req+decoding 0xF2
    i_sb_rx_req   = 1;
    i_rx_decoding = 'hF2;
    @(negedge i_clk);
    i_sb_rx_req   = 0;
    i_rx_decoding = 0;
    repeat (2) @(negedge i_clk);

    do_txrx_done_hs('hF2);

    // Exit: req+decoding 0xF2 → req_received → RXDESKEW
    do_state_exit_req('hA8);

    $display("PASS  TEST 11: DATATRAINVREF");
    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 12: RXDESKEW State — 2 substates (no eye-sweep)
    //   Sub0: enc=0xA8, imm rsp; advances via i_sb_rx_req && decoding==0xAC
    //   Sub1: enc=0xAC, tx_done+rx_done → rsp → done → substates_done
    //   Exit: req+decoding 0xB0 → DATATRAINCENTER2
    // ===================================================================
    $display("=== TEST 12: RXDESKEW (0xA8 → 0xAC) ===");

    // Sub0: DUT immediately asserts rsp at enc=0xA8
    o_rx_encoding_expected = 'hA8;
    o_rx_sb_rsp_expected   = 1;

    @(negedge i_clk);
    assert (o_rx_encoding_expected == o_rx_encoding)
    else $display("ERROR: Expected o_rx_encoding=%h, got %h at %0t",
                  o_rx_encoding_expected, o_rx_encoding, $time);
    assert (o_rx_sb_rsp_expected == o_rx_sb_rsp)
    else $display("ERROR: Expected o_rx_sb_rsp=%h, got %h at %0t",
                  o_rx_sb_rsp_expected, o_rx_sb_rsp, $time);

    // Advance sub0→sub1 by sending req+decoding 0xAC
    i_sb_rx_req   = 1;
    i_rx_decoding = 'hAC;

    @(negedge i_clk);
    i_sb_rx_req   = 0;
    i_rx_decoding = 0;

    repeat (2) @(negedge i_clk);

    // Sub1: enc=0xAC, tx_done+rx_done → rsp → done
    do_txrx_done_hs('hAC);

    // Exit → DATATRAINCENTER2
    do_state_exit_req('hB0);

    $display("PASS  TEST 12: RXDESKEW");
    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 13: DATATRAINCENTER2 — Final state
    //   Sub0: enc=0xB0, imm rsp, advances via i_sb_rx_done
    //   Sub1: eye-sweep (init=1, no_retry=1)
    //   Sub2: enc=0xB2, tx_done+rx_done → rsp → done (also triggers train_active_en)
    //   Completion: train_active_en=1 → NS back to VALVREF
    // ===================================================================
    $display("=== TEST 13: DATATRAINCENTER2 (0xB0 → eye_sweep[no_retry] → 0xB2) ===");

    // Sub0: DUT immediately asserts rsp, TB done → advances to sub1
    do_imm_rsp_done_hs('hB0);
    do_eye_sweep_happy_pass_rx();

    // Trigger sub2 entry: clock_to_test_done && req+decoding 0xB2
    i_sb_rx_req   = 1;
    i_rx_decoding = 'hB2;
    @(negedge i_clk);
    i_sb_rx_req   = 0;
    i_rx_decoding = 0;
    repeat (2) @(negedge i_clk);

    // Sub2: tx_done+rx_done → rsp; the same i_sb_rx_done that completes
    // sub2 also triggers train_active_en_reg=1 at the state level
    do_txrx_done_hs('hB2);

    // Completion: train_active_en should be asserted a cycle or two later
    train_active_en_expected = 1;

    repeat (3) @(negedge i_clk);
    assert (train_active_en_expected == train_active_en)
    else $display("ERROR: Expected train_active_en=%h, got %h at %0t",
                  train_active_en_expected, train_active_en, $time);

    $display("PASS  TEST 13: DATATRAINCENTER2 → train_active_en=1 → back to VALVREF");

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