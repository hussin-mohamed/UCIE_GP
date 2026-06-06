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


class linkinit_virtual_sequence extends virtual_sequence_base;
    `uvm_object_utils(linkinit_virtual_sequence)
    linkinit_tx_clk_req_handshake tx_clk_req_handshake_seq ;
    // rx sequences
    linkinit_rx_clk_req_handshake rx_clk_req_handshake_seq ;
    // common sequences
    linkinit_wake_req_handshake wake_req_handshake_seq ;
    linkinit_state_req_handshake state_req_handshake_seq ;
    

    // Function: new
    //
    // Creates a new virtual_sequence instance with the given name.

    extern function new(string name = "linkinit_virtual_sequence");


    // Task: pre_body
    //
    // Creates instances of child reactive sequences before body execution.

    extern task pre_body();


    // Task: body
    //
    // Retrieves sequencer handles via base class, then starts both reactive
    // sequences on their respective sequencers sequentially.

    extern task body();

endclass : linkinit_virtual_sequence


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

task linkinit_virtual_sequence::pre_body();
    // tx sequences
    tx_clk_req_handshake_seq = linkinit_tx_clk_req_handshake::type_id::create("tx_clk_req_handshake_seq");
    // rx sequences
    rx_clk_req_handshake_seq = linkinit_rx_clk_req_handshake::type_id::create("rx_clk_req_handshake_seq");
    // common sequences
    wake_req_handshake_seq = linkinit_wake_req_handshake::type_id::create("tx_wake_req_handshake_seq");
    state_req_handshake_seq = linkinit_state_req_handshake::type_id::create("tx_state_req_handshake_seq");
    
endtask

// body
// ----

task linkinit_virtual_sequence::body();
    super.body();
       /* fork
            tx_clk_req_handshake_seq.start(tx_fsm_sb_seqr);
            rx_clk_req_handshake_seq.start(rx_fsm_sb_seqr);  
        join*/
        //common_thread
        wake_req_handshake_seq.start(ltsm_rdi_seqr);
        state_req_handshake_seq.start(ltsm_rdi_seqr);    

endtask : body
