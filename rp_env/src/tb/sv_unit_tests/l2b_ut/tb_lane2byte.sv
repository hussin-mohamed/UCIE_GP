//=============================================================================
// PACKAGE: b2l_pkg
//=============================================================================
package b2l_pkg;
  `include "uvm_macros.svh"
  import uvm_pkg::*;

  parameter pNUM_LANES  = 16;
  parameter pDATA_WIDTH = 64;
  parameter pNBYTES     = 256;

  int l2b_iter_cnt;

  function void lane2byte(
     input  logic [(pDATA_WIDTH/8)-1:0][7:0] _lanes [pNUM_LANES]
    ,input  logic [2:0]                      _lane_map_code
    ,output logic [pNBYTES-1:0][7:0]         _data
  );

    int data_byte_idx;
    int lane_byte_idx;
    int lane_idx;
    int start_lane;
    int byte_step;
    int num_iter;

    // Determine offset based on your lane map code
    case (_lane_map_code)
      3'b001: begin start_lane = 0; byte_step = 8;  end // x8 mode, lower lanes
      3'b010: begin start_lane = 8; byte_step = 8;  end // x8 mode, upper lanes
      3'b011: begin start_lane = 0; byte_step = 16; end // x16 mode
      3'b100: begin start_lane = 0; byte_step = 4;  end // x4 mode, lower lanes
      3'b101: begin start_lane = 4; byte_step = 4;  end // x4 mode, upper lanes
      
      default:
      begin
        `uvm_fatal("PRD_L2B", $sformatf("Unsupported lane_map_code: %0b, Supported codes are 001b...101b", _lane_map_code))
      end
    endcase // lane_map_code

    for (int norm_idx = 0; norm_idx < byte_step; norm_idx++) begin
      logic [(pDATA_WIDTH/8)-1:0][7:0] lane;
      lane_idx = start_lane + norm_idx;
      lane = _lanes[lane_idx];

      for (int lane_byte_idx = 0; lane_byte_idx < (pDATA_WIDTH/8); lane_byte_idx++) begin
        data_byte_idx = byte_step*(8*l2b_iter_cnt + lane_byte_idx) + norm_idx;
        _data[data_byte_idx] = lane[lane_byte_idx];
      end
    end

    num_iter = (pNBYTES/(8*byte_step)) - 1;

    if (l2b_iter_cnt == num_iter) begin
      l2b_iter_cnt = 0;
    end else begin
      l2b_iter_cnt++;
    end
  endfunction : lane2byte

endpackage : b2l_pkg


