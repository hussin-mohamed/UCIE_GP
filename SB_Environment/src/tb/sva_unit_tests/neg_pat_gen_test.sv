// File: neg_pat_gen_test.sv

`include "uvm_macros.svh"
`include "svaunit_defines.svh"
import uvm_pkg::*;
import svaunit_pkg::*;

class neg_pat_gen_test extends svaunit_test;
  `uvm_component_utils(neg_pat_gen_test)

  virtual sb_sva vif;

  int tx_iterations_completed = 0;
  int rx_iterations_completed = 0;

  function new(string name = "neg_pat_gen_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sb_sva)::get(this, "", "VIF", vif)) begin
      `uvm_fatal("NO_VIF", "SVA IF is not set!")
    end
  endfunction

  // ------------------------------------------------------------------------
  // Helper Task: TX Generator
  // ------------------------------------------------------------------------
  task tx_pattern_iteration();
    // 64 cycles of alternating 1 and 0
    for (int i = 0; i < 64; i++) begin
      @(posedge vif.clk_1x);
      vif.o_tx_sb_data <= (i % 2 == 0) ? 1'b1 : 1'b0;
    end
    
    // 32 cycles of 0
    for (int i = 0; i < 32; i++) begin
      @(posedge vif.clk_1x);
      vif.o_tx_sb_data <= 1'b0;
    end
  endtask

  // ------------------------------------------------------------------------
  // Helper Task: RX Generator
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
  // Negative Bug Injection Scenario
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
      // THREAD 1: The Remote Die (Behaves perfectly according to spec)
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
      // THREAD 2: The Local Die (INJECTING THE RTL BUG)
      // ==================================================================
      begin
        @(posedge vif.i_clk);

        while (rx_iterations_completed < 2) begin
          tx_pattern_iteration();
          tx_iterations_completed++;
        end

        // ----------------------------------------------------------------
        // BUG INJECTION: The spec mandates 4 iterations. 
        // We simulate a broken DUT that only outputs 3 iterations!
        // ----------------------------------------------------------------
        for (int i = 0; i < 3; i++) begin
          tx_pattern_iteration();
          tx_iterations_completed++;
        end
        
        // DUT completely flatlines after 3 iterations
        vif.o_tx_sb_data <= 1'b0;
      end
    join

    // Wait a significant amount of time to ensure the assertion realizes the 4th iteration is missing
    repeat(150) @(posedge vif.clk_1x);

    // --------------------------------------------------------------------
    // CHECKER VALIDATION
    // Notice we use fail_if_sva_SUCCEEDED here instead of NOT_SUCCEEDED.
    // We WANT the SVA to fail. If it passes, the SVA itself is broken!
    // --------------------------------------------------------------------
    // `fail_if_sva_succeeded("tb_top.dut_if.ap_pat_gen", "DANGER: The SVA passed even though the DUT missed the final iteration! SVA logic is flawed.")
  endtask

endclass