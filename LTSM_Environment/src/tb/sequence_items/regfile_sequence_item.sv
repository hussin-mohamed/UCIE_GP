// ****************************************************************************
// *                                                                          *
// * Copyright (c) 2014-2015 Synopsys Inc. All rights reserved.               *
// *                                                                          *
// * Synopsys Proprietary and Confidential. This file contains confidential   *
// * information and the trade secrets of Synopsys Inc. Use, disclosure, or   *
// * reproduction is prohibited without the prior express written permission  *
// * of Synopsys, Inc.                                                        *
// *                                                                          *
// * Synopsys, Inc.                                                           *
// * 700 East Middlefield Road                                                *
// * Mountain View, California 94043                                          *
// * (800) 541-7737                                                           *
// *                                                                          *
// ****************************************************************************

//------------------------------------------------------------------------------
//
// CLASS: regfile_sequence_item
//
// The regfile_sequence_item class represents the output transaction
//
//------------------------------------------------------------------------------

class regfile_sequence_item extends uvm_sequence_item;

	 logic [2:0] i_speedreg,o_speedreg;
    logic [15:0] i_local_cap;
    logic i_Runtime_Link_Test_status_register,o_Runtime_Link_Test_status_register;
    logic [36:0] i_Runtime_Link_Test_Control_register,o_Runtime_Link_Test_Control_register;
    `uvm_object_utils_begin(regfile_sequence_item)
        `uvm_field_int(i_speedreg, UVM_NORECORD)
        `uvm_field_int(o_speedreg, UVM_NORECORD)
        `uvm_field_int(i_local_cap, UVM_NORECORD)
        `uvm_field_int(i_Runtime_Link_Test_status_register, UVM_NORECORD)
        `uvm_field_int(o_Runtime_Link_Test_status_register, UVM_NORECORD)
        `uvm_field_int(i_Runtime_Link_Test_Control_register, UVM_NORECORD)
        `uvm_field_int(o_Runtime_Link_Test_Control_register, UVM_NORECORD)

    `uvm_object_utils_end


    // Function: new
    //
    // Creates a new regfile_sequence_item instance with the given name.

    extern function new(string name = "regfile_sequence_item");

endclass : regfile_sequence_item


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- regfile_sequence_item
//
//------------------------------------------------------------------------------


// new
// ---

function regfile_sequence_item::new(string name = "regfile_sequence_item");
    super.new(name);
endfunction
