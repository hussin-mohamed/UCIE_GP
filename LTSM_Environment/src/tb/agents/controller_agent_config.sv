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
// CLASS: LTSM_controllers_agent_cfg
//
// The LTSM_controllers_agent_cfg class provides a parameterized configuration object for
// agents, containing the virtual interface handle and activity mode setting.
// This enables flexible agent configuration across the testbench.
//
// Type Parameters:
//   LTSM_controllers_if - Virtual interface type for the agent
//
//------------------------------------------------------------------------------
class LTSM_controllers_agent_cfg #(type LTSM_controllers_if) extends uvm_object;

    virtual LTSM_controllers_if vif;

    uvm_active_passive_enum is_active = UVM_ACTIVE;

    `uvm_object_param_utils_begin(LTSM_controllers_agent_cfg #(LTSM_controllers_if))
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
    `uvm_object_utils_end


    // Function: new
    //
    // Creates a new agent_config instance with the given name.

    extern function new(string name = "LTSM_controllers_agent_cfg");

endclass : LTSM_controllers_agent_cfg


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- agent_config
//
//------------------------------------------------------------------------------


// new
// ---

function LTSM_controllers_agent_cfg::new(string name = "LTSM_controllers_agent_cfg");
    super.new(name);
endfunction : new

