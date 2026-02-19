/***********************************************************************
 * Author : Amr El Batarny
 * File   : env_config.svh
 * Brief  : Environment configuration object containing virtual interfaces
 *          and agent activity settings for the bridge testbench.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

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

    virtual SYSCTRL_bfm         sysctrl_bfm;
    virtual APB_bfm             apb_bfm_1;
    virtual APB_bfm             apb_bfm_2;
    virtual APB_controller_if   apb_controller_if_1;
    virtual APB_controller_if   apb_controller_if_2;
    virtual AES_if              aes_if;

    bit disable_checking [5]; // Five flags for the five scoreboards

    uvm_active_passive_enum is_active_sysctrl             = UVM_ACTIVE;
    uvm_active_passive_enum is_active_apb_1               = UVM_ACTIVE;
    uvm_active_passive_enum is_active_apb_2               = UVM_ACTIVE;
    uvm_active_passive_enum is_active_apb_controller_1      = UVM_PASSIVE;
    uvm_active_passive_enum is_active_apb_controller_2      = UVM_PASSIVE;
    uvm_active_passive_enum is_active_aes                 = UVM_PASSIVE;

    `uvm_object_utils_begin(env_config)
        `uvm_field_enum(uvm_active_passive_enum, is_active_sysctrl, UVM_DEFAULT)
        `uvm_field_enum(uvm_active_passive_enum, is_active_apb_1, UVM_DEFAULT)
        `uvm_field_enum(uvm_active_passive_enum, is_active_apb_2, UVM_DEFAULT)
        `uvm_field_enum(uvm_active_passive_enum, is_active_apb_controller_1, UVM_DEFAULT)
        `uvm_field_enum(uvm_active_passive_enum, is_active_apb_controller_2, UVM_DEFAULT)
        `uvm_field_enum(uvm_active_passive_enum, is_active_aes, UVM_DEFAULT)
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
