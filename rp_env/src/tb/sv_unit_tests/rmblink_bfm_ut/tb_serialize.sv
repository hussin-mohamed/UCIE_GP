`include "uvm_macros.svh"
`include "../shared_pkg.sv"
import uvm_pkg::*;
// Assuming shared_pkg contains pDATA_WIDTH and pNUM_LANES as you imported in the BFM
import shared_pkg::*; 

`include "../../bfms/rp_rmblink_bfm.sv"

module tb_serialize;

  // ---------------------------------------------------------
  // 1. Clock and Reset Generation
  // ---------------------------------------------------------
  logic clk    = 0;
  logic i_hclk = 0;
  logic i_dclk = 0;
  logic reset  = 1;

  // Generate clocks
  initial forever #4 clk    = ~clk;
  initial forever #2 i_hclk = ~i_hclk;
  initial forever #1 i_dclk = ~i_dclk;

  // Release reset
  initial begin
    #10 reset = 0;
  end

  // ---------------------------------------------------------
  // 2. BFM Interface Instantiation
  // ---------------------------------------------------------
  rp_rmblink_bfm bfm_inst(
    .clk(clk),
    .i_hclk(i_hclk),
    .i_dclk(i_dclk),
    .reset(reset)
  );

  // ---------------------------------------------------------
  // 3. Randomized Directed Test Sequence
  // ---------------------------------------------------------
  initial begin
    // Transaction variables
    logic [pDATA_WIDTH-1:0] tx_data [pNUM_LANES];
    logic [pDATA_WIDTH-1:0] rx_data [pNUM_LANES];
    
    logic [7:0] tx_val_stream [];
    logic [7:0] rx_val_stream [];
    logic       tx_clk_stream_p [];
    logic       tx_clk_stream_n [];
    logic       tx_track_stream [];
    
    int num_bytes = pDATA_WIDTH / 8;
    int idle_ui_cnt;
    
    // Test configuration
    int NUM_ITERATIONS = 100;
    int total_errors   = 0;
    int current_errors = 0;

    // Allocate dynamic arrays
    tx_val_stream   = new[num_bytes];
    tx_clk_stream_p = new[pDATA_WIDTH];
    tx_clk_stream_n = new[pDATA_WIDTH];
    tx_track_stream = new[pDATA_WIDTH];

    // Wait for reset to drop before starting
    @(negedge reset);
    $display("Starting Randomized Loopback Test with %0d iterations at time %0t...\n", NUM_ITERATIONS, $time);

    // =========================================================
    // RANDOMIZATION LOOP
    // =========================================================
    for (int iter = 1; iter <= NUM_ITERATIONS; iter++) begin
      $display("--- Starting Iteration %0d ---", iter);
      current_errors = 0;

      // 1. Randomize the Stimulus
      for (int i = 0; i < pNUM_LANES; i++) begin
        // SystemVerilog $urandom returns 32 bits, so we concatenate two to fill the 64-bit lane
        tx_data[i] = {$urandom(), $urandom()}; 
      end
      
      // Randomize idle UI between transactions (e.g., between 2 and 10 UIs)
      idle_ui_cnt = $urandom_range(2, 10);

      // Populate streams (Keeping protocol valid/clocking standard for the BFM to lock onto)
      for (int i = 0; i < pDATA_WIDTH; i++) begin
        tx_clk_stream_p[i] = (i % 2 == 0) ? 1'b1 : 1'b0;
        tx_clk_stream_n[i] = (i % 2 == 0) ? 1'b0 : 1'b1;
        tx_track_stream[i] = (i % 2 == 0) ? 1'b1 : 1'b0;
      end
      for (int i = 0; i < num_bytes; i++) begin
        tx_val_stream[i] = 8'b0000_1111;
      end

      // 2. Execute Loopback using the BFM instance
      fork
        begin
          bfm_inst.serialize_data(tx_data, tx_val_stream, tx_clk_stream_p, tx_clk_stream_n, tx_track_stream, idle_ui_cnt);
        end
        begin
          bfm_inst.deserialize_data(rx_data, rx_val_stream);
        end
      join

      // 3. Self-Checking for this iteration
      for (int lane = 0; lane < pNUM_LANES; lane++) begin
        if (rx_data[lane] !== tx_data[lane]) begin
          $error("Iter %0d | Lane %0d MISMATCH! \n  TX: %h \n  RX: %h", iter, lane, tx_data[lane], rx_data[lane]);
          current_errors++;
        end
      end
      
      if (rx_val_stream.size() != tx_val_stream.size()) begin
        $error("Iter %0d | Valid Stream Size Mismatch! TX: %0d, RX: %0d", iter, tx_val_stream.size(), rx_val_stream.size());
        current_errors++;
      end else begin
        for (int i = 0; i < tx_val_stream.size(); i++) begin
          if (rx_val_stream[i] !== tx_val_stream[i]) begin
            $error("Iter %0d | Valid Byte %0d MISMATCH! TX: %b, RX: %b", iter, i, tx_val_stream[i], rx_val_stream[i]);
            current_errors++;
          end
        end
      end

      if (current_errors == 0) begin
        $display("Iteration %0d PASSED. (Idle UIs generated: %0d)\n", iter, idle_ui_cnt);
      end else begin
        $display("Iteration %0d FAILED with %0d errors.\n", iter, current_errors);
      end
      
      total_errors += current_errors;
    end

    // ---------------------------------------------------------
    // 4. Final Results
    // ---------------------------------------------------------
    $display("=========================================");
    $display("          FINAL TEST SUMMARY             ");
    $display("=========================================");
    if (total_errors == 0) 
      $display(">>> ALL %0d ITERATIONS PASSED SUCCESSFULLY! <<<", NUM_ITERATIONS);
    else 
      $display(">>> TEST FAILED WITH %0d TOTAL ERRORS. <<<", total_errors);
    $display("=========================================\n");

    // Give the simulation a moment to breathe before finishing
    repeat(10) @(posedge i_dclk);
    $stop;
  end

endmodule