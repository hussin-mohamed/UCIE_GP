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

class mbtrain_valtraincenter_success extends virtual_sequence_base;
    `uvm_object_utils(mbtrain_valtraincenter_success)


    // Function: new
    //
    // Creates a new virtual_sequence instance with the given name.

    extern function new(string name = "mbtrain_valtraincenter_success");


    // Task: pre_body
    //
    // Creates instances of child reactive sequences before body execution.

    extern task pre_body();


    // Task: body
    //
    // Retrieves sequencer handles via base class, then starts both reactive
    // sequences on their respective sequencers sequentially.

    extern task body();

endclass : mbtrain_valtraincenter_success


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

function mbtrain_valtraincenter_success::new(string name = "mbtrain_valtraincenter_success");
    super.new(name);
endfunction : new

// pre_body
// --------

task mbtrain_valtraincenter_success::pre_body();
    // tx sequences
    start_tx=mbtrain_valtraincenter_tx_starthandshake::type_id::create("start_tx");
    end_handshake_tx=mbtrain_valtraincenter_tx_endhandshake::type_id::create("end_handshake_tx");
    // rx sequences
    start_rx=mbtrain_valtraincenter_rx_starthandshake::type_id::create("start_rx");
    end_handshake_rx=mbtrain_valtraincenter_rx_endhandshake::type_id::create("end_handshake_rx");
    // datasweep sequence  
    data_sweep=mbtrain_rxinit_datasweep_success::type_id::create("data_sweep");
endtask

// body
// ----

task mbtrain_valtraincenter_success::body();
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
    fork
        // tx thread
        begin
            end_handshake_tx.start(tx_fsm_sb_seqr);
                  
        end
        // rx thread
        begin
            end_handshake_rx.start(rx_fsm_sb_seqr);
        end
    join
endtask : body