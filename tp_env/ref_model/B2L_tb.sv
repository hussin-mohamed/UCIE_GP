module B2L_tb;

    import B2L_modelling_pkg::*;

    //-------------------------------------------------------------------------
    // Signal Declarations
    //-------------------------------------------------------------------------
    logic [2:0]                 i_lane_map_code;
    logic                       i_reset;
    logic                       i_enable;
    logic                       i_data_ready;
    logic [7:0]                 i_lp_data [0:NBYTES-1];

    logic [DATA_WIDTH-1:0]      o_lane [0:LANES_NUMBER-1];
    logic                       o_data_sent;

    //-------------------------------------------------------------------------
    // Drive Task
    // Applies one stimulus vector and calls the golden model
    //-------------------------------------------------------------------------
    task automatic drive (
        input logic [2:0]  lane_map_code,
        input logic        reset,
        input logic        enable,
        input logic        data_ready,
        input logic [7:0]  lp_data [0:NBYTES-1]
    );
        i_lane_map_code = lane_map_code;
        i_reset         = reset;
        i_enable        = enable;
        i_data_ready    = data_ready;
        i_lp_data       = lp_data;

        // Call the golden model
        B2L_modelling(i_lane_map_code, i_reset,
                      i_lp_data, o_lane, o_data_sent);
    endtask

    //-------------------------------------------------------------------------
    // Check Task
    // Compares o_lane against an expected array, lane by lane
    //-------------------------------------------------------------------------
    task automatic check (
        input logic [DATA_WIDTH-1:0]  expected [0:LANES_NUMBER-1],
        input logic                   expected_sent,
        input string                  test_name
    );
        int pass_count = 0;
        int fail_count = 0;

        foreach (o_lane[i]) begin
            if (o_lane[i] !== expected[i]) begin
                $error("[FAIL] %s | Lane %02d | Expected: 0x%016h | Got: 0x%016h",
                        test_name, i, expected[i], o_lane[i]);
                fail_count++;
            end else begin
                $display("[PASS] %s | Lane %02d | 0x%016h", test_name, i, o_lane[i]);
                pass_count++;
            end
        end

        if (o_data_sent !== expected_sent) begin
            $error("[FAIL] %s | o_data_sent | Expected: %0b | Got: %0b",
                    test_name, expected_sent, o_data_sent);
            fail_count++;
        end else begin
            $display("[PASS] %s | o_data_sent = %0b", test_name, o_data_sent);
            pass_count++;
        end

        $display("----------------------------------------");
        $display("%s Summary: %0d PASSED | %0d FAILED", test_name, pass_count, fail_count);
        $display("----------------------------------------");
    endtask

    //-------------------------------------------------------------------------
    // Print Task
    // Dumps current o_lane without expected comparison (useful during
    // sequence development when expected values aren't known yet)
    //-------------------------------------------------------------------------
    task automatic print_output (input string label);
        $display("\n[%0t] %s", $time, label);
        foreach (o_lane[i]) begin
            $display("  Lane %02d : 0x%016h", i, o_lane[i]);
        end
        $display("  o_data_sent : %0b", o_data_sent);
    endtask

    //-------------------------------------------------------------------------
    // Print Input Task
    // Dumps current input stimulus (control signals + i_lp_data buffer).
    // Useful during sequence development to confirm what's being driven in.
    //-------------------------------------------------------------------------
    task automatic print_input (input string label);
        $display("\n[%0t] %s", $time, label);
        $display("  i_lane_map_code : 3'b%03b", i_lane_map_code);
        $display("  i_reset         : %0b", i_reset);
        $display("  i_enable        : %0b", i_enable);
        $display("  i_data_ready    : %0b", i_data_ready);
        $display("  i_lp_data[0:%0d] :", NBYTES-1);
        // Print 16 bytes per row for readability
        for (int row = 0; row < NBYTES/16; row++) begin
            string line;
            line = $sformatf("    [%03d..%03d] :", row*16, row*16+15);
            for (int col = 0; col < 16; col++) begin
                line = {line, $sformatf(" %02h", i_lp_data[row*16 + col])};
            end
            $display("%s", line);
        end
    endtask

    //-------------------------------------------------------------------------
    // Helper: Generate an incrementing byte pattern (data[i] = i)
    //-------------------------------------------------------------------------
    function automatic void gen_incrementing (output logic [7:0] buf_data [0:NBYTES-1]);
        for (int i = 0; i < NBYTES; i++) begin
            buf_data[i] = i[7:0];
        end
    endfunction

    //-------------------------------------------------------------------------
    // Helper: Generate a constant byte pattern
    //-------------------------------------------------------------------------
    function automatic void gen_constant (input logic [7:0] val,
                                          output logic [7:0] buf_data [0:NBYTES-1]);
        for (int i = 0; i < NBYTES; i++) begin
            buf_data[i] = val;
        end
    endfunction

    //-------------------------------------------------------------------------
    // Local stimulus buffers
    //-------------------------------------------------------------------------
    logic [7:0] data_inc   [0:NBYTES-1];
    logic [7:0] data_zero  [0:NBYTES-1];
    logic [7:0] data_AA    [0:NBYTES-1];

    //-------------------------------------------------------------------------
    // Expected-value arrays
    //-------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0] exp_zero [0:LANES_NUMBER-1];

    //-------------------------------------------------------------------------
    // Main Test Block — plug your sequences in here
    //-------------------------------------------------------------------------
    initial begin
        $display("\n========== B2L Golden Model Testbench Start ==========\n");

        // Build stimulus patterns
        gen_incrementing(data_inc);
        gen_constant(8'h00, data_zero);
        gen_constant(8'hAA, data_AA);

        // All-zero expected vector
        for (int i = 0; i < LANES_NUMBER; i++) exp_zero[i] = '0;

        //----------------------------------------------------------------
        // 1) RESET — outputs should all be cleared
        //----------------------------------------------------------------
        #5;
        drive(NONE, 1'b1, 1'b0, 1'b0, data_zero);
        check(exp_zero, 1'b0, "Reset");

        //----------------------------------------------------------------
        // 2) NONE mode after enabling — all lanes still 0
        //----------------------------------------------------------------
        #5;
        drive(NONE, 1'b0, 1'b1, 1'b1, data_inc);  // push data into queue
        check(exp_zero, 1'b0, "NONE mode");

        //----------------------------------------------------------------
        // 3) LOGICAL_LANES_0_TO_7 — first byte cycle (count_byte = 0)
        //    Expected: lane[i] = {data[i], data[i+8], data[i+16], data[i+24]}
        //    With data[i]=i:
        //      lane[0] = 32'h00081018, lane[1] = 32'h01091119, ...
        //----------------------------------------------------------------
        #5;
        drive(LOGICAL_LANES_0_TO_7, 1'b0, 1'b1, 1'b0, data_inc);
        print_output("LOGICAL_LANES_0_TO_7 - cycle 0");
        // Optional check (lanes 8..15 keep prior value = 0 from reset path):
        check('{
            64'h0000000000081018,
            64'h0000000001091119,
            64'h00000000020A121A,
            64'h00000000030B131B,
            64'h00000000040C141C,
            64'h00000000050D151D,
            64'h00000000060E161E,
            64'h00000000070F171F,
            64'h0, 64'h0, 64'h0, 64'h0, 64'h0, 64'h0, 64'h0, 64'h0
        }, 1'b0, "LL_0_TO_7 cycle0");

        //----------------------------------------------------------------
        // 4) LOGICAL_LANES_8_TO_15 — push new buffer & exercise upper lanes
        //----------------------------------------------------------------
        #5;
        drive(NONE, 1'b1, 1'b0, 1'b0, data_zero);          // reset state
        check(exp_zero, 1'b0, "NONE mode");
        #5;
        drive(LOGICAL_LANES_8_TO_15, 1'b0, 1'b1, 1'b1, data_inc);  // load + run
        print_output("LOGICAL_LANES_8_TO_15 - cycle 0");
        check('{
            64'h0, 64'h0, 64'h0, 64'h0, 64'h0, 64'h0, 64'h0, 64'h0,
            64'h0000000008101820,
            64'h0000000009111921,
            64'h000000000A121A22,
            64'h000000000B131B23,
            64'h000000000C141C24,
            64'h000000000D151D25,
            64'h000000000E161E26,
            64'h000000000F171F27
        }, 1'b0, "LL_8_TO_15 cycle0");

        //----------------------------------------------------------------
        // 5) ALL_LANES — full 16-lane mapping
        //    Expected: lane[i] = {data[i], data[i+16], data[i+32], data[i+48]}
        //    For data[i]=i and count_byte=0:
        //      lane[0] = 32'h00102030, lane[1] = 32'h01112131, ...
        //----------------------------------------------------------------
        #5;
        drive(NONE, 1'b1, 1'b0, 1'b0, data_zero);          // reset
        check(exp_zero, 1'b0, "NONE mode");

        #5;
        drive(ALL_LANES, 1'b0, 1'b1, 1'b1, data_inc);      // push & process
        print_output("ALL_LANES - cycle 0");
        check('{
            64'h0000000000102030,
            64'h0000000001112131,
            64'h0000000002122232,
            64'h0000000003132333,
            64'h0000000004142434,
            64'h0000000005152535,
            64'h0000000006162636,
            64'h0000000007172737,
            64'h0000000008182838,
            64'h0000000009192939,
            64'h000000000A1A2A3A,
            64'h000000000B1B2B3B,
            64'h000000000C1C2C3C,
            64'h000000000D1D2D3D,
            64'h000000000E1E2E3E,
            64'h000000000F1F2F3F
        }, 1'b0, "ALL_LANES cycle0");

        //----------------------------------------------------------------
        // 6) ALL_LANES — subsequent cycles until o_data_sent asserts
        //    256 bytes / (16 lanes * 4 bytes) = 4 cycles total
        //----------------------------------------------------------------

        // ---- Cycle 1 : count_byte = 1 -> lane[i] = {i+64, i+80, i+96, i+112}
        #5;
        drive(ALL_LANES, 1'b0, 1'b1, 1'b0, data_inc);
        print_output("ALL_LANES - cycle 1");
        check('{
            64'h0000000040506070,
            64'h0000000041516171,
            64'h0000000042526272,
            64'h0000000043536373,
            64'h0000000044546474,
            64'h0000000045556575,
            64'h0000000046566676,
            64'h0000000047576777,
            64'h0000000048586878,
            64'h0000000049596979,
            64'h000000004A5A6A7A,
            64'h000000004B5B6B7B,
            64'h000000004C5C6C7C,
            64'h000000004D5D6D7D,
            64'h000000004E5E6E7E,
            64'h000000004F5F6F7F
        }, 1'b0, "ALL_LANES cycle1");

        // ---- Cycle 2 : count_byte = 2 -> lane[i] = {i+128, i+144, i+160, i+176}
        #5;
        drive(ALL_LANES, 1'b0, 1'b1, 1'b0, data_inc);
        print_output("ALL_LANES - cycle 2");
        check('{
            64'h000000008090A0B0,
            64'h000000008191A1B1,
            64'h000000008292A2B2,
            64'h000000008393A3B3,
            64'h000000008494A4B4,
            64'h000000008595A5B5,
            64'h000000008696A6B6,
            64'h000000008797A7B7,
            64'h000000008898A8B8,
            64'h000000008999A9B9,
            64'h000000008A9AAABA,
            64'h000000008B9BABBB,
            64'h000000008C9CACBC,
            64'h000000008D9DADBD,
            64'h000000008E9EAEBE,
            64'h000000008F9FAFBF
        }, 1'b0, "ALL_LANES cycle2");

        // ---- Cycle 3 : count_byte = 3 -> lane[i] = {i+192, i+208, i+224, i+240}
        //      Final cycle: (3+1)*4*16 == 256 -> o_data_sent = 1, count_byte resets to 0
        #5;
        drive(ALL_LANES, 1'b0, 1'b1, 1'b0, data_inc);
        print_output("ALL_LANES - cycle 3 (final)");
        check('{
            64'h00000000C0D0E0F0,
            64'h00000000C1D1E1F1,
            64'h00000000C2D2E2F2,
            64'h00000000C3D3E3F3,
            64'h00000000C4D4E4F4,
            64'h00000000C5D5E5F5,
            64'h00000000C6D6E6F6,
            64'h00000000C7D7E7F7,
            64'h00000000C8D8E8F8,
            64'h00000000C9D9E9F9,
            64'h00000000CADAEAFA,
            64'h00000000CBDBEBFB,
            64'h00000000CCDCECFC,
            64'h00000000CDDDEDFD,
            64'h00000000CEDEEEFE,
            64'h00000000CFDFEFFF
        }, 1'b1, "ALL_LANES cycle3 (final)");

        //----------------------------------------------------------------
        // 7) Constant-pattern sanity check (data = 0xAA everywhere)
        //----------------------------------------------------------------
        #5;
        drive(NONE, 1'b1, 1'b0, 1'b0, data_zero);
        #5;
        drive(ALL_LANES, 1'b0, 1'b1, 1'b1, data_AA);
        // every byte = 0xAA ⇒ every lane = 32'hAAAAAAAA
        check('{
            64'h00000000AAAAAAAA, 64'h00000000AAAAAAAA, 64'h00000000AAAAAAAA, 64'h00000000AAAAAAAA,
            64'h00000000AAAAAAAA, 64'h00000000AAAAAAAA, 64'h00000000AAAAAAAA, 64'h00000000AAAAAAAA,
            64'h00000000AAAAAAAA, 64'h00000000AAAAAAAA, 64'h00000000AAAAAAAA, 64'h00000000AAAAAAAA,
            64'h00000000AAAAAAAA, 64'h00000000AAAAAAAA, 64'h00000000AAAAAAAA, 64'h00000000AAAAAAAA
        }, 1'b0, "ALL_LANES constant 0xAA");

        $display("\n========== B2L Testbench Complete ==========\n");
        $finish;
    end

endmodule