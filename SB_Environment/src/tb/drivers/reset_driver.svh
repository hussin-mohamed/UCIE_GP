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
// CLASS: reset_driver
//
// ...
//
//------------------------------------------------------------------------------

class reset_driver extends uvm_driver;
  // var: intf_name 
  string intf_name = "reset_intf";

  // var: reset_time_ps
  // The length of time, in ps, that reset will stay active
  rand int reset_time_ps;

  // Base constraints
  constraint rst_cnstr { reset_time_ps inside {[1:1000000]}; }

  // var: rst_vi 
  // Reset virtual interface
  virtual sb_reset_intf rst_vi;
  

  `uvm_component_utils_begin(reset_driver)
    `uvm_field_string(intf_name,  UVM_ALL_ON)
    `uvm_field_int(reset_time_ps, UVM_ALL_ON | UVM_DEC)
  `uvm_component_utils_end

  // Function: new
  //
  // Creates a new reset_driver instance with the given name and parent.

  extern function new(string name, uvm_component parent);

  // Function: build_phase
  //
  // Creates the analysis port for broadcasting driven transactions.

  extern virtual function void build_phase(uvm_phase phase);


  // Task: reset_phase
  //
  // ...

  extern virtual task reset_phase(uvm_phase phase);

endclass : reset_driver

//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- reset_driver
//
//------------------------------------------------------------------------------


// new
// ---

function reset_driver::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void reset_driver::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if(!uvm_config_db#(virtual sb_reset_intf)::get(this, "", intf_name, rst_vi))
    `uvm_fatal("build_phase", $sformatf("RST_DRVR - Unable to get the %s virtual interface handle from the uvm_config_db", intf_name))
endfunction : build_phase

// reset_phase
// -----

task reset_driver::reset_phase(uvm_phase phase);
  super.reset_phase(phase);

  phase.raise_objection(this);
  rst_vi.reset = 1;
  #(reset_time_ps * 1ps);
  rst_vi.reset = 0;
  phase.drop_objection(this);
endtask : reset_phase
