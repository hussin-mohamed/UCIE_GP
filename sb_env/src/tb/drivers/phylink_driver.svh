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
// The phylink_driver class converts phylink sequence items into serialized
// sideband activity on the sb_phylink_bfm. It handles both SBINIT pattern
// traffic and ACTIVE serialized messages.
//
//-----------------------------------------------------------------------------

class phylink_driver extends sb_driver_base #(phylink_seq_item, virtual sb_phylink_bfm);
  `uvm_component_utils(phylink_driver)


  // Function: new
  //
  // Creates a new phylink_driver instance with the given name and parent.

  extern function new(string name, uvm_component parent);

  // Function: start_of_simulation_phase
  //
  // Disables the base-class ready wait because this driver must also handle
  // SBINIT traffic before the DUT asserts readiness.

  extern function void start_of_simulation_phase(uvm_phase phase);


  // Task: drive_item
  //
  // Drives a phylink item either as an SBINIT pattern exchange or as an
  // ACTIVE serialized sideband message.

  extern virtual task drive_item(inout phylink_seq_item req, output phylink_seq_item rsp);


  // Function: report_phase
  //
  // Reports the number of SBINIT transactions in addition to the base ACTIVE
  // transaction count.

  extern virtual function void report_phase(uvm_phase phase);

endclass : phylink_driver


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: phylink_driver
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
endfunction : start_of_simulation_phase

// drive_item
// -----

task phylink_driver::drive_item(inout phylink_seq_item req, output phylink_seq_item rsp);
  message_t    msg;
  logic[127:0] msg_raw;


  if (req.op_mode == SBINIT) begin
    rsp = new("rsp");
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
    if (m_op_mode == SBINIT) begin
      wait (m_op_mode == ACTIVE);
      repeat(10) @(posedge bfm.clk);
    end
    msg = item2struct(req);

    msg_raw = struct2raw(msg);

    bfm.serialize_data(msg_raw, req.idle_ui_cnt);

    record_driven_item();
  end
endtask : drive_item

// report_phase
// ------------

function void phylink_driver::report_phase(uvm_phase phase);
  super.report_phase(phase);
  `uvm_info(get_type_name(), $sformatf("DRIVED %0d SBINIT TRANSACTIONS", sbinit_txn_cnt), UVM_LOW)
endfunction : report_phase
