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

class rx_sb_driver extends uvm_driver #(rx_sequence_item);
    `uvm_component_utils(rx_sb_driver)
    virtual sb_rx_link_bfm vif;
    rx_sequence_item item,rsp;
    uvm_analysis_port#(rx_sequence_item) ap;

    // Function: new
    //
    // Creates a new rx_sb_driver instance with the given name and parent.

    extern function new(string name = "rx_sb_driver", uvm_component parent = null);

    // Function: build_phase
    //
    // Builds the driver component 

    extern function void build_phase(uvm_phase phase);
    // Task: run_phase
    //
    // Drives rx transactions on the bus by setting path selection signals and
    // executing read or write operations based on the transaction type.

    extern task run_phase(rx_sequence_item item);

endclass : rx_sb_driver


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- rx_sb_driver
//
//------------------------------------------------------------------------------


// new
// ---

function rx_sb_driver::new(string name = "rx_sb_driver", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// build_phase
// -----

function void rx_sb_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
endfunction : build_phase

// run_phase
// ---------

task rx_sb_driver::run_phase(rx_sequence_item item);
   super.run_phase(phase);
   forever begin
    item = rx_sequence_item::type_id::create("item");
    seq_item_port.get_next_item(item);
    if (item.t==req) begin
        vif.i_rx_sb_req =1;
        vif.i_rx_sb_rsp =0;
        vif.i_rx_sb_done =0;
    end
    else if (item.t==rsp) begin
        vif.i_rx_sb_req =0;
        vif.i_rx_sb_rsp =1;
        vif.i_rx_sb_done =0;
    end
    else if (item.t==done) begin
        vif.i_rx_sb_req =0;
        vif.i_rx_sb_rsp =0;
        vif.i_rx_sb_done =1;
    end
    vif.i_rx_data = item.data;
    vif.i_rx_info = item.info;
    vif.i_rx_encoding = item.encoding;
    ap.write(item);
    seq_item_port.item_done();
   end
endtask