/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_controller_sequence_item.svh
 * Brief  : Sequence item for APB controller output containing concatenated
 *          AES-width data from multiple APB transactions.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: APB_controller_sequence_item
//
// The APB_controller_sequence_item class represents the output transaction
// from the APB controller, containing concatenated data of AES width formed
// from multiple sequential APB read transactions.
//
//------------------------------------------------------------------------------

class APB_controller_sequence_item extends uvm_sequence_item;

    logic [N_AES-1:0] data;

    `uvm_object_utils_begin(APB_controller_sequence_item)
        `uvm_field_int(data, UVM_NORECORD)
    `uvm_object_utils_end


    // Function: new
    //
    // Creates a new APB_controller_sequence_item instance with the given name.

    extern function new(string name = "APB_controller_sequence_item");

endclass : APB_controller_sequence_item


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- APB_controller_sequence_item
//
//------------------------------------------------------------------------------


// new
// ---

function APB_controller_sequence_item::new(string name = "APB_controller_sequence_item");
    super.new(name);
endfunction