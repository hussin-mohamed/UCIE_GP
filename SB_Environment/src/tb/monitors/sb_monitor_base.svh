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
// ...
//
//-----------------------------------------------------------------------------

virtual class sb_monitor_base #(type ITEM_T = uvm_sequence_item, type INTF_T = virtual sb_tx_bfm) extends uvm_monitor;
  // `uvm_component_param_utils(sb_monitor_base #(ITEM_T, INTF_T))
  
  INTF_T bfm;
  ITEM_T item;
  uvm_analysis_port #(ITEM_T) ap;
  int unsigned txn_cnt = 0;


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
  // calling the virtual collect_item() method.

  extern virtual task run_phase(uvm_phase phase);


  // Task: monitor_items
  //
  // ...

  extern virtual task monitor_items();


  // Task: collect_item
  //
  // Pure virtual method that must be implemented by derived classes to define
  // protocol-specific transaction collection behavior.

  pure virtual task collect_item(output ITEM_T _item);


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
// CLASS- sb_monitor_base
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
  ap = new("ap", this);
endfunction

// run_phase
// ---------

task sb_monitor_base::run_phase(uvm_phase phase);
  super.run_phase(phase);
  
  forever begin 
    @(negedge bfm.reset); 

    fork 
      monitor_items(); 
    join_none 

    @(posedge bfm.reset);
    disable fork;
    // cleanup(); 
  end 
endtask : run_phase

// monitor_items
// -------------

task sb_monitor_base::monitor_items();
  forever begin
    collect_item(item);

    // Write the item to the analysis port and log the monitored item
    ap.write(item);
    `uvm_info(get_type_name(), $sformatf("MONITORED %s: \n%s", item.get_type_name(), item.sprint()), UVM_DEBUG)
    txn_cnt++;
  end
endtask : monitor_items

// report_phase
// ------------

function void sb_monitor_base::report_phase(uvm_phase phase);
  super.report_phase(phase);
  `uvm_info(get_type_name(), $sformatf("MONITORED %0d TRANSACTIONS", txn_cnt), UVM_LOW)
endfunction : report_phase
