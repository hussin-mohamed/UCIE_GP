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


class l1_rx_vs_refuse_l1 extends virtual_sequence_base;
    `uvm_object_utils(l1_rx_vs_refuse_l1)
    l1_rx_wait_seq rx_wait_seq;
    l1_rx_refuse_l1 rx_refuse_l1_seq;
    l1_rx_refuse_done rx_refuse_done_seq;
    nothing_rx nothing_rx_seq;

    // Function: new
    //
    // Creates a new virtual_sequence instance with the given name.

    extern function new(string name = "l1_rx_vs_refuse_l1");


    // Task: pre_body
    //
    // Creates instances of child reactive sequences before body execution.

    extern task pre_body();


    // Task: body
    //
    // Retrieves sequencer handles via base class, then starts both reactive
    // sequences on their respective sequencers sequentially.

    extern task body();

endclass : l1_rx_vs_refuse_l1


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

function l1_rx_vs_refuse_l1::new(string name = "l1_rx_vs_refuse_l1");
    super.new(name);
endfunction : new

// pre_body
// --------

task l1_rx_vs_refuse_l1::pre_body();
    // rx sequences
    rx_wait_seq = l1_rx_wait_seq::type_id::create("rx_wait_seq");
    rx_refuse_l1_seq = l1_rx_refuse_l1::type_id::create("rx_refuse_l1_seq");
    rx_refuse_done_seq = l1_rx_refuse_done::type_id::create("rx_refuse_done_seq");
    nothing_rx_seq = nothing_rx::type_id::create("nothing_rx_seq");
endtask

// body
// ----
// remote die initiates the handshake by sending the L1 state request, then remote die responds with the L1 state response, then both sides enter L1
task l1_rx_vs_refuse_l1::body();
    super.body();
        //rx sequences
        rx_wait_seq.start(rx_fsm_sb_seqr);
         repeat(8)begin
           nothing_rx_seq.start(rx_fsm_sb_seqr);
        end
       // rx_refuse_l1_seq.start(ltsm_rdi_seqr);
        rx_refuse_done_seq.start(rx_fsm_sb_seqr);
endtask : body

