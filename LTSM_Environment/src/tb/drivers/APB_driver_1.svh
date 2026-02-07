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

class APB_driver_1 #(type INTF_T) extends APB_driver_base #(APB_sequence_item_1, INTF_T);
    `uvm_component_param_utils(APB_driver_1#(INTF_T))


    // Function: new
    //
    // Creates a new APB_driver_1 instance with the given name and parent.

    extern function new(string name = "APB_driver_1", uvm_component parent = null);


    // Task: drive
    //
    // Drives APB transactions on the bus by setting path selection signals and
    // executing read or write operations based on the transaction type.

    extern virtual task drive(APB_sequence_item_1 item);

endclass : APB_driver_1


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- APB_driver_1
//
//------------------------------------------------------------------------------


// new
// ---

function APB_driver_1::new(string name = "APB_driver_1", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// drive
// -----

task APB_driver_1::drive(APB_sequence_item_1 item);
    `uvm_info(get_type_name(), "Driving...", UVM_DEBUG)
    
    item_type_name = req.get_type_name();

    if (item.regfile_path == APB_BFM_TO_REGFILE_PATH) begin
        bfm.sel_1 = 1'b0;
    end else begin
        bfm.sel_1 = 1'b1;
    end
    
    if (item.kind == WRITE) begin
        bfm.write_reg(item.addr, item.data, item.strobe);
    end else if (item.kind == READ) begin
        bfm.read_reg(item.addr, item.data);
    end

    `uvm_info(get_type_name(), $sformatf("DRIVED %s: \n%s", item.get_type_name(), item.sprint()), UVM_DEBUG)
endtask