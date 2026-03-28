// File: glitch_neg_pat_gen_test.sv

`include "uvm_macros.svh"
`include "svaunit_defines.svh"
import uvm_pkg::*;
import svaunit_pkg::*;

class glitch_neg_pat_gen_test extends svaunit_test;
  `uvm_component_utils(glitch_neg_pat_gen_test)

  virtual sb_sva vif;

  int tx_iterations_completed = 0;
  int rx_iterations_completed = 0;

  function new(string name = "glitch_neg_pat_gen_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sb_sva)::get(this, "", "VIF", vif)) begin
      `uvm_fatal("NO_VIF", "SVA IF is not set!")
    end
  endfunction

  // ------------------------------------------------------------------------
  // Helper Task: TX Generator (Now with an optional Glitch Injector!)
  // ------------------------------------------------------------------------
  task tx_pattern_iteration(bit inject_glitch = 0);
    // 64 cycles of alternating 1 and 0 (Normal behavior)
    for (int i = 0; i < 64; i++) begin
      @(posedge vif.clk_1x);
      vif.o_tx_sb_data <= (i % 2 == 0) ? 1'b1 : 1'b0;
    end
    
    // 32 cycles of 0 (With a potential hardware bug!)
    for (int i = 0; i < 32; i++) begin
      @(posedge vif.clk_1x);
      
      // BUG INJECTION: On the 15th clock of the quiet period, the FSM twitches high!
      if (inject_glitch && i == 15) begin
        vif.o_tx_sb_data <= 1'b1; 
      end else begin
        vif.o_tx_sb_data <= 1'b0;
      end
    end
  endtask

  // ------------------------------------------------------------------------
  // Helper Task: RX Generator (Behaves Perfectly)
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
    vif.i_sb_init_start <= 1'b0;
    vif.o_tx_sb_data    <= 1'b0;
    vif.i_rx_sb_data    <= 1'b0;
    vif.i_rx_sb_clk     <= 1'b0;

    @(posedge vif.i_clk);
    vif.i_sb_init_start <= 1'b1;

    fork
      // ==================================================================
      // THREAD 1: The Remote Die (Flawless)
      // ==================================================================
      begin
        repeat(45) @(posedge vif.clk_1x); 
        
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
      // THREAD 2: The Local Die (Bugged)
      // ==================================================================
      begin
        @(posedge vif.i_clk);

        // Wait for RX to finish its 2 loops. The TX is clean here.
        while (rx_iterations_completed < 2) begin
          tx_pattern_iteration(1'b0); // No glitch
          tx_iterations_completed++;
        end

        // Do 3 perfectly clean final loops
        for (int i = 0; i < 3; i++) begin
          tx_pattern_iteration(1'b0); // No glitch
          tx_iterations_completed++;
        end
        
        // ----------------------------------------------------------------
        // INJECT THE BUG ON THE VERY LAST ITERATION
        // The quiet period will be interrupted by a 1-cycle spike.
        // ----------------------------------------------------------------
        tx_pattern_iteration(1'b1); // INJECT GLITCH!
        tx_iterations_completed++;
        
      end
    join

    repeat(20) @(posedge vif.i_clk);

    // --------------------------------------------------------------------
    // CHECKER VALIDATION
    // If the SVA says this passed, the SVA is blinding trusting a delay 
    // instead of actively monitoring the data line during the quiet period!
    // --------------------------------------------------------------------
    // `fail_if_sva_succeeded("tb_top.dut_if.ap_pat_gen", "DANGER: The SVA passed even though the TX data line glitched high during the 32-cycle quiet period!")
  endtask

endclass