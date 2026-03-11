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

//-----------------------------------------------------------------------------
//
// CLASS: phylink_monitor
//
// ...
//
//-----------------------------------------------------------------------------

class phylink_monitor extends sb_monitor_base #(phylink_seq_item, virtual sb_phylink_bfm);
    `uvm_component_utils(phylink_monitor)


    // Function: new
    //
    // Creates a new phylink_monitor instance with the given name and parent.

    extern function new(string name, uvm_component parent);


    // Task: collect_item
    //
    // ...

    extern virtual task collect_item(output phylink_seq_item _item);

endclass : phylink_monitor


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS- phylink_monitor
//
//-----------------------------------------------------------------------------


// new
// ---

function phylink_monitor::new(string name, uvm_component parent);
    super.new(name, parent);
endfunction : new

// collect_item
// ------------

task phylink_monitor::collect_item(output phylink_seq_item _item);
    logic [127:0] msg_raw;
    message_t     msg;

    _item = phylink_seq_item::type_id::create("_item");

    // Since collect_item() is executed, this means the SB is in the ACTIVE mode
    _item.op_mode = ACTIVE;

    // Start deserialization
    bfm.deserialize_data(msg_raw);

    // Convert the raw message into a message_t struct
    msg = raw2struct(msg_raw);

    // Populate the _item with the message fields
    _item.fullcode = msg.fullcode;
    _item.opcode   = msg.opcode;
    _item.srcid    = msg.srcid;
    _item.dstid    = msg.dstid;
    _item.info     = msg.info;
    _item.data     = msg.data;
    _item.cp       = msg.cp;
    _item.dp       = msg.dp;
endtask : collect_item
