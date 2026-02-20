module ucie_TX_Data_to_Clock_eye_sweep_TB ();

parameter DECODING_WIDTH = 9;   // Width of command decoding input
parameter DATA_WIDTH = 64;       // Width of data input/output
parameter INFO_WIDTH = 16;      // Width of info/control output
parameter ERROR_THRESHOLD = 1;   // Error threshold for test pass/fail

//Signal interface
logic i_clk;
logic i_reset;
logic [DECODING_WIDTH-1:0] i_xx_decoding;
logic [DATA_WIDTH-1:0] i_xx_data;
logic [7:0] i_xx_sweep_result;
logic i_sb_xx_req;
logic i_sb_xx_rsp;
logic i_sb_xx_done;
logic i_xx_done;
logic done_ack;
logic init;
logic no_retry;
logic [DECODING_WIDTH-1:0] o_xx_encoding;
logic [DATA_WIDTH-1:0] o_xx_data;
logic [INFO_WIDTH-1:0] o_xx_info;
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
logic o_xx_sb_req_expected;
logic o_xx_sb_rsp_expected;
logic o_xx_sb_done_expected;
logic train_error_expected;
logic failed_test_expected;
logic done_expected;

//module instantiation
ucie_TX_Data_to_Clock_eye_sweep #(
    .DECODING_WIDTH(DECODING_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .INFO_WIDTH(INFO_WIDTH),
    .ERROR_THRESHOLD(ERROR_THRESHOLD)
) ucie_TX_Data_to_Clock_eye_sweep_DUT (
   .i_clk(i_clk),
   .i_reset(i_reset),
   .i_xx_decoding(i_xx_decoding),
   .i_xx_data(i_xx_data),
   .i_xx_sweep_result(i_xx_sweep_result),
   .i_sb_xx_req(i_sb_xx_req),  
   .i_sb_xx_rsp(i_sb_xx_rsp),   
   .i_sb_xx_done(i_sb_xx_done), 
   .i_xx_done(i_xx_done),      
   .done_ack(done_ack),        
   .init(init),         
   .no_retry(no_retry),       
   .o_xx_encoding(o_xx_encoding), 
   .o_xx_data(o_xx_data),        
   .o_xx_info(o_xx_info),         
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
    // =========================================================================
    // TEST 1: init=1, no_retry=1 (happy path, no retry)
    // TX init-mode sequence:
    //   REQ_HANDSHAKE   (0x180): o_xx_sb_req=1,  transition on i_sb_xx_rsp  && dec==0x180
    //   LFSR_HANDSHAKE  (0x181): o_xx_sb_req=1,  transition on i_sb_xx_rsp  && dec==0x181
    //   DATA_GENERATE   (0x182): no sideband out, transition on i_xx_done
    //   RESULT_HANDSHAKE(0x183): o_xx_sb_req=1,  transition on i_sb_xx_rsp  && dec==0x183
    //   END_HANDSHAKE   (0x184): o_xx_sb_req=1,  transition on i_sb_xx_rsp  && dec==0x184
    // =========================================================================
    init    = 1;
    i_reset = 1;
    no_retry = 1;
    @(negedge i_clk);
    i_reset = 0;

    // --- REQ_HANDSHAKE (encoding 0x180) ---
    // TX init: o_xx_sb_req=1 unconditionally until done_ack
    // o_xx_info carries ERROR_THRESHOLD parameter to the remote RX
    o_xx_encoding_expected = 'h180;
    o_xx_sb_req_expected   = 1;
    o_xx_info_expected     = ERROR_THRESHOLD;
    o_xx_sb_done_expected  = 0;

    @(negedge i_clk);
    assert (o_xx_encoding_expected == o_xx_encoding) 
    else    $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
    
    assert (o_xx_sb_req_expected == o_xx_sb_req) 
    else    $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);

    assert (o_xx_info_expected == o_xx_info) 
    else    $display("ERROR: Expected o_xx_info = %h, got %h, time %0t", o_xx_info_expected, o_xx_info, $time);
    
    assert (o_xx_sb_done_expected == o_xx_sb_done) 
    else    $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

    done_ack = 1; // Clear o_xx_sb_req — DUT holds req until done_ack
    o_xx_sb_req_expected = 0;

    @(negedge i_clk);
    assert (o_xx_sb_req_expected == o_xx_sb_req) 
    else    $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);

    repeat (3) @(negedge i_clk); // Wait for some cycles

    // Trigger REQ→LFSR + check LFSR_HANDSHAKE outputs
    // i_sb_xx_rsp=1 && dec==0x180 : causes REQ→LFSR transition
    // i_sb_xx_rsp also fires o_xx_sb_done on the same posedge
    // In LFSR state, o_xx_sb_req=1 unconditionally (until done_ack)
    i_sb_xx_rsp   = 1;
    done_ack      = 0;
    i_xx_decoding = 'h180;

    // --- LFSR_HANDSHAKE (encoding 0x181) ---
    // TX init: o_xx_sb_req=1 unconditionally (initiating LFSR setup with RX)
    // o_xx_sb_done=1 fires because i_sb_xx_rsp was asserted on the REQ→LFSR edge
    o_xx_sb_done_expected  = 1;
    o_xx_encoding_expected = 'h181;
    o_xx_sb_req_expected   = 1;
    
    @(negedge i_clk);
    assert (o_xx_encoding_expected == o_xx_encoding) 
    else    $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
    
    assert (o_xx_sb_req_expected == o_xx_sb_req) 
    else    $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);
    
    assert (o_xx_sb_done_expected == o_xx_sb_done) 
    else    $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

    i_sb_xx_rsp = 0;
    done_ack    = 1; // Clear o_xx_sb_req
    o_xx_sb_req_expected  = 0;
    o_xx_sb_done_expected = 0; // Self-clears one cycle after assertion

    @(negedge i_clk);
    assert (o_xx_sb_req_expected == o_xx_sb_req) 
    else    $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);

    assert (o_xx_sb_done_expected == o_xx_sb_done) 
    else    $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

    // Trigger LFSR→DATA
    // i_sb_xx_rsp=1 && dec==0x181 : causes LFSR→DATA transition
    // i_sb_xx_rsp also fires o_xx_sb_done on the same posedge
    repeat (5) @(negedge i_clk); // Wait for some cycles
    i_sb_xx_rsp   = 1;
    done_ack      = 0;
    i_xx_decoding = 'h181;

    // --- DATA_GENERATE (encoding 0x182) ---
    // TX has no sideband output in this state — just generates the LFSR pattern
    // o_xx_sb_done=1 fires because i_sb_xx_rsp was asserted on the LFSR→DATA edge
    // Stays here until i_xx_done=1 (data generation complete)
    o_xx_sb_done_expected  = 1;
    o_xx_encoding_expected = 'h182;

    @(negedge i_clk);
    assert (o_xx_encoding_expected == o_xx_encoding) 
    else    $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
        
    assert (o_xx_sb_done_expected == o_xx_sb_done) 
    else    $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

    i_sb_xx_rsp   = 0;
    o_xx_sb_done_expected = 0; // Self-clears
    i_xx_done     = 0;

    @(negedge i_clk);
    assert (o_xx_sb_done_expected == o_xx_sb_done) 
    else    $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

    // Trigger DATA→RESULT via i_xx_done
    @(negedge i_clk); // Wait for some cycles
    i_xx_done = 1;

    // --- RESULT_HANDSHAKE (encoding 0x183) ---
    // TX init: o_xx_sb_req=1 unconditionally, requesting the result from RX
    // Stays here until i_sb_xx_rsp=1 && dec==0x183 (RX responds with its measurement)
    o_xx_encoding_expected = 'h183;
    o_xx_sb_req_expected   = 1;
    
    @(negedge i_clk);
    assert (o_xx_encoding_expected == o_xx_encoding) 
    else    $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
    
    assert (o_xx_sb_req_expected == o_xx_sb_req) 
    else    $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);
    
    done_ack  = 1; // Clear o_xx_sb_req
    i_xx_done = 0;
    o_xx_sb_req_expected = 0;

    @(negedge i_clk);
    assert (o_xx_sb_req_expected == o_xx_sb_req) 
    else    $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);

    // Trigger RESULT→END (pass)
    // i_sb_xx_rsp=1 && dec==0x183 : triggers RESULT→END transition
    // i_xx_data = all 1s : failed_test = !(&i_xx_data) = 0 → test passes → go to END (not LFSR)
    // i_sb_xx_rsp also fires o_xx_sb_done on the same posedge
    @(negedge i_clk);
    i_sb_xx_rsp   = 1;
    done_ack      = 0;
    i_xx_decoding = 'h183;
    i_xx_data     = 'hFFFFFFFFFFFFFFFF; // All bits set to 1 for passing test

    // --- END_HANDSHAKE (encoding 0x184) ---
    // TX init: o_xx_sb_req=1 unconditionally, signalling completion to RX
    // failed_test = !(&i_xx_data) = 0 (pass)
    // o_xx_sb_done=1 fires because i_sb_xx_rsp was asserted on the RESULT→END edge
    failed_test_expected  = !(&i_xx_data); // 0 = pass
    o_xx_sb_done_expected = 1;
    o_xx_encoding_expected = 'h184;
    o_xx_sb_req_expected   = 1;
    
    @(negedge i_clk);
    assert (o_xx_encoding_expected == o_xx_encoding) 
    else    $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
    
    assert (o_xx_sb_req_expected == o_xx_sb_req) 
    else    $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);
    
    assert (o_xx_sb_done_expected == o_xx_sb_done) 
    else    $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);
    
    assert (failed_test_expected == failed_test) 
    else    $display("ERROR: Expected failed_test = %h, got %h, time %0t", failed_test_expected, failed_test, $time);

    done_ack = 1; // Clear o_xx_sb_req
    o_xx_sb_req_expected  = 0;
    o_xx_sb_done_expected = 0; // Self-clears
    i_sb_xx_rsp = 0;

    @(negedge i_clk);
    assert (o_xx_sb_req_expected == o_xx_sb_req) 
    else    $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);

    assert (o_xx_sb_done_expected == o_xx_sb_done) 
    else    $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

    // Trigger END→done
    // i_sb_xx_rsp=1 && dec==0x184 : sets done=1 (test fully complete)
    repeat (5) @(negedge i_clk); // Wait for some cycles
    i_sb_xx_rsp   = 1;
    done_ack      = 0;
    i_xx_decoding = 'h184;

    done_expected = 1;

    @(negedge i_clk);
    i_sb_xx_rsp = 0;
    assert (done_expected == done) 
    else    $display("ERROR: Expected done = %h, got %h, time %0t", done_expected, done, $time);

    // =========================================================================
    // TEST 2: init=1, no_retry=0 (retry enabled — fail twice then train_error)
    // Same state sequence as test 1 but in RESULT_HANDSHAKE, when failed_test=1
    // and no_retry=0, the DUT retries back to LFSR_HANDSHAKE.
    // TX has a MAXIMUM_ITERATIONS counter: after 2 retries it asserts train_error
    // instead of looping again.
    // =========================================================================
    init    = 1;
    i_reset = 1;
    no_retry = 0;
    @(negedge i_clk);
    i_reset = 0;

    // --- REQ_HANDSHAKE (encoding 0x180) ---
    o_xx_encoding_expected = 'h180;
    o_xx_sb_req_expected   = 1;
    o_xx_info_expected     = ERROR_THRESHOLD;
    o_xx_sb_done_expected  = 0;

    @(negedge i_clk);
    assert (o_xx_encoding_expected == o_xx_encoding) 
    else    $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
    
    assert (o_xx_sb_req_expected == o_xx_sb_req) 
    else    $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);

    assert (o_xx_info_expected == o_xx_info) 
    else    $display("ERROR: Expected o_xx_info = %h, got %h, time %0t", o_xx_info_expected, o_xx_info, $time);
    
    assert (o_xx_sb_done_expected == o_xx_sb_done) 
    else    $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

    done_ack = 1; // Clear o_xx_sb_req
    o_xx_sb_req_expected = 0;

    @(negedge i_clk);
    assert (o_xx_sb_req_expected == o_xx_sb_req) 
    else    $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);

    repeat (3) @(negedge i_clk); // Wait for some cycles

    // Trigger REQ→LFSR + check LFSR_HANDSHAKE outputs
    i_sb_xx_rsp   = 1;
    done_ack      = 0;
    i_xx_decoding = 'h180;

    // --- LFSR_HANDSHAKE (encoding 0x181) ---
    // o_xx_sb_done=1 fires from i_sb_xx_rsp on the REQ→LFSR edge
    o_xx_sb_done_expected  = 1;
    o_xx_encoding_expected = 'h181;
    o_xx_sb_req_expected   = 1;
    
    @(negedge i_clk);
    assert (o_xx_encoding_expected == o_xx_encoding) 
    else    $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
    
    assert (o_xx_sb_req_expected == o_xx_sb_req) 
    else    $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);
    
    assert (o_xx_sb_done_expected == o_xx_sb_done) 
    else    $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

    i_sb_xx_rsp = 0;
    done_ack    = 1; // Clear o_xx_sb_req
    o_xx_sb_req_expected  = 0;
    o_xx_sb_done_expected = 0;

    @(negedge i_clk);
    assert (o_xx_sb_req_expected == o_xx_sb_req) 
    else    $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);

    assert (o_xx_sb_done_expected == o_xx_sb_done) 
    else    $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

    // Trigger LFSR→DATA (before retry loop)
    // i_sb_xx_rsp=1 && dec==0x181 : causes LFSR→DATA transition
    // also fires o_xx_sb_done on the same posedge
    repeat (5) @(negedge i_clk); // Wait for some cycles
    i_sb_xx_rsp   = 1;
    done_ack      = 0;
    i_xx_decoding = 'h181;

    repeat (2) begin

        // --- DATA_GENERATE (encoding 0x182) ---
        // o_xx_sb_done=1 fires from i_sb_xx_rsp on the LFSR→DATA edge (or retry edge)
        // Stays here until i_xx_done=1
        o_xx_sb_done_expected  = 1;
        o_xx_encoding_expected = 'h182;

        @(negedge i_clk);
        assert (o_xx_encoding_expected == o_xx_encoding) 
        else    $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);

        assert (o_xx_sb_done_expected == o_xx_sb_done) 
        else    $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

        i_sb_xx_rsp   = 0;
        o_xx_sb_done_expected = 0; // Self-clears
        i_xx_done     = 0;

        @(negedge i_clk);
        assert (o_xx_sb_done_expected == o_xx_sb_done) 
        else    $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

        // Trigger DATA→RESULT via i_xx_done
        @(negedge i_clk); // Wait for some cycles
        i_xx_done = 1;

        // --- RESULT_HANDSHAKE (encoding 0x183) ---
        // TX init: o_xx_sb_req=1, waiting for RX to respond with its measurement
        o_xx_encoding_expected = 'h183;
        o_xx_sb_req_expected   = 1;

        @(negedge i_clk);
        assert (o_xx_encoding_expected == o_xx_encoding) 
        else    $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);

        assert (o_xx_sb_req_expected == o_xx_sb_req) 
        else    $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);

        done_ack  = 1; // Clear o_xx_sb_req
        i_xx_done = 0;
        o_xx_sb_req_expected = 0;

        @(negedge i_clk);
        assert (o_xx_sb_req_expected == o_xx_sb_req) 
        else    $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);

        // Trigger RESULT→LFSR (fail, retry)
        // i_sb_xx_rsp=1 && dec==0x183 : triggers evaluation of i_xx_data
        // i_xx_data = 1 (not all 1s) : failed_test = !(&1) = 1 → retry to LFSR
        // i_sb_xx_rsp also fires o_xx_sb_done on the same posedge
        // In LFSR state, o_xx_sb_req=1 unconditionally (count incremented internally)
        @(negedge i_clk);
        i_sb_xx_rsp   = 1;
        done_ack      = 0;
        i_xx_decoding = 'h183;
        i_xx_data     = 1; // Not all 1s → test fail → retry
    
        // --- LFSR_HANDSHAKE retry (encoding 0x181) ---
        // failed_test = !(&i_xx_data) = 1 (fail)
        // no_retry=0 and count < MAXIMUM_ITERATIONS → retry back to LFSR
        // o_xx_sb_done=1 fires because i_sb_xx_rsp was asserted on the RESULT→LFSR edge
        failed_test_expected  = !(&i_xx_data); // 1 = fail
        o_xx_sb_done_expected = 1;
        o_xx_encoding_expected = 'h181; // Retry → back to LFSR
        o_xx_sb_req_expected   = 1;
        
        @(negedge i_clk);
        assert (o_xx_encoding_expected == o_xx_encoding) 
        else    $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
        
        assert (o_xx_sb_req_expected == o_xx_sb_req) 
        else    $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);
        
        assert (o_xx_sb_done_expected == o_xx_sb_done) 
        else    $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);
        
        assert (failed_test_expected == failed_test) 
        else    $display("ERROR: Expected failed_test = %h, got %h, time %0t", failed_test_expected, failed_test, $time);
    
        done_ack = 1; // Clear o_xx_sb_req
        o_xx_sb_req_expected  = 0;
        o_xx_sb_done_expected = 0;
        i_sb_xx_rsp = 0;
    
        @(negedge i_clk);
        assert (o_xx_sb_req_expected == o_xx_sb_req) 
        else    $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);
    
        assert (o_xx_sb_done_expected == o_xx_sb_done) 
        else    $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);
    
        // Trigger LFSR→DATA again (for next retry iteration)
        // i_sb_xx_rsp=1 && dec==0x181 : causes LFSR→DATA transition
        repeat (5) @(negedge i_clk); // Wait for some cycles
        i_sb_xx_rsp   = 1;
        done_ack      = 0;
        i_xx_decoding = 'h181;
    end

    // --- DATA_GENERATE (encoding 0x182) — final attempt after max retries ---
    // o_xx_sb_done=1 fires from i_sb_xx_rsp on the LFSR→DATA edge
    o_xx_sb_done_expected  = 1;
    o_xx_encoding_expected = 'h182;

    @(negedge i_clk);
    assert (o_xx_encoding_expected == o_xx_encoding) 
    else    $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
    assert (o_xx_sb_done_expected == o_xx_sb_done) 
    else    $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

    i_sb_xx_rsp   = 0;
    o_xx_sb_done_expected = 0;
    i_xx_done     = 0;

    @(negedge i_clk);
    assert (o_xx_sb_done_expected == o_xx_sb_done) 
    else    $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);
    
    // Trigger DATA→RESULT via i_xx_done
    @(negedge i_clk); // Wait for some cycles
    i_xx_done = 1;

    // --- RESULT_HANDSHAKE (encoding 0x183) — final attempt ---
    o_xx_encoding_expected = 'h183;
    o_xx_sb_req_expected   = 1;

    @(negedge i_clk);
    assert (o_xx_encoding_expected == o_xx_encoding) 
    else    $display("ERROR: Expected o_xx_encoding = %h, got %h, time %0t", o_xx_encoding_expected, o_xx_encoding, $time);
    assert (o_xx_sb_req_expected == o_xx_sb_req) 
    else    $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);

    done_ack  = 1; // Clear o_xx_sb_req
    i_xx_done = 0;
    o_xx_sb_req_expected = 0;

    @(negedge i_clk);
    assert (o_xx_sb_req_expected == o_xx_sb_req) 
    else    $display("ERROR: Expected o_xx_sb_req = %h, got %h, time %0t", o_xx_sb_req_expected, o_xx_sb_req, $time);

    // Trigger final RESULT evaluation (fail → train_error)
    // i_sb_xx_rsp=1 && dec==0x183 : triggers evaluation of i_xx_data
    // i_xx_data = 1 (fail) + no_retry=0 + count == MAXIMUM_ITERATIONS-1
    // → DUT asserts train_error instead of retrying (max retries reached)
    // i_sb_xx_rsp also fires o_xx_sb_done on the same posedge
    @(negedge i_clk);
    i_sb_xx_rsp   = 1;
    done_ack      = 0;
    i_xx_decoding = 'h183;
    i_xx_data     = 1; // Fail again → but now count == MAXIMUM_ITERATIONS-1 → train_error

    failed_test_expected  = !(&i_xx_data); // 1 = fail
    o_xx_sb_done_expected = 1;
    train_error_expected  = 1; // Max retries reached → training failed

    @(negedge i_clk);
    assert (train_error_expected == train_error) 
    else    $display("ERROR: Expected train_error = %h, got %h, time %0t", train_error_expected, train_error, $time);
        
    assert (o_xx_sb_done_expected == o_xx_sb_done) 
    else    $display("ERROR: Expected o_xx_sb_done = %h, got %h, time %0t", o_xx_sb_done_expected, o_xx_sb_done, $time);

    $display("Test completed");
    $finish;
end
    
endmodule