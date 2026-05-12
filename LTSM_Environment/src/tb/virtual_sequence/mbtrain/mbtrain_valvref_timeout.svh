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
import shared_ltsm_pkg::*;
class mbtrain_valvref_timeout extends virtual_sequence_base;
    `uvm_object_utils(mbtrain_valvref_timeout)
    mbtrain_valvref_tx_starthandshake        start_tx;
    nothing_tx                               nothing;
    mbtrain_valvref_rx_starthandshake        start_rx;
    trainerror_rx_rsp                        error_rx_rsp;
    trainerror_tx_rsp                          error_tx_rsp;
    trainerror_rx_starthandshake               error_rx;
    trainerror_exitreset                     exit_to_reset;
    trainerror_rdiexit                       rdiexit;

    // Function: new
    //
    // Creates a new virtual_sequence instance with the given name.

    extern function new(string name = "mbtrain_valvref_timeout");


    // Task: pre_body
    //
    // Creates instances of child reactive sequences before body execution.

    extern task pre_body();


    // Task: body
    //
    // Retrieves sequencer handles via base class, then starts both reactive
    // sequences on their respective sequencers sequentially.

    extern task body();

endclass : mbtrain_valvref_timeout


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

function mbtrain_valvref_timeout::new(string name = "mbtrain_valvref_timeout");
    super.new(name);
endfunction : new

// pre_body
// --------

task mbtrain_valvref_timeout::pre_body();
    // tx sequences
    start_tx=mbtrain_valvref_tx_starthandshake::type_id::create("start_tx");
    nothing=nothing_tx::type_id::create("nothing");
    // rx sequences
    start_rx=mbtrain_valvref_rx_starthandshake::type_id::create("start_rx");
    error_tx_rsp=trainerror_tx_rsp::type_id::create("error_tx_rsp");
    error_rx=trainerror_rx_starthandshake::type_id::create("error_rx");
    error_rx_rsp=trainerror_rx_rsp::type_id::create("error_rx_rsp");
    // datasweep sequence  
    exit_to_reset=trainerror_exitreset::type_id::create("exit_to_reset"); // controller
    rdiexit=trainerror_rdiexit::type_id::create("rdiexit");
endtask

// body
// ----

task mbtrain_valvref_timeout::body();
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
    repeat(timeout/2+1)begin
        nothing.start(tx_fsm_sb_seqr);
    end
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