//=============================================================================
// TESTBENCH MODULE: tb_lane2byte
//=============================================================================
module tb_lane2byte;
  import b2l_pkg::*;

  // 1. Module-level Declarations (No inline initialization)
  logic [(pDATA_WIDTH/8)-1:0][7:0] test_lanes [pNUM_LANES];
  logic [2:0]                      test_map_code;
  logic [pNBYTES-1:0][7:0]         actual_data;
  logic [pNBYTES-1:0][7:0]         expected_data;

  int start_lane;
  int num_active_lanes;
  int num_iters;
  int total_errors;
  int NUM_TRIALS;
  
  // Fixed-size array for supported codes to avoid dynamic array initialization issues
  logic [2:0] supported_codes [5]; 

  initial begin
    // ------------------------------------------------------------------------
    // STRICT SCOPE DECLARATIONS: All variables declared at the top of the block
    // ------------------------------------------------------------------------
    int idx;
    int trial;
    int byte_idx_counter;
    int iter;
    int l;
    int b;
    int physical_lane;
    byte random_val;
    int local_errors;
    int byte_idx;

    // ------------------------------------------------------------------------
    // STATEMENTS & INITIALIZATIONS START HERE
    // ------------------------------------------------------------------------
    total_errors = 0;
    NUM_TRIALS   = 5;

    // Manually assign the array to avoid inline list assignment errors
    supported_codes[0] = 3'b011; // x16 mode
    supported_codes[1] = 3'b001; // x8 mode (0-7)
    supported_codes[2] = 3'b010; // x8 mode (8-15)
    supported_codes[3] = 3'b100; // x4 mode (0-3)
    supported_codes[4] = 3'b101; // x4 mode (4-7)

    $display("\n=======================================================");
    $display("  STARTING STRICT-SYNTAX RANDOMIZED L2B TESTBENCH      ");
    $display("=======================================================\n");

    for (idx = 0; idx < 5; idx = idx + 1) begin
      test_map_code = supported_codes[idx];
      
      case (test_map_code)
        3'b011: begin start_lane = 0; num_active_lanes = 16; num_iters = 2; end
        3'b001: begin start_lane = 0; num_active_lanes = 8;  num_iters = 4; end
        3'b010: begin start_lane = 8; num_active_lanes = 8;  num_iters = 4; end
        3'b100: begin start_lane = 0; num_active_lanes = 4;  num_iters = 8; end
        3'b101: begin start_lane = 4; num_active_lanes = 4;  num_iters = 8; end
        default: $fatal(1, "Unsupported lane map code encountered in testbench array.");
      endcase

      $display("Testing Map Code: %3b | Mode: x%0d | Active Lanes: %0d-%0d | %0d Trials", 
                test_map_code, num_active_lanes, start_lane, (start_lane + num_active_lanes - 1), NUM_TRIALS);

      // Execute multiple randomized trials
      for (trial = 1; trial <= NUM_TRIALS; trial = trial + 1) begin
        
        actual_data   = '0;
        expected_data = '0;
        byte_idx_counter = 0; 

        for (iter = 0; iter < num_iters; iter = iter + 1) begin
          
          // Flush test_lanes with dummy data
          for (l = 0; l < pNUM_LANES; l = l + 1) begin
            for (b = 0; b < (pDATA_WIDTH/8); b = b + 1) begin
              test_lanes[l][b] = 8'hEE; 
            end
          end

          // Populate active lanes with random data
          for (b = 0; b < (pDATA_WIDTH/8); b = b + 1) begin
            for (l = 0; l < num_active_lanes; l = l + 1) begin
              
              // Variables assigned here, but declared at the top of the initial block
              physical_lane = start_lane + l;
              random_val    = $urandom(); 
              
              test_lanes[physical_lane][b] = random_val;
              expected_data[byte_idx_counter] = random_val;
              
              byte_idx_counter = byte_idx_counter + 1;
            end
          end

          lane2byte(test_lanes, test_map_code, actual_data);
          
        end 

        // Verification Step for this specific trial
        local_errors = 0;
        for (byte_idx = 0; byte_idx < pNBYTES; byte_idx = byte_idx + 1) begin
          if (actual_data[byte_idx] !== expected_data[byte_idx]) begin
            $error("Trial %0d | MISMATCH on Code %3b at Output Byte %0d! Expected: %h, Got: %h", 
                   trial, test_map_code, byte_idx, expected_data[byte_idx], actual_data[byte_idx]);
            local_errors = local_errors + 1;
          end
        end

        if (local_errors > 0) begin
          $display("    -> Trial %0d FAILED with %0d byte mismatches.", trial, local_errors);
        end
        total_errors = total_errors + local_errors;
        
      end // End of trials loop
      
      if (total_errors == 0) begin
         $display("  -> PASSED! All %0d randomized trials successful.\n", NUM_TRIALS);
      end else begin
         $display("  -> FAILED! Errors detected in trials.\n");
      end

    end // End of map codes loop

    // Final Report
    $display("=======================================================");
    if (total_errors == 0) begin
      $display("  TEST RESULT: SUCCESS (0 Errors Across All Trials)");
    end else begin
      $display("  TEST RESULT: FAILED (%0d Total Errors)", total_errors);
    end
    $display("=======================================================\n");
    $finish;
  end

endmodule : tb_lane2byte