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

package rp_pkg;
  import uvm_pkg::*;
  import rp_shared_pkg::*;
  `include "uvm_macros.svh"
  `include "agent_typedefs.svh"
  `include "rp_utils.svh"

  event ev_ready_for_next_encoding;


  // Group: Sequence Items
  //
  // Contains all sequence item definitions used in the RX-Path environment.
  `include "sequence_items/rdi_seq_item.svh"
  `include "sequence_items/ltsmc_seq_item.svh"
  `include "sequence_items/rmblink_seq_item.svh"

  // Group: Sequencers
  //
  // Contains all sequencer definitions for various RX-Path interfaces.
  `include "sequencers/rdi_sequencer.svh"
  `include "sequencers/ltsmc_sequencer.svh"
  `include "sequencers/rmblink_sequencer.svh"
  `include "virtual_sequencer.svh"
  
  // Group: Configuration Objects
  //
  // Contains environment and agent configuration classes.
  `include "env_config.svh"
  `include "agent_config.svh"

  // Group: Monitors
  //
  // Contains all monitor components for capturing transaction data.
  `include "monitors/rp_monitor_base.svh"
  `include "monitors/rdi_monitor.svh"
  `include "monitors/ltsmc_monitor.svh"
  `include "monitors/rmblink_monitor.svh"

  // Group: Drivers
  //
  // Contains all driver components for driving transactions into the BFMs.
  `include "drivers/rp_driver_base.svh"
  `include "drivers/reset_driver.svh"
  `include "drivers/rdi_driver.svh"
  `include "drivers/ltsmc_driver.svh"
  `include "drivers/rmblink_driver.svh"

  // Group: Agents
  //
  // Contains all agent components that encapsulate monitors, drivers, and sequencers.
  `include "agents/rp_agent_base.svh"
  `include "agents/rdi_agent.svh"
  `include "agents/ltsmc_agent.svh"
  `include "agents/rmblink_agent.svh"

  // Group: Scoreboard
  //
  // Contains predictor and comparator components for verification.
  `include "scoreboard/rp_pred.svh"
  `include "scoreboard/rp_cmp_base.svh"
  `include "scoreboard/rp_cmp_rdi.svh"
  `include "scoreboard/rp_cmp_ltsmc.svh"
  `include "scoreboard/rp_scoreboard.svh"

  // Group: Coverage Collector
  //
  // Contains the coverage collector component.
  // `include "rp_coverage_collector.svh"


  // Group: Environment
  //
  // The top-level UVM environment component for the RX-Path testbench.
  `include "env.svh"

  // Group: Base Sequences
  //
  // Contains base sequence classes for other sequences to extend from.
  `include "virtual_sequences/virtual_sequence_base.svh"
  `include "sequences/rp_sequence_base.svh"

  // Group: Sequences
  //
  // Contains all test sequences for driving the RX-Path verification.
  `include "sequences/ltsmc_sequence.svh"
  `include "sequences/rmblink_sanity_valid_sequence.svh"
  `include "sequences/rmblink_sanity_clk_sequence.svh"
  `include "sequences/rmblink_sanity_PerLaneID_sequence.svh"

  // Group: Virtual Sequences
  //
  // Contains all virtual sequences for managing the existing sequences.
  `include "virtual_sequences/rp_vaild_sanity_vseq.svh"
  `include "virtual_sequences/rp_clk_sanity_vseq.svh"
  `include "virtual_sequences/rp_sanity_PerLaneID_vseq.svh"

  // Group: Tests
  //
  // Contains the verification test cases.
  `include "tests/rp_test_base.svh"
  `include "tests/rp_sanity_valid_test.svh"
  `include "tests/rp_sanity_clk_test.svh"
  `include "tests/rp_sanity_PerLaneID_test.svh"

endpackage : rp_pkg
