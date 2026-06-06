// ============================================================================
// TESTBENCH MODULE: tb_per_lane_id_detector
// ============================================================================
module tb_per_lane_id_detector;
  import per_lane_id_detector_pkg::*;

  // ------------------------------------------------------------------------
  // STRICT SCOPE DECLARATIONS: All variables declared at the absolute top
  // ------------------------------------------------------------------------
  
  // Testbench interconnects
  logic                                       clk;
  logic                                       reset;
  logic [pNUM_LANES-1:0]                      enable;
  logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0]     data_in;
  logic [pNUM_LANES-1:0]                      laneid_success;

  // Golden model arrays
  logic [(pDATA_WIDTH/16)-1:0][15:0]          tb_lanes [pNUM_LANES];
  logic                                       golden_success [pNUM_LANES];

  // Loop/iteration control variables
  int map_idx;
  int cycle;
  int lane;
  int word;
  
  // Result monitoring
  int total_errors;
  int start_errors;
  logic expected_bit;
  logic actual_bit;
  logic latched_golden [pNUM_LANES]; // Added to track RTL's clock-gating lock

  // Randomization variables
  logic [7:0] wrong_lane_id;
  logic       is_valid_coin_toss;

  // Supported lane modes
  logic [2:0] supported_modes [3];
  logic [2:0] current_mode;

  // ------------------------------------------------------------------------
  // DEVICE UNDER TEST (DUT)
  // ------------------------------------------------------------------------
  per_lane_id_detector_top #(
    .pDATA_WIDTH(pDATA_WIDTH),
    .pNUM_LANES(pNUM_LANES)
  ) dut (
    .i_clk(clk),
    .i_reset(reset),
    .i_enable(enable),
    .i_data_in(data_in),
    .o_laneid_success(laneid_success)
  );

  // ------------------------------------------------------------------------
  // CLOCK GENERATION
  // ------------------------------------------------------------------------
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk; // 100MHz clock
  end

  // ------------------------------------------------------------------------
  // MAIN TEST SEQUENCE
  // ------------------------------------------------------------------------
  initial begin
    // Standard initialization mappings (No inline initialization allowed)
    total_errors = 0;
    
    // As requested: testing only x8 lower, x8 upper, and x16 modes
    supported_modes[0] = 3'b001; // x8 lower
    supported_modes[1] = 3'b010; // x8 upper
    supported_modes[2] = 3'b011; // x16

    // Initial default values
    reset = 1'b1;
    enable = 16'h0000;
    for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
      data_in[lane] = 64'h0;
    end

    $display("=======================================================");
    $display("  STARTING ADVANCED PER-LANE ID DETECTOR TESTBENCH");
    $display("=======================================================\n");

    for (map_idx = 0; map_idx < 3; map_idx = map_idx + 1) begin
      // Ensure RTL is completely cleared before testing a new map code
      reset = 1'b1;
      @(negedge clk);
      @(negedge clk);
      reset = 1'b0;
      @(negedge clk);

      current_mode = supported_modes[map_idx];

      // Decode the 'enable' mask corresponding to the lane code
      if (current_mode == 3'b001) begin
        enable = 16'h00FF;
      end else if (current_mode == 3'b010) begin
        enable = 16'hFF00;
      end else if (current_mode == 3'b011) begin
        enable = 16'hFFFF;
      end else begin
        enable = 16'h0000;
      end

      $display(">>> TESTING MAP CODE: %03b | ENABLE MASK: %04X <<<", current_mode, enable);

      // ========================================================================
      // SCENARIO 1: Ideal Transmission (128 continuous valid patterns)
      // ========================================================================
      $display("--- SCENARIO 1: Ideal 128 Pattern Iterations ---");
      start_errors = total_errors;
      
      per_lane_iter_cnt = 0;
      for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
        per_lane_pat_cnt[lane] = 0;
        latched_golden[lane] = 1'b0;
      end

      for (cycle = 0; cycle < 32; cycle = cycle + 1) begin
        for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
          for (word = 0; word < 4; word = word + 1) begin
             tb_lanes[lane][word] = {4'b1010, 8'(lane), 4'b1010};
          end
        end
        for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
          data_in[lane] = {tb_lanes[lane][3], tb_lanes[lane][2], tb_lanes[lane][1], tb_lanes[lane][0]};
        end
        @(negedge clk);
        get_per_lane_id_results(tb_lanes, current_mode, golden_success);
        for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
          if (golden_success[lane]) latched_golden[lane] = 1'b1;
        end
      end
      
      for (lane = 0; lane < pNUM_LANES; lane = lane + 1) data_in[lane] = 64'h0;
      @(negedge clk); @(negedge clk);

      for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
        expected_bit = latched_golden[lane];
        actual_bit   = laneid_success[lane];
        if (enable[lane] == 1'b1) begin
          if (actual_bit !== expected_bit) begin
            $error("S1 FAIL [%03b] Active Lane %0d - Expected: %0b, Got: %0b", current_mode, lane, expected_bit, actual_bit);
            total_errors = total_errors + 1;
          end
        end else begin
          if (actual_bit !== 1'b0) begin
            $error("S1 FAIL [%03b] Inactive Lane %0d - Expected: 0, Got: %0b", current_mode, lane, actual_bit);
            total_errors = total_errors + 1;
          end
        end
      end

      if (total_errors == start_errors) $display("    *** SCENARIO 1 PASSED ***");
      else $display("    *** SCENARIO 1 FAILED ***");

      // ========================================================================
      // SCENARIO 2: Injected Failures and Recovery
      // ========================================================================
      $display("--- SCENARIO 2: Injecting Failures Midway ---");
      start_errors = total_errors;

      // Hardware reset to clear DUT clock-gating before new scenario
      reset = 1'b1;
      @(negedge clk);
      @(negedge clk);
      reset = 1'b0;
      @(negedge clk);
      
      per_lane_iter_cnt = 0;
      for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
        per_lane_pat_cnt[lane] = 0;
        latched_golden[lane] = 1'b0;
      end

      for (cycle = 0; cycle < 32; cycle = cycle + 1) begin
        for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
          for (word = 0; word < 4; word = word + 1) begin
            if (cycle == 10) begin
               tb_lanes[lane][word] = 16'hDEAD; // Inject failure
            end else begin
               tb_lanes[lane][word] = {4'b1010, 8'(lane), 4'b1010};
            end
          end
        end
        for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
          data_in[lane] = {tb_lanes[lane][3], tb_lanes[lane][2], tb_lanes[lane][1], tb_lanes[lane][0]};
        end
        @(negedge clk);
        get_per_lane_id_results(tb_lanes, current_mode, golden_success);
        for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
          if (golden_success[lane]) latched_golden[lane] = 1'b1;
        end
      end
      
      for (lane = 0; lane < pNUM_LANES; lane = lane + 1) data_in[lane] = 64'h0;
      @(negedge clk); @(negedge clk);

      for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
        expected_bit = latched_golden[lane];
        actual_bit   = laneid_success[lane];
        if (enable[lane] == 1'b1) begin
          if (actual_bit !== expected_bit) begin
            $error("S2 FAIL [%03b] Active Lane %0d - Expected: %0b, Got: %0b", current_mode, lane, expected_bit, actual_bit);
            total_errors = total_errors + 1;
          end
        end else begin
          if (actual_bit !== 1'b0) begin
            $error("S2 FAIL [%03b] Inactive Lane %0d - Expected: 0, Got: %0b", current_mode, lane, actual_bit);
            total_errors = total_errors + 1;
          end
        end
      end

      if (total_errors == start_errors) $display("    *** SCENARIO 2 PASSED ***");
      else $display("    *** SCENARIO 2 FAILED ***");

      // ========================================================================
      // SCENARIO 3: Random Noise Initialization
      // ========================================================================
      $display("--- SCENARIO 3: Random Noise Followed By Valid Patterns ---");
      start_errors = total_errors;
      
      // Hardware reset to clear DUT clock-gating before new scenario
      reset = 1'b1;
      @(negedge clk);
      @(negedge clk);
      reset = 1'b0;
      @(negedge clk);

      per_lane_iter_cnt = 0;
      for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
        per_lane_pat_cnt[lane] = 0;
        latched_golden[lane] = 1'b0;
      end

      // 15 cycles of pure random garbage noise
      for (cycle = 0; cycle < 15; cycle = cycle + 1) begin
        for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
          for (word = 0; word < 4; word = word + 1) begin
             tb_lanes[lane][word] = $urandom();
          end
        end
        for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
          data_in[lane] = {tb_lanes[lane][3], tb_lanes[lane][2], tb_lanes[lane][1], tb_lanes[lane][0]};
        end
        @(negedge clk);
        get_per_lane_id_results(tb_lanes, current_mode, golden_success);
        for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
          if (golden_success[lane]) latched_golden[lane] = 1'b1;
        end
      end

      // 32 cycles of valid data
      for (cycle = 0; cycle < 32; cycle = cycle + 1) begin
        for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
          for (word = 0; word < 4; word = word + 1) begin
             tb_lanes[lane][word] = {4'b1010, 8'(lane), 4'b1010};
          end
        end
        for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
          data_in[lane] = {tb_lanes[lane][3], tb_lanes[lane][2], tb_lanes[lane][1], tb_lanes[lane][0]};
        end
        @(negedge clk);
        get_per_lane_id_results(tb_lanes, current_mode, golden_success);
        for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
          if (golden_success[lane]) latched_golden[lane] = 1'b1;
        end
      end
      
      for (lane = 0; lane < pNUM_LANES; lane = lane + 1) data_in[lane] = 64'h0;
      @(negedge clk); @(negedge clk);

      for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
        expected_bit = latched_golden[lane];
        actual_bit   = laneid_success[lane];
        if (enable[lane] == 1'b1) begin
          if (actual_bit !== expected_bit) begin
            $error("S3 FAIL [%03b] Active Lane %0d - Expected: %0b, Got: %0b", current_mode, lane, expected_bit, actual_bit);
            total_errors = total_errors + 1;
          end
        end else begin
          if (actual_bit !== 1'b0) begin
            $error("S3 FAIL [%03b] Inactive Lane %0d - Expected: 0, Got: %0b", current_mode, lane, actual_bit);
            total_errors = total_errors + 1;
          end
        end
      end

      if (total_errors == start_errors) $display("    *** SCENARIO 3 PASSED ***");
      else $display("    *** SCENARIO 3 FAILED ***");

      // ========================================================================
      // SCENARIO 4: Wrong Lane ID (Cross-Talk Simulation)
      // ========================================================================
      $display("--- SCENARIO 4: Valid Framing but Wrong Lane IDs ---");
      start_errors = total_errors;

      // Hardware reset to clear DUT clock-gating before new scenario
      reset = 1'b1;
      @(negedge clk);
      @(negedge clk);
      reset = 1'b0;
      @(negedge clk);
      
      per_lane_iter_cnt = 0;
      for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
        per_lane_pat_cnt[lane] = 0;
        latched_golden[lane] = 1'b0;
      end

      for (cycle = 0; cycle < 32; cycle = cycle + 1) begin
        for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
          wrong_lane_id = (lane + 1) % pNUM_LANES; // Shift ID by 1
          for (word = 0; word < 4; word = word + 1) begin
             tb_lanes[lane][word] = {4'b1010, wrong_lane_id, 4'b1010};
          end
        end
        for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
          data_in[lane] = {tb_lanes[lane][3], tb_lanes[lane][2], tb_lanes[lane][1], tb_lanes[lane][0]};
        end
        @(negedge clk);
        get_per_lane_id_results(tb_lanes, current_mode, golden_success);
        for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
          if (golden_success[lane]) latched_golden[lane] = 1'b1;
        end
      end
      
      for (lane = 0; lane < pNUM_LANES; lane = lane + 1) data_in[lane] = 64'h0;
      @(negedge clk); @(negedge clk);

      for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
        expected_bit = latched_golden[lane]; // Expected to be 0
        actual_bit   = laneid_success[lane];
        if (actual_bit !== expected_bit) begin
          $error("S4 FAIL [%03b] Lane %0d incorrectly asserted success on wrong ID!", current_mode, lane);
          total_errors = total_errors + 1;
        end
      end

      if (total_errors == start_errors) $display("    *** SCENARIO 4 PASSED ***");
      else $display("    *** SCENARIO 4 FAILED ***");

      // ========================================================================
      // SCENARIO 5: Highly Randomized Interleaved Valid/Invalid Sequences
      // ========================================================================
      $display("--- SCENARIO 5: Highly Randomized Interleaved Validation ---");
      start_errors = total_errors;

      // Hardware reset to clear DUT clock-gating before new scenario
      reset = 1'b1;
      @(negedge clk);
      @(negedge clk);
      reset = 1'b0;
      @(negedge clk);
      
      per_lane_iter_cnt = 0;
      for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
        per_lane_pat_cnt[lane] = 0;
        latched_golden[lane] = 1'b0;
      end

      // Extended 100-cycle randomized blast
      for (cycle = 0; cycle < 100; cycle = cycle + 1) begin
        for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
          is_valid_coin_toss = $urandom_range(0, 1);
          for (word = 0; word < 4; word = word + 1) begin
             if (is_valid_coin_toss) begin
                 tb_lanes[lane][word] = {4'b1010, 8'(lane), 4'b1010};
             end else begin
                 tb_lanes[lane][word] = $urandom();
             end
          end
        end
        for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
          data_in[lane] = {tb_lanes[lane][3], tb_lanes[lane][2], tb_lanes[lane][1], tb_lanes[lane][0]};
        end
        @(negedge clk);
        get_per_lane_id_results(tb_lanes, current_mode, golden_success);
        for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
          if (golden_success[lane]) latched_golden[lane] = 1'b1;
        end
      end
      
      for (lane = 0; lane < pNUM_LANES; lane = lane + 1) data_in[lane] = 64'h0;
      @(negedge clk); @(negedge clk);

      for (lane = 0; lane < pNUM_LANES; lane = lane + 1) begin
        expected_bit = latched_golden[lane];
        actual_bit   = laneid_success[lane];
        if (enable[lane] == 1'b1) begin
          if (actual_bit !== expected_bit) begin
            $error("S5 FAIL [%03b] Active Lane %0d - Expected: %0b, Got: %0b", current_mode, lane, expected_bit, actual_bit);
            total_errors = total_errors + 1;
          end
        end else begin
          if (actual_bit !== 1'b0) begin
            $error("S5 FAIL [%03b] Inactive Lane %0d - Expected: 0, Got: %0b", current_mode, lane, actual_bit);
            total_errors = total_errors + 1;
          end
        end
      end

      if (total_errors == start_errors) $display("    *** SCENARIO 5 PASSED ***");
      else $display("    *** SCENARIO 5 FAILED ***");

      $display(" "); // formatting spacer
    end // map_idx loop

    // ========================================================================
    // Final Report Summary
    // ========================================================================
    $display("=======================================================");
    if (total_errors == 0) begin
      $display("  TEST RESULT: SUCCESS (0 Errors against Golden Model)");
    end else begin
      $display("  TEST RESULT: FAILED (%0d Total RTL Mismatches)", total_errors);
    end
    $display("=======================================================\n");
    
    $finish;
  end

endmodule : tb_per_lane_id_detector