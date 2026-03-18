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


class l1_virtual_sequence extends virtual_sequence_base;
    `uvm_object_utils(l1_virtual_sequence)


    // Function: new
    //
    // Creates a new virtual_sequence instance with the given name.

    extern function new(string name = "l1_virtual_sequence");


    // Task: pre_body
    //
    // Creates instances of child reactive sequences before body execution.

    extern task pre_body();


    // Task: body
    //
    // Retrieves sequencer handles via base class, then starts both reactive
    // sequences on their respective sequencers sequentially.

    extern task body();

endclass : l1_virtual_sequence


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

function linkinit_virtual_sequence::new(string name = "linkinit_virtual_sequence");
    super.new(name);
endfunction : new

// pre_body
// --------

task l1_virtual_sequence::pre_body();
    // tx sequences
    tx_start_handshake_seq = l1_start_handshake::type_id::create("tx_start_handshake_seq");
    tx_enter_l1_seq = l1_tx_enter_l1::type_id::create("tx_enter_l1_seq");
    //tx_enter_pmnak_seq = l1_tx_rsp_pmnak::type_id::create("tx_rsp_pmnak_seq");
    // rx sequences
    rx_start_handshake_seq = l1_start_handshake::type_id::create("rx_start_handshake_seq");
    rx_rsp_l1_seq = l1_rx_rsp_l1::type_id::create("rx_rsp_l1_seq");
    rx_enter_l1_seq = l1_rx_enter_l1::type_id::create("rx_enter_l1_seq");
endtask

// body
// ----

task l1_virtual_sequence::body();
    super.body();
    fork
        // tx thread
        begin
            tx_start_handshake_seq.start(ltsm_rdi_sequencer);
            tx_enter_l1_seq.start(tx_fsm_sb_seqr);  
        end
        // rx thread
        begin
            rx_start_handshake_seq.start(ltsm_rdi_sequencer);
            rx_rsp_l1_seq.start(rx_fsm_sb_seqr);
            rx_enter_l1_seq.start(rx_fsm_sb_seqr);
        end
    join
endtask : body

