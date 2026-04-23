// ****************************************************************************
// *                                                                          *
// * Copyright (c) 2014-2015 Synopsys Inc. All rights reserved.               *
// *                                                                          *
// * Synopsys Proprietary and Confidential. This file contains confidential   *
// * information and the trade secrets of Synopsys Inc. Use, disclosure, or   *
// * reproduction is prohibited without the prior express written permission  *
// * of Synopsys, Inc.                                                        *
// *                                                                          *
// * Synopsys, Inc.                                                           *
// * 700 East Middlefield Road                                                *
// * Mountain View, California 94043                                          *
// * (800) 541-7737                                                           *
// *                                                                          *
// ****************************************************************************

package sb_pkg;
  import uvm_pkg::*;
  import shared_pkg::*;
  `include "uvm_macros.svh"
  `include "agent_typedefs.svh"
  `include "sb_utils.svh"

  event timeout_triggered;

  // Group: Sequence Items
  //
  // Contains all sequence item definitions used in the Sideband environment.
  `include "sequence_items/ltsm_ctrl_seq_item.svh"
  `include "sequence_items/ltsm_seq_item.svh"
  `include "sequence_items/phylink_seq_item.svh"
  `include "sequence_items/rdi_seq_item.svh"

  // Group: Sequencers
  //
  // Contains all sequencer definitions for various Sideband interfaces.
  `include "sequencers/ltsm_ctrl_sequencer.svh"
  `include "sequencers/rdi_sequencer.svh"
  `include "sequencers/tx_sequencer.svh"
  `include "sequencers/phylink_sequencer.svh"
  `include "sequencers/rx_sequencer.svh"
  `include "virtual_sequencer.svh"
  
  // Group: Configuration Objects
  //
  // Contains environment and agent configuration classes.
  `include "env_config.svh"
  `include "agent_config.svh"

  // Group: Monitors
  //
  // Contains all monitor components for capturing transaction data.
  `include "monitors/sb_monitor_base.svh"
  `include "monitors/phylink_monitor.svh"
  `include "monitors/rx_monitor.svh"
  `include "monitors/tx_monitor.svh"

  // Group: Drivers
  //
  // Contains all driver components for driving transactions into the BFMs.
  `include "drivers/sb_driver_base.svh"
  `include "drivers/ltsm_ctrl_driver.svh"
  `include "drivers/reset_driver.svh"
  `include "drivers/phylink_driver.svh"
  `include "drivers/rx_driver.svh"
  `include "drivers/tx_driver.svh"

  // Group: Agents
  //
  // Contains all agent components that encapsulate monitors, drivers, and sequencers.
  `include "agents/agent_base.svh"
  `include "agents/ltsm_ctrl_agent.svh"
  `include "agents/phylink_agent.svh"
  `include "agents/rx_agent.svh"
  `include "agents/tx_agent.svh"

  // Group: Scoreboard
  //
  // Contains predictor and comparator components for verification.
  `include "scoreboard/sb_pred_ltsm2link.svh"
  `include "scoreboard/sb_pred_link2ltsm.svh"
  `include "scoreboard/sb_cmp_base.svh"
  `include "scoreboard/sb_cmp_ltsm2link.svh"
  `include "scoreboard/sb_cmp_link2ltsm_tx.svh"
  `include "scoreboard/sb_cmp_link2ltsm_rx.svh"
  `include "scoreboard/sb_cmp_link2ltsm_rdi.svh"
  `include "scoreboard/sb_scoreboard.svh"

  // Group: Coverage Collector
  //
  // Contains the coverage collector component.
  `include "sb_coverage_collector.svh"


  // Group: Environment
  //
  // The top-level UVM environment component for the Sideband testbench.
  `include "env.svh"

  // Group: Base Sequences
  //
  // Contains base sequence classes for other sequences to extend from.
  `include "virtual_sequences/virtual_sequence_base.svh"
  `include "sequences/sb_sequence_base.svh"

  // Group: Sequences
  //
  // Contains all test sequences for driving the Sideband verification.
  `include "sequences/sanity_sequences/sbinit_ctrl_sanity_seq.svh"
  `include "sequences/sanity_sequences/sbinit_phylink_sanity_seq.svh"
  `include "sequences/sanity_sequences/active_phylink_sanity_seq.svh"
  `include "sequences/sanity_sequences/active_tx_sanity_seq.svh"
  `include "sequences/sanity_sequences/active_rx_sanity_seq.svh"
  `include "sequences/rand_sequences/sbinit_phylink_rand_seq.svh"
  `include "sequences/rand_sequences/active_phylink_rand_seq.svh"
  `include "sequences/rand_sequences/active_tx_rand_seq.svh"
  `include "sequences/rand_sequences/active_rx_rand_seq.svh"
  `include "sequences/sendall_sequences/active_phylink_sendall_seq.svh"
  `include "sequences/sendall_sequences/active_tx_sendall_seq.svh"
  `include "sequences/sendall_sequences/active_rx_sendall_seq.svh"
  `include "sequences/conc_sequences/active_phylink_conc_seq.svh"
  `include "sequences/conc_sequences/active_tx_conc_seq.svh"
  `include "sequences/conc_sequences/active_rx_conc_seq.svh"

  // Group: Virtual Sequences
  //
  // Contains all virtual sequences for managing the existing sequences.
  `include "virtual_sequences/sb_sanity_vseq.svh"
  `include "virtual_sequences/sb_sendall_vseq.svh"
  `include "virtual_sequences/sb_conc_vseq.svh"
  `include "virtual_sequences/sb_rand_vseq.svh"

  // Group: Tests
  //
  // Contains the verification test cases.
  `include "tests/sb_test_base.svh"
  `include "tests/sb_sanity_test.svh"
  `include "tests/sb_sendall_test.svh"
  `include "tests/sb_conc_test.svh"
  `include "tests/sb_rand_test.svh"

endpackage : sb_pkg
