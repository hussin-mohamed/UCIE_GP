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


package LTSM_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    typedef state state_t; 
    // Sequence Items
    `include "sequence_items/LTSM_controllers_sequence_item.sv"
    `include "sequence_items/ltsm_rdi_sequence_item.sv"
    `include "sequence_items/rx_fsm_sb_sequence_item.svh"
    `include "sequence_items/tx_fsm_sb_sequence_item.svh"
    
    // Sequencers
    `include "sequencers/LTSM_controllers_sqr.sv"
    `include "sequencers/ltsm_rdi_sequencer.sv"
    `include "sequencers/rx_fsm_sb_sequencer.svh"
    `include "sequencers/tx_fsm_sb_sequencer.svh"
    `include "virtual_sequencer.svh"
    
    // Configuration Objects
    `include "env_config.svh"
    `include "agent_config.svh"
    `include "controller_agent_config.sv"
    `include "rdi_agent_config.sv"

    // Monitors
    `include "monitors/LTSM_monitor_base.svh"
    `include "monitors/LTSM_controllers_monitor.sv"
    `include "monitors/ltsm_rdi_monitor.sv"
    `include "monitors/rx_fsm_sb_monitor.svh"
    `include "monitors/tx_fsm_sb_monitor.svh"
    
    // Drivers
    `include "drivers/LTSM_driver_base.svh"
    `include "drivers/LTSM_controllers_driver.sv"
    `include "drivers/ltsm_rdi_driver.sv"
    `include "drivers/rx_fsm_sb_driver.svh"
    `include "drivers/tx_fsm_sb_driver.svh"
    
    // Agents 
    `include "ltsm_rdi_agent.sv"
    `include "rx_fsm_sb_agent.svh"
    `include "tx_fsm_sb_agent.svh"
    `include "TX_RX_controllers_agent.sv"
    
    

    // Environment
    `include "env.svh"
    
    // Base Sequences
    `include "virtual_sequence/virtual_sequence_base.svh"


    // Reactive Sequences
    `include "virtual_sequence/virtual_sequence.svh"
    
    // Tests    
    `include "LTSM_test_base.svh"
    
endpackage : LTSM_pkg
