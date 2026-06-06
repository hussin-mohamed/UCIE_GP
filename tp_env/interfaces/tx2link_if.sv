//=============================================================================
// File       : tx2link_if.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: TX to Link interface — the final physical output boundary
//              before the analog serial drivers. Carries serialized data
//              on 16 lanes plus forwarded clock, valid, and track signals.
//
//              Operates on the fast UI clock (half-rate: 1 fast clk = 2 UI).
//              The DUT includes a 16:1 serializer, so each of the 16 lanes
//              carries serial bit data.
//
//              The monitor must correctly detect and handle Hi-Z ('z) states
//              for lanes disabled via width degradation or during reset/init.
//=============================================================================

interface tx2link_if (
  input logic clk,      // Slow logical clock — frame boundary reference
  input logic ui_clk,
  input logic rst
);

  // -------------------------------------------------------------------------
  //  Physical Lane Signals
  // -------------------------------------------------------------------------

  // 16 serial data lanes — each carries 1 bit per UI (serialized)
  // During disabled/reset states these should be Hi-Z ('z)
  logic tx_data [0:15];

  // Forwarded differential clock pair
  logic tx_clkp;
  logic tx_clkn;

  // Physical valid lane
  logic tx_valid;

  // Track signal lane (used during training for synchronization)
  logic tx_track;

  // -------------------------------------------------------------------------
  //  Modports
  // -------------------------------------------------------------------------

  // Monitor side (passive — samples all output signals)
  modport mon_mp (
    input clk, ui_clk, rst, tx_data, tx_clkp, tx_clkn, tx_valid, tx_track
  );

  // DUT side (DUT drives all output signals)
  modport dut_mp (
    input  clk, ui_clk, rst,
    output tx_data, tx_clkp, tx_clkn, tx_valid, tx_track
  );

endinterface : tx2link_if
