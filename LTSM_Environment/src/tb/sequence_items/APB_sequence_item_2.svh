/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_sequence_item_2.svh
 * Brief  : Extended APB sequence item with dual path selection for
 *          register file and UART routing control.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: APB_sequence_item_2
//
// The APB_sequence_item_2 class extends APB_sequence_item_1 to add UART
// path selection capability, providing independent control of both register
// file routing and UART routing paths.
//
//------------------------------------------------------------------------------

class APB_sequence_item_2 extends APB_sequence_item_1;
    rand uart_path_e    uart_path;      // 0 = APB_TO_UART_PATH,        1 = AES_TO_UART_PATH

    // Use begin/end even with just one field
    `uvm_object_utils_begin(APB_sequence_item_2)
        `uvm_field_enum(uart_path_e, uart_path, UVM_NORECORD | UVM_NOCOMPARE)
    `uvm_object_utils_end


    // Function: new
    //
    // Creates a new APB_sequence_item_2 instance with the given name.

    extern function new(string name = "APB_sequence_item_2");

endclass : APB_sequence_item_2


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- APB_sequence_item_2
//
//------------------------------------------------------------------------------


// new
// ---

function APB_sequence_item_2::new(string name = "APB_sequence_item_2");
    super.new(name);
endfunction