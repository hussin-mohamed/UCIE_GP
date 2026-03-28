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
// CLASS: ltsm_ctrl_driver
//
// ...
//
//------------------------------------------------------------------------------

class ltsm_ctrl_driver extends sb_driver_base #(ltsm_ctrl_seq_item, virtual sb_ltsm_ctrl_bfm);
  `uvm_component_utils(ltsm_ctrl_driver)


  // Function: new
  //
  // Creates a new ltsm_ctrl_driver instance with the given name and parent.

  extern function new(string name, uvm_component parent);

  extern virtual function void start_of_simulation_phase(uvm_phase phase);


  // Task: drive_item
  //
  // ...

  extern virtual task drive_item(inout ltsm_ctrl_seq_item req, output ltsm_ctrl_seq_item rsp);

endclass : ltsm_ctrl_driver


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- ltsm_ctrl_driver
//
//------------------------------------------------------------------------------


// new
// ---

function ltsm_ctrl_driver::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// start_of_simulation_phase
// -----------

function void ltsm_ctrl_driver::start_of_simulation_phase(uvm_phase phase);
  super.start_of_simulation_phase(phase);
  wait_for_sbinit = 0; // Do NOT wait for SBINIT since this driver is responsible for handling SBINIT sequences
endfunction : start_of_simulation_phase

// drive_item
// -----

task ltsm_ctrl_driver::drive_item(inout ltsm_ctrl_seq_item req, output ltsm_ctrl_seq_item rsp);
  `uvm_info(get_type_name(), "Entered ltsm_ctrl_driver drive_item", UVM_DEBUG)
  if (req.sbinit_mode == START) begin
    `uvm_info(get_type_name(), "sbinit_mode is START", UVM_DEBUG)
    fork
      begin
        `uvm_info(get_type_name(), "Waiting for timeout...", UVM_DEBUG)
        @(posedge bfm.timeout);
        -> timeout_triggered;
        `uvm_info(get_type_name(), "TRIGGERED timeout", UVM_DEBUG)
      end

      begin
        @(posedge bfm.clk);
        `uvm_info(get_type_name(), "Starting SBINIT...", UVM_DEBUG)
        bfm.i_sb_init_start <= 1;
        @(posedge bfm.o_sb_ready);
        @(posedge bfm.clk);
        bfm.i_sb_init_start <= 0;
      end
    join_any
    disable fork;
    `uvm_info(get_type_name(), "SBINIT ENDED", UVM_DEBUG)
  end
endtask : drive_item
