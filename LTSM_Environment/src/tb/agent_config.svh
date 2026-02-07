/***********************************************************************
 * Author : Amr El Batarny
 * File   : agent_config.svh
 * Brief  : Parameterized agent configuration object for setting virtual
 *          interface handle and active/passive mode.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
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
//------------------------------------------------------------------------------

class agent_config #(type INTF_T) extends uvm_object;

    INTF_T bfm;

    uvm_active_passive_enum is_active = UVM_ACTIVE;

    `uvm_object_param_utils_begin(agent_config #(INTF_T))
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
    `uvm_object_utils_end


    // Function: new
    //
    // Creates a new agent_config instance with the given name.

    extern function new(string name = "agent_config");

endclass : agent_config


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

function agent_config::new(string name = "agent_config");
    super.new(name);
endfunction : new
