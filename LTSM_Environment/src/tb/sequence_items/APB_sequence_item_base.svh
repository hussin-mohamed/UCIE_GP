/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_sequence_item_base.svh
 * Brief  : Base sequence item class for APB transactions with common
 *          fields and constraints for address, data, and strobe.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: APB_sequence_item_base
//
// The APB_sequence_item_base class provides the base transaction item for
// APB protocol operations. It includes address, data, strobe, operation type,
// and request fields with appropriate constraints for word-aligned addressing
// and register file range compliance.
//
//------------------------------------------------------------------------------

class APB_sequence_item_base extends uvm_sequence_item;
  
    randc logic [ADDR_WIDTH-1:0] addr;      // 32-bit word-aligned address
    rand  logic [DATA_WIDTH-1:0] data;      // 32-bit data
    rand  logic [NBYTES-1:0]     strobe;    // 4-bit strobe (0–15)
    rand  type_e                 kind;      // 0 = READ, 1 = WRITE
    rand  bit                    request;   // 0 = APB_BFM_TO_REGFILE_PATH, 1 = AES_TO_REGFILE_PATH

    `uvm_object_utils_begin(APB_sequence_item_base)
        `uvm_field_int(addr,            UVM_NORECORD)
        `uvm_field_int(data,            UVM_NORECORD)
        `uvm_field_int(strobe,          UVM_NORECORD)
        `uvm_field_enum(type_e, kind,   UVM_NORECORD)
        `uvm_field_int(request,         UVM_NORECORD | UVM_NOCOMPARE)
    `uvm_object_utils_end

    constraint c_randomize {
        // Strobe: WRITE picks weighted, READ forces 0
        if (kind == READ)
            strobe == 0;

        // Address constraints
        addr inside {[32'h00000000:32'h0000003C]};
        (addr % 4) == 0;
    }


    // Function: new
    //
    // Creates a new APB_sequence_item_base instance with the given name.

    extern function new(string name = "APB_sequence_item_base");

endclass : APB_sequence_item_base


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- APB_sequence_item_base
//
//------------------------------------------------------------------------------


// new
// ---

function APB_sequence_item_base::new(string name = "APB_sequence_item_base");
    super.new(name);
endfunction