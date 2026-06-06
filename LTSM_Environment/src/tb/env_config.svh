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



//------------------------------------------------------------------------------
//
// CLASS: env_config
//
// The env_config class encapsulates all configuration settings for the bridge
// environment including virtual interface handles and active/passive mode
// settings for all agents. It also provides scoreboard enable/disable flags.
//
//------------------------------------------------------------------------------

class env_config extends uvm_object;

    virtual TX_FSM_SB         tx_fsm_sb_if;
    virtual RX_FSM_SB         rx_fsm_sb_if;
    virtual LTSM_controllers_if vif;
    virtual ltsm_rdi_if         ltsm_rdi_vif;
    virtual ltsm_rdi_if         ltsm_rdi_vif_drive;

    uvm_active_passive_enum is_active_rdi             = UVM_ACTIVE;
    uvm_active_passive_enum is_active_LTSM_controllers      = UVM_ACTIVE;
    uvm_active_passive_enum is_active_tx_fsm_sb             = UVM_ACTIVE;
    uvm_active_passive_enum is_active_rx_fsm_sb             = UVM_ACTIVE;

    `uvm_object_utils_begin(env_config)
        `uvm_field_enum(uvm_active_passive_enum, is_active_tx_fsm_sb, UVM_DEFAULT)
        `uvm_field_enum(uvm_active_passive_enum, is_active_rx_fsm_sb, UVM_DEFAULT)
    `uvm_object_utils_end


    // Function: new
    //
    // Creates a new env_config instance with the given name.

    extern function new(string name = "env_config");

endclass : env_config


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- env_config
//
//------------------------------------------------------------------------------


// new
// ---

function env_config::new(string name = "env_config");
    super.new(name);
endfunction : new
