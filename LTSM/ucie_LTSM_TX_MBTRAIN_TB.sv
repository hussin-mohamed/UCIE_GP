// =============================================================================
// Module : ucie_LTSM_TX_MBTRAIN_TB
// Description: Testbench for the UCIe TX Link Training State Machine.
//              Follows the same req/done/rsp handshake sequencing pattern
//              established in ucie_TX_Data_to_Clock_eye_sweep_TB.
//
// Handshake Protocol Recap (same as eye-sweep TB):
//   1. DUT asserts o_tx_sb_req=1 when entering a new encoding substate
//   2. TB asserts i_sb_tx_done=1 → internal done_ack=1 → DUT deasserts req
//   3. TB asserts i_sb_tx_rsp=1  with matching i_tx_decoding
//       → clears done_ack, triggers substate advance, fires o_tx_sb_done pulse
//   4. State-level exit: TB asserts BOTH o_rx_sb_rsp=1 (rsp_sent) AND
//      i_sb_tx_rsp=1 with matching i_tx_decoding (rsp_received)
//      once substates_done=1, so that previous_state_done fires → next CS
//
// State / Substate Map (happy path):
//   VALVREF        (0x80 → eye_sweep → 0x82)  → DATAVREF
//   DATAVREF       (0x88 → eye_sweep → 0x8A)  → SPEEDIDLE
//   SPEEDIDLE      (0xC8 → 0xCA)               → TXSELFCAL
//   TXSELFCAL      (0xD0 → 0xD1)               → RXCLKCAL
//   RXCLKCAL       (0x98 → eye_sweep → 0x9A)  → VALTRAINCENTER
//   VALTRAINCENTER (0xA0 → eye_sweep → 0xA2)  → VALTRAINVREF
//   VALTRAINVREF   (0xE8 → eye_sweep → 0xEA)  → DATATRAINCENTER1
//   DATATRAINCENTER1(0x90 → eye_sweep[no_retry] → 0x92) → DATATRAINVREF
//   DATATRAINVREF  (0xF0 → eye_sweep → 0xF2)  → RXDESKEW
//   RXDESKEW       (0xA8 → 0xAC)               → DATATRAINCENTER2
//   DATATRAINCENTER2(0xB0 → eye_sweep[no_retry] → 0xB2) → VALVREF
//
// Eye-Sweep Sub-sequence (per state, happy path):
//   REQ_HANDSHAKE  (0x180): req → done_ack → rsp+0x180
//   LFSR_HANDSHAKE (0x181): req → done_ack → rsp+0x181
//   DATA_GENERATE  (0x182): wait for i_tx_done
//   RESULT_HS      (0x183): req → done_ack → rsp+0x183 + i_tx_data=all1s (pass)
//   END_HANDSHAKE  (0x184): req → done_ack → rsp+0x184 → done
// =============================================================================

module ucie_LTSM_TX_MBTRAIN_TB ();

// -----------------------------------------------------------------------
// Parameters
// -----------------------------------------------------------------------
parameter DECODING_WIDTH = 9;
parameter DATA_WIDTH     = 64;
parameter INFO_WIDTH     = 16;
parameter ERROR_THRESHOLD = 0;

// -----------------------------------------------------------------------
// DUT Signal Declarations
// -----------------------------------------------------------------------
logic                       i_clk;
logic                       i_reset;

// TX interface inputs (from remote RX)
logic [DECODING_WIDTH-1:0]  i_tx_decoding;
logic [DATA_WIDTH-1:0]      i_tx_data;
logic [INFO_WIDTH-1:0]      i_tx_info;
logic [7:0]                 i_tx_sweep_result;  // wired to eye-sweep sub-module inside DUT
// Note: the port in the design is named i_xx_sweep_result on the sub-module;
//       the top-level LTSM does not re-expose it so we leave it as wire.

// Sideband inputs
logic i_sb_tx_req;
logic i_sb_tx_rsp;
logic i_sb_tx_done;
logic i_tx_done;

