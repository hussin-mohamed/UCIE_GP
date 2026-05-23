//=============================================================================
// File       : rdi_if.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: Raw Die-to-Die Interface (RDI) between the D2D Adapter and
//              the TX Logical PHY. Carries flit payloads as a 2D byte array
//              with ready/valid handshaking.
//
//              Parameterized by NBYTES (flit size in bytes).
//=============================================================================

interface rdi_if #(parameter int NBYTES = 256) (
  input logic clk,
  input logic rst
);

  // -------------------------------------------------------------------------
  //  Signals
  // -------------------------------------------------------------------------

  // Flit data: 2D array of bytes [NBYTES-1:0][7:0]
  logic [NBYTES-1:0][7:0] lp_data;

  // Valid: asserted when lp_data carries a valid flit
  logic lp_valid;

  // Ready from LP (Link Partner / adapter side): indicates intent to send
  logic lp_irdy;

  // Ready from PL (Physical Layer): backpressure from PHY to adapter
  // When de-asserted, the adapter must hold lp_data, lp_valid, lp_irdy stable
  logic pl_trdy;

  // -------------------------------------------------------------------------
  //  Modports
  // -------------------------------------------------------------------------

  // Driver side (TB drives lp_data, lp_valid, lp_irdy; samples pl_trdy)
  modport drv_mp (
    input  clk, rst, pl_trdy,
    output lp_data, lp_valid, lp_irdy
  );

  // Monitor side (TB samples all signals passively)
  modport mon_mp (
    input clk, rst, lp_data, lp_valid, lp_irdy, pl_trdy
  );

  // DUT side (DUT receives lp_data, lp_valid, lp_irdy; drives pl_trdy)
  modport dut_mp (
    input  clk, rst, lp_data, lp_valid, lp_irdy,
    output pl_trdy
  );

endinterface : rdi_if
