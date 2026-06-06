// ============================================================================
// TESTBENCH MODULE: tb_ucie_lane_to_byte
// ============================================================================
module tb_ucie_lane_to_byte;
  import uvm_pkg::*;
  import b2l_pkg::*;
  `include "uvm_macros.svh"

  // --------------------------------------------------------------------------
  // Module-Level Signals
  // --------------------------------------------------------------------------
  logic                    clk;
  logic                    reset;
  logic                    enable;
  logic [2:0]              lane_map_code;
  logic [15:0][63:0]       dut_lanes_in;
  logic [2047:0]           dut_pl_data_out;
  logic                    dut_pl_valid_out;

  // Reference model inputs/outputs
  logic [(pDATA_WIDTH/8)-1:0][7:0] ref_lanes_in [pNUM_LANES];
  logic [pNBYTES-1:0][7:0]         ref_data_out;
  logic [2047:0]                   packed_ref_data;

  // --------------------------------------------------------------------------
  // DUT Instantiation
  // --------------------------------------------------------------------------
  ucie_lane_to_byte #(
    .pDATA_IN_WIDTH  (64),
    .pDATA_OUT_WIDTH (2048)
  ) u_dut (
    .i_clk           (clk),
    .i_reset         (reset),
    .i_enable        (enable),
    .i_lane_map_code (lane_map_code),
    .i_lane_0        (dut_lanes_in[0]),
    .i_lane_1        (dut_lanes_in[1]),
    .i_lane_2        (dut_lanes_in[2]),
    .i_lane_3        (dut_lanes_in[3]),
    .i_lane_4        (dut_lanes_in[4]),
    .i_lane_5        (dut_lanes_in[5]),
    .i_lane_6        (dut_lanes_in[6]),
    .i_lane_7        (dut_lanes_in[7]),
    .i_lane_8        (dut_lanes_in[8]),
    .i_lane_9        (dut_lanes_in[9]),
    .i_lane_10       (dut_lanes_in[10]),
    .i_lane_11       (dut_lanes_in[11]),
    .i_lane_12       (dut_lanes_in[12]),
    .i_lane_13       (dut_lanes_in[13]),
    .i_lane_14       (dut_lanes_in[14]),
    .i_lane_15       (dut_lanes_in[15]),
    .o_pl_data       (dut_pl_data_out),
    .o_pl_valid      (dut_pl_valid_out)
  );

  // --------------------------------------------------------------------------
  // Clock Generation
  // --------------------------------------------------------------------------
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // --------------------------------------------------------------------------
  // Main Verification Sequence
  // --------------------------------------------------------------------------
  initial begin
    // STRICT SCOPE DECLARATIONS (Verilog-2001 style)
    int map_idx;
    int iter_idx;
    int lane_idx;
    int byte_idx;
    int start_lane;
    int num_active_lanes;
    int num_iters;
    int total_errors;
    int local_errors;
    int wait_cycles;
    
    logic [2:0] test_map_code;
    logic [2:0] supported_codes [5];
    byte random_byte;

    // STATEMENTS & INITIALIZATIONS
    total_errors = 0;
    enable       = 1'b0;
    dut_lanes_in = '0;

    // Initialize supported lane map codes manually
    supported_codes[0] = 3'b011; // x16 mode (2 iterations)
    supported_codes[1] = 3'b001; // x8 lower (4 iterations)
    supported_codes[2] = 3'b010; // x8 upper (4 iterations)
    supported_codes[3] = 3'b100; // x4 lower (8 iterations)
    supported_codes[4] = 3'b101; // x4 upper (8 iterations)

    $display("\n=======================================================");
    $display("  STARTING LANE-TO-BYTE (L2B) RTL UNIT TESTBENCH");
    $display("=======================================================\n");


    repeat (1000) begin
      // 2. Stimulus & Verification Loop
      for (map_idx = 0; map_idx < 5; map_idx = map_idx + 1) begin
        reset = 1'b1;
        repeat(5) @(posedge clk);
        reset = 1'b0;
        @(posedge clk);

        test_map_code = supported_codes[map_idx];
        local_errors  = 0;

        // Decode expected active lanes and required iterations
        case (test_map_code)
          3'b011: begin start_lane = 0; num_active_lanes = 16; num_iters = 2; end
          3'b001: begin start_lane = 0; num_active_lanes = 8;  num_iters = 4; end
          3'b010: begin start_lane = 8; num_active_lanes = 8;  num_iters = 4; end
          3'b100: begin start_lane = 0; num_active_lanes = 4;  num_iters = 8; end
          3'b101: begin start_lane = 4; num_active_lanes = 4;  num_iters = 8; end
          default: $fatal(1, "Unsupported lane map code in TB.");
        endcase

        $display(">>> TESTING MAP CODE: %3b | Active Lanes: %0d-%0d <<<", 
                 test_map_code, start_lane, (start_lane + num_active_lanes - 1));

        // Configure DUT inputs for the current mode
        lane_map_code = test_map_code;
        enable        = 1'b1;
        ref_data_out  = '0; // Clear reference buffer

        // Shift Register Fill Loop (Requires continuous data driving)
        for (iter_idx = 0; iter_idx < num_iters; iter_idx = iter_idx + 1) begin
          // Generate random data for all 16 physical lanes
          for (lane_idx = 0; lane_idx < pNUM_LANES; lane_idx = lane_idx + 1) begin
            for (byte_idx = 0; byte_idx < 8; byte_idx = byte_idx + 1) begin
              random_byte = $urandom();
              
              // Assign to DUT 64-bit packed vector
              dut_lanes_in[lane_idx][(byte_idx*8) +: 8] = random_byte;
              
              // Assign to Ref Model 2D packed array ([7:0][7:0])
              ref_lanes_in[lane_idx][byte_idx] = random_byte;
            end
          end

          // Call the reference model to accumulate data for this iteration
          lane2byte(ref_lanes_in, test_map_code, ref_data_out);

          // Advance 1 clock cycle to let RTL shift registers capture the data
          @(posedge clk);
        end

        // Dynamically wait for o_pl_valid to assert (with a timeout safeguard)
        wait_cycles = 0;
        while (dut_pl_valid_out !== 1'b1 && wait_cycles < 50) begin
          @(posedge clk);
          wait_cycles = wait_cycles + 1;
        end

        // Verification Step
        if (dut_pl_valid_out !== 1'b1) begin
          $error("[%3b] TIMEOUT FAIL: o_pl_valid was never asserted by the RTL!", test_map_code);
          local_errors = local_errors + 1;
        end else begin
          // Pack the reference multi-dimensional array into a flat 2048-bit vector for direct comparison
          packed_ref_data = ref_data_out;

          if (dut_pl_data_out !== packed_ref_data) begin
            $error("[%3b] DATA MISMATCH FAIL! \nExpected: %h\nGot     : %h", 
                   test_map_code, packed_ref_data, dut_pl_data_out);
            local_errors = local_errors + 1;
          end
        end

        total_errors = total_errors + local_errors;
        if (local_errors == 0) begin
          $display("    -> PASSED.");
        end

        // Disable enable and flush for a few clocks before the next test
        enable = 1'b0;
        repeat(3) @(posedge clk);
        
      end // End of map codes loop
    end
    
    // ------------------------------------------------------------------------
    // Final Report
    // ------------------------------------------------------------------------
    $display("=======================================================");
    if (total_errors == 0) begin
      $display("  TEST RESULT: SUCCESS (0 Errors Across All Modes)");
    end else begin
      $display("  TEST RESULT: FAILED (%0d Total Errors)", total_errors);
    end
    $display("=======================================================\n");
    $stop;
  end

endmodule : tb_ucie_lane_to_byte