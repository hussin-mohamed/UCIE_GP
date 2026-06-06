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
// The env_config class encapsulates all configuration settings for the
// sideband verification environment. It stores the virtual interface handles
// used by the environment, the active/passive settings for each agent, and
// the reactive-mode controls that enable monitor-to-sequencer feedback.
//
//-----------------------------------------------------------------------------

class env_config extends uvm_object;

  virtual rp_reset_intf     reset_intf;
  virtual rp_rdi_bfm        rdi_bfm;
  virtual rp_ltsmc_bfm      ltsmc_bfm;
  virtual rp_rmblink_bfm    rmblink_bfm;
  virtual rp_rmblink_bfm    rmblink_bfm_drive;

  bit disable_checking [5]; // Five flags for the five scoreboards

  uvm_active_passive_enum is_active_rdi     = UVM_PASSIVE;
  uvm_active_passive_enum is_active_ltsmc   = UVM_ACTIVE;
  uvm_active_passive_enum is_active_rmblink = UVM_ACTIVE;

  bit is_reactive_rdi;
  bit is_reactive_ltsmc;
  bit is_reactive_rmblink;

  `uvm_object_utils_begin(env_config)
    `uvm_field_enum(uvm_active_passive_enum, is_active_rdi,     UVM_DEFAULT)
    `uvm_field_enum(uvm_active_passive_enum, is_active_ltsmc,    UVM_DEFAULT)
    `uvm_field_enum(uvm_active_passive_enum, is_active_rmblink, UVM_DEFAULT)
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
// CLASS: env_config
//
//-----------------------------------------------------------------------------


// new
// ---

function env_config::new(string name = "");
  super.new(name);
endfunction : new
