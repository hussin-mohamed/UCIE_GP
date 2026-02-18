/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_driver_2.svh
 * Brief  : APB driver implementation with dual path selection for
 *          register file and UART routing control.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: APB_driver_2
//
// The APB_driver_2 class extends APB_driver_base to implement APB transaction
// driving with dual path selection. It controls sel_2 for UART routing and
// sel_3 for register file routing, then executes read/write operations.
//
// Type Parameters:
//   INTF_T - Virtual interface type for the APB bus
//
//------------------------------------------------------------------------------

class APB_driver_2 #(type INTF_T) extends APB_driver_base #(APB_sequence_item_2, INTF_T);
    `uvm_component_param_utils(APB_driver_2#(INTF_T))


    // Function: new
    //
    // Creates a new APB_driver_2 instance with the given name and parent.

    extern function new(string name = "APB_driver_2", uvm_component parent = null);


    // Task: drive
    //
    // Drives APB transactions with dual path control by setting register file
    // and UART path selection signals, then executing read or write operations.

    extern virtual task drive(APB_sequence_item_2 item);

endclass : APB_driver_2


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- APB_driver_2
//
//------------------------------------------------------------------------------


// new
// ---

function APB_driver_2::new(string name = "APB_driver_2", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// drive
// -----

task APB_driver_2::drive(APB_sequence_item_2 item);
    `uvm_info(get_type_name(), "Driving...", UVM_DEBUG)
    
    item_type_name = req.get_type_name();
    
    if (item.regfile_path == APB_BFM_TO_REGFILE_PATH) begin
        bfm.sel_3 = 1'b0;
    end else begin
        bfm.sel_3 = 1'b1;
    end

    if (item.uart_path == APB_TO_UART_PATH) begin
        bfm.sel_2 = 1'b1;
    end else begin
        bfm.sel_2 = 1'b0;
    end
    
    if (item.kind == WRITE) begin
        bfm.write_reg(item.addr, item.data, item.strobe);
    end else if (item.kind == READ) begin
        bfm.read_reg(item.addr, item.data);
    end

    `uvm_info(get_type_name(), $sformatf("DRIVED %s: \n%s", item.get_type_name(), item.sprint()), UVM_DEBUG)
endtask