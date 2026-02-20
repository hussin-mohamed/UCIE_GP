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
import shared_pkg::*;
class ctrl_sb_driver extends uvm_driver #(ctrl_sequence_item);
    `uvm_component_utils(ctrl_sb_driver)
    virtual sb_ctrl_link_bfm vif;
    ctrl_sequence_item item,rsp;
    uvm_analysis_port#(ctrl_sequence_item) ap;

    // Function: new
    //
    // Creates a new ctrl_sb_driver instance with the given name and parent.

    extern function new(string name = "ctrl_sb_driver", uvm_component parent = null);

    // Function: build_phase
    //
    // Builds the driver component 

    extern function void build_phase(uvm_phase phase);
    // Task: run_phase
    //
    // Drives ctrl transactions on the bus by setting path selection signals and
    // executing read or write operations based on the transaction type.

    extern task run_phase(ctrl_sequence_item item);

endclass : ctrl_sb_driver


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- ctrl_sb_driver
//
//------------------------------------------------------------------------------


// new
// ---

function ctrl_sb_driver::new(string name = "ctrl_sb_driver", uvm_component parent = null);
    super.new(name, parent);
    
endfunction : new

// build_phase
// ------------

function void ctrl_sb_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
endfunction : build_phase

// run_phase
// ---------

task ctrl_sb_driver::run_phase(ctrl_sequence_item item);
   super.run_phase(phase);
   forever begin
    item = ctrl_sequence_item::type_id::create("item");
    seq_item_port.get_next_item(item);
    if (item.m == start) begin
        vif.i_sb_init_start = 1;
        vif.reset= 1;
        vif.i_timer_1ms = 0;
        @(negedge vif.clk);
    end
    else if (item.m == reset) begin
        vif.i_sb_init_start = 0;
        vif.reset= 1;
        vif.i_timer_1ms = 0;
        @(negedge vif.clk);
    end
    else if (item.m == init) begin
        vif.i_sb_init_start = 1;
        vif.reset= 0;
        vif.i_timer_1ms = 0;
        repeat(1ms) begin
            if(item.o_sb_ready)begin
            rsp.m = ready;
            break;
            end
            else  begin    
            @(negedge vif.clk);
            end
        end
    end
    else if (item.m == mode_t::t1ms) begin
        vif.i_sb_init_start = 1;
        vif.reset= 1;
        vif.i_timer_1ms = 1;
        @(negedge vif.clk);
        vif.i_timer_1ms = 0;
        repeat(1ms-1) begin
            @(negedge vif.clk);
        end
    end
    else if (item.m == mode_t::ready) begin
        vif.i_sb_init_start = 0;
        vif.reset= 1;
        vif.i_timer_1ms = 0;
        @(negedge vif.clk);
    end
    else
    ap.write(item);
    seq_item_port.item_done(rsp);
   end
endtask