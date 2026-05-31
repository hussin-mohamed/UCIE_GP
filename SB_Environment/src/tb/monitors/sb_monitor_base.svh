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
// CLASS: sb_monitor_base
//
// Base monitor class for all Sideband monitors, providing common interface and capture logic.
//
//-----------------------------------------------------------------------------

virtual class sb_monitor_base #(type ITEM_T = uvm_sequence_item, type INTF_T = virtual sb_tx_bfm) extends uvm_monitor;
  // `uvm_component_param_utils(sb_monitor_base #(ITEM_T, INTF_T))
  
  INTF_T bfm;
  ITEM_T item_out, item_in;
  uvm_analysis_port #(ITEM_T) out_ap, in_ap, reactive_ap;
  int unsigned txn_out_cnt = 0;
  int unsigned txn_in_cnt = 0;
  bit is_reactive;


  // Function: new
  //
  // Creates a new sb_monitor_base instance with the given name and parent.

  extern function new(string name = "sb_monitor_base", uvm_component parent = null);


  // Function: build_phase
  //
  // Creates the analysis port for broadcasting monitored transactions.

  extern virtual function void build_phase(uvm_phase phase);


  // Task: run_phase
  //
  // Waits for reset deassertion then continuously collects transactions by
  // calling the virtual collect_item_out() method.

  extern virtual task run_phase(uvm_phase phase);


  // Task: monitor_items_out
  //
  // Base monitor class for all Sideband monitors, providing common interface and capture logic.

  extern virtual task monitor_items_out();

  // Task: monitor_items_in
  //
  // Base monitor class for all Sideband monitors, providing common interface and capture logic.

  extern virtual task monitor_items_in();


  // Task: collect_item_out
  //
  // Pure virtual method that must be implemented by derived classes to define
  // protocol-specific transaction collection behavior.

  pure virtual task collect_item_out(output ITEM_T _item);

  // Task: collect_item_in
  //
  // Base monitor class for all Sideband monitors, providing common interface and capture logic.

  pure virtual task collect_item_in(output ITEM_T _item);


  // Function: report_phase
  //
  // Reports the total number of transactions monitored during simulation.

  extern virtual function void report_phase(uvm_phase phase);

endclass : sb_monitor_base


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: sb_monitor_base
//
//-----------------------------------------------------------------------------


// new
// ---

function sb_monitor_base::new(string name = "sb_monitor_base", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void sb_monitor_base::build_phase(uvm_phase phase);
  super.build_phase(phase);
  out_ap      = new("out_ap", this);
  in_ap       = new("in_ap", this);
  reactive_ap = new("reactive_ap", this);
endfunction

// run_phase
// ---------

task sb_monitor_base::run_phase(uvm_phase phase);
  super.run_phase(phase);
  
  forever begin
    // Wait for reset deassertion
    @(negedge bfm.reset);

    // Wait for the SBINIT to finish
    // @(negedge bfm.o_sb_ready);

    fork
      monitor_items_out();
      monitor_items_in();
    join_none

    @(posedge bfm.reset);
    disable fork;
    // cleanup(); 
  end 
endtask : run_phase

// monitor_items_out
// ----------------

task sb_monitor_base::monitor_items_out();
  forever begin
    collect_item_out(item_out);

    // Write item_out to the analysis port and log the monitored item_out
    out_ap.write(item_out);
    `uvm_info(get_type_name(), $sformatf("MONITORED item_out %s: \n%s", item_out.get_type_name(), item_out.sprint()), UVM_DEBUG)
    txn_out_cnt++;

    // Send item_out to the sequencer if the monitor is configured to be reactive
    if (is_reactive) begin
      reactive_ap.write(item_out);
    end
  end
endtask : monitor_items_out

// monitor_items_in
// ----------------

task sb_monitor_base::monitor_items_in();
  forever begin
    collect_item_in(item_in);

    // Write the item_in to the analysis port and log the monitored item_in
    in_ap.write(item_in);
    `uvm_info(get_type_name(), $sformatf("MONITORED item_in %s: \n%s", item_in.get_type_name(), item_in.sprint()), UVM_DEBUG)
    txn_in_cnt++;
  end
endtask : monitor_items_in

// report_phase
// ------------

function void sb_monitor_base::report_phase(uvm_phase phase);
  super.report_phase(phase);
  `uvm_info(get_type_name(), $sformatf("MONITORED %0d OUTPUT TRANSACTIONS", txn_out_cnt), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("MONITORED %0d INPUT TRANSACTIONS", txn_in_cnt), UVM_LOW)
endfunction : report_phase
