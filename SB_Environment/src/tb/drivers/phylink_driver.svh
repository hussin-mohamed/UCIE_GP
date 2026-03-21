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
// CLASS: phylink_driver
//
// ...
//
//-----------------------------------------------------------------------------

class phylink_driver extends sb_driver_base #(phylink_seq_item, virtual sb_phylink_bfm);
  `uvm_component_utils(phylink_driver)


  // Function: new
  //
  // Creates a new phylink_driver instance with the given name and parent.

  extern function new(string name, uvm_component parent);

  extern function void start_of_simulation_phase(uvm_phase phase);


  // Task: drive_item
  //
  // Drives APB transactions on the bus by setting path selection signals and
  // executing read or write operations based on the transaction type.

  extern virtual task drive_item(inout phylink_seq_item req, output phylink_seq_item rsp);

endclass : phylink_driver


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS- phylink_driver
//
//-----------------------------------------------------------------------------


// new
// ---

function phylink_driver::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// start_of_simulation_phase
// -----------

function void phylink_driver::start_of_simulation_phase(uvm_phase phase);
  super.start_of_simulation_phase(phase);
  wait_for_sbinit = 0; // Do NOT wait for SBINIT since this driver is responsible for handling SBINIT sequences
  is_reactive = 1;
endfunction : start_of_simulation_phase

// drive_item
// -----

task phylink_driver::drive_item(inout phylink_seq_item req, output phylink_seq_item rsp);
  message_t    msg;
  logic[127:0] msg_raw;

  rsp = new("rsp");

  if (req.op_mode == SBINIT) begin
    fork
      begin
        bfm.serialize_pattern(req.pattern, req.idle_ui_cnt, req.out_of_rst_ui_cnt);
        rsp.pat_detected = bfm.pat_detected;
      end
      
      begin
        @(timeout_triggered);
        rsp.timeout_detected = 1;
      end
    join_any
    disable fork;
  end else if (req.op_mode == ACTIVE) begin
    msg.fullcode = req.fullcode;
    msg.opcode   = req.opcode;
    msg.srcid    = req.srcid;
    msg.dstid    = req.dstid;
    msg.info     = req.info;
    msg.data     = req.data;
    msg.cp       = req.cp;
    msg.dp       = req.dp;

    msg_raw = struct2raw(msg);

    bfm.serialize_data(msg_raw, req.idle_ui_cnt);
  end
endtask : drive_item
