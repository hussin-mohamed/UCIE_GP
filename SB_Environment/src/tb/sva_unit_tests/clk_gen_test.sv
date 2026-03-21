// File: clk_gen_test.sv
import uvm_pkg::*;
import svaunit_pkg::*;
`include "uvm_macros.svh"

class clk_gen_test extends svaunit_test;
  `uvm_component_utils(clk_gen_test)

  // Virtual interface handle to access your signals
  virtual sb_sva vif;

  function new(string name = "clk_gen_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sb_sva)::get(this, "", "VIF", vif)) begin
      `uvm_fatal("NO_VIF", "SVA IF is not set!")
    end
  endfunction

  // SVAUnit automatically monitors all assertions in the background while this runs!
  task test();
    // 1. Initialize to safe states
    vif.i_sb_init_start <= 1'b0;
    vif.o_tx_sb_clk     <= 1'b0;

    // 2. Align to the main logic clock and trigger the sequence
    @(posedge vif.i_clk);
    vif.i_sb_init_start <= 1'b1;

    // Wait for the next active clock edge
    @(posedge vif.i_clk);

    // 3. Drive o_tx_sb_clk to match clk_ser for 64 cycles
    for (int i = 0; i < 64; i++) begin
      @(posedge vif.clk_ser)  vif.o_tx_sb_clk <= 1'b1;
      @(negedge vif.clk_ser)  vif.o_tx_sb_clk <= 1'b0;
    end

    // 4. Keep o_tx_sb_clk low for 32 cycles
    for (int i = 0; i < 32; i++) begin
      @(posedge vif.clk_ser);
      vif.o_tx_sb_clk <= 1'b0;
    end

    // Wait exactly 1 more clk_ser cycle for the final clk_2x SVA sequence step to evaluate and register SUCCESS
    @(posedge vif.clk_ser);
  endtask

endclass