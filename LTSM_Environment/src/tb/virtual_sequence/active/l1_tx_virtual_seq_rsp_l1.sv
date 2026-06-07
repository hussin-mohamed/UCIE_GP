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


class l1_virtual_sequence_rsp_l1 extends virtual_sequence_base;
    `uvm_object_utils(l1_virtual_sequence_rsp_l1)
    l1_start_handshake tx_start_handshake_seq ;
    l1_rx_start_handshake rx_start_handshake_seq ;
    l1_tx_enter_l1_txinit  tx_enter_l1_seq;
    l1_rx_rsp_l1 rx_rsp_l1_seq;
    l1_rx_enter_l1 rx_enter_l1_seq;

    // Function: new
    //
    // Creates a new virtual_sequence instance with the given name.

    extern function new(string name = "l1_virtual_sequence_rsp_l1");


    // Task: pre_body
    //
    // Creates instances of child reactive sequences before body execution.

    extern task pre_body();


    // Task: body
    //
    // Retrieves sequencer handles via base class, then starts both reactive
    // sequences on their respective sequencers sequentially.

    extern task body();

endclass : l1_virtual_sequence_rsp_l1


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

function l1_virtual_sequence_rsp_l1::new(string name = "l1_virtual_sequence_rsp_l1");
    super.new(name);
endfunction : new

// pre_body
// --------

task l1_virtual_sequence_rsp_l1::pre_body();
    // tx sequences
    tx_start_handshake_seq = l1_start_handshake::type_id::create("tx_start_handshake_seq");
    tx_enter_l1_seq = l1_tx_enter_l1_txinit::type_id::create("tx_enter_l1_seq");
    // rx sequences
    rx_start_handshake_seq = l1_rx_start_handshake::type_id::create("rx_start_handshake_seq");
    rx_rsp_l1_seq = l1_rx_rsp_l1::type_id::create("rx_rsp_l1_seq");
  //  rx_enter_l1_seq = l1_rx_enter_l1::type_id::create("rx_enter_l1_seq");
endtask

// body
// ----
// local die initiates the handshake by sending the L1 state request, then remote die responds with the L1 state response, then both sides enter L1
task l1_virtual_sequence_rsp_l1::body();
    super.body();
        tx_start_handshake_seq.start(ltsm_rdi_seqr);
        tx_enter_l1_seq.start(tx_fsm_sb_seqr);
        rx_start_handshake_seq.start(rx_fsm_sb_seqr);  
        

endtask : body

