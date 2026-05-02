//=============================================================================
// File       : tx_tb_pkg.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: Testbench-level package. Imports UVM and tx_defs_pkg, then
//              includes all verification component class files in dependency
//              order. This is the single import point for the entire TB.
//=============================================================================

package tx_tb_pkg;

  // -------------------------------------------------------------------------
  //  Standard imports
  // -------------------------------------------------------------------------
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import tx_defs_pkg::*;

  // -------------------------------------------------------------------------
  //  Layer 1: Sequence Items
  // -------------------------------------------------------------------------
  `include "rdi_seq_item.sv"
  `include "ltsm_seq_item.sv"
  `include "tx2link_item.sv"

  // -------------------------------------------------------------------------
  //  Layer 2: Configuration
  // -------------------------------------------------------------------------
  `include "tx_env_cfg.sv"

  // -------------------------------------------------------------------------
  //  Layer 3: Agent Components
  // -------------------------------------------------------------------------
  `include "rdi_driver.sv"
  `include "rdi_monitor.sv"
  `include "rdi_sequencer.sv"
  `include "rdi_agent.sv"

  `include "ltsm_driver.sv"
  `include "ltsm_monitor.sv"
  `include "ltsm_sequencer.sv"
  `include "ltsm_agent.sv"

  `include "tx2link_monitor.sv"
  `include "tx2link_agent.sv"

  // -------------------------------------------------------------------------
  //  Layer 4: Sequencer Container & Sequences
  // -------------------------------------------------------------------------
  `include "sqr_pool.sv"
  `include "rdi_base_seq.sv"
  `include "ltsm_base_seq.sv"
  `include "tx_virtual_seq.sv"

  // -------------------------------------------------------------------------
  //  Layer 5: Reference Model & Checking
  // -------------------------------------------------------------------------
  `include "tx_predictor.sv"
  `include "tx_scoreboard.sv"
  `include "tx_coverage.sv"

  // -------------------------------------------------------------------------
  //  Layer 6: Environment
  // -------------------------------------------------------------------------
  `include "tx_env.sv"

  // -------------------------------------------------------------------------
  //  Layer 7: Tests
  // -------------------------------------------------------------------------
  `include "tx_base_test.sv"
  `include "tx_smoke_test.sv"

endpackage : tx_tb_pkg