// Training control inputs
logic       init_train_en;
logic       timeout;
logic       o_rx_sb_rsp;       // local RX response (feeds rsp_sent tracking)
logic [2:0] o_pl_speedmode;    // expected speed mode
logic [DECODING_WIDTH-1:0] encoding_rsp_sent;      // Encoding value when response sent
logic [DECODING_WIDTH-1:0] encoding_rsp_received;  // Encoding value when response received
logic rsp_received;               // Response sent flag
logic rsp_sent;                   // Response sent flag

// TX interface outputs
logic [DECODING_WIDTH-1:0] o_tx_encoding;
logic [DATA_WIDTH-1:0]     o_tx_data;
logic [INFO_WIDTH-1:0]     o_tx_info;

// Sideband outputs
logic o_tx_sb_req;
logic o_tx_sb_rsp;
logic o_tx_sb_done;

// Status outputs
logic train_error;
logic train_active_en;

// -----------------------------------------------------------------------
// Expected-value mirrors (for assertion messages)
// -----------------------------------------------------------------------
logic [DECODING_WIDTH-1:0] o_tx_encoding_expected;
logic [DATA_WIDTH-1:0]     o_tx_data_expected;
logic [INFO_WIDTH-1:0]     o_tx_info_expected;
logic                      o_tx_sb_req_expected;
logic                      o_tx_sb_rsp_expected;
logic                      o_tx_sb_done_expected;
logic                      train_error_expected;
logic                      train_active_en_expected;

// -----------------------------------------------------------------------
// DUT Instantiation
// -----------------------------------------------------------------------
ucie_LTSM_TX_MBTRAIN #(
    .DECODING_WIDTH  (DECODING_WIDTH),
    .DATA_WIDTH      (DATA_WIDTH),
    .INFO_WIDTH      (INFO_WIDTH),
    .ERROR_THRESHOLD (ERROR_THRESHOLD)
) DUT (
    .i_clk                    (i_clk),
    .i_reset                  (i_reset),
    .i_tx_decoding            (i_tx_decoding),
    .i_tx_data                (i_tx_data),
    .i_tx_info                (i_tx_info),
    .i_tx_sweep_result        (i_tx_sweep_result),
    .i_sb_tx_req              (i_sb_tx_req),
    .i_sb_tx_rsp              (i_sb_tx_rsp),
    .i_sb_tx_done             (i_sb_tx_done),
    .i_tx_done                (i_tx_done),
    .init_train_en            (init_train_en),
    .timeout                  (timeout),
    .o_pl_speedmode           (o_pl_speedmode),
    .encoding_rsp_sent        (encoding_rsp_sent),
    .encoding_rsp_received    (encoding_rsp_received),
    .rsp_received             (rsp_received),
    .rsp_sent                 (rsp_sent),
    .o_tx_encoding            (o_tx_encoding),
    .o_tx_data                (o_tx_data),
    .o_tx_info                (o_tx_info),
    .o_tx_sb_req              (o_tx_sb_req),
    .o_tx_sb_rsp              (o_tx_sb_rsp),
    .o_tx_sb_done             (o_tx_sb_done),
    .train_error              (train_error),
    .train_active_en          (train_active_en)
);

// -----------------------------------------------------------------------
// Clock Generation  (100 MHz)
// -----------------------------------------------------------------------
initial begin
    i_clk = 0;
    forever #5 i_clk = ~i_clk;
end

// -----------------------------------------------------------------------
// Helper Tasks
// -----------------------------------------------------------------------

