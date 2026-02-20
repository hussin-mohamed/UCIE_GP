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
   .o_xx_sb_done(o_xx_sb_done), 
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
    o_xx_encoding_expected = 'h180;
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
    assert (o_xx_sb_done_expected == o_xx_sb_done)
    else $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

    done_ack = 1; // clear req
    o_xx_sb_req_expected = 0;

    @(negedge i_clk);
    assert (o_xx_sb_req_expected == o_xx_sb_req)
    else $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);

    repeat (3) @(negedge i_clk);

    // Trigger REQ→LFSR + immediately check LFSR_HANDSHAKE outputs
    // i_sb_xx_rsp=1 : REQ→LFSR transition trigger AND fires o_xx_sb_done
    // i_sb_xx_req=1 : drives o_xx_sb_rsp=1 in LFSR state (combinational, after CS changes)
    i_sb_xx_rsp = 1;
    i_sb_xx_req = 1;
    done_ack    = 0;
    i_xx_decoding = 'h180;

    // --- LFSR_HANDSHAKE (encoding 0x181) ---
    // RX init: output is o_xx_sb_rsp (NOT req) when i_sb_xx_req=1
    // o_xx_sb_done fires from i_sb_xx_rsp (the REQ→LFSR edge)
    o_xx_sb_done_expected  = 1;
    o_xx_encoding_expected = 'h181;
    o_xx_sb_rsp_expected   = 1;

    @(negedge i_clk);
    assert (o_xx_encoding_expected == o_xx_encoding)
    else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
    assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
    else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);
    assert (o_xx_sb_done_expected == o_xx_sb_done)
    else $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

    i_sb_xx_rsp = 0;
    i_sb_xx_req = 0;
    o_xx_sb_rsp_expected  = 0;
    o_xx_sb_done_expected = 0;

    @(negedge i_clk);
    assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
    else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);
    assert (o_xx_sb_done_expected == o_xx_sb_done)
    else $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

    i_sb_xx_req = 1;

    o_xx_sb_rsp_expected  = 1;

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
    i_xx_decoding = 'h181;

    // --- DATA_DETECTION (encoding 0x182) ---
    o_xx_encoding_expected = 'h182;
    o_xx_sb_done_expected  = 0; // i_sb_xx_done does NOT fire o_xx_sb_done

    @(negedge i_clk);
    assert (o_xx_encoding_expected == o_xx_encoding)
    else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
    assert (o_xx_sb_done_expected == o_xx_sb_done)
    else $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

    i_sb_xx_done = 0;
    i_xx_done    = 0;

    @(negedge i_clk);
    assert (o_xx_sb_done_expected == o_xx_sb_done)
    else $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

    // Trigger DATA→RESULT via i_xx_done
    // Also drive i_sb_xx_req now so o_xx_sb_rsp=1 is visible on that same negedge
    @(negedge i_clk);
    i_xx_done    = 1;
    i_sb_xx_req = 0;

    // --- RESULT_HANDSHAKE (encoding 0x183) ---
    // RX init: o_xx_sb_rsp=1 (when i_sb_xx_req), NOT o_xx_sb_req
    // result=1 → failed_test=0 → will transition to SWEEP_RESULT (not END directly)
    o_xx_encoding_expected = 'h183;

    @(negedge i_clk);
    assert (o_xx_encoding_expected == o_xx_encoding)
    else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);

    done_ack    = 0;
    i_xx_done   = 0;
    i_sb_xx_req = 0;
    o_xx_sb_rsp_expected = 0;

    @(negedge i_clk);
    assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
    else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);

    // Trigger RESULT→SWEEP_RESULT (pass)
    // i_sb_xx_rsp=1 && dec==0x183 triggers transition (same as TX)
    // i_sb_xx_req=1 drives o_xx_sb_rsp in RESULT before transition fires
    @(negedge i_clk);
    i_sb_xx_req   = 1;

    o_xx_sb_rsp_expected   = 1; // from i_sb_xx_req in RESULT state
    o_xx_sb_done_expected = 1; // fires from i_sb_xx_rsp or i_sb_xx_req

    @(negedge i_clk);
    assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
    else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);
    assert (o_xx_sb_done_expected == o_xx_sb_done)
    else $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);
    
    i_sb_xx_done   = 1;
    i_sb_xx_req = 0;
    done_ack      = 1;
    i_xx_decoding = 'h183;
    result        = 'hFFFFFFFFFFFFFFFF; // pass → goes to SWEEP_RESULT, not LFSR

    // RX: failed_test = !(&result) = !result (1-bit)
    failed_test_expected  = !result; // 0
    
    o_xx_encoding_expected = 'h184; // SWEEP_RESULT_HANDSHAKE (check AFTER transition)
    // Note: in SWEEP_RESULT state there is no req/rsp output, so we don't check rsp here

    @(negedge i_clk);
    assert (o_xx_encoding_expected == o_xx_encoding)
    else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
    assert (failed_test_expected == failed_test)
    else $display("ERROR: Expected failed_test = %h, got %h, time %0t", failed_test_expected, failed_test, $time);

    // --- SWEEP_RESULT_HANDSHAKE (encoding 0x184) ---
    // RX: no req/rsp output; captures o_xx_sweep_result = i_xx_data[7:0]
    // Transition: i_sb_xx_done && dec==0x184
    i_sb_xx_done = 0;
    i_sb_xx_req = 0;
    i_xx_data = 'hAB; // sweep data → o_xx_sweep_result should latch 0xAB

    o_xx_sb_done_expected = 0; // self-clears
    o_xx_sweep_result_expected = i_xx_data[7:0];

    @(negedge i_clk);
    assert (o_xx_sb_done_expected == o_xx_sb_done)
    else $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

    assert (o_xx_sweep_result_expected == o_xx_sweep_result)
    else $display("ERROR: Expected o_xx_sweep_result = %h, got %h, time %0t", o_xx_sweep_result_expected, o_xx_sweep_result, $time);

    @(negedge i_clk);
    i_sb_xx_done  = 1;
    done_ack      = 0;
    i_xx_decoding = 'h184;

    // --- END_HANDSHAKE (encoding 0x185) ---
    // RX init: o_xx_sb_req=1 (same pattern as REQ_HANDSHAKE)
    // Transition: i_sb_xx_rsp && dec==0x185
    o_xx_encoding_expected = 'h185;

    @(negedge i_clk);
    assert (o_xx_encoding_expected == o_xx_encoding)
    else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);

    i_sb_xx_done = 0;
    o_xx_sb_req_expected = 1;

    @(negedge i_clk);
    assert (o_xx_sb_req_expected == o_xx_sb_req)
    else $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);

    // Trigger END→done
    repeat (5) @(negedge i_clk);
    i_sb_xx_rsp   = 1;
    done_ack      = 0;
    i_xx_decoding = 'h185;

    done_expected = 1;

    @(negedge i_clk);
    i_sb_xx_rsp = 0;
    assert (done_expected == done)
    else $display("ERROR: Expected done = %h, got %h, time %0t", done_expected, done, $time);

    // =========================================================================
    // TEST 2: init=1, no_retry=0 (retry enabled — fail MAXIMUM_ITERATIONS-1 times then train_error)
    // count increments each time LFSR_HANDSHAKE exits to DATA_DETECTION:
    //   count=1 after 1st LFSR: count(1) != MAXIMUM_ITERATIONS-1(3), retry
    //   count=2 after 2nd LFSR: count(2) != MAXIMUM_ITERATIONS-1(3), retry
    //   count=3 after 3rd LFSR: count(3) == MAXIMUM_ITERATIONS-1(3), train_error
    // repeat(2) covers the first two retries; the final check after the loop hits train_error
    // =========================================================================
    init    = 1;
    i_reset = 1;
    no_retry = 0;
    i_sb_xx_rsp  = 0;
    i_sb_xx_req  = 0;
    i_sb_xx_done = 0;
    i_xx_done    = 0;
    done_ack     = 0;
    @(negedge i_clk);
    i_reset = 0;

    // --- REQ_HANDSHAKE (encoding 0x180) ---
    o_xx_encoding_expected = 'h180;
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
    assert (o_xx_sb_done_expected == o_xx_sb_done)
    else $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

    done_ack = 1; // clear req
    o_xx_sb_req_expected = 0;

    @(negedge i_clk);
    assert (o_xx_sb_req_expected == o_xx_sb_req)
    else $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);

    repeat (3) @(negedge i_clk);

    // Trigger REQ→LFSR + check LFSR_HANDSHAKE outputs
    // i_sb_xx_rsp=1 : REQ→LFSR transition trigger AND fires o_xx_sb_done
    // i_sb_xx_req=1 : drives o_xx_sb_rsp=1 in LFSR state (combinational, after CS changes)
    i_sb_xx_rsp = 1;
    i_sb_xx_req = 1;
    done_ack    = 0;
    i_xx_decoding = 'h180;

    // --- LFSR_HANDSHAKE (encoding 0x181) ---
    // o_xx_sb_done fires from i_sb_xx_rsp (the REQ→LFSR edge)
    // o_xx_sb_rsp=1 because i_sb_xx_req=1
    o_xx_sb_done_expected  = 1;
    o_xx_encoding_expected = 'h181;
    o_xx_sb_rsp_expected   = 1;

    @(negedge i_clk);
    assert (o_xx_encoding_expected == o_xx_encoding)
    else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
    assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
    else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);
    assert (o_xx_sb_done_expected == o_xx_sb_done)
    else $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

    i_sb_xx_rsp = 0;
    i_sb_xx_req = 0;
    o_xx_sb_rsp_expected  = 0;
    o_xx_sb_done_expected = 0;

    @(negedge i_clk);
    assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
    else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);
    assert (o_xx_sb_done_expected == o_xx_sb_done)
    else $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

    i_sb_xx_req = 1;
    o_xx_sb_rsp_expected = 1;

    @(negedge i_clk);
    assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
    else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);

    // Trigger LFSR→DATA (initial, count: 0→1)
    // i_sb_xx_done && dec==0x181 : LFSR→DATA transition; i_sb_xx_done does NOT fire o_xx_sb_done
    repeat (5) @(negedge i_clk);
    i_sb_xx_done  = 1;
    done_ack      = 1;
    i_sb_xx_req   = 0;
    i_xx_decoding = 'h181;

    repeat (2) begin

        // --- DATA_DETECTION (encoding 0x182) ---
        // o_xx_sb_done=0 because i_sb_xx_done does NOT fire o_xx_sb_done
        o_xx_encoding_expected = 'h182;
        o_xx_sb_done_expected  = 0;

        @(negedge i_clk);
        assert (o_xx_encoding_expected == o_xx_encoding)
        else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
        assert (o_xx_sb_done_expected == o_xx_sb_done)
        else $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

        i_sb_xx_done = 0;
        i_xx_done    = 0;

        @(negedge i_clk);
        assert (o_xx_sb_done_expected == o_xx_sb_done)
        else $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

        // Trigger DATA→RESULT via i_xx_done
        @(negedge i_clk);
        i_xx_done   = 1;
        i_sb_xx_req = 0;

        // --- RESULT_HANDSHAKE (encoding 0x183, fail) ---
        // RX init: o_xx_sb_rsp=1 when i_sb_xx_req=1
        o_xx_encoding_expected = 'h183;

        @(negedge i_clk);
        assert (o_xx_encoding_expected == o_xx_encoding)
        else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);

        done_ack    = 0;
        i_xx_done   = 0;
        i_sb_xx_req = 0;
        o_xx_sb_rsp_expected = 0;

        @(negedge i_clk);
        assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
        else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);

        i_sb_xx_req           = 1;
        o_xx_sb_rsp_expected  = 1;
        o_xx_sb_done_expected = 1; // fires from i_sb_xx_req

        @(negedge i_clk);
        assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
        else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);
        assert (o_xx_sb_done_expected == o_xx_sb_done)
        else $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

        // Trigger RESULT→LFSR (fail, retry — count < MAXIMUM_ITERATIONS-1)
        // result=0 → failed_test=1; no_retry=0 → retry to LFSR_HANDSHAKE
        i_sb_xx_done  = 1;
        i_sb_xx_req   = 0;
        done_ack      = 1;
        i_xx_decoding = 'h183;
        result        = 0; // fail → retry

        failed_test_expected  = !result; // 1
        o_xx_encoding_expected = 'h181;  // retry → back to LFSR

        @(negedge i_clk);
        assert (o_xx_encoding_expected == o_xx_encoding)
        else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
        assert (failed_test_expected == failed_test)
        else $display("ERROR: Expected failed_test = %h, got %h, time %0t", failed_test_expected, failed_test, $time);

        // --- LFSR_HANDSHAKE (retry, encoding 0x181) ---
        // Entry: done_ack=1, i_sb_xx_req=0 → o_xx_sb_rsp=0, o_xx_sb_done=0 (self-cleared)
        // Drive i_sb_xx_req=1 to verify rsp handshake and fire o_xx_sb_done
        done_ack      = 0;
        i_sb_xx_done  = 0;
        i_sb_xx_req   = 1;
        o_xx_sb_rsp_expected  = 1;
        o_xx_sb_done_expected = 1; // fires from i_sb_xx_req

        @(negedge i_clk);
        assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
        else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);
        assert (o_xx_sb_done_expected == o_xx_sb_done)
        else $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

        i_sb_xx_req           = 0;
        o_xx_sb_rsp_expected  = 0;
        o_xx_sb_done_expected = 0;

        @(negedge i_clk);
        assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
        else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);
        assert (o_xx_sb_done_expected == o_xx_sb_done)
        else $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

        i_sb_xx_req          = 1;
        o_xx_sb_rsp_expected = 1;

        @(negedge i_clk);
        assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
        else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);

        // Trigger LFSR→DATA (count increments on each iteration)
        repeat (5) @(negedge i_clk);
        i_sb_xx_done  = 1;
        done_ack      = 1;
        i_sb_xx_req   = 0;
        i_xx_decoding = 'h181;
    end

    // --- Final DATA_DETECTION (encoding 0x182) ---
    // count==3 will be checked in the next RESULT_HANDSHAKE → train_error
    o_xx_encoding_expected = 'h182;
    o_xx_sb_done_expected  = 0;

    @(negedge i_clk);
    assert (o_xx_encoding_expected == o_xx_encoding)
    else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
    assert (o_xx_sb_done_expected == o_xx_sb_done)
    else $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

    i_sb_xx_done = 0;
    i_xx_done    = 0;

    @(negedge i_clk);
    assert (o_xx_sb_done_expected == o_xx_sb_done)
    else $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

    // Trigger DATA→RESULT via i_xx_done
    @(negedge i_clk);
    i_xx_done   = 1;
    i_sb_xx_req = 0;

    // --- Final RESULT_HANDSHAKE (encoding 0x183, train_error) ---
    // count==MAXIMUM_ITERATIONS-1(3): failed_test=1 + no_retry=0 → train_error instead of retry
    o_xx_encoding_expected = 'h183;

    @(negedge i_clk);
    assert (o_xx_encoding_expected == o_xx_encoding)
    else $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);

    done_ack    = 0;
    i_xx_done   = 0;
    i_sb_xx_req = 0;
    o_xx_sb_rsp_expected = 0;

    @(negedge i_clk);
    assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
    else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);

    i_sb_xx_req           = 1;
    o_xx_sb_rsp_expected  = 1;
    o_xx_sb_done_expected = 1; // fires from i_sb_xx_req

    @(negedge i_clk);
    assert (o_xx_sb_rsp_expected == o_xx_sb_rsp)
    else $display("ERROR: Expected o_xx_sb_rsp = %h, got %h, time %0t", o_xx_sb_rsp_expected, o_xx_sb_rsp, $time);
    assert (o_xx_sb_done_expected == o_xx_sb_done)
    else $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

    // Trigger final RESULT evaluation (count==MAXIMUM_ITERATIONS-1 → train_error, NS stays RESULT)
    // result=0 → failed_test=1; no_retry=0; count==3==MAXIMUM_ITERATIONS-1 → train_error=1
    i_sb_xx_done  = 1;
    i_sb_xx_req   = 0;
    done_ack      = 1;
    i_xx_decoding = 'h183;
    result        = 0; // fail → train_error (max retries reached)

    failed_test_expected = !result; // 1
    train_error_expected = 1;

    @(negedge i_clk);
    assert (train_error_expected == train_error)
    else $display("ERROR: Expected train_error = %h, got %h, time %0t", train_error_expected, train_error, $time);

    $display("Test completed");
    $finish;
end
    
endmodule