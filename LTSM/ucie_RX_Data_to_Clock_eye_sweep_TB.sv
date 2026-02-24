module ucie_RX_Data_to_Clock_eye_sweep_TB ();

parameter DECODING_WIDTH = 9;   // Width of command decoding input
parameter DATA_WIDTH = 64;       // Width of data input/output
parameter INFO_WIDTH = 16;      // Width of info/control output
parameter ERROR_THRESHOLD = 1;   // Error threshold for test pass/fail

//Signal interface
logic i_clk;
logic i_reset;
logic [DECODING_WIDTH-1:0] i_xx_decoding;
logic [DATA_WIDTH-1:0] i_xx_data;
logic i_sb_xx_req;
logic i_sb_xx_rsp;
logic i_sb_xx_done;
logic i_xx_done;
logic done_ack;
logic init;
logic no_retry;
logic result;
logic [DECODING_WIDTH-1:0] o_xx_encoding;
logic [DATA_WIDTH-1:0] o_xx_data;
logic [INFO_WIDTH-1:0] o_xx_info;
logic [7:0] o_xx_sweep_result;
logic o_xx_sb_req;
logic o_xx_sb_rsp;
logic o_xx_sb_done;
logic train_error;
logic failed_test;
logic done;

// Expected output signals for verification
logic [DECODING_WIDTH-1:0] o_xx_encoding_expected;
logic [DATA_WIDTH-1:0] o_xx_data_expected;
logic [INFO_WIDTH-1:0] o_xx_info_expected;
logic [7:0] o_xx_sweep_result_expected;
logic o_xx_sb_req_expected;
logic o_xx_sb_rsp_expected;
logic o_xx_sb_done_expected;
logic train_error_expected;
logic failed_test_expected;
logic done_expected;

//module instantiation
ucie_RX_Data_to_Clock_eye_sweep #(
    .DECODING_WIDTH(DECODING_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .INFO_WIDTH(INFO_WIDTH),
    .ERROR_THRESHOLD(ERROR_THRESHOLD)
) ucie_RX_Data_to_Clock_eye_sweep_DUT (
   .i_clk(i_clk),
   .i_reset(i_reset),
   .i_xx_decoding(i_xx_decoding),
   .i_xx_data(i_xx_data),
   .i_sb_xx_req(i_sb_xx_req),  
   .i_sb_xx_rsp(i_sb_xx_rsp),   
   .i_sb_xx_done(i_sb_xx_done), 
   .i_xx_done(i_xx_done),      
   .done_ack(done_ack),        
   .init(init),         
   .no_retry(no_retry),       
   .result(result),       
   .o_xx_encoding(o_xx_encoding), 
   .o_xx_data(o_xx_data),        
   .o_xx_info(o_xx_info),         
   .o_xx_sweep_result(o_xx_sweep_result),         
   .o_xx_sb_req(o_xx_sb_req),
   .o_xx_sb_rsp(o_xx_sb_rsp),   
   .train_error(train_error),  
   .failed_test(failed_test),
   .done(done)        
);

initial begin
    i_clk = 0;
    forever #5 i_clk = ~i_clk; // 100MHz clock
end

