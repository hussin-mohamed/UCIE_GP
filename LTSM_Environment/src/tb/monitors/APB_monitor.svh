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

class APB_monitor #(type ITEM_T, type INTF_T) extends APB_monitor_base #(ITEM_T, INTF_T);
    `uvm_component_param_utils(APB_monitor #(ITEM_T, INTF_T))


    // Function: new
    //
    // Creates a new APB_monitor instance with the given name and parent.

    extern function new(string name = "APB_monitor", uvm_component parent = null);


    // Task: collect_transaction
    //
    // Monitors the APB bus for setup and access phases, captures transaction
    // details including address, data, strobe, and operation type (read/write),
    // then broadcasts the transaction through the analysis port.

    extern virtual task collect_transaction();

endclass : APB_monitor


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- APB_monitor
//
//------------------------------------------------------------------------------


// new
// ---

function APB_monitor::new(string name = "APB_monitor", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// collect_transaction
// -------------------

task APB_monitor::collect_transaction();
    item = ITEM_T::type_id::create("item");

    // Align to APB clock
    @(negedge bfm.PCLK);

    // Wait for setup phase conditions
    while (!(bfm.PSELx_int === 1'b1 && 
             bfm.PENABLE_int === 1'b1 && 
             bfm.PRESETn === 1'b1)) begin
        @(negedge bfm.PCLK);
    end
    
    `uvm_info(get_type_name(), "Setup phase detected", UVM_DEBUG)
    
    // Capture address and strobe
    item.addr = bfm.PADDR_int;
    item.strobe = bfm.PSTRB_int;
    
    if (bfm.PWRITE_int) begin
        item.kind = WRITE;
        item.data = bfm.PWDATA_int;
    end else begin
        item.kind = READ;
        
        // Wait for PREADY
        @(posedge bfm.PREADY);
        `uvm_info(get_type_name(), "PREADY asserted", UVM_DEBUG)
        @(negedge bfm.PREADY);

        // Capture read data on next cycle
        @(negedge bfm.PCLK);
        item.data = bfm.PRDATA;
    end

    ap.write(item);
    `uvm_info(get_type_name(), $sformatf("MONITORED %s: \n%s", item.get_type_name(), item.sprint()), UVM_DEBUG)
    transaction_count++;
endtask : collect_transaction