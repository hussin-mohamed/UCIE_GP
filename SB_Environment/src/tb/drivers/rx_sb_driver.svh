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

class rx_sb_driver #(type INTF_T) extends sb_driver_base #(rx_sequence_item, INTF_T);
    `uvm_component_param_utils(rx_sb_driver#(INTF_T))


    // Function: new
    //
    // Creates a new rx_sb_driver instance with the given name and parent.

    extern function new(string name = "rx_sb_driver", uvm_component parent = null);


    // Task: drive
    //
    // Drives APB transactions on the bus by setting path selection signals and
    // executing read or write operations based on the transaction type.

    extern virtual task drive(APB_sequence_item_1 item);

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

// drive
// -----

task rx_sb_driver::drive(APB_sequence_item_1 item);
   
endtask