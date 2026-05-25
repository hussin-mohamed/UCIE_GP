// ============================================================================
// Macro for the Per-Lane ID Pattern
// ============================================================================
`define GET_PER_LANE_ID_PATTERN(lane_idx) {4'b1010, 8'(lane_idx), 4'b1010}

// ============================================================================
// PACKAGE: per_lane_id_detector_pkg
// ============================================================================
package per_lane_id_detector_pkg;
  `include "uvm_macros.svh"
  import uvm_pkg::*;

  parameter pNUM_LANES  = 16;
  parameter pDATA_WIDTH = 64;
  parameter pNBYTES     = 256;

  int per_lane_pat_cnt [pNUM_LANES];
  int per_lane_iter_cnt;

  function void get_per_lane_id_results(
     input  logic [(pDATA_WIDTH/16)-1:0][15:0] _lanes         [pNUM_LANES]
    ,input  logic [2:0]                        _lane_map_code
    ,output logic                              _lanes_success [pNUM_LANES]
  );
    int start_lane;
    int num_active_lanes;

    // Initialize all success flags to 0
    for (int i = 0; i < pNUM_LANES; i++) begin
      _lanes_success[i] = 1'b0;
    end

    // Determine offset based on your lane map code
    case (_lane_map_code)
      3'b001: begin start_lane = 0; num_active_lanes = 8;  end // x8 mode, lower lanes
      3'b010: begin start_lane = 8; num_active_lanes = 8;  end // x8 mode, upper lanes
      3'b011: begin start_lane = 0; num_active_lanes = 16; end // x16 mode
      3'b100: begin start_lane = 0; num_active_lanes = 4;  end // x4 mode, lower lanes
      3'b101: begin start_lane = 4; num_active_lanes = 4;  end // x4 mode, upper lanes
      
      default:
      begin
        `uvm_fatal("PRD_PERLANE", $sformatf("Unsupported lane_map_code: %0b, Supported codes are 001b...101b", _lane_map_code))
      end
    endcase // lane_map_code

    for (int lane_idx = start_lane; lane_idx < (start_lane + num_active_lanes); lane_idx++) begin
      for (int pat_idx = 0; pat_idx < pDATA_WIDTH/16; pat_idx++) begin
        if (_lanes[lane_idx][pat_idx] == {4'b1010, 8'(lane_idx), 4'b1010}) begin
          per_lane_pat_cnt[lane_idx]++;
        end else begin
          per_lane_pat_cnt[lane_idx] = 0;
        end
      end
    end

    foreach (per_lane_pat_cnt[lane_idx]) begin
      if (per_lane_pat_cnt[lane_idx] >= 16) begin
        _lanes_success[lane_idx] = 1;
      end else begin
        _lanes_success[lane_idx] = 0;
      end
    end

    if (per_lane_iter_cnt == ((128*16)/(pDATA_WIDTH))) begin
      per_lane_iter_cnt = 0;
    end else begin
      per_lane_iter_cnt++;
    end
  endfunction : get_per_lane_id_results

endpackage : per_lane_id_detector_pkg


// ============================================================================
// TESTBENCH MODULE: tb_per_lane_id_detector
// ============================================================================
module tb_per_lane_id_detector;
  import per_lane_id_detector_pkg::*;

  // Module-level signals (no inline initializations)
  logic [(pDATA_WIDTH/16)-1:0][15:0] test_lanes     [pNUM_LANES];
  logic                              actual_success [pNUM_LANES];

  initial begin
    // ------------------------------------------------------------------------
    // STRICT SCOPE DECLARATIONS: All variables declared at the absolute top
    // ------------------------------------------------------------------------
    int map_idx;
    int call_idx;
    int lane_idx;
    int word_idx;
    int total_errors;
    int local_err;
    logic expected_success;
    logic is_active_lane;
    
    int trial;
    int err_call_idx;
    int rand_val;
    
    logic [2:0] test_map_code;
    int start_lane;
    int num_active_lanes;
    
    logic [2:0] supported_codes [5];

    // ------------------------------------------------------------------------
    // STATEMENTS & INITIALIZATIONS START HERE
    // ------------------------------------------------------------------------
    total_errors = 0;

    // Manually assign the array to avoid inline list assignment errors
    supported_codes[0] = 3'b011; // x16 mode (0-15)
    supported_codes[1] = 3'b001; // x8 mode  (0-7)
    supported_codes[2] = 3'b010; // x8 mode  (8-15)
    supported_codes[3] = 3'b100; // x4 mode  (0-3)
    supported_codes[4] = 3'b101; // x4 mode  (4-7)

    $display("\n=======================================================");
    $display("  STARTING RANDOMIZED PER-LANE ID DETECTOR TESTBENCH");
    $display("=======================================================\n");

    // Loop through all supported map codes
    for (map_idx = 0; map_idx < 5; map_idx = map_idx + 1) begin
      test_map_code = supported_codes[map_idx];

      // Decode the active lanes for the current test
      case (test_map_code)
        3'b001: begin start_lane = 0; num_active_lanes = 8;  end
        3'b010: begin start_lane = 8; num_active_lanes = 8;  end
        3'b011: begin start_lane = 0; num_active_lanes = 16; end
        3'b100: begin start_lane = 0; num_active_lanes = 4;  end
        3'b101: begin start_lane = 4; num_active_lanes = 4;  end
        default: $fatal(1, "Unsupported lane map code encountered.");
      endcase

      $display(">>> TESTING MAP CODE: %3b | Active Lanes: %0d-%0d <<<", 
               test_map_code, start_lane, (start_lane + num_active_lanes - 1));

      // ========================================================================
      // SCENARIO 1: Ideal Transmission (128 patterns)
      // ========================================================================
      $display("--- SCENARIO 1: Ideal Transmission ---");
      for (lane_idx = 0; lane_idx < pNUM_LANES; lane_idx = lane_idx + 1) per_lane_pat_cnt[lane_idx] = 0;
      local_err = 0;
      
      for (call_idx = 0; call_idx < 32; call_idx = call_idx + 1) begin
        for (lane_idx = 0; lane_idx < pNUM_LANES; lane_idx = lane_idx + 1) begin
          for (word_idx = 0; word_idx < 4; word_idx = word_idx + 1) begin
            test_lanes[lane_idx][word_idx] = `GET_PER_LANE_ID_PATTERN(lane_idx);
          end
        end
        get_per_lane_id_results(test_lanes, test_map_code, actual_success);

        for (lane_idx = 0; lane_idx < pNUM_LANES; lane_idx = lane_idx + 1) begin
          is_active_lane = (lane_idx >= start_lane) && (lane_idx < start_lane + num_active_lanes);
          expected_success = ((call_idx >= 3) && is_active_lane) ? 1'b1 : 1'b0;
          if (actual_success[lane_idx] !== expected_success) begin
            $error("S1 FAIL [%3b]: Call %0d, Lane %0d - Expected: %0b, Got: %0b", test_map_code, call_idx, lane_idx, expected_success, actual_success[lane_idx]);
            local_err = local_err + 1;
          end
        end
      end
      total_errors = total_errors + local_err;
      if (local_err == 0) $display("    -> SCENARIO 1 PASSED.");

      // ========================================================================
      // SCENARIO 2: Basic Error Injection and Recovery
      // ========================================================================
      $display("--- SCENARIO 2: Static Error Injection & Recovery ---");
      for (lane_idx = 0; lane_idx < pNUM_LANES; lane_idx = lane_idx + 1) per_lane_pat_cnt[lane_idx] = 0;
      local_err = 0;

      // 3 Perfect Calls
      for (call_idx = 0; call_idx < 3; call_idx = call_idx + 1) begin
        for (lane_idx = 0; lane_idx < pNUM_LANES; lane_idx = lane_idx + 1) begin
          for (word_idx = 0; word_idx < 4; word_idx = word_idx + 1) test_lanes[lane_idx][word_idx] = `GET_PER_LANE_ID_PATTERN(lane_idx);
        end
        get_per_lane_id_results(test_lanes, test_map_code, actual_success);
      end

      // 1 Error Call
      for (lane_idx = 0; lane_idx < pNUM_LANES; lane_idx = lane_idx + 1) begin
        for (word_idx = 0; word_idx < 3; word_idx = word_idx + 1) test_lanes[lane_idx][word_idx] = `GET_PER_LANE_ID_PATTERN(lane_idx);
        test_lanes[lane_idx][3] = 16'hDEAD;
      end
      get_per_lane_id_results(test_lanes, test_map_code, actual_success);

      // 4 Perfect Recovery Calls
      for (call_idx = 0; call_idx < 4; call_idx = call_idx + 1) begin
        for (lane_idx = 0; lane_idx < pNUM_LANES; lane_idx = lane_idx + 1) begin
          for (word_idx = 0; word_idx < 4; word_idx = word_idx + 1) test_lanes[lane_idx][word_idx] = `GET_PER_LANE_ID_PATTERN(lane_idx);
        end
        get_per_lane_id_results(test_lanes, test_map_code, actual_success);
      end

      for (lane_idx = 0; lane_idx < pNUM_LANES; lane_idx = lane_idx + 1) begin
        is_active_lane = (lane_idx >= start_lane) && (lane_idx < start_lane + num_active_lanes);
        expected_success = is_active_lane ? 1'b1 : 1'b0;
        if (actual_success[lane_idx] !== expected_success) begin
          $error("S2 FAIL [%3b]: Lane %0d - Expected: %0b, Got: %0b", test_map_code, lane_idx, expected_success, actual_success[lane_idx]);
          local_err = local_err + 1;
        end
      end
      total_errors = total_errors + local_err;
      if (local_err == 0) $display("    -> SCENARIO 2 PASSED.");

      // ========================================================================
      // SCENARIO 3: Random Noise on Inactive Lanes
      // ========================================================================
      $display("--- SCENARIO 3: Random Noise on Inactive Lanes ---");
      for (lane_idx = 0; lane_idx < pNUM_LANES; lane_idx = lane_idx + 1) per_lane_pat_cnt[lane_idx] = 0;
      local_err = 0;

      for (call_idx = 0; call_idx < 8; call_idx = call_idx + 1) begin
        for (lane_idx = 0; lane_idx < pNUM_LANES; lane_idx = lane_idx + 1) begin
          is_active_lane = (lane_idx >= start_lane) && (lane_idx < start_lane + num_active_lanes);
          for (word_idx = 0; word_idx < 4; word_idx = word_idx + 1) begin
            if (is_active_lane) begin
              test_lanes[lane_idx][word_idx] = `GET_PER_LANE_ID_PATTERN(lane_idx);
            end else begin
              // Blast inactive lanes with random garbage
              test_lanes[lane_idx][word_idx] = $urandom(); 
            end
          end
        end
        
        get_per_lane_id_results(test_lanes, test_map_code, actual_success);

        for (lane_idx = 0; lane_idx < pNUM_LANES; lane_idx = lane_idx + 1) begin
          is_active_lane = (lane_idx >= start_lane) && (lane_idx < start_lane + num_active_lanes);
          expected_success = ((call_idx >= 3) && is_active_lane) ? 1'b1 : 1'b0;
          if (actual_success[lane_idx] !== expected_success) begin
            $error("S3 FAIL [%3b]: Call %0d, Lane %0d - Expected: %0b, Got: %0b", test_map_code, call_idx, lane_idx, expected_success, actual_success[lane_idx]);
            local_err = local_err + 1;
          end
        end
      end
      total_errors = total_errors + local_err;
      if (local_err == 0) $display("    -> SCENARIO 3 PASSED.");

      // ========================================================================
      // SCENARIO 4: Randomized Error Injection Timing
      // ========================================================================
      $display("--- SCENARIO 4: Randomized Error Injection Timing (3 Trials) ---");
      local_err = 0;
      
      for (trial = 1; trial <= 3; trial = trial + 1) begin
        for (lane_idx = 0; lane_idx < pNUM_LANES; lane_idx = lane_idx + 1) per_lane_pat_cnt[lane_idx] = 0;
        
        // Pick a random call (between 0 and 5) to blast with errors
        err_call_idx = $urandom_range(0, 5);
        
        for (call_idx = 0; call_idx < 12; call_idx = call_idx + 1) begin
          
          for (lane_idx = 0; lane_idx < pNUM_LANES; lane_idx = lane_idx + 1) begin
            for (word_idx = 0; word_idx < 4; word_idx = word_idx + 1) begin
              if (call_idx == err_call_idx) begin
                test_lanes[lane_idx][word_idx] = $urandom(); // Inject random error
              end else begin
                test_lanes[lane_idx][word_idx] = `GET_PER_LANE_ID_PATTERN(lane_idx);
              end
            end
          end
          
          get_per_lane_id_results(test_lanes, test_map_code, actual_success);

          // Success asserts if we had 4 perfect calls BEFORE the error,
          // OR if we had 4 perfect calls AFTER the error.
          for (lane_idx = 0; lane_idx < pNUM_LANES; lane_idx = lane_idx + 1) begin
            is_active_lane = (lane_idx >= start_lane) && (lane_idx < start_lane + num_active_lanes);
            
            if (is_active_lane) begin
              if ( (call_idx >= 3 && call_idx < err_call_idx) || (call_idx >= err_call_idx + 4) ) begin
                 expected_success = 1'b1;
              end else begin
                 expected_success = 1'b0;
              end
            end else begin
              expected_success = 1'b0;
            end
            
            if (actual_success[lane_idx] !== expected_success) begin
              $error("S4 FAIL [%3b] Trial %0d: Error at call %0d. Failed at call %0d, Lane %0d - Expected: %0b, Got: %0b", 
                     test_map_code, trial, err_call_idx, call_idx, lane_idx, expected_success, actual_success[lane_idx]);
              local_err = local_err + 1;
            end
          end
        end
      end
      total_errors = total_errors + local_err;
      if (local_err == 0) $display("    -> SCENARIO 4 PASSED.\n");
      
    end // End of map codes loop

    // ========================================================================
    // Final Report
    // ========================================================================
    $display("=======================================================");
    if (total_errors == 0) begin
      $display("  TEST RESULT: SUCCESS (0 Errors Across All Modes & Random Scenarios)");
    end else begin
      $display("  TEST RESULT: FAILED (%0d Total Errors)", total_errors);
    end
    $display("=======================================================\n");
    $finish;
  end

endmodule : tb_per_lane_id_detector