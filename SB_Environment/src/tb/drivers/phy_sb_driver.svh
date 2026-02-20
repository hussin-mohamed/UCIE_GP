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

class phy_sb_driver extends uvm_driver #(phy_sequence_item);
    `uvm_component_utils(phy_sb_driver)
    virtual sb_phy_link_bfm vif;
    phy_sequence_item item,rsp;
    uvm_analysis_port#(phy_sequence_item) ap;

    // Function: new
    //
    // Creates a new phy_sb_driver instance with the given name and parent.

    extern function new(string name = "phy_sb_driver", uvm_component parent = null);

    // Function: build_phase
    //
    // Builds the driver component 

    extern function void build_phase(uvm_phase phase);
    // Task: run_phase
    //
    // Drives phy transactions on the bus by setting path selection signals and
    // executing read or write operations based on the transaction type.

    extern task run_phase(phy_sequence_item item);

endclass : phy_sb_driver


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- phy_sb_driver
//
//------------------------------------------------------------------------------


// new
// ---

function phy_sb_driver::new(string name = "phy_sb_driver", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// build_phase
// -----

function void phy_sb_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
endfunction : build_phase

// run_phase
// ---------

task phy_sb_driver::run_phase(phy_sequence_item item);
   super.run_phase(phase);
   forever begin
    item = phy_sequence_item::type_id::create("item");
    seq_item_port.get_next_item(item);
    if (item.op == initialization) begin

        for (int i = 0; i < 96; i++) begin
            if (item.pattern==0) begin
                vif.i_rx_sb_clk=0;
            end
            else  begin
                vif.i_rx_sb_clk=vif.clk;
            end
            vif.i_rx_sb_data = item.pattern[63-i];
            @(negedge vif.clk);
        end
    end
    else if (item.op == active) begin
        if (item.size==64) begin
            for (int i = 0; i < 64; i++) begin
                vif.i_rx_sb_clk=vif.clk;
                vif.i_rx_sb_data = item.header[63-i];
                @(negedge vif.clk);
            end
        end
        else if (item.size==128) begin
            for (int i = 0; i < 64; i++) begin
                vif.i_rx_sb_clk=vif.clk;
                vif.i_rx_sb_data = item.header[63-i];
                @(negedge vif.clk);
            end
            for (int i = 0; i < 64; i++) begin
                vif.i_rx_sb_clk=vif.clk;
                vif.i_rx_sb_data = item.data[63-i];
                @(negedge vif.clk);
            end
        end
    end
    ap.write(item);
    seq_item_port.item_done();
   end
endtask
