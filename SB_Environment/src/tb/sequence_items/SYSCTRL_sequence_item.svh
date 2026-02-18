/***********************************************************************
 * Author : Amr El Batarny
 * File   : SYSCTRL_sequence_item.svh
 * Brief  : Sequence item for system control transactions with address,
 *          data, operation type, and path selection fields.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: SYSCTRL_sequence_item
//
// The SYSCTRL_sequence_item class represents system control transactions
// with full APB protocol fields including address, data, strobe, operation
// type, and register file path selection for system-level control operations.
//
//------------------------------------------------------------------------------

class SYSCTRL_sequence_item extends uvm_sequence_item;
  
    randc logic [ADDR_WIDTH-1:0] addr;      // 32-bit word-aligned address
    rand logic [DATA_WIDTH-1:0] data;       // 32-bit data
    rand logic [NBYTES-1:0]     strobe;     // 4-bit strobe (0–15)
    rand type_e                 kind;       // 0 = READ, 1 = WRITE
    rand regfile_path_e         path;       // 0 = APB_BFM_TO_REGFILE_PATH, 1 = AES_TO_REGFILE_PATH

    `uvm_object_utils_begin(SYSCTRL_sequence_item)
        `uvm_field_int(addr,                    UVM_NORECORD)
        `uvm_field_int(data,                    UVM_NORECORD)
        `uvm_field_int(strobe,                  UVM_NORECORD)
        `uvm_field_enum(type_e, kind,           UVM_NORECORD)
        `uvm_field_enum(regfile_path_e, path,   UVM_NORECORD)
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
    // Creates a new SYSCTRL_sequence_item instance with the given name.

    extern function new(string name = "SYSCTRL_sequence_item");

endclass : SYSCTRL_sequence_item


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- SYSCTRL_sequence_item
//
//------------------------------------------------------------------------------


// new
// ---

function SYSCTRL_sequence_item::new(string name = "SYSCTRL_sequence_item");
    super.new(name);
endfunction : new