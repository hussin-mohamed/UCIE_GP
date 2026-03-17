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

class mbtrain_linkspeed_phyretrain_lanepossible_txfail extends virtual_sequence_base;
    `uvm_object_utils(mbtrain_linkspeed_phyretrain_lanepossible_txfail)


    // Function: new
    //
    // Creates a new virtual_sequence instance with the given name.

    extern function new(string name = "mbtrain_linkspeed_phyretrain_lanepossible_txfail");


    // Task: pre_body
    //
    // Creates instances of child reactive sequences before body execution.

    extern task pre_body();


    // Task: body
    //
    // Retrieves sequencer handles via base class, then starts both reactive
    // sequences on their respective sequencers sequentially.

    extern task body();

endclass : mbtrain_linkspeed_phyretrain_lanepossible_txfail


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

function mbtrain_linkspeed_phyretrain_lanepossible_txfail::new(string name = "mbtrain_linkspeed_phyretrain_lanepossible_txfail");
    super.new(name);
endfunction : new

// pre_body
// --------

task mbtrain_linkspeed_phyretrain_lanepossible_txfail::pre_body();
    // tx sequences
    start_tx=mbtrain_linkspeed_tx_starthandshake::type_id::create("start_tx");
    phyretrain_req=mbtrain_linkspeed_tx_phyretrainreq::type_id::create("phyretrain_req");
    // rx sequences
    start_rx=mbtrain_linkspeed_rx_starthandshake::type_id::create("start_rx");
    error_req=mbtrain_linkspeed_rx_error_req::type_id::create("error_req");
    speeddegrade_req=mbtrain_linkspeed_rx_speeddegrade::type_id::create("speeddegrade_req");
    end_state=mbtrain_linkspeed_phyretrain_rx::type_id::create("end_handshake_tx");
    // datasweep sequence  
    data_sweep=mbtrain_txinit_datasweep_txpass_rxallfail::type_id::create("data_sweep");
endtask

// body
// ----

task mbtrain_linkspeed_phyretrain_lanepossible_txfail::body();
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
    error_req.start(rx_fsm_sb_seqr);
    phyretrain_req.start(tx_fsm_sb_seqr);
    end_state.start(rx_fsm_sb_seqr);
endtask : body