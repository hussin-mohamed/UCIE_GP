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

class mbtrain_linkspeed_repair_fail_8_15 extends virtual_sequence_base;
    `uvm_object_utils(mbtrain_linkspeed_repair_fail_8_15)
    mbtrain_linkspeed_tx_starthandshake       start_tx;
    mbtrain_linkspeed_tx_error_rsp            error_rsp;
    mbtrain_repair_tx_starthandshake          end_linkspeed_tx;
    mbtrain_repair_tx_applydegrade            apply_tx;
    mbtrain_repair_tx_endhandshake            end_handshake_tx;
    mbtrain_repair_txselfcal                  end_repair_tx;
    mbtrain_txselfcal_tx_endhandshake         txselfcal_end_tx;
    mbtrain_linkspeed_rx_starthandshake       start_rx;
    mbtrain_linkspeed_rx_error_req            error_req;
    mbtrain_linkspeed_rx_repair               repair_req;
    mbtrain_repair_rx_starthandshake          end_linkspeed_rx;
    mbtrain_repair_rx_degrade_0_7             apply_rx;
    mbtrain_repair_rx_endhandshake            end_handshake_rx;
    mbtrain_txselfcal_rx_endhandshake         end_repair_rx;
    mbtrain_txinit_datasweep_fail_8_15        data_sweep;
    rx_done done_rx;
    tx_done done_tx;

    // Function: new
    //
    // Creates a new virtual_sequence instance with the given name.

    extern function new(string name = "mbtrain_linkspeed_repair_fail_8_15");


    // Task: pre_body
    //
    // Creates instances of child reactive sequences before body execution.

    extern task pre_body();


    // Task: body
    //
    // Retrieves sequencer handles via base class, then starts both reactive
    // sequences on their respective sequencers sequentially.

    extern task body();

endclass : mbtrain_linkspeed_repair_fail_8_15


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

function mbtrain_linkspeed_repair_fail_8_15::new(string name = "mbtrain_linkspeed_repair_fail_8_15");
    super.new(name);
endfunction : new

// pre_body
// --------

task mbtrain_linkspeed_repair_fail_8_15::pre_body();
    // tx sequences
    start_tx=mbtrain_linkspeed_tx_starthandshake::type_id::create("start_tx");
    error_rsp=mbtrain_linkspeed_tx_error_rsp::type_id::create("error_rsp");
    end_linkspeed_tx=mbtrain_repair_tx_starthandshake::type_id::create("end_linkspeed_tx");
    apply_tx=mbtrain_repair_tx_applydegrade::type_id::create("apply_tx");
    end_handshake_tx=mbtrain_repair_tx_endhandshake::type_id::create("end_handshake_tx");
    end_repair_tx=mbtrain_repair_txselfcal::type_id::create("end_repair_tx");
    txselfcal_end_tx=mbtrain_txselfcal_tx_endhandshake::type_id::create("txselfcal_end_tx");
    done_tx=tx_done::type_id::create("txselfcal_end_tx");
    // rx sequences
    start_rx=mbtrain_linkspeed_rx_starthandshake::type_id::create("start_rx");
    error_req=mbtrain_linkspeed_rx_error_req::type_id::create("error_req");
    repair_req=mbtrain_linkspeed_rx_repair::type_id::create("repair_req");
    end_linkspeed_rx=mbtrain_repair_rx_starthandshake::type_id::create("repair_req");
    apply_rx=mbtrain_repair_rx_degrade_0_7::type_id::create("apply_rx");
    end_handshake_rx=mbtrain_repair_rx_endhandshake::type_id::create("end_handshake_rx");
    end_repair_rx=mbtrain_txselfcal_rx_endhandshake::type_id::create("txselfcal_rx_end");
    // datasweep sequence  
    data_sweep=mbtrain_txinit_datasweep_fail_8_15::type_id::create("data_sweep");
endtask

// body
// ----

task mbtrain_linkspeed_repair_fail_8_15::body();
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
            error_rsp.start(tx_fsm_sb_seqr);
        end
        // rx thread
        begin
            error_req.start(rx_fsm_sb_seqr);
        end
    join
    repair_req.start(rx_fsm_sb_seqr);
    fork
        // tx thread
        begin
            end_linkspeed_tx.start(tx_fsm_sb_seqr);
            apply_tx.start(tx_fsm_sb_seqr);
            end_handshake_tx.start(tx_fsm_sb_seqr);
        end
        // rx thread
        begin
            end_linkspeed_rx.start(rx_fsm_sb_seqr);
            apply_rx.start(rx_fsm_sb_seqr);
            end_handshake_rx.start(rx_fsm_sb_seqr);
        end
    join
    end_repair_tx.start(tx_fsm_sb_seqr);
    fork
        // tx thread
        begin
            txselfcal_end_tx.start(LTSM_ctrl_seqr);
        end
        // rx thread
        begin
            end_repair_rx.start(rx_fsm_sb_seqr);
        end
    join
    done_tx.start(tx_fsm_sb_seqr);
endtask : body