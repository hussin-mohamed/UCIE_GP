//=============================================================================
// File       : tx_dut_rtl_wrapper.sv
// Description: Wrapper for tx_path RTL DUT. Adapts the RTL interface to
//              the testbench interface (unpacked arrays, signal conversions).
//=============================================================================

`timescale 1ns/1ps

module tx_dut_rtl_wrapper #(
  parameter NBYTES = 256,
  parameter DATA_WIDTH = 64,
  parameter LANES_NUMBER = 16
) (
  input  logic        clk,
  input  logic        ui_clk,
  input  logic        rst,

  // From RDI Interface
  input  logic [NBYTES-1:0][7:0] lp_data,
  input  logic        lp_valid,
  input  logic        lp_irdy,
  output logic        pl_trdy,

  // From LTSM Interface
  input  logic [8:0]  tx_encoding,
  input  logic [2:0]  lane_map,
  output logic        pll_stable,
  output logic        supply_stable,
  output logic        tx_done,

  // To TX2LINK Interface
  output logic        tx_data [0:15],
  output logic        tx_clkp,
  output logic        tx_clkn,
  output logic        tx_valid,
  output logic        tx_track
);

  // -------------------------------------------------------------------------
  //  RTL Parameters
  // -------------------------------------------------------------------------
  localparam int pDATA_WIDTH   = 64;
  localparam int pNUM_LANES    = 16;
  localparam int pRDI_IN_WIDTH = 2048;

  // -------------------------------------------------------------------------
  //  Internal Signals - Data Type Conversions
  // -------------------------------------------------------------------------
  logic [pRDI_IN_WIDTH-1:0] rtl_lp_data;
  logic [pNUM_LANES-1:0]    rtl_data_out;

  // -------------------------------------------------------------------------
  //  Unpacked to Packed Conversion for lp_data
  // -------------------------------------------------------------------------
  always_comb begin
    for (int i = 0; i < NBYTES; i++) begin
      rtl_lp_data[i*8 +: 8] = lp_data[i];
    end
  end

  // -------------------------------------------------------------------------
  //  pll_stable and supply_stable Generation
  // -------------------------------------------------------------------------
  initial begin
    pll_stable = 1'b0;
    supply_stable = 1'b0;
    #50;
    pll_stable = 1'b1;
    supply_stable = 1'b1;
  end

  // -------------------------------------------------------------------------
  //  Packed to Unpacked Conversion for tx_data
  // -------------------------------------------------------------------------
  always_comb begin
    for (int i = 0; i < LANES_NUMBER; i++) begin
      tx_data[i] = rtl_data_out[i];
    end
  end

  // -------------------------------------------------------------------------
  //  TX Path RTL Instantiation
  // -------------------------------------------------------------------------
  tx_path #(
    .pDATA_WIDTH  (pDATA_WIDTH),
    .pNUM_LANES   (pNUM_LANES),
    .pRDI_IN_WIDTH(pRDI_IN_WIDTH)
  ) tx_path_dut (
    // Clock and reset
    .i_clk_l         (clk),
    .i_reset         (rst),
    .i_dclk          (ui_clk),

    // Control
    .i_halfrate      (1'b1),           // Half-rate mode (matches stub's 64:1 ratio)
    .i_lp_irdy       (lp_irdy),
    .i_lp_valid      (lp_valid),
    .i_tx_encoding   (tx_encoding),
    .i_lane_map_code (lane_map),

    // Data
    .i_lp_data       (rtl_lp_data),

    // Outputs
    .o_pl_trdy       (pl_trdy),
    .o_tx_done       (tx_done),
    .o_data_out      (rtl_data_out),
    .o_clk_p         (tx_clkp),
    .o_clk_n         (tx_clkn),
    .o_track         (tx_track),
    .o_valid         (tx_valid)
  );

endmodule
