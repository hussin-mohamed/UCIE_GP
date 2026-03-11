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
  // Drives APB transactions on the bus by setting path selection signals and
  // executing read or write operations based on the transaction type.

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
  //============================================================================
  // LTSM → SB Control Signals
  //============================================================================
  logic i_sb_init_start;  // Trigger SBINIT sequence
  logic i_timer_1ms;      // 1ms timer tick for timeout logic

  //============================================================================
  // SB → LTSM Status Signals
  //============================================================================
  logic o_sb_ready;

  if (req.sbinit_mode == START) begin
    bfm.start();
  end else if (req.sbinit_mode == T1MS) begin
    bfm.t1ms();
  end else begin
    bfm.wait_for_ready();
  end


  
endtask : drive_item
