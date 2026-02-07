/***********************************************************************
 * Author : Amr El Batarny
 * File   : AES_sequence_item.svh
 * Brief  : Sequence item for AES transactions containing input and
 *          output data fields for encryption operations.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: AES_sequence_item
//
// The AES_sequence_item class represents AES encryption transactions,
// containing both input data to be encrypted and output encrypted data
// fields for verification purposes.
//
//------------------------------------------------------------------------------

class AES_sequence_item extends uvm_sequence_item;

    rand logic [N_AES-1:0] data_in;
    rand logic [N_AES-1:0] data_out;

    `uvm_object_utils_begin(AES_sequence_item)
        `uvm_field_int(data_in,  UVM_NORECORD)
        `uvm_field_int(data_out, UVM_NORECORD)
    `uvm_object_utils_end


    // Function: new
    //
    // Creates a new AES_sequence_item instance with the given name.

    extern function new(string name = "AES_sequence_item");

endclass : AES_sequence_item


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- AES_sequence_item
//
//------------------------------------------------------------------------------


// new
// ---

function AES_sequence_item::new(string name = "AES_sequence_item");
    super.new(name);
endfunction