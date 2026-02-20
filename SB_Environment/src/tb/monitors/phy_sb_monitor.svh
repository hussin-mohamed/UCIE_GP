/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_monitor.svh
 * Brief  : APB protocol monitor for capturing read and write transactions
 *          from the APB bus including address, data, and strobe signals.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: APB_monitor
//
// The APB_monitor class extends APB_monitor_base to implement complete APB
// protocol monitoring. It captures both read and write transactions by
// detecting setup and access phases, sampling appropriate signals, and
// broadcasting transactions through the analysis port.
//
// Type Parameters:
//   ITEM_T - Transaction item type (typically APB_sequence_item)
//   INTF_T - Virtual interface type for the APB bus
//
//------------------------------------------------------------------------------

class phy_sb_monitor extends uvm_monitor;
    `uvm_component_utils(phy_sb_monitor)
    phy_sequence_item item;

    virtual sb_ltsm_phy_bfm vif;
    uvm_analysis_port #(phy_sequence_item) ap;

   // Function: new
    //
    // Creates a new phy_sb_monitor instance with the given name and parent.

    extern function new(string name = "phy_sb_monitor", uvm_component parent = null);

    // Function: build_phase
    //
    // Builds the monitor component 

    extern function void build_phase(uvm_phase phase);
    // Task: run_phase
    //
    // Monitors phy transactions on the bus by sampling signals and
    // broadcasting captured transactions through the analysis port.

    extern task run_phase(phy_sequence_item item);

endclass : phy_sb_monitor


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- phy_sb_monitor
//
//------------------------------------------------------------------------------


// new
// ---

function phy_sb_monitor::new(string name = "phy_sb_monitor", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// build_phase
// -------------------

function phy_sb_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    
endfunction : build_phase

// run_phase
// ---------

task phy_sb_monitor::run_phase(phy_sequence_item item);
    super.run_phase(phase);
    forever begin
        item = phy_sequence_item::type_id::create("item");
        for (int i = 0; i < 64; i++) begin
            @(negedge vif.clk);
           item.payload[63-i] = vif.o_tx_sb_data; 
        end
        if (item.payload [36:32] ==5'b10010 ) begin
            item.header=item.payload;
        end
        else if (item.payload [36:32] ==5'b11011 ) begin
            item.header=item.payload;
            for (int i = 0; i < 64; i++) begin
                @(negedge vif.clk);
                item.data[63-i] = vif.o_tx_sb_data; 
            end
        end
        else begin
            item.pattern[63:0]=item.payload;
            for (int i = 0; i < 32; i++) begin
                @(negedge vif.clk);
                item.pattern[64+i] = vif.o_tx_sb_data; 
            end
        end
        ap.write(item);
    end
endtask


