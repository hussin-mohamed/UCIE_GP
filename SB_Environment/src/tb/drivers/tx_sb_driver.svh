/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_driver_1.svh
 * Brief  : APB driver implementation with path selection control
 *          for routing transactions between BFM and register file.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: APB_driver_1
//
// The APB_driver_1 class extends APB_driver_base to implement APB transaction
// driving with path selection capability. It controls the sel_1 signal to
// route transactions and executes read/write operations on the APB bus.
//
// Type Parameters:
//   INTF_T - Virtual interface type for the APB bus
//
//------------------------------------------------------------------------------

class tx_sb_driver extends uvm_driver #(tx_sequence_item);
    `uvm_component_utils(tx_sb_driver)
    virtual sb_tx_link_bfm vif;
    tx_sequence_item item,rsp;
    uvm_analysis_port#(tx_sequence_item) ap;

    // Function: new
    //
    // Creates a new tx_sb_driver instance with the given name and parent.

    extern function new(string name = "tx_sb_driver", uvm_component parent = null);

    // Function: build_phase
    //
    // Builds the driver component 

    extern function void build_phase(uvm_phase phase);
    // Task: run_phase
    //
    // Drives tx transactions on the bus by setting path selection signals and
    // executing read or write operations based on the transaction type.

    extern task run_phase(tx_sequence_item item);

endclass : tx_sb_driver


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- tx_sb_driver
//
//------------------------------------------------------------------------------


// new
// ---

function tx_sb_driver::new(string name = "tx_sb_driver", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// build_phase
// -----

function void tx_sb_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
endfunction : build_phase

// run_phase
// ---------

task tx_sb_driver::run_phase(tx_sequence_item item);
   super.run_phase(phase);
   forever begin
    item = tx_sequence_item::type_id::create("item");
    seq_item_port.get_next_item(item);
    if (item.t==req) begin
        vif.i_tx_sb_req =1;
        vif.i_tx_sb_rsp =0;
        vif.i_tx_sb_done =0;
    end
    else if (item.t==rsp) begin
        vif.i_tx_sb_req =0;
        vif.i_tx_sb_rsp =1;
        vif.i_tx_sb_done =0;
    end
    else if (item.t==done) begin
        vif.i_tx_sb_req =0;
        vif.i_tx_sb_rsp =0;
        vif.i_tx_sb_done =1;
    end
    vif.i_tx_data = item.data;
    vif.i_tx_info = item.info;
    vif.i_tx_encoding = item.encoding;
    ap.write(item);
    seq_item_port.item_done();
   end
endtask