initial begin
    // Initialize all inputs
    i_sb_xx_req  = 0;
    i_sb_xx_rsp  = 0;
    i_sb_xx_done = 0;
    i_xx_done    = 0;
    done_ack     = 0;
    i_xx_decoding = 0;
    i_xx_data    = 0;
    result       = 1; // default: pass

    // =========================================================================
    // TEST 1: init=1, no_retry=1 (happy path, no retry)
    // RX init-mode sequence:
    //   REQ_HANDSHAKE  (0x180): o_xx_sb_req=1,  transition on i_sb_xx_rsp  && dec==0x180
    //   LFSR_HANDSHAKE (0x181): o_xx_sb_rsp=1,  transition on i_sb_xx_done && dec==0x181
    //   DATA_DETECTION (0x182): no sideband out, transition on i_xx_done
    //   RESULT_HANDSHAKE(0x183):o_xx_sb_rsp=1,  transition on i_sb_xx_rsp  && dec==0x183
    //   SWEEP_RESULT   (0x184): no sideband out, transition on i_sb_xx_done && dec==0x184
    //   END_HANDSHAKE  (0x185): o_xx_sb_req=1,  transition on i_sb_xx_rsp  && dec==0x185
    // =========================================================================
    init = 1;
    i_reset = 1;
    no_retry = 1;
    @(negedge i_clk);
    i_reset = 0;

    // --- REQ_HANDSHAKE (encoding 0x180) ---
    // RX init: o_xx_sb_req=1 unconditionally (same as TX)
    o_xx_encoding_expected = 'h185;
    o_xx_sb_req_expected   = 1;
    o_xx_info_expected     = ERROR_THRESHOLD;
    o_xx_sb_done_expected  = 0;

    @(negedge i_clk);
    assert (o_xx_encoding_expected == o_xx_encoding)
    else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
    assert (o_xx_sb_req_expected == o_xx_sb_req)
    else $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);
    assert (o_xx_info_expected == o_xx_info)
    else $display("ERROR: Expected o_xx_info = %h, got %h, time %0t", o_xx_info_expected, o_xx_info, $time);
    

    done_ack = 1; // clear req
    o_xx_sb_req_expected = 0;

    @(negedge i_clk);
    assert (o_xx_sb_req_expected == o_xx_sb_req)
    else $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);

    repeat (3) @(negedge i_clk);

    // Trigger REQ→LFSR + immediately check LFSR_HANDSHAKE outputs
    // i_sb_xx_rsp=1 : REQ→LFSR transition trigger AND fires o_xx_sb_done
    // i_sb_xx_req=1 : drives o_xx_sb_rsp=1 in LFSR state (combinational, after CS changes)
    i_sb_xx_rsp = 0;
    i_sb_xx_req = 1;
    done_ack    = 0;
    i_xx_decoding = 'h186;

    // --- LFSR_HANDSHAKE (encoding 0x181) ---
    // RX init: output is o_xx_sb_rsp (NOT req) when i_sb_xx_req=1
    // o_xx_sb_done fires from i_sb_xx_rsp (the REQ→LFSR edge)
    o_xx_sb_done_expected  = 1;
    o_xx_encoding_expected = 'h186;
    o_xx_sb_rsp_expected   = 1;

    @(negedge i_clk);
    assert (o_xx_encoding_expected == o_xx_encoding)
    else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
    assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
    else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);
    

    i_sb_xx_rsp = 0;
    i_sb_xx_req = 0;
    o_xx_sb_rsp_expected  = 1;
    o_xx_sb_done_expected = 0;

    @(negedge i_clk);
    assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
    else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);
    
    // Trigger LFSR→DATA
    // RX init LFSR: transition is i_sb_xx_done && dec==0x181 (NOT i_sb_xx_rsp)
    // NOTE: i_sb_xx_done does NOT trigger o_xx_sb_done, so o_xx_sb_done=0 in DATA
    repeat (5) @(negedge i_clk);
    i_sb_xx_done  = 1;
    done_ack      = 1;
    i_sb_xx_req = 0;
    i_xx_decoding = 'h186;

    // --- DATA_DETECTION (encoding 0x182) ---
    o_xx_encoding_expected = 'h187;
    o_xx_sb_done_expected  = 0; // i_sb_xx_done does NOT fire o_xx_sb_done

    @(negedge i_clk);
    assert (o_xx_encoding_expected == o_xx_encoding)
    else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
    
    i_sb_xx_req    = 1;
    i_xx_decoding = 'h188;

    // --- RESULT_HANDSHAKE (encoding 0x183) ---
    // RX init: o_xx_sb_rsp=1 (when i_sb_xx_req), NOT o_xx_sb_req
    // result=1 → failed_test=0 → will transition to SWEEP_RESULT (not END directly)
    o_xx_encoding_expected = 'h188;

    @(negedge i_clk);
    assert (o_xx_encoding_expected == o_xx_encoding)
    else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);

    done_ack    = 0;
    i_xx_done   = 0;
    i_sb_xx_req = 0;
    o_xx_sb_rsp_expected = 1;

    @(negedge i_clk);
    assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
    else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);

    // Trigger RESULT→SWEEP_RESULT (pass)
    // i_sb_xx_rsp=1 && dec==0x183 triggers transition (same as TX)
    // i_sb_xx_req=1 drives o_xx_sb_rsp in RESULT before transition fires
    @(negedge i_clk);

    o_xx_sb_rsp_expected   = 1; // from i_sb_xx_req in RESULT state

    @(negedge i_clk);
    assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
    else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);
    
    
    i_sb_xx_done   = 1;
    i_sb_xx_req = 1;
    done_ack      = 1;
    i_xx_decoding = 'h189;

    // RX: failed_test = !(&result) = !result (1-bit)
    failed_test_expected  = !result; // 0

    @(negedge i_clk);
    assert (failed_test_expected == failed_test)
    else $display("ERROR: Expected failed_test = %h, got %h, time %0t", failed_test_expected, failed_test, $time);

    // --- SWEEP_RESULT_HANDSHAKE (encoding 0x184) ---
    // RX: no req/rsp output; captures o_xx_sweep_result = i_xx_data[7:0]
    // Transition: i_sb_xx_done && dec==0x184
    i_sb_xx_done = 0;
    i_sb_xx_req = 0;
    i_xx_data = 'hAB; // sweep data → o_xx_sweep_result should latch 0xAB
    o_xx_encoding_expected = 'h190;

    o_xx_sb_done_expected = 0; // self-clears
    o_xx_sweep_result_expected = i_xx_data[7:0];

    @(negedge i_clk);
    assert (o_xx_sweep_result_expected == o_xx_sweep_result)
    else $display("ERROR: Expected o_xx_sweep_result = %h, got %h, time %0t", o_xx_sweep_result_expected, o_xx_sweep_result, $time);
    assert (o_xx_encoding_expected == o_xx_encoding)
    else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);

    // --- END_HANDSHAKE (encoding 0x185) ---
    // RX init: o_xx_sb_req=1 (same pattern as REQ_HANDSHAKE)
    // Transition: i_sb_xx_rsp && dec==0x18
    i_sb_xx_done = 0;
    done_ack = 0;
    o_xx_sb_req_expected = 1;

    @(negedge i_clk);
    assert (o_xx_sb_req_expected == o_xx_sb_req)
    else $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);

    // Trigger END→done
    repeat (5) @(negedge i_clk);
    i_sb_xx_rsp   = 1;
    done_ack      = 0;
    i_xx_decoding = 'h190;

    done_expected = 1;

    @(negedge i_clk);
    i_sb_xx_rsp = 0;
    assert (done_expected == done)
    else $display("ERROR: Expected done = %h, got %h, time %0t", done_expected, done, $time);

    // =========================================================================
    // TEST 2: init=1, no_retry=0 (retry path — 2 retries via req+dec, then pass)
    //
    // Key design changes from old to new (init=1 mode):
    //   DATA_DETECTION  : transitions on i_sb_xx_req && dec==0x188 (NOT i_xx_done)
    //   LFSR_HANDSHAKE  : o_xx_sb_rsp=1 always when !done_ack (NOT req-gated)
    //   RESULT_HANDSHAKE: o_xx_sb_rsp=1 always when !done_ack (NOT req-gated)
    //   retry path      : triggered externally by i_sb_xx_req && dec==0x186
    //   pass path       : triggered externally by i_sb_xx_req && dec==0x189
    //   SWEEP_RESULT    : immediate transition (no wait signal)
    //   train_error     : removed from init=1 mode; retry/pass fully TB-controlled
    //
    // Sequence:
    //   REQ_HANDSHAKE → LFSR_HANDSHAKE → DATA_DETECTION → RESULT_HANDSHAKE
    //   [repeat 2: RESULT→LFSR(retry)→DATA→RESULT]
    //   RESULT→SWEEP_RESULT(pass) → END_HANDSHAKE → done=1
    // =========================================================================
    init     = 1;
    i_reset  = 1;
    no_retry = 0;
    result   = 1;
    i_sb_xx_rsp  = 0;
    i_sb_xx_req  = 0;
    i_sb_xx_done = 0;
    i_xx_done    = 0;
    done_ack     = 0;
    @(negedge i_clk);
    i_reset = 0;

    // --- REQ_HANDSHAKE (encoding 0x185) ---
    // DUT asserts o_xx_sb_req=1; done_ack clears it;
    // TB sends i_sb_xx_req=1 && dec==0x186 to trigger REQ→LFSR transition
    o_xx_encoding_expected = 'h185;
    o_xx_sb_req_expected   = 1;
    o_xx_info_expected     = ERROR_THRESHOLD;

    @(negedge i_clk);
    assert (o_xx_encoding_expected == o_xx_encoding)
    else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
    assert (o_xx_sb_req_expected == o_xx_sb_req)
    else $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);
    assert (o_xx_info_expected == o_xx_info)
    else $display("ERROR: Expected o_xx_info = %h, got %h, time %0t", o_xx_info_expected, o_xx_info, $time);

    // done_ack → clears req
    done_ack             = 1;
    o_xx_sb_req_expected = 0;

    @(negedge i_clk);
    assert (o_xx_sb_req_expected == o_xx_sb_req)
    else $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);

    repeat (3) @(negedge i_clk);

    // Trigger REQ→LFSR: i_sb_xx_req=1 && dec==0x186
    i_sb_xx_req   = 1;
    done_ack      = 0;
    i_xx_decoding = 'h186;

    // --- LFSR_HANDSHAKE (encoding 0x186) ---
    // NEW: o_xx_sb_rsp=1 immediately (not req-gated); done_ack clears it
    o_xx_encoding_expected = 'h186;
    o_xx_sb_rsp_expected   = 1;  // asserted unconditionally while !done_ack

    @(negedge i_clk);
    i_sb_xx_req   = 0;
    i_xx_decoding = 0;
    assert (o_xx_encoding_expected == o_xx_encoding)
    else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
    assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
    else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);

    // done_ack → clears rsp
    done_ack             = 1;
    o_xx_sb_rsp_expected = 0;

    @(negedge i_clk);
    assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
    else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);

    // Trigger LFSR→DATA: i_sb_xx_done=1 (no decoding check in new design)
    repeat (3) @(negedge i_clk);
    i_sb_xx_done  = 1;
    done_ack      = 0;

    // =========================================================================
    // Retry loop x2: DATA_DETECTION → RESULT_HANDSHAKE → retry → LFSR_HANDSHAKE
    // =========================================================================
    repeat (2) begin

        // --- DATA_DETECTION (encoding 0x187) ---
        // NEW: transition triggered by i_sb_xx_req && dec==0x188 (NOT i_xx_done)
        o_xx_encoding_expected = 'h187;

        @(negedge i_clk);
        i_sb_xx_done = 0;
        assert (o_xx_encoding_expected == o_xx_encoding)
        else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);

        // TB drives req + dec==0x188 → DATA→RESULT transition (combinational this cycle)
        i_sb_xx_req   = 1;
        i_xx_decoding = 'h188;

        // --- RESULT_HANDSHAKE (encoding 0x188) ---
        // NEW: o_xx_sb_rsp=1 immediately when !done_ack (not req-gated)
        o_xx_encoding_expected = 'h188;
        o_xx_sb_rsp_expected   = 1;

        @(negedge i_clk);
        i_sb_xx_req   = 0;
        i_xx_decoding = 0;
        assert (o_xx_encoding_expected == o_xx_encoding)
        else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
        assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
        else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);

        // done_ack → clears rsp
        done_ack             = 1;
        o_xx_sb_rsp_expected = 0;

        @(negedge i_clk);
        assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
        else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);

        // Trigger RESULT→LFSR (retry): i_sb_xx_req=1 && dec==0x186
        // (retry/pass decision is fully TB-driven; no internal failed_test/no_retry logic)
        done_ack      = 0;
        i_sb_xx_req   = 1;
        i_xx_decoding = 'h186;

        o_xx_encoding_expected = 'h186;  // DUT back in LFSR_HANDSHAKE

        @(negedge i_clk);
        i_sb_xx_req   = 0;
        i_xx_decoding = 0;
        assert (o_xx_encoding_expected == o_xx_encoding)
        else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);

        // --- LFSR_HANDSHAKE (retry, encoding 0x186) ---
        // NEW: rsp=1 immediately while !done_ack; no req needed
        o_xx_sb_rsp_expected = 1;

        @(negedge i_clk);
        assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
        else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);

        // done_ack → clears rsp
        done_ack             = 1;
        o_xx_sb_rsp_expected = 0;

        @(negedge i_clk);
        assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
        else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);

        // Trigger LFSR→DATA: i_sb_xx_done=1
        repeat (3) @(negedge i_clk);
        i_sb_xx_done = 1;
        done_ack     = 0;

    end // repeat (2) retry loop

    // =========================================================================
    // Final DATA_DETECTION → RESULT_HANDSHAKE → PASS → SWEEP_RESULT → END
    // =========================================================================

    // --- Final DATA_DETECTION (encoding 0x187) ---
    o_xx_encoding_expected = 'h187;

    @(negedge i_clk);
    i_sb_xx_done = 0;
    assert (o_xx_encoding_expected == o_xx_encoding)
    else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);

    // Trigger DATA→RESULT: i_sb_xx_req=1 && dec==0x188
    i_sb_xx_req   = 1;
    i_xx_decoding = 'h188;

    // --- Final RESULT_HANDSHAKE (encoding 0x188, pass) ---
    // rsp=1 immediately (done_ack=0)
    o_xx_encoding_expected = 'h188;
    o_xx_sb_rsp_expected   = 1;

    @(negedge i_clk);
    i_sb_xx_req   = 0;
    i_xx_decoding = 0;
    assert (o_xx_encoding_expected == o_xx_encoding)
    else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
    assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
    else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);

    // done_ack → clears rsp
    done_ack             = 1;
    o_xx_sb_rsp_expected = 0;

    @(negedge i_clk);
    assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
    else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);

    // Trigger RESULT→SWEEP_RESULT (pass): i_sb_xx_req=1 && dec==0x189
    done_ack      = 0;
    i_sb_xx_req   = 1;
    i_xx_decoding = 'h189;
    i_xx_data     = 64'hAB; // sweep data captured into o_xx_sweep_result[7:0]

    // --- SWEEP_RESULT_HANDSHAKE (encoding 0x189) ---
    // NEW: immediate transition (NS=END_HANDSHAKE unconditionally, no wait)
    // DUT latches o_xx_sweep_result = i_xx_data[7:0] and moves to END_HANDSHAKE
    o_xx_encoding_expected      = 'h189;
    o_xx_sweep_result_expected  = i_xx_data[7:0]; // 0xAB

    @(negedge i_clk);
    i_sb_xx_req   = 0;
    i_xx_decoding = 0;
    assert (o_xx_sweep_result_expected == o_xx_sweep_result)
    else $display("ERROR: Expected o_xx_sweep_result = %h, got %h, time %0t", o_xx_sweep_result_expected, o_xx_sweep_result, $time);

    // --- END_HANDSHAKE (encoding 0x190) ---
    // SWEEP_RESULT is immediate, so END_HANDSHAKE starts next cycle
    // DUT asserts o_xx_sb_req=1; done_ack clears it;
    // TB sends i_sb_xx_rsp=1 && dec==0x190 → done=1
    done_ack             = 0;
    o_xx_encoding_expected = 'h190;
    o_xx_sb_req_expected   = 1;

    @(negedge i_clk);
    assert (o_xx_encoding_expected == o_xx_encoding)
    else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
    assert (o_xx_sb_req_expected == o_xx_sb_req)
    else $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);

    // done_ack → clears req
    done_ack             = 1;
    o_xx_sb_req_expected = 0;

    @(negedge i_clk);
    assert (o_xx_sb_req_expected == o_xx_sb_req)
    else $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);

    // Trigger END→done: i_sb_xx_rsp=1 && dec==0x190
    repeat (3) @(negedge i_clk);
    i_sb_xx_rsp   = 1;
    done_ack      = 0;
    i_xx_decoding = 'h190;

    done_expected = 1;

    @(negedge i_clk);
    i_sb_xx_rsp   = 0;
    i_xx_decoding = 0;
    assert (done_expected == done)
    else $display("ERROR: Expected done = %h, got %h, time %0t", done_expected, done, $time);

    $display("All tests completed");
    $finish;
end
    
endmodule