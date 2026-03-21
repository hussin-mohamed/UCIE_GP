// File: corner_pat_gen_test.sv

`include "uvm_macros.svh"
`include "svaunit_defines.svh"
import uvm_pkg::*;
import svaunit_pkg::*;

class corner_pat_gen_test extends svaunit_test;
  `uvm_component_utils(corner_pat_gen_test)

  virtual sb_sva vif;

  int tx_iterations_completed = 0;
  int rx_iterations_completed = 0;

  function new(string name = "corner_pat_gen_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sb_sva)::get(this, "", "VIF", vif)) begin
      `uvm_fatal("NO_VIF", "SVA IF is not set!")
    end
  endfunction

  // ------------------------------------------------------------------------
  // Local Die TX Generator (Allows variable "or more" low UI)
  // ------------------------------------------------------------------------
  task tx_pattern_iteration(int low_ui = 32);
    // 64 cycles of alternating 1 and 0
    for (int i = 0; i < 64; i++) begin
      @(posedge vif.clk_1x);
      vif.o_tx_sb_data <= (i % 2 == 0) ? 1'b1 : 1'b0;
    end
    
    // Variable low period
    for (int i = 0; i < low_ui; i++) begin
      @(posedge vif.clk_1x);
      vif.o_tx_sb_data <= 1'b0;
    end
  endtask

  // ------------------------------------------------------------------------
  // Remote Die RX Generator (Allows variable "or more" low UI)
  // ------------------------------------------------------------------------
  task rx_pattern_iteration(int low_ui = 32);
    // 64 cycles of toggling clock and data
    for (int i = 0; i < 64; i++) begin
      @(posedge vif.clk_1x);
      vif.i_rx_sb_clk  <= 1'b1;
      vif.i_rx_sb_data <= (i % 2 == 0) ? 1'b1 : 1'b0;

      @(negedge vif.clk_1x);
      vif.i_rx_sb_clk  <= 1'b0;
    end
    
    // Variable low period (Clock is legally gated low, Data is low)
    for (int i = 0; i < low_ui; i++) begin
      @(posedge vif.clk_1x);
      vif.i_rx_sb_clk  <= 1'b0;
      vif.i_rx_sb_data <= 1'b0;
    end
  endtask

  // ------------------------------------------------------------------------
  // Corner Case Scenario
  // ------------------------------------------------------------------------
  task test();
    vif.i_sb_init_start <= 1'b0;
    vif.o_tx_sb_data    <= 1'b0;
    vif.i_rx_sb_data    <= 1'b0;
    vif.i_rx_sb_clk     <= 1'b0;

    // TRAP 1: The 1-Cycle Pulse
    @(posedge vif.i_clk);
    vif.i_sb_init_start <= 1'b1;
    @(posedge vif.i_clk);
    vif.i_sb_init_start <= 1'b0; // Dropped immediately!

    fork
      // ==================================================================
      // THREAD 1: The Remote Die (Injecting extreme delays)
      // ==================================================================
      begin
        // TRAP 3: Asynchronous Skew (Starts mid-TX cycle)
        repeat(117) @(posedge vif.clk_1x); 
        
        while (tx_iterations_completed < 2) begin
          // TRAP 2: The "Or More" Clause (145 UI and 60 UI instead of 32)
          int variable_delay = (rx_iterations_completed == 0) ? 145 : 60;
          rx_pattern_iteration(variable_delay);
          rx_iterations_completed++;
        end
        
        for (int i = 0; i < 4; i++) begin
          rx_pattern_iteration(32);
          rx_iterations_completed++;
        end
      end

      // ==================================================================
      // THREAD 2: The Local Die 
      // ==================================================================
      begin
        // Note: SVA evaluation started at the pulse, TX starts generating immediately
        while (rx_iterations_completed < 2) begin
          tx_pattern_iteration(32);
          tx_iterations_completed++;
        end

        for (int i = 0; i < 4; i++) begin
          tx_pattern_iteration(32);
          tx_iterations_completed++;
        end
      end
    join

    repeat(15) @(posedge vif.i_clk);
  endtask

endclass