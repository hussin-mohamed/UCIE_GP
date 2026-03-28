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

//-----------------------------------------------------------------------------
//
// CLASS: env_config
//
// The env_config class encapsulates all configuration settings for the bridge
// environment including virtual interface handles and active/passive mode
// settings for all agents. It also provides scoreboard enable/disable flags.
//
//-----------------------------------------------------------------------------

class env_config extends uvm_object;

  virtual sb_reset_intf     reset_intf;
  virtual sb_ltsm_ctrl_bfm  ltsm_ctrl_bfm;
  virtual sb_tx_bfm         tx_bfm;
  virtual sb_rx_bfm         rx_bfm;
  virtual sb_rdi_bfm        rdi_bfm;
  virtual sb_phylink_bfm    phylink_bfm;

  bit disable_checking [5]; // Five flags for the five scoreboards

  uvm_active_passive_enum is_active_ltsm_ctrl = UVM_ACTIVE;
  uvm_active_passive_enum is_active_tx        = UVM_ACTIVE;
  uvm_active_passive_enum is_active_rx        = UVM_ACTIVE;
  uvm_active_passive_enum is_active_rdi       = UVM_ACTIVE;
  uvm_active_passive_enum is_active_phylink   = UVM_ACTIVE;

  `uvm_object_utils_begin(env_config)
    `uvm_field_enum(uvm_active_passive_enum, is_active_ltsm_ctrl, UVM_DEFAULT)
    `uvm_field_enum(uvm_active_passive_enum, is_active_tx,        UVM_DEFAULT)
    `uvm_field_enum(uvm_active_passive_enum, is_active_rx,        UVM_DEFAULT)
    `uvm_field_enum(uvm_active_passive_enum, is_active_rdi,       UVM_DEFAULT)
    `uvm_field_enum(uvm_active_passive_enum, is_active_phylink,   UVM_DEFAULT)
  `uvm_object_utils_end


  // Function: new
  //
  // Creates a new env_config instance with the given name.

  extern function new(string name = "");

endclass : env_config


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS- env_config
//
//-----------------------------------------------------------------------------


// new
// ---

function env_config::new(string name = "");
  super.new(name);
endfunction : new
