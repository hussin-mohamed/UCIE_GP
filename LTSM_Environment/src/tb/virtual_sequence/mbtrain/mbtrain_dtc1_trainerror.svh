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
// CLASS: virtual_sequence
//
// The virtual_sequence class extends virtual_sequence_base to implement
// coordinated execution of reactive APB sequences on multiple sequencers,
// creating and starting child sequences in sequence.
//
//------------------------------------------------------------------------------

class mbtrain_dtc1_trainerror extends virtual_sequence_base;
    `uvm_object_utils(mbtrain_dtc1_trainerror)
    mbtrain_dtc1_tx_starthandshake            start_tx;
    trainerror_tx_rsp                         error_tx_rsp;
    mbtrain_dtc1_rx_starthandshake            start_rx;
    trainerror_rx_starthandshake              error_rx;
    trainerror_rx_rsp                         error_rx_rsp;
    trainerror_exitreset                      exit_to_reset;
    mbtrain_rxinit_datasweep_success          data_sweep;
    trainerror_rdiexit                       rdiexit;

    // Function: new
    //
    // Creates a new virtual_sequence instance with the given name.

    extern function new(string name = "mbtrain_dtc1_trainerror");


    // Task: pre_body
    //
    // Creates instances of child reactive sequences before body execution.

    extern task pre_body();


    // Task: body
    //
    // Retrieves sequencer handles via base class, then starts both reactive
    // sequences on their respective sequencers sequentially.

    extern task body();

endclass : mbtrain_dtc1_trainerror


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

function mbtrain_dtc1_trainerror::new(string name = "mbtrain_dtc1_trainerror");
    super.new(name);
endfunction : new

// pre_body
// --------

task mbtrain_dtc1_trainerror::pre_body();
    // tx sequences
    start_tx=mbtrain_dtc1_tx_starthandshake::type_id::create("start_tx");
    error_tx_rsp=trainerror_tx_rsp::type_id::create("error_tx_rsp");
    // rx sequences
    start_rx=mbtrain_dtc1_rx_starthandshake::type_id::create("start_rx");
    error_rx=trainerror_rx_starthandshake::type_id::create("start_rx");
    error_rx_rsp=trainerror_rx_rsp::type_id::create("error_tx_rsp");
    // datasweep sequence  
    exit_to_reset=trainerror_exitreset::type_id::create("exit_to_reset"); // controller
    data_sweep=mbtrain_rxinit_datasweep_success::type_id::create("data_sweep"); // virtualsequencer
    rdiexit=trainerror_rdiexit::type_id::create("rdiexit");
endtask

// body
// ----

task mbtrain_dtc1_trainerror::body();
    super.body();
    fork
        // tx thread
        begin
            start_tx.start(tx_fsm_sb_seqr);
                  
        end
        // rx thread
        begin
            start_rx.start(rx_fsm_sb_seqr);
        end
    join
    data_sweep.start(v_seqr);
    error_rx.start(rx_fsm_sb_seqr);
    fork
        // tx thread
        begin
            error_tx_rsp.start(tx_fsm_sb_seqr);
        end
        // rx thread
        begin
            error_rx_rsp.start(rx_fsm_sb_seqr);
        end
    join
    fork
        begin
            exit_to_reset.start(LTSM_ctrl_seqr);
        end
        begin
            rdiexit.start(ltsm_rdi_seqr);
        end
    join
    
endtask : body