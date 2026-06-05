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
// CLASS: sb_driver_base
//
// Base driver class for all Sideband drivers, handling BFM interaction and reset.
//
// Type Parameters:
//   ITEM_T - Transaction item type to be driven
//   INTF_T - Virtual interface type for the SB bus
//
//------------------------------------------------------------------------------

virtual class sb_driver_base #(type ITEM_T = uvm_sequence_item, type INTF_T = virtual sb_tx_bfm) extends uvm_driver #(ITEM_T);
  // `uvm_component_param_utils(sb_driver_base#(ITEM_T, INTF_T))

  INTF_T                      bfm;
  ITEM_T                      req, rsp;
  uvm_analysis_port #(ITEM_T) ap;
  event                       reset_driver;
  bit                         wait_for_sbinit;
  int unsigned                active_txn_cnt = 0;
  int unsigned                sbinit_txn_cnt = 0;
  operation_t                 m_op_mode;

  // Function: new
  //
  // Creates a new sb_driver_base instance with the given name and parent.

  extern function new(string name, uvm_component parent);


  // Function: build_phase
  //
  // Creates the analysis port and initializes the default SBINIT wait policy.

  extern virtual function void build_phase(uvm_phase phase);

  // Task: reset_phase
  //
  // Clears the attached BFM during the UVM reset phase.

  extern task reset_phase(uvm_phase phase);


  // Task: run_phase
  //
  // Main driver loop that fetches sequence items, drives them via the virtual
  // drive() method, broadcasts transactions, and sends responses back to sequencer.

  extern virtual task run_phase(uvm_phase phase);

  // Task: drive_items
  //
  // Fetches sequence items, publishes ACTIVE items to the reference model, and
  // delegates pin-level activity to the protocol-specific drive_item() method.

  extern virtual task drive_items();


  // Task: drive_item
  //
  // Pure virtual method that must be implemented by derived classes to define
  // protocol-specific transaction driving behavior on the SB bus.

  pure virtual task drive_item(inout ITEM_T req, output ITEM_T rsp);

  // Function: report_phase
  //
  // Reports the number of ACTIVE transactions driven during simulation.
  
  extern virtual function void report_phase(uvm_phase phase);
  
  // Function: record_driven_item
  //
  // Updates the ACTIVE or SBINIT transaction counters after a successful drive.

  extern virtual function void record_driven_item();

endclass : sb_driver_base


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS: sb_driver_base
//
//------------------------------------------------------------------------------


// new
// ---

function sb_driver_base::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void sb_driver_base::build_phase(uvm_phase phase);
  super.build_phase(phase);
  ap = new("ap", this);
  wait_for_sbinit = 1;
endfunction : build_phase

// run_phase
// ---------

task sb_driver_base::run_phase(uvm_phase phase); 
  super.run_phase(phase);

  m_op_mode = SBINIT;
  
  fork
    forever begin
      @(posedge bfm.o_sb_ready);
      @(negedge bfm.o_sb_ready);
      m_op_mode = ACTIVE;
    end
  join_none

  fork
    forever begin
      @(posedge bfm.reset);
      m_op_mode = SBINIT;
    end
  join_none

  forever begin
    // Wait for reset deassertion
    if (bfm.reset === 1'b1) begin
      @(negedge bfm.reset);
    end
    `uvm_info(get_type_name(), "Got out of reset", UVM_DEBUG)
    
    // Wait for the SBINIT to finish
    if (wait_for_sbinit) begin
     `uvm_info(get_type_name(), "Waiting for the ready signal assertion to start the Sideband ACTIVE phase.", UVM_DEBUG)
      @(negedge bfm.o_sb_ready);
      repeat(2) @(negedge bfm.clk);
    end
    
    fork
      begin
        fork
          drive_items();
        join_none
        @(reset_driver);
        disable fork;
      end
    join
    // cleanup();
  end
endtask : run_phase

// reset_phase
// -----

task sb_driver_base::reset_phase(uvm_phase phase);
  super.reset_phase(phase);

  phase.raise_objection(this);
  bfm.clear();
  phase.drop_objection(this);
endtask : reset_phase


// drive_items
// -----------

task sb_driver_base::drive_items();
  forever begin
    `uvm_info(get_type_name(), "Entered drive_items", UVM_DEBUG)

    // Get the next item from the sequencer
    seq_item_port.get_next_item(req);
    `uvm_info(get_type_name(), "Got a request item", UVM_DEBUG)

    // Send the item to the reference model
    if (req.op_mode == ACTIVE) begin // The model accepts only ACTIVE itmes
      ap.write(req);
    end

    // Call the drive_item() task to convert the transaction-level item to pin-level signals
    `uvm_info(get_type_name(), "Base driver class for all Sideband drivers, handling BFM interaction and reset.", UVM_DEBUG)
    drive_item(req, rsp);
    `uvm_info(get_type_name(), $sformatf("DRIVED %s: \n%s", req.get_type_name(), req.sprint()), UVM_DEBUG)

    // Trigger item driving completion for the sequence with/without sending response
    if(rsp != null) begin
      rsp.set_id_info(req); // Preserve transaction ID
      seq_item_port.item_done(rsp);
    end else begin
      seq_item_port.item_done();
    end
  end
endtask : drive_items

// report_phase
// ------------

function void sb_driver_base::report_phase(uvm_phase phase);
  super.report_phase(phase);
  `uvm_info(get_type_name(), $sformatf("DRIVED %0d ACTIVE TRANSACTIONS", active_txn_cnt), UVM_LOW)
endfunction : report_phase


// record_driven_item
// ------------------
function void sb_driver_base::record_driven_item();
    // Count only ACTIVE items
    if (req.op_mode == ACTIVE) begin
      active_txn_cnt++;
    end else begin
      sbinit_txn_cnt++;
    end
endfunction : record_driven_item
