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


class active_virtual_sequence extends virtual_sequence_base;
    `uvm_object_utils(active_virtual_sequence)


    // Function: new
    //
    // Creates a new virtual_sequence instance with the given name.

    extern function new(string name = "active_virtual_sequence");


    // Task: pre_body
    //
    // Creates instances of child reactive sequences before body execution.

    extern task pre_body();


    // Task: body
    //
    // Retrieves sequencer handles via base class, then starts both reactive
    // sequences on their respective sequencers sequentially.

    extern task body();

endclass : active_virtual_sequence


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- virtual_sequence
//
//------------------------------------------------------------------------------


// new
// ---

function active_virtual_sequence::new(string name = "active_virtual_sequence");
    super.new(name);
endfunction : new

// pre_body
// --------

task active_virtual_sequence::pre_body();
    // tx sequences
    start_handshake_seq = active_tx_handshake::type_id::create("start_handshake_seq");
    // rx sequences
    start_handshake_rx_seq = active_rx_handshake::type_id::create("start_handshake_rx_seq");
    start_handshake_rx_done_seq = active_rx_done_handshake::type_id::create("start_handshake_rx_done_seq");
endtask

// body
// ----

task active_virtual_sequence::body();
    super.body();
    fork
        // tx thread
        begin
            start_handshake_seq.start(tx_fsm_sb_seqr);
        end
        // rx thread
        begin
            start_handshake_rx_seq.start(rx_fsm_sb_seqr);
            start_handshake_rx_done_seq.start(rx_fsm_sb_seqr); 
        end
    join
endtask : body