// --- do_req_hs -----------------------------------------------------------
// Drive a single encoding req/done/rsp handshake:
//   1. Check DUT is asserting o_tx_sb_req with the right encoding
//   2. Assert i_sb_tx_done → done_ack → DUT deasserts req
//   3. Assert i_sb_tx_rsp with matching decoding → substate advance + done pulse
// -------------------------------------------------------------------------
task do_req_hs (input [DECODING_WIDTH-1:0] enc);
    begin
        // ---- Step 1: verify req is asserted with expected encoding ----
        o_tx_encoding_expected = enc;

        @(negedge i_clk);
        assert (o_tx_encoding_expected == o_tx_encoding)
        else $display("ERROR: Expected o_tx_encoding = %h, got %h, time %0t",
                      o_tx_encoding_expected, o_tx_encoding, $time);

        o_tx_sb_req_expected   = 1;
        
        @(negedge i_clk);
        assert (o_tx_sb_req_expected == o_tx_sb_req)
        else $display("ERROR: Expected o_tx_sb_req = %h, got %h, time %0t",
                      o_tx_sb_req_expected, o_tx_sb_req, $time);

        // ---- Step 2: done → ack → DUT clears req ----------------------
        i_sb_tx_done         = 1;
        o_tx_sb_req_expected = 0;

        @(negedge i_clk);
        i_sb_tx_done = 0;

        assert (o_tx_sb_req_expected == o_tx_sb_req)
        else $display("ERROR: Expected o_tx_sb_req = %h, got %h, time %0t",
                      o_tx_sb_req_expected, o_tx_sb_req, $time);

        repeat (2) @(negedge i_clk);

        // ---- Step 3: rsp + matching decoding → advance substate -------
        i_sb_tx_rsp   = 1;
        rsp_sent = 1;
        encoding_rsp_sent = enc;
        i_tx_decoding = enc;
        o_tx_sb_done_expected = 1;   // done pulse fires on rsp

        @(negedge i_clk);
        assert (o_tx_sb_done_expected == o_tx_sb_done)
        else $display("ERROR: Expected o_tx_sb_done = %h, got %h, time %0t",
                      o_tx_sb_done_expected, o_tx_sb_done, $time);

        i_sb_tx_rsp   = 0;
        i_tx_decoding = 0;
        o_tx_sb_done_expected = 1;

        i_sb_tx_req = 1;
        i_tx_decoding = 'h188;

        @(negedge i_clk);
        i_sb_tx_req = 0;
        i_sb_tx_rsp = 0;
        i_tx_decoding = 0;
        assert (o_tx_sb_done_expected == o_tx_sb_done)
        else $display("ERROR: Expected o_tx_sb_done = %h, got %h, time %0t",
                      o_tx_sb_done_expected, o_tx_sb_done, $time);
    end
endtask

// --- do_state_exit_hs ----------------------------------------------------
// Once substates are done, drive BOTH o_rx_sb_rsp (rsp_sent) AND i_sb_tx_rsp
// (rsp_received) with matching encoding so that previous_state_done fires
// and CS advances to the next state.
// -------------------------------------------------------------------------
task do_state_exit_hs(input [DECODING_WIDTH-1:0] enc);
    
    begin
        // Assert local RX response (rsp_sent side)
        rsp_received   = 1;
        encoding_rsp_received = enc;

        @(negedge i_clk);

        rsp_received   = 0;
        encoding_rsp_received = enc;
        i_sb_tx_req = 0;
        i_sb_tx_rsp = 0;
        i_tx_decoding = 0;
        $display("INFO  [do_state_exit_hs] state exit handshake complete for enc=%h at %0t",
                 enc, $time);
    end
endtask

