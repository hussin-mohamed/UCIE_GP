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

  // Sequence Items
  `include "sequence_items/ltsm_ctrl_seq_item.svh"
  `include "sequence_items/ltsm_seq_item.svh"
  `include "sequence_items/phylink_seq_item.svh"
  `include "sequence_items/rdi_seq_item.svh"

  // Sequencers
  `include "sequencers/ltsm_ctrl_sequencer.svh"
  `include "sequencers/rdi_sequencer.svh"
  `include "sequencers/tx_sequencer.svh"
  `include "sequencers/phylink_sequencer.svh"
  `include "sequencers/rx_sequencer.svh"
  `include "virtual_sequencer.svh"
  
  // Configuration Objects
  `include "env_config.svh"
  `include "agent_config.svh"

  // Monitors
  `include "monitors/sb_monitor_base.svh"
  `include "monitors/phylink_monitor.svh"
  `include "monitors/rx_monitor.svh"
  `include "monitors/tx_monitor.svh"

  // Drivers
  `include "drivers/sb_driver_base.svh"
  `include "drivers/ltsm_ctrl_driver.svh"
  `include "drivers/reset_driver.svh"
  `include "drivers/phylink_driver.svh"
  `include "drivers/rx_driver.svh"
  `include "drivers/tx_driver.svh"

  // Agents
  `include "agents/agent_base.svh"
  `include "agents/ltsm_ctrl_agent.svh"
  `include "agents/phylink_agent.svh"
  `include "agents/rx_agent.svh"
  `include "agents/tx_agent.svh"

  // Scoreboard
  `include "scoreboard/sb_pred_ltsm2link.svh"
  `include "scoreboard/sb_pred_link2ltsm.svh"
  `include "scoreboard/sb_cmp_base.svh"
  `include "scoreboard/sb_cmp_ltsm2link.svh"
  `include "scoreboard/sb_cmp_link2ltsm_tx.svh"
  `include "scoreboard/sb_cmp_link2ltsm_rx.svh"
  `include "scoreboard/sb_cmp_link2ltsm_rdi.svh"
  `include "scoreboard/sb_scoreboard.svh"

  // Environment
  `include "env.svh"

  // // Base Sequences
  // `include "virtual_sequence/virtual_sequence_base.svh"
  // `include "reactive_sequences/APB_sequence_base.svh"

  // // Reactive Sequences
  // `include "reactive_sequences/APB_reactive_sequence_1.svh"
  // `include "reactive_sequences/APB_reactive_sequence_2.svh"
  // `include "virtual_sequence/virtual_sequence.svh"
  
  // Tests    
  `include "sb_test_base.svh"
  
endpackage : sb_pkg
