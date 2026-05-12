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


class l1_virtual_sequence_rsp_pmnak extends virtual_sequence_base;
    `uvm_object_utils(l1_virtual_sequence_rsp_pmnak)
    l1_start_handshake tx_start_handshake_seq ;
    l1_tx_refuse_l1 tx_refuse_l1_seq ;

    // Function: new
    //
    // Creates a new virtual_sequence instance with the given name.

    extern function new(string name = "l1_virtual_sequence_rsp_pmnak");


    // Task: pre_body
    //
    // Creates instances of child reactive sequences before body execution.

    extern task pre_body();


    // Task: body
    //
    // Retrieves sequencer handles via base class, then starts both reactive
    // sequences on their respective sequencers sequentially.

    extern task body();

endclass : l1_virtual_sequence_rsp_pmnak


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

function l1_virtual_sequence_rsp_pmnak::new(string name = "l1_virtual_sequence_rsp_pmnak");
    super.new(name);
endfunction : new

// pre_body
// --------

task l1_virtual_sequence_rsp_pmnak::pre_body();
    // tx sequences
    tx_start_handshake_seq = l1_start_handshake::type_id::create("tx_start_handshake_seq");
    tx_refuse_l1_seq = l1_tx_refuse_l1::type_id::create("tx_refuse_l1_seq");
    // rx sequences

endtask

// body
// ----
// local die initiates the handshake by sending the L1 state request, then remote die responds with the L1 state response, then both sides enter L1
// remote die refuses the handshake by sending the L1 state response with PMNAK 
task l1_virtual_sequence_rsp_pmnak::body();
    super.body();
        tx_start_handshake_seq.start(ltsm_rdi_seqr);
        tx_refuse_l1_seq.start(tx_fsm_sb_seqr);  
endtask : body

