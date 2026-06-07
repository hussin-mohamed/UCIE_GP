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

class mbtrain_txinit_datasweep_txfail_0_7_rxpass extends virtual_sequence_base;
    `uvm_object_utils(mbtrain_txinit_datasweep_txfail_0_7_rxpass)
    mbtrain_txinit_datasweep_tx_lfsrclear                  lfsr_clear_tx;
    mbtrain_txinit_datasweep_tx_pattern                    pattern_tx;
    mbtrain_txinit_datasweep_tx_result                     result_tx;
    mbtrain_txinit_datasweep_tx_result_rsp_fai_0_7   end_handshake_tx;
    mbtrain_txinit_datasweep_tx_endhandshake               end_rsp;
    mbtrain_txinit_datasweep_rx_starthandshake             start_rx;
    mbtrain_txinit_datasweep_rx_lfsrclear                  lfsr_clear_rx;
    mbtrain_txinit_datasweep_rx_pattern                    pattern_rx;
    result_success                                   result_rx;
    result_success                                         clean_error;
    mbtrain_txinit_datasweep_rx_result                     result_req;
    mbtrain_txinit_datasweep_rx_endhandshake               end_handshake_rx;
    mbtrain_linkspeed_tx_datatoclockstart                  start_tx;
    // Function: new
    //
    // Creates a new virtual_sequence instance with the given name.

    extern function new(string name = "mbtrain_txinit_datasweep_txfail_0_7_rxpass");


    // Task: pre_body
    //
    // Creates instances of child reactive sequences before body execution.

    extern task pre_body();


    // Task: body
    //
    // Retrieves sequencer handles via base class, then starts both reactive
    // sequences on their respective sequencers sequentially.

    extern task body();

endclass : mbtrain_txinit_datasweep_txfail_0_7_rxpass


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

function mbtrain_txinit_datasweep_txfail_0_7_rxpass::new(string name = "mbtrain_txinit_datasweep_txfail_0_7_rxpass");
    super.new(name);
endfunction : new

// pre_body
// --------

task mbtrain_txinit_datasweep_txfail_0_7_rxpass::pre_body();
    // tx sequences
    start_tx=mbtrain_linkspeed_tx_datatoclockstart::type_id::create("start_tx");
    lfsr_clear_tx = mbtrain_txinit_datasweep_tx_lfsrclear::type_id::create("lfsr_clear_tx");
    pattern_tx=mbtrain_txinit_datasweep_tx_pattern::type_id::create("pattern_tx");
    result_tx=mbtrain_txinit_datasweep_tx_result::type_id::create("result_tx"); // controller sequencer
    end_handshake_tx=mbtrain_txinit_datasweep_tx_result_rsp_fai_0_7::type_id::create("end_handshake_tx");
    end_rsp=mbtrain_txinit_datasweep_tx_endhandshake::type_id::create("end_rsp");
    // rx sequences
    start_rx=mbtrain_txinit_datasweep_rx_starthandshake::type_id::create("start_rx");
    lfsr_clear_rx = mbtrain_txinit_datasweep_rx_lfsrclear::type_id::create("lfsr_clear_rx");
    pattern_rx=mbtrain_txinit_datasweep_rx_pattern::type_id::create("pattern_rx");
    result_rx=result_success::type_id::create("result_rx"); // controller sequencer
    clean_error=result_success::type_id::create("clean_error"); // controller sequencer
    result_req=mbtrain_txinit_datasweep_rx_result::type_id::create("result_req");
    end_handshake_rx=mbtrain_txinit_datasweep_rx_endhandshake::type_id::create("end_handshake_rx");
endtask

// body
// ----

task mbtrain_txinit_datasweep_txfail_0_7_rxpass::body();
    super.body();
    start_tx.start(tx_fsm_sb_seqr);
    fork
        // tx thread
        begin
            lfsr_clear_tx.start(tx_fsm_sb_seqr);
            pattern_tx.start(tx_fsm_sb_seqr);
            result_tx.start(LTSM_ctrl_seqr);
            end_handshake_tx.start(tx_fsm_sb_seqr);
            end_rsp.start(tx_fsm_sb_seqr);        
        end
        // rx thread
        begin
            start_rx.start(rx_fsm_sb_seqr);
            lfsr_clear_rx.start(rx_fsm_sb_seqr);
            fork
                begin
                    pattern_rx.start(rx_fsm_sb_seqr);
                end
                begin
                    clean_error.start(LTSM_ctrl_seqr);
                end
            join
            fork
                begin
                    result_rx.start(LTSM_ctrl_seqr);
                end
                begin
                    result_req.start(rx_fsm_sb_seqr);
                end
            join
            end_handshake_rx.start(rx_fsm_sb_seqr); 
        end
    join
endtask : body