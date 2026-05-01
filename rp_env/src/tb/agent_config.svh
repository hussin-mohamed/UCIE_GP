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

//---------------------------------------------------------------------------
//
// CLASS: agent_config
//
// The agent_config class provides a parameterized configuration object for
// agents, containing the virtual interface handle and activity mode setting.
// This enables flexible agent configuration across the testbench.
//
// Type Parameters:
//   INTF_T - Virtual interface type for the agent
//
//---------------------------------------------------------------------------

class agent_config #(type INTF_T = virtual rp_tx_bfm) extends uvm_object;

  INTF_T bfm;

  uvm_active_passive_enum is_active = UVM_ACTIVE;
  bit is_reactive;

  `uvm_object_param_utils_begin(agent_config #(INTF_T))
  `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
  `uvm_object_utils_end


  // Function: new
  //
  // Creates a new agent_config instance with the given name.

  extern function new(string name = "");

endclass : agent_config


//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: agent_config
//
//---------------------------------------------------------------------------


// new
// ---

function agent_config::new(string name = "");
  super.new(name);
endfunction : new
