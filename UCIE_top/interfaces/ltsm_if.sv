//=============================================================================
// File       : ltsm_if.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: Link Training State Machine (LTSM) Controller interface.
//              Bypasses the physical internal state machine, acting as a
//              direct control vector into the TX Controller.
//
//              The TB drives tx_encoding and lane_map; the DUT responds
//              with status outputs (pll_stable, supply_stable, tx_done).
//=============================================================================

interface ltsm_if (
  input logic clk,
  input logic rst
);

  import tx_defs_pkg::*;

  // -------------------------------------------------------------------------
  //  Signals driven TO the DUT
  // -------------------------------------------------------------------------

  // 9-bit state encoding — selects the active LTSM state/substate
  ltsm_encoding_e tx_encoding;

  // 3-bit lane map configuration for width degradation/reversal
  //   000 = Degrade not possible
  //   001 = Lanes 0-7 functional (disable 8-15)
  //   010 = Lanes 8-15 functional (disable 0-7)
  //   011 = All lanes functional (no degradation)
  logic [2:0] lane_map;

  // -------------------------------------------------------------------------
  //  Signals driven FROM the DUT
  // -------------------------------------------------------------------------

  // PLL lock indicator — asserted when PLL is stable after power-up
  logic pll_stable;

  // Power supply indicator — asserted when supply rails are stable
  logic supply_stable;

  // asserted by DUT when current state's
  // operation is complete (pattern gen done, handshake acknowledged, etc.)
  logic tx_done;

  // -------------------------------------------------------------------------
  //  Modports
  // -------------------------------------------------------------------------

  // Driver side (TB drives encoding + lane_map; samples DUT responses)
  modport drv_mp (
    input  clk, rst, pll_stable, supply_stable, tx_done,
    output tx_encoding, lane_map
  );

  // Monitor side (TB samples all signals passively)
  modport mon_mp (
    input clk, rst, tx_encoding, lane_map,
          pll_stable, supply_stable, tx_done
  );

  // DUT side (DUT receives encoding + lane_map; drives status outputs)
  modport dut_mp (
    input  clk, rst, tx_encoding, lane_map,
    output pll_stable, supply_stable, tx_done
  );

endinterface : ltsm_if
