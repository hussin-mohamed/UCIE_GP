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

class mbtrain_success extends virtual_sequence_base;
    `uvm_object_utils(mbtrain_success)
    mbtrain_valvref_success                  valvref;
    mbtrain_datavref_success                 datavref;
    mbtrain_datavref_speedidle_tx            speedidle_start;
    mbtrain_speedidle_tx_endhandshake        speedidle_tx_end;
    mbtrain_speedidle_rx_endhandshake        speedidle_rx_end;
    mbtrain_txselfcal_calibration_tx         txselfcal_start_tx;
    mbtrain_txselfcal_tx_endhandshake        txselfcal_end_tx;
    mbtrain_txselfcal_rx_endhandshake        txselfcal_rx_end;
    mbtrain_rxclkcal_success                 rxclkcal;
    mbtrain_valtraincenter_success           valtraincenter;
    mbtrain_valtrainvref_success             valtrainvref;
    mbtrain_dtc1_success                     dtc1;
    mbtrain_datatrainvref_success            datatrainvref;
    mbtrain_dtc2_success                     dtc2;
    mbtrain_rxdeskew_success                 rxdeskew;
    mbtrain_linkspeed_success                linkspeed;
    controllers_done                         done;
    tx_done                                  done_tx;
    rx_done                                  done_rx;

    // Function: new
    //
    // Creates a new virtual_sequence instance with the given name.

    extern function new(string name = "mbtrain_success");


    // Task: pre_body
    //
    // Creates instances of child reactive sequences before body execution.

    extern task pre_body();


    // Task: body
    //
    // Retrieves sequencer handles via base class, then starts both reactive
    // sequences on their respective sequencers sequentially.

    extern task body();

endclass : mbtrain_success


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

function mbtrain_success::new(string name = "mbtrain_success");
    super.new(name);
endfunction : new

// pre_body
// --------

task mbtrain_success::pre_body();
    // tx sequences
    valvref=mbtrain_valvref_success::type_id::create("valvref");
    datavref=mbtrain_datavref_success::type_id::create("datavref");
    speedidle_start=mbtrain_datavref_speedidle_tx::type_id::create("speedidle_start");// tx sequencer
    speedidle_tx_end=mbtrain_speedidle_tx_endhandshake::type_id::create("speedidle_tx_end");// tx sequencer
    speedidle_rx_end=mbtrain_speedidle_rx_endhandshake::type_id::create("speedidle_rx_end");// rx sequencer
    txselfcal_start_tx=mbtrain_txselfcal_calibration_tx::type_id::create("txselfcal_start_tx");// tx sequencer
    txselfcal_end_tx=mbtrain_txselfcal_tx_endhandshake::type_id::create("txselfcal_end_tx");// tx sequencer
    txselfcal_rx_end=mbtrain_txselfcal_rx_endhandshake::type_id::create("txselfcal_rx_end");// rx sequencer
    rxclkcal=mbtrain_rxclkcal_success::type_id::create("rxclkcal");
    valtraincenter=mbtrain_valtraincenter_success::type_id::create("valtraincenter");
    valtrainvref=mbtrain_valtrainvref_success::type_id::create("valtrainvref");
    dtc1=mbtrain_dtc1_success::type_id::create("dtc1");
    datatrainvref=mbtrain_datatrainvref_success::type_id::create("datatrainvref");
    dtc2=mbtrain_dtc2_success::type_id::create("dtc2");
    rxdeskew=mbtrain_rxdeskew_success::type_id::create("rxdeskew");
    linkspeed=mbtrain_linkspeed_success::type_id::create("linkspeed");
    done=controllers_done::type_id::create("done");
    done_tx=tx_done::type_id::create("done_tx");
    done_rx=rx_done::type_id::create("done_rx");
endtask

// body
// ----

task mbtrain_success::body();
    super.body();
    valvref.start(v_seqr);
    datavref.start(v_seqr);
    speedidle_start.start(tx_fsm_sb_seqr);
    fork
        // tx thread
        begin
            //done_tx.start(tx_fsm_sb_seqr);      
        end
        // rx thread
        begin
            fork
            done.start(LTSM_ctrl_seqr);    
            speedidle_rx_end.start(rx_fsm_sb_seqr);
            join
        end
    join

    txselfcal_start_tx.start(tx_fsm_sb_seqr);

    fork
        // tx thread
        begin
            //done_tx.start(tx_fsm_sb_seqr);      
        end
        // rx thread
        begin
            fork
            done.start(LTSM_ctrl_seqr);    
            txselfcal_rx_end.start(rx_fsm_sb_seqr);
            join
        end
    join

    rxclkcal.start(v_seqr);
    valtraincenter.start(v_seqr);
    valtrainvref.start(v_seqr);
    dtc1.start(v_seqr);
    datatrainvref.start(v_seqr);
    rxdeskew.start(v_seqr);
    dtc2.start(v_seqr);
    linkspeed.start(v_seqr);
endtask : body