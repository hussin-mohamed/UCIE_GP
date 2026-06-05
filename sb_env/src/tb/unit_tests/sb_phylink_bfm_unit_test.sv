`include "../shared_pkg.sv"
import shared_pkg::*;
import uvm_pkg::*;

`include "uvm_macros.svh"
`include "svunit_defines.svh"
`include "../../bfms/sb_phylink_bfm.sv"


// Note: Ensure the package containing opcode_t, MSG_WO_DATA, and MSG_W_64B_DATA is imported here
// import shared_pkg::*;

module sb_phylink_bfm_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "sb_phylink_bfm_ut";
  svunit_testcase svunit_ut;

  //===================================
  // UUT Instance
  //===================================
  logic clk;
  logic reset;
  sb_phylink_bfm my_sb_phylink_bfm(.*);

  // Test variables for deserialization
  logic [127:0] actual_data;

  //===================================
  // Build
  //===================================
  function void build();
    svunit_ut = new(name);
  endfunction

  //===================================
  // Setup & Teardown
  //===================================
  task setup();
    svunit_ut.setup();
    
    // Provide a basic system clock and reset for the BFM
    clk = 0;
    reset = 1;
    
    // Initialize o_tx signals to 0 (idle state) before any tests run
    my_sb_phylink_bfm.o_tx_sb_data = 1'b0;
    my_sb_phylink_bfm.o_tx_sb_clk  = 1'b0;
    
    #10 reset = 0;
  endtask

  task teardown();
    svunit_ut.teardown();
  endtask

  //---------------------------------------------------------
  // Helper Task (TX): Verify 64 UI Data + Variable UI Low
  //---------------------------------------------------------
  task verify_64b_chunk(logic [63:0] expected_data, int expected_idle_cnt);
    // 1. Verify 64-bit serialization
    for (int i = 0; i < 64; i++) begin
      @(negedge my_sb_phylink_bfm.i_rx_sb_clk);
      `FAIL_UNLESS_EQUAL(my_sb_phylink_bfm.i_rx_sb_data, expected_data[i]);
    end
    
    // 2. Verify variable-bit low gap
    for (int i = 0; i < expected_idle_cnt; i++) begin
      #2; // 1 UI = 2 time units
      `FAIL_UNLESS_EQUAL(my_sb_phylink_bfm.i_rx_sb_clk, 1'b0);
      `FAIL_UNLESS_EQUAL(my_sb_phylink_bfm.i_rx_sb_data, 1'b0);
    end
  endtask

  //---------------------------------------------------------
  // Helper Task (RX): Drive 64 UI Data + Variable UI Low
  // Emulates the DUT driving signals into the BFM
  //---------------------------------------------------------
  task drive_o_tx_chunk(logic [63:0] data_to_drive, int idle_ui_cnt);
    for (int i = 0; i < 64; i++) begin
      my_sb_phylink_bfm.o_tx_sb_data = data_to_drive[i];
      my_sb_phylink_bfm.o_tx_sb_clk  = 1'b1; // Posedge
      #1;
      my_sb_phylink_bfm.o_tx_sb_clk  = 1'b0; // Negedge
      #1;
    end
    
    // Drive gap
    my_sb_phylink_bfm.o_tx_sb_data = 1'b0;
    my_sb_phylink_bfm.o_tx_sb_clk  = 1'b0;
    #(2 * idle_ui_cnt);
  endtask

  //===================================
  // SVUNIT TESTS
  //===================================
  `SVUNIT_TESTS_BEGIN

    //=========================================================================
    // SERIALIZATION TESTS (BFM drives i_rx_*)
    //=========================================================================

    `SVTEST(serialize_msg_wo_data_standard_gap_test)
      logic [127:0] test_data = 128'h0000_0000_0000_0000_DEAD_BEEF_CAFE_BABE;
      test_data[4:0] = MSG_WO_DATA; 
      fork
        begin my_sb_phylink_bfm.serialize_data(test_data, 32); end
        begin verify_64b_chunk(test_data[63:0], 32); end
      join
    `SVTEST_END

    `SVTEST(serialize_msg_w_64b_data_standard_gap_test)
      logic [127:0] test_data = 128'h1122_3344_5566_7788_DEAD_BEEF_CAFE_BABE;
      test_data[4:0] = MSG_W_64B_DATA;
      fork
        begin my_sb_phylink_bfm.serialize_data(test_data, 32); end
        begin
          verify_64b_chunk(test_data[63:0], 32);   
          verify_64b_chunk(test_data[127:64], 32); 
        end
      join
    `SVTEST_END

    `SVTEST(serialize_msg_wo_data_extended_gap_test)
      logic [127:0] test_data = 128'h0000_0000_0000_0000_FEED_FACE_C0DE_0000;
      test_data[4:0] = MSG_WO_DATA;
      fork
        begin my_sb_phylink_bfm.serialize_data(test_data, 100); end
        begin verify_64b_chunk(test_data[63:0], 100); end
      join
    `SVTEST_END

    `SVTEST(serialize_msg_w_64b_data_extended_gap_test)
      logic [127:0] test_data = 128'hAAAA_BBBB_CCCC_DDDD_1111_2222_3333_4444;
      test_data[4:0] = MSG_W_64B_DATA;
      fork
        begin my_sb_phylink_bfm.serialize_data(test_data, 50); end
        begin
          verify_64b_chunk(test_data[63:0], 50);   
          verify_64b_chunk(test_data[127:64], 50); 
        end
      join
    `SVTEST_END

    //---------------------------------------------------------
    // Test: Serialize All 1s (Stress test stuck-at-0 faults)
    //---------------------------------------------------------
    `SVTEST(serialize_msg_w_64b_data_all_ones_test)
      logic [127:0] test_data = '1; // 128 bits of 1s
      test_data[4:0] = MSG_W_64B_DATA; // Ensure BFM knows to serialize 128 bits
      
      fork
        begin my_sb_phylink_bfm.serialize_data(test_data, 32); end
        begin
          verify_64b_chunk(test_data[63:0], 32);
          verify_64b_chunk(test_data[127:64], 32);
        end
      join
    `SVTEST_END

    //---------------------------------------------------------
    // Test: Serialize Alternating Bits (Stress clock/data alignment)
    //---------------------------------------------------------
    `SVTEST(serialize_msg_wo_data_alternating_bits_test)
      logic [127:0] test_data = {4{32'hA5A5A5A5}}; // 10100101... pattern
      test_data[4:0] = MSG_WO_DATA; // Ensure BFM knows to serialize 64 bits
      
      fork
        begin my_sb_phylink_bfm.serialize_data(test_data, 33); end // Odd idle count
        begin verify_64b_chunk(test_data[63:0], 33); end
      join
    `SVTEST_END

    //=========================================================================
    // DESERIALIZATION TESTS (BFM samples o_tx_*)
    //=========================================================================

    //---------------------------------------------------------
    // Test 5: Deserialize Header Only (MSG_WO_DATA)
    //---------------------------------------------------------
    `SVTEST(deserialize_msg_wo_data_test)
      // Bits [4:0] must equal MSG_WO_DATA
      logic [127:0] test_data = 128'h0000_0000_0000_0000_DEAD_BEEF_CAFE_0000;
      test_data[4:0] = MSG_WO_DATA;
      
      actual_data = '0; // Clear actual data
      
      fork
        begin
          // BFM samples the line
          my_sb_phylink_bfm.deserialize_data(actual_data);
        end
        begin
          // Testbed acts as DUT, driving the line
          drive_o_tx_chunk(test_data[63:0], 32);
        end
      join
      
      `FAIL_UNLESS_EQUAL(actual_data[63:0], test_data[63:0]);
    `SVTEST_END

    //---------------------------------------------------------
    // Test 6: Deserialize Header + Payload (MSG_W_64B_DATA)
    //---------------------------------------------------------
    `SVTEST(deserialize_msg_w_64b_data_test)
      // Bits [4:0] must equal MSG_W_64B_DATA
      logic [127:0] test_data = 128'h1122_3344_5566_7788_DEAD_BEEF_CAFE_0000;
      test_data[4:0] = MSG_W_64B_DATA;
      
      actual_data = '0; 
      
      fork
        begin
          my_sb_phylink_bfm.deserialize_data(actual_data);
        end
        begin
          drive_o_tx_chunk(test_data[63:0], 32);   // Drive Header
          drive_o_tx_chunk(test_data[127:64], 32); // Drive Payload
        end
      join
      
      `FAIL_UNLESS_EQUAL(actual_data, test_data);
    `SVTEST_END

    //---------------------------------------------------------
    // Test: Deserialize with Extended Intra-Packet Gap 
    // (DUT stalls for 150 UI between sending Header and Payload)
    //---------------------------------------------------------
    `SVTEST(deserialize_msg_w_64b_data_extended_intra_gap_test)
      logic [127:0] test_data = 128'h1122_3344_5566_7788_DEAD_BEEF_CAFE_0000;
      test_data[4:0] = MSG_W_64B_DATA;
      actual_data = '0; 
      
      fork
        begin my_sb_phylink_bfm.deserialize_data(actual_data); end
        begin
          drive_o_tx_chunk(test_data[63:0], 150);  // Huge 150 UI gap after header
          drive_o_tx_chunk(test_data[127:64], 32); // Standard gap after payload
        end
      join
      
      `FAIL_UNLESS_EQUAL(actual_data, test_data);
    `SVTEST_END

    //---------------------------------------------------------
    // Test: Deserialize All 1s (Validates opcode extraction 
    // from a saturated bus)
    //---------------------------------------------------------
    `SVTEST(deserialize_msg_wo_data_all_ones_test)
      logic [127:0] test_data = '1; // Set all 128 bits to 1
      test_data[4:0] = MSG_WO_DATA; // Overwrite just the opcode bits to valid
      actual_data = '0;
      
      fork
        begin my_sb_phylink_bfm.deserialize_data(actual_data); end
        begin drive_o_tx_chunk(test_data[63:0], 32); end
      join
      
      `FAIL_UNLESS_EQUAL(actual_data[63:0], test_data[63:0]);
    `SVTEST_END

    //=========================================================================
    // LOOPBACK TESTS (Ping-Pong Echo Testing)
    //=========================================================================

    //---------------------------------------------------------
    // Test: Serialize then Deserialize (BFM TX -> Testbed -> BFM RX)
    //---------------------------------------------------------
    `SVTEST(serialize_then_deserialize_loopback_test)
      logic [127:0] test_data = 128'hCAFE_F00D_DEAD_BEEF_1234_5678_9ABC_DEF0;
      test_data[4:0] = MSG_W_64B_DATA; // Ensure valid opcode
      actual_data = '0;
      
      // 1. Serialize Phase: BFM transmits, Testbed verifies it hit the wire correctly
      fork
        begin my_sb_phylink_bfm.serialize_data(test_data, 32); end
        begin 
          verify_64b_chunk(test_data[63:0], 32); 
          verify_64b_chunk(test_data[127:64], 32);
        end
      join
      
      // 2. Deserialize Phase: Testbed echos the data back, BFM captures it
      fork
        begin my_sb_phylink_bfm.deserialize_data(actual_data); end
        begin 
          drive_o_tx_chunk(test_data[63:0], 32);
          drive_o_tx_chunk(test_data[127:64], 32);
        end
      join
      
      // 3. Final Assertion
      `FAIL_UNLESS_EQUAL(actual_data, test_data);
    `SVTEST_END

    //---------------------------------------------------------
    // Test: Deserialize then Serialize (Testbed -> BFM RX -> BFM TX)
    //---------------------------------------------------------
    `SVTEST(deserialize_then_serialize_loopback_test)
      logic [127:0] test_data = 128'h1111_2222_3333_4444_5555_6666_7777_8888;
      test_data[4:0] = MSG_W_64B_DATA; 
      actual_data = '0;
      
      // 1. Deserialize Phase: Testbed transmits, BFM captures into actual_data
      fork
        begin my_sb_phylink_bfm.deserialize_data(actual_data); end
        begin 
          drive_o_tx_chunk(test_data[63:0], 32);
          drive_o_tx_chunk(test_data[127:64], 32);
        end
      join
      
      // Verify the BFM caught it correctly before sending it back
      `FAIL_UNLESS_EQUAL(actual_data, test_data);
      
      // 2. Serialize Phase: BFM transmits the captured actual_data back out
      fork
        begin my_sb_phylink_bfm.serialize_data(actual_data, 32); end
        begin 
          verify_64b_chunk(actual_data[63:0], 32); 
          verify_64b_chunk(actual_data[127:64], 32);
        end
      join
    `SVTEST_END

    //=========================================================================
    // PATTERN SERIALIZATION TESTS (SBINIT Patterns)
    //=========================================================================

    //---------------------------------------------------------
    // Test: Serialize Pattern (Standard 32 UI Gap)
    //---------------------------------------------------------
    `SVTEST(serialize_pattern_standard_gap_test)
      // Typical training pattern
      logic [63:0] test_pattern = 64'hAAAA_5555_AAAA_5555; 
      
      fork
        begin my_sb_phylink_bfm.serialize_pattern(test_pattern, 32); end
        begin verify_64b_chunk(test_pattern, 32); end
      join
    `SVTEST_END

    //---------------------------------------------------------
    // Test: Serialize Pattern All 1s (Extended 100 UI Gap)
    //---------------------------------------------------------
    `SVTEST(serialize_pattern_all_ones_extended_gap_test)
      // Stress testing the physical line with all highs
      logic [63:0] test_pattern = 64'hFFFF_FFFF_FFFF_FFFF; 
      
      fork
        begin my_sb_phylink_bfm.serialize_pattern(test_pattern, 100); end
        begin verify_64b_chunk(test_pattern, 100); end
      join
    `SVTEST_END

    //---------------------------------------------------------
    // Test: Serialize Pattern Alternating Bits (50 UI Gap)
    //---------------------------------------------------------
    `SVTEST(serialize_pattern_alternating_bits_test)
      // Stress testing clock-data alignment with rapid toggling
      logic [63:0] test_pattern = 64'hA5A5_A5A5_A5A5_A5A5; 
      
      fork
        begin my_sb_phylink_bfm.serialize_pattern(test_pattern, 50); end
        begin verify_64b_chunk(test_pattern, 50); end
      join
    `SVTEST_END

  `SVUNIT_TESTS_END

endmodule