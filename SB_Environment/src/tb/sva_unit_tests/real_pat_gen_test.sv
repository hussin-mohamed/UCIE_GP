// File: real_pat_gen_test.sv

`include "uvm_macros.svh"
`include "svaunit_defines.svh"
import uvm_pkg::*;
import svaunit_pkg::*;

class real_pat_gen_test extends svaunit_test;
  `uvm_component_utils(real_pat_gen_test)

  virtual sb_sva vif;

  // Shared variables to mimic the hardware deserializers
  int tx_iterations_completed = 0;
  int rx_iterations_completed = 0;

  function new(string name = "real_pat_gen_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sb_sva)::get(this, "", "VIF", vif)) begin
      `uvm_fatal("NO_VIF", "SVA IF is not set!")
    end
    
    // Disable UVM timeout to allow long ms intervals
    uvm_top.set_timeout(0, 0); 
  endfunction

  // ------------------------------------------------------------------------
  // Helper Function: Get the expected bit for a specific index in the UI
  // ------------------------------------------------------------------------
  function logic get_pattern_bit(int idx);
    if (idx < 64) begin
      return (idx % 2 == 0) ? 1'b1 : 1'b0; // 101010...
    end else begin
      return 1'b0; // 32 UI low period
    end
  endfunction

  // ------------------------------------------------------------------------
  // Helper Task: Remote Die RX Generator 
  // ------------------------------------------------------------------------
  task rx_pattern_iteration();
    for (int i = 0; i < 64; i++) begin
      @(posedge vif.clk_1x);
      vif.i_rx_sb_clk  <= 1'b1;
      vif.i_rx_sb_data <= (i % 2 == 0) ? 1'b1 : 1'b0;

      @(negedge vif.clk_1x);
      vif.i_rx_sb_clk  <= 1'b0;
    end
    
    for (int i = 0; i < 32; i++) begin
      @(posedge vif.clk_1x);
      vif.i_rx_sb_clk  <= 1'b0;
      vif.i_rx_sb_data <= 1'b0;
    end
  endtask

  // ------------------------------------------------------------------------
  // Main Test Scenario
  // ------------------------------------------------------------------------
  task test();
    int ms_count = 0;
    int tx_bit_idx = 0;
    
    bit pattern_detected = 0;
    bit start_final_countdown = 0;
    int post_detect_iters = 0;

    // 1. Initialize
    vif.i_sb_init_start <= 1'b0;
    vif.o_tx_sb_data    <= 1'b0;
    vif.o_tx_sb_clk     <= 1'b0;
    vif.i_rx_sb_data    <= 1'b0;
    vif.i_rx_sb_clk     <= 1'b0;
    vif.o_sb_ready      <= 1'b0;

    // Asserting start on the negative edge to stress-test the synchronization
    @(negedge vif.i_clk);
    vif.i_sb_init_start <= 1'b1;

    fork
      // ==================================================================
      // THREAD 1: Background Timer (Tracks Even/Odd ms intervals)
      // ==================================================================
      begin
        forever @(posedge vif.i_clk) begin
          if (vif.i_timer_1ms) begin
            ms_count++;
          end
        end
      end

      // ==================================================================
      // THREAD 2: The Remote Die (RX Generation)
      // ==================================================================
      begin
        // Delay to intentionally force the TX die into a paused state
        // before detection happens.
        // repeat(2000) @(posedge vif.clk_1x); 
        
        while (tx_iterations_completed < 2) begin
          rx_pattern_iteration();
          rx_iterations_completed++;
        end
        
        for (int i = 0; i < 4; i++) begin
          rx_pattern_iteration();
          rx_iterations_completed++;
        end
      end

      // ==================================================================
      // THREAD 3: The Local Die (Unified Time-Multiplexed TX Generator)
      // ==================================================================
      begin
        // ----------------------------------------------------------------
        // THE FIX: Wait for the DUT to officially sample the start signal 
        // on the slow clock before generating fast-clock data.
        // ----------------------------------------------------------------
        @(posedge vif.i_clk);

        // Loop runs until we have completed exactly 4 full iterations AFTER detection
        while (post_detect_iters < 4) begin
          @(posedge vif.clk_1x);

          // 1. Asynchronous Detection Latch
          if (!pattern_detected && rx_iterations_completed >= 2) begin
            pattern_detected = 1;
          end

          // 2. The Gated Generator
          if (ms_count % 2 == 0) begin
            // --- ACTIVE WINDOW (Even ms) ---
            vif.o_tx_sb_data <= get_pattern_bit(tx_bit_idx);
            
            // Toggle the clock only during the 64-UI payload phase
            if (tx_bit_idx < 64) begin
              vif.o_tx_sb_clk <= 1'b1;
              @(negedge vif.clk_1x); // Wait half a cycle to pull it down
              vif.o_tx_sb_clk <= 1'b0;
            end else begin
              // During the 32-UI low phase, clock stays gated
              vif.o_tx_sb_clk <= 1'b0;
            end

            tx_bit_idx++;
            
            // Handle reaching the end of a 96 UI iteration
            if (tx_bit_idx == 96) begin
              tx_bit_idx = 0; 
              tx_iterations_completed++;
              
              if (start_final_countdown) begin
                post_detect_iters++;
              end

              if (pattern_detected && !start_final_countdown) begin
                start_final_countdown = 1;
              end
            end
          end else begin
            // --- PAUSE WINDOW (Odd ms) ---
            vif.o_tx_sb_data <= 1'b0;
            vif.o_tx_sb_clk  <= 1'b0; // Clock remains gated during pause
          end
        end

        // 3. Handshake
        @(posedge vif.i_clk);
        vif.o_sb_ready <= 1'b1;
      end
    join_any 

    repeat(100) @(posedge vif.i_clk);
  endtask

endclass