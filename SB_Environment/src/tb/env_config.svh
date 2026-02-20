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

    virtual sb_tx_path_bfm         tx_path_if;
    virtual sb_rx_path_bfm         rx_path_if;
    virtual sb_phy_link_bfm        phy_link_if;
    virtual sb_ltsm_ctrl_bfm       ltsm_ctrl_if;
    virtual sb_rdi_bfm             rdi_if;
    

    bit disable_checking [5]; // Five flags for the five scoreboards

    uvm_active_passive_enum is_active_tx_path             = UVM_ACTIVE;
    uvm_active_passive_enum is_active_rx_path             = UVM_ACTIVE;
    uvm_active_passive_enum is_active_phy_link            = UVM_ACTIVE;
    uvm_active_passive_enum is_active_ltsm_ctrl           = UVM_ACTIVE;
    uvm_active_passive_enum is_active_rdi                 = UVM_ACTIVE;

    `uvm_object_utils_begin(env_config)
        `uvm_field_enum(uvm_active_passive_enum, is_active_tx_path, UVM_DEFAULT)
        `uvm_field_enum(uvm_active_passive_enum, is_active_rx_path, UVM_DEFAULT)
        `uvm_field_enum(uvm_active_passive_enum, is_active_phy_link, UVM_DEFAULT)
        `uvm_field_enum(uvm_active_passive_enum, is_active_ltsm_ctrl, UVM_DEFAULT)
        `uvm_field_enum(uvm_active_passive_enum, is_active_rdi, UVM_DEFAULT)
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
