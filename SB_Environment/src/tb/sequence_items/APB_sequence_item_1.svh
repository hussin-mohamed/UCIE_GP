/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_sequence_item_1.svh
 * Brief  : Extended APB sequence item with register file path selection
 *          for routing between BFM and AES paths.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: APB_sequence_item_1
//
// The APB_sequence_item_1 class extends APB_sequence_item_base to add
// register file path selection capability, enabling routing control between
// the APB BFM to register file path and the AES to register file path.
//
//------------------------------------------------------------------------------

class APB_sequence_item_1 extends APB_sequence_item_base;
    rand regfile_path_e regfile_path;   // 0 = APB_BFM_TO_REGFILE_PATH, 1 = AES_TO_REGFILE_PATH

    // Use begin/end even with just one field
    `uvm_object_utils_begin(APB_sequence_item_1)
        `uvm_field_enum(regfile_path_e, regfile_path, UVM_NORECORD | UVM_NOCOMPARE)
    `uvm_object_utils_end


    // Function: new
    //
    // Creates a new APB_sequence_item_1 instance with the given name.

    extern function new(string name = "APB_sequence_item_1");

endclass : APB_sequence_item_1


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- APB_sequence_item_1
//
//------------------------------------------------------------------------------


// new
// ---

function APB_sequence_item_1::new(string name = "APB_sequence_item_1");
    super.new(name);
endfunction