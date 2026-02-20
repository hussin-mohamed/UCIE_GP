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
// CLASS: ltsm_sequence_item_base
//
// Description: Sequence item class for LTSM sequences, containing all necessary
//              fields for controlling and monitoring the LTSM behavior.
//------------------------------------------------------------------------------

import uvm_pkg::*;
`include "uvm_macros.svh"
class phy_sequence_item extends ltsm_sequence_item_base;
    `uvm_object_utils(phy_sequence_item)
    
     // Fields representing LTSM control and status signals
    // Function: new
    //
    // Creates a new phy_sequence_item instance with the given name.

    extern function new(string name = "phy_sequence_item");
  // Fields representing LTSM control and status signals
        logic [63:0] header;
        operation_t op;
        rand logic [95:0] pattern; 
        logic [63:0] payload; // will be used in monitoring to be able to capture all cases
    `uvm_object_utils_begin(phy_sequence_item)
        `uvm_field_int(header, UVM_NORECORD)
        `uvm_field_enum(operation_t, op, UVM_NORECORD)
        `uvm_field_int(pattern, UVM_NORECORD)
    `uvm_object_utils_end

    // Function: new
    //
    // Creates a new phy_sequence_item instance with the given name.
    extern function new(string name = "phy_sequence_item");
endclass : phy_sequence_item

function phy_sequence_item::new(string name = "phy_sequence_item");
    super.new(name);

endfunction
