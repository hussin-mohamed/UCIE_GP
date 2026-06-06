// File: tb_top.sv
`include "svaunit_defines.svh"
import uvm_pkg::*;

module tb_top;
  `SVAUNIT_UTILS

  // Clock generation
  bit i_clk;
  bit clk_800MHz;

  initial forever #16 i_clk = ~i_clk;     // 32 time units
  initial forever #2 clk_800MHz = ~clk_800MHz;  // 4 time units

  // Latch the start pulse and clear it on reset or timeout
  bit timer_en = 0;
  always @(posedge i_clk) begin
    if (dut_if.i_reset || dut_if.timeout) begin
      timer_en <= 1'b0; // Stop the timer when timeout asserts
    end else if (dut_if.i_sb_init_start) begin
      timer_en <= 1'b1; // Latches high on the pulse
    end
  end

  // Generate the 1ms pulse exactly fitting 7 pattern iterations (84 i_clk cycles)
  int ms_counter = 0;
  always @(posedge i_clk) begin
    // USE THE LATCHED ENABLE HERE
    if (dut_if.i_reset || !timer_en) begin
      ms_counter <= 0;
      dut_if.i_timer_1ms <= 1'b0;
    end else begin
      // Count 0 to 83 to create an exact 84-cycle interval
      if (ms_counter == 83) begin
        dut_if.i_timer_1ms <= 1'b1; // Pulse high for 1 logic cycle
        ms_counter <= 0;
      end else begin
        dut_if.i_timer_1ms <= 1'b0;
        ms_counter <= ms_counter + 1;
      end
    end
  end

  // always @(dut_if.i_reset) begin
  //   if (dut_if.i_reset === 1'b1) begin
  //     // Stop any NEW assertions from firing
  //     $assertoff(0, dut_if); 
      
  //     // Kill all CURRENTLY RUNNING assertion threads
  //     $assertkill(0, dut_if);
      
  //     `uvm_info("SVA_CTRL", "Reset active: Assertions disabled and killed.", UVM_LOW)
  //   end 
  //   else if (dut_if.i_reset === 1'b0) begin
  //     // Resume starting new assertions when reset drops
  //     $asserton(0, dut_if);
      
  //     `uvm_info("SVA_CTRL", "Reset de-asserted: Assertions enabled.", UVM_LOW)
  //   end
  // end

  // Instantiate your SVA interface
  sb_sva dut_if(
    .i_clk(i_clk),
    .clk_800MHz(clk_800MHz)
    // The remaining interface signals are driven directly by each SVA unit test.
  );

  initial begin
    // Pass interface to the test
    uvm_config_db#(virtual sb_sva)::set(uvm_root::get(), "*", "VIF", dut_if);
    run_test("timeout_pat_gen_test");
  end
endmodule