// --- do_eye_sweep_happy_pass();
// Drive the embedded ucie_TX_Data_to_Clock_eye_sweep through a full
// successful sweep while the LTSM is in eye-sweep substate (substate 1).
//
// Sequence mirrors the data-to-clock TB happy-path (init=0 case):
//   REQ_HANDSHAKE  (0x180) req/done/rsp
//   LFSR_HANDSHAKE (0x181) req/done/rsp
//   DATA_GENERATE  (0x182) wait, then assert i_tx_done
//   RESULT_HS      (0x183) req/done/rsp  with i_tx_data=all-1s (pass)
//   END_HANDSHAKE  (0x184) req/done/rsp  → clock_to_test_done → substate 2
// -------------------------------------------------------------------------
task do_eye_sweep_happy_pass();
    begin
        $display("INFO  [eye_sweep] starting eye-sweep handshake at %0t", $time);

        // --- REQ_HANDSHAKE (0x180) ---
        o_tx_encoding_expected = 'h188;
        i_sb_tx_req = 0;

        @(negedge i_clk);
        assert (o_tx_encoding_expected == o_tx_encoding)
        else $display("ERROR: Expected o_tx_encoding = %h, got %h, time %0t",
                      o_tx_encoding_expected, o_tx_encoding, $time);

        o_tx_sb_rsp_expected   = 1;
        o_tx_sb_done_expected = 0;

        @(negedge i_clk);
        assert (o_tx_sb_rsp_expected == o_tx_sb_rsp)
        else $display("ERROR: Expected o_tx_sb_rsp = %h, got %h, time %0t",
                      o_tx_sb_rsp_expected, o_tx_sb_rsp, $time);
        assert (o_tx_sb_done_expected == o_tx_sb_done)
        else $display("ERROR: Expected o_tx_sb_done = %h, got %h, time %0t",
                      o_tx_sb_done_expected, o_tx_sb_done, $time);

        i_sb_tx_done   = 1;
        i_sb_tx_req = 0;
        i_tx_decoding  = 'h188;

        o_tx_sb_rsp_expected = 0;
        o_tx_encoding_expected = 'h189;
        
        @(negedge i_clk);
        assert (o_tx_sb_rsp_expected == o_tx_sb_rsp)
        else $display("ERROR: Expected o_tx_sb_rsp = %h, got %h, time %0t",
                      o_tx_sb_rsp_expected, o_tx_sb_rsp, $time);
        assert (o_tx_encoding_expected == o_tx_encoding)
        else $display("ERROR: Expected o_tx_encoding = %h, got %h, time %0t",
                      o_tx_encoding_expected, o_tx_encoding, $time);
        
        i_sb_tx_done         = 0;
        o_tx_sb_req_expected   = 1;

        @(negedge i_clk);
        assert (o_tx_sb_req_expected == o_tx_sb_req)
        else $display("ERROR: Expected o_tx_sb_req = %h, got %h, time %0t",
                      o_tx_sb_req_expected, o_tx_sb_req, $time);

        // --- LFSR_HANDSHAKE (0x181) ---
        // done_ack → deassert req
        i_sb_tx_done         = 1;

        o_tx_sb_req_expected = 0;
        o_tx_sb_done_expected = 0;
        @(negedge i_clk);
        i_sb_tx_done = 0;
        assert (o_tx_sb_req_expected == o_tx_sb_req)
        else $display("ERROR: Expected o_tx_sb_req = %h, got %h, time %0t",
                      o_tx_sb_req_expected, o_tx_sb_req, $time);
        assert (o_tx_sb_done_expected == o_tx_sb_done)
        else $display("ERROR: Expected o_tx_sb_done = %h, got %h, time %0t",
                      o_tx_sb_done_expected, o_tx_sb_done, $time);

        repeat (3) @(negedge i_clk);

        // rsp → advance to DATA_GENERATE (0x182)
        i_sb_tx_rsp    = 1;
        i_tx_decoding  = 'h189;

        o_tx_sb_done_expected  = 1;
        o_tx_encoding_expected = 'h18A;

        @(negedge i_clk);
        assert (o_tx_encoding_expected == o_tx_encoding)
        else $display("ERROR: Expected o_tx_encoding = %h, got %h, time %0t",
                      o_tx_encoding_expected, o_tx_encoding, $time);
        assert (o_tx_sb_done_expected == o_tx_sb_done)
        else $display("ERROR: Expected o_tx_sb_done = %h, got %h, time %0t",
                      o_tx_sb_done_expected, o_tx_sb_done, $time);

        i_sb_tx_rsp   = 0;
        i_tx_decoding = 0;
        o_tx_sb_done_expected = 0;

        @(negedge i_clk);
        assert (o_tx_sb_done_expected == o_tx_sb_done)
        else $display("ERROR: Expected o_tx_sb_done = %h, got %h, time %0t",
                      o_tx_sb_done_expected, o_tx_sb_done, $time);

        // --- DATA_GENERATE (0x182): wait then assert i_tx_done ---
        repeat (4) @(negedge i_clk);
        i_tx_done = 1;

        // → advance to RESULT_HANDSHAKE (0x183)
        o_tx_encoding_expected = 'h18B;

        @(negedge i_clk);
        i_tx_done = 0;
        assert (o_tx_encoding_expected == o_tx_encoding)
        else $display("ERROR: Expected o_tx_encoding = %h, got %h, time %0t",
                      o_tx_encoding_expected, o_tx_encoding, $time);
        
        i_sb_tx_done         = 0;
        o_tx_sb_req_expected   = 1;

        @(negedge i_clk);
        assert (o_tx_sb_req_expected == o_tx_sb_req)
        else $display("ERROR: Expected o_tx_sb_req = %h, got %h, time %0t",
                      o_tx_sb_req_expected, o_tx_sb_req, $time);

        // --- RESULT_HANDSHAKE (0x183) ---
        // done_ack → deassert req
        i_sb_tx_done         = 1;

        o_tx_sb_req_expected = 0;
        @(negedge i_clk);
        i_sb_tx_done = 0;
        assert (o_tx_sb_req_expected == o_tx_sb_req)
        else $display("ERROR: Expected o_tx_sb_req = %h, got %h, time %0t",
                      o_tx_sb_req_expected, o_tx_sb_req, $time);

        repeat (2) @(negedge i_clk);

        // rsp + all-1s data → PASS → advance to END_HANDSHAKE (0x184)
        i_sb_tx_rsp    = 1;
        i_tx_decoding  = 'h18B;
        i_tx_data      = {DATA_WIDTH{1'b1}};   // all 1s = test pass

        o_tx_sb_done_expected  = 1;
        o_tx_encoding_expected = 'h18C;
        o_tx_data_expected     = i_tx_sweep_result;

        @(negedge i_clk);
        assert (o_tx_encoding_expected == o_tx_encoding)
        else $display("ERROR: Expected o_tx_encoding = %h, got %h, time %0t",
                      o_tx_encoding_expected, o_tx_encoding, $time);
        assert (o_tx_sb_done_expected == o_tx_sb_done)
        else $display("ERROR: Expected o_tx_sb_done = %h, got %h, time %0t",
                      o_tx_sb_done_expected, o_tx_sb_done, $time);

        i_sb_tx_rsp   = 0;
        i_sb_tx_done         = 0;
        o_tx_sb_req_expected   = 1;

        @(negedge i_clk);
        assert (o_tx_sb_req_expected == o_tx_sb_req)
        else $display("ERROR: Expected o_tx_sb_req = %h, got %h, time %0t",
                      o_tx_sb_req_expected, o_tx_sb_req, $time);

        // --- END_HANDSHAKE (0x184) ---
        // done_ack → deassert req
        i_sb_tx_done         = 1;
        o_tx_sb_req_expected = 0;
        o_tx_sb_done_expected = 0;
        @(negedge i_clk);
        i_sb_tx_done = 0;
        assert (o_tx_sb_req_expected == o_tx_sb_req)
        else $display("ERROR: Expected o_tx_sb_req = %h, got %h, time %0t",
                      o_tx_sb_req_expected, o_tx_sb_req, $time);
        assert (o_tx_sb_done_expected == o_tx_sb_done)
        else $display("ERROR: Expected o_tx_sb_done = %h, got %h, time %0t",
                      o_tx_sb_done_expected, o_tx_sb_done, $time);

        repeat (2) @(negedge i_clk);

        // rsp → clock_to_test_done → LTSM substate 1 finishes → substate 2
        i_sb_tx_req   = 1;
        i_tx_decoding = 'h18D;

        o_tx_sb_done_expected  = 1;
        o_tx_encoding_expected = 'h18D;

        @(negedge i_clk);
        assert (o_tx_encoding_expected == o_tx_encoding)
        else $display("ERROR: Expected o_tx_encoding = %h, got %h, time %0t",
                      o_tx_encoding_expected, o_tx_encoding, $time);
        assert (o_tx_sb_done_expected == o_tx_sb_done)
        else $display("ERROR: Expected o_tx_sb_done = %h, got %h, time %0t",
                      o_tx_sb_done_expected, o_tx_sb_done, $time);

        i_sb_tx_done   = 0;
        i_tx_decoding = 0;

        o_tx_sb_rsp_expected   = 1;
        o_tx_sb_done_expected = 1;

        @(negedge i_clk);
        assert (o_tx_sb_rsp_expected == o_tx_sb_rsp)
        else $display("ERROR: Expected o_tx_sb_rsp = %h, got %h, time %0t",
                      o_tx_sb_rsp_expected, o_tx_sb_rsp, $time);
        assert (o_tx_sb_done_expected == o_tx_sb_done)
        else $display("ERROR: Expected o_tx_sb_done = %h, got %h, time %0t",
                      o_tx_sb_done_expected, o_tx_sb_done, $time);

        i_sb_tx_done   = 1;
        i_sb_tx_req = 0;
        i_tx_decoding  = 'h18D;

        @(negedge i_clk);

        i_sb_tx_done   = 0;

        repeat (2) @(negedge i_clk);

        $display("INFO  [eye_sweep] eye-sweep complete at %0t", $time);
    end
endtask

// -----------------------------------------------------------------------
// Shared defaults / init
// -----------------------------------------------------------------------
task automatic init_signals;
    begin
        i_reset          = 1;
        init_train_en    = 0;
        i_tx_decoding    = 0;
        i_tx_data        = 0;
        i_tx_info        = 0;
        i_tx_sweep_result = 0;
        i_sb_tx_req      = 0;
        i_sb_tx_rsp      = 0;
        i_sb_tx_done     = 0;
        i_tx_done        = 0;
        timeout          = 0;
        o_rx_sb_rsp      = 0;
        o_pl_speedmode   = 3'b001;  // some default speed mode
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

    // Enable the LTSM state machine
    init_train_en = 1;
    @(negedge i_clk);

    // ===================================================================
    // TEST 1: VALVREF State — Substate 0 (REQ handshake at encoding 0x80)
    // ===================================================================
    // After reset+init_train_en, CS=VALVREF, substate=0
    // DUT should assert o_tx_sb_req=1 with o_tx_encoding=0x80
    // ===================================================================
    $display("=== TEST 1: VALVREF substate-0 req handshake (enc=0x80) ===");

    o_tx_encoding_expected = 'h80;
    o_tx_sb_req_expected   = 1;

    @(negedge i_clk);
    assert (o_tx_encoding_expected == o_tx_encoding)
    else $display("ERROR: Expected o_tx_encoding = %h, got %h, time %0t",
                  o_tx_encoding_expected, o_tx_encoding, $time);
    assert (o_tx_sb_req_expected == o_tx_sb_req)
    else $display("ERROR: Expected o_tx_sb_req = %h, got %h, time %0t",
                  o_tx_sb_req_expected, o_tx_sb_req, $time);

    // Send done → DUT deasserts req
    i_sb_tx_done         = 1;
    o_tx_sb_req_expected = 0;
    @(negedge i_clk);
    i_sb_tx_done = 0;
    assert (o_tx_sb_req_expected == o_tx_sb_req)
    else $display("ERROR: Expected o_tx_sb_req = %h, got %h, time %0t",
                  o_tx_sb_req_expected, o_tx_sb_req, $time);

    repeat (2) @(negedge i_clk);

    // Send rsp with matching decoding → advance to substate 1 (eye sweep)
    // o_tx_sb_done should pulse on this edge
    i_sb_tx_rsp    = 1;
    i_tx_decoding  = 'h80;
    o_tx_sb_done_expected = 1;

    @(negedge i_clk);
    assert (o_tx_sb_done_expected == o_tx_sb_done)
    else $display("ERROR: Expected o_tx_sb_done = %h, got %h, time %0t",
                  o_tx_sb_done_expected, o_tx_sb_done, $time);

    i_sb_tx_rsp   = 0;
    i_tx_decoding = 0;
    o_tx_sb_done_expected = 1;

    i_sb_tx_req    = 1;
    i_tx_decoding  = 'h188;

    @(negedge i_clk);
    assert (o_tx_sb_done_expected == o_tx_sb_done)
    else $display("ERROR: Expected o_tx_sb_done = %h, got %h, time %0t",
                  o_tx_sb_done_expected, o_tx_sb_done, $time);

    $display("PASS  TEST 1: VALVREF sub0 handshake");

    // ===================================================================
    // TEST 2: VALVREF — Substate 1 (eye-sweep sub-sequence, no_retry=0)
    //         DUT is now proxying the eye-sweep module outputs
    // ===================================================================
    $display("=== TEST 2: VALVREF substate-1 eye-sweep sequence ===");

    do_eye_sweep_happy_pass();

    $display("PASS  TEST 2: VALVREF sub1 eye-sweep");

    // ===================================================================
    // TEST 3: VALVREF — Substate 2 (completion req at encoding 0x82)
    //         After eye-sweep done, LTSM moves to substate 2
    // ===================================================================
    $display("=== TEST 3: VALVREF substate-2 completion handshake (enc=0x82) ===");

    do_req_hs('h82);

    // State-level exit: both rsp_sent and rsp_received must fire for
    // previous_state_done to assert and NS to advance to DATAVREF
    do_state_exit_hs('h82);

    $display("PASS  TEST 3: VALVREF sub2 completion handshake");

    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 4: DATAVREF State — Full 3-substate walk
    //         Sub0: 0x88, Sub1: eye-sweep, Sub2: 0x8A
    // ===================================================================
    $display("=== TEST 4: DATAVREF full walk (0x88 → eye_sweep → 0x8A) ===");

    do_req_hs('h88);
    do_eye_sweep_happy_pass();
    do_req_hs('h8A);
    do_state_exit_hs('h8A);

    $display("PASS  TEST 4: DATAVREF");

    // ===================================================================
    // TEST 5: SPEEDIDLE State
    //         Sub0: 0xC8 — speed mode match check (o_pl_speedmode must be non-zero)
    //         Sub1: 0xCA
    // ===================================================================
    $display("=== TEST 5: SPEEDIDLE (0xC8 speed-match → 0xCA) ===");

    // --- Sub0: encoding 0xC8, speed mode must match o_pl_speedmode to avoid train error ---
    o_tx_encoding_expected = 'hC8;

    @(negedge i_clk);
    assert (o_tx_encoding_expected == o_tx_encoding)
    else $display("ERROR: Expected o_tx_encoding = %h, got %h, time %0t",
                  o_tx_encoding_expected, o_tx_encoding, $time);

    // done_ack
    o_pl_speedmode = 1;

    // --- Sub1: encoding 0xCA ---
    do_req_hs('hCA);
    do_state_exit_hs('hCA);

    $display("PASS  TEST 5: SPEEDIDLE");

    // ===================================================================
    // TEST 8: TXSELFCAL State — Two-substate walk (no eye-sweep)
    //         Sub0: 0xD0 (wait for i_tx_done), Sub1: 0xD1
    // ===================================================================
    $display("=== TEST 8: TXSELFCAL (0xD0 → 0xD1) ===");

    // --- Sub0: encoding 0xD0, wait for i_tx_done (self-calibration complete) ---
    o_tx_encoding_expected = 'hD0;

    @(negedge i_clk);
    assert (o_tx_encoding_expected == o_tx_encoding)
    else $display("ERROR: Expected o_tx_encoding = %h, got %h, time %0t",
                  o_tx_encoding_expected, o_tx_encoding, $time);

    i_tx_done = 1;

    // --- Sub1: encoding 0xD1 ---
    do_req_hs('hD1);
    do_state_exit_hs('hD1);

    $display("PASS  TEST 8: TXSELFCAL");

    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 9: RXCLKCAL State — Sub0(0x90) + eye-sweep with init=1 + Sub2(0x92)
    //         The key difference: eye-sweep init=1 sends encoding 0x180 with
    //         o_tx_info = ERROR_THRESHOLD (passed to RX)
    // ===================================================================
    $display("=== TEST 9: RXCLKCAL (0x90 → eye_sweep[init=1] → 0x92) ===");

    do_req_hs('h98);
    
    do_req_hs('h9A);
    do_state_exit_hs('h9A);

    $display("PASS  TEST 9: RXCLKCAL");

    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 11: VALTRAINCENTER State — Full 3-substate walk
    //          Sub0: 0xA0, Sub1: eye-sweep, Sub2: 0xA2
    // ===================================================================
    do_req_hs('hA0);
    do_eye_sweep_happy_pass();
    do_req_hs('hA2);
    do_state_exit_hs('hA2);

    $display("PASS  TEST 11: VALTRAINCENTER");
    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 12: VALTRAINVREF State — Full 3-substate walk
    //          Sub0: 0xE8, Sub1: eye-sweep, Sub2: 0xEA
    // ===================================================================
    do_req_hs('hE8);
    do_eye_sweep_happy_pass();
    do_req_hs('hEA);
    do_state_exit_hs('hEA);

    $display("PASS  TEST 12: VALTRAINVREF");
    repeat (3) @(negedge i_clk);
    
    // ===================================================================
    // TEST 13: DATATRAINCENTER1 State — Full 3-substate walk
    //          Sub0: 0x90, Sub1: eye-sweep (no_retry=1), Sub2: 0x92
    // ===================================================================
    do_req_hs('h90);
    do_eye_sweep_happy_pass();
    do_req_hs('h92);
    do_state_exit_hs('h92);

    $display("PASS  TEST 13: DATATRAINCENTER1");
    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 14: DATATRAINVREF State — Full 3-substate walk
    //          Sub0: 0xF0, Sub1: eye-sweep, Sub2: 0xF2
    // ===================================================================
    do_req_hs('hF0);
    do_eye_sweep_happy_pass();
    do_req_hs('hF2);
    do_state_exit_hs('hF2);

    $display("PASS  TEST 14: DATATRAINVREF");
    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 10: RXDESKEW State — Two-substate walk (no eye-sweep)
    //          Sub0: 0xA8, Sub1: 0xAC
    // ===================================================================
    $display("=== TEST 10: RXDESKEW (0xA8 → 0xAC) ===");

    do_req_hs('hA8);
    do_req_hs('hAC);
    do_state_exit_hs('hAC);

    $display("PASS  TEST 10: RXDESKEW");

    repeat (3) @(negedge i_clk);

    // ===================================================================
    // TEST 11: DATATRAINCENTER2 — Sub0(0xB0) + eye-sweep[no_retry=1] + Sub2(0xB2)
    //          On completion: train_active_en=1, NS=VALVREF
    // ===================================================================
    $display("=== TEST 11: DATATRAINCENTER2 (0xB0 → eye_sweep[no_retry] → 0xB2) ===");

    do_req_hs('hB0);
    do_eye_sweep_happy_pass();
    do_req_hs('hB2);
    do_state_exit_hs('hB2);

    // Completion: previous_state_done → train_active_en=1 and NS=VALVREF
    train_active_en_expected = 1;

    @(negedge i_clk);
    assert (train_active_en_expected == train_active_en)
    else $display("ERROR: Expected train_active_en = %h, got %h, time %0t",
                  train_active_en_expected, train_active_en, $time);

    $display("PASS  TEST 11: DATATRAINCENTER2 → train_active_en → back to VALVREF");

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