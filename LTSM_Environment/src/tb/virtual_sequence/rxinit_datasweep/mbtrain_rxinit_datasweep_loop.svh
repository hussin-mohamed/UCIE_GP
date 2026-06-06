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

class mbtrain_rxinit_datasweep_loop extends virtual_sequence_base;
    `uvm_object_utils(mbtrain_rxinit_datasweep_loop)
    mbtrain_rxinit_datasweep_tx_starthandshake        start_tx;
    mbtrain_rxinit_datasweep_tx_lfsrclear             lfsr_clear_tx;
    mbtrain_rxinit_datasweep_tx_pattern               pattern_tx;
    mbtrain_rxinit_datasweep_tx_result                result_tx;
    mbtrain_rxinit_datasweep_tx_result_rsp_allfail    sweep_tx;
    mbtrain_rxinit_datasweep_tx_end                   end_handshake_tx;
    mbtrain_rxinit_datasweep_rx_starthandshake        start_rx;
    mbtrain_rxinit_datasweep_rx_lfsrclear             lfsr_clear_rx;
    mbtrain_rxinit_datasweep_rx_pattern               pattern_rx;
    result_all_fail                                   result_rx;
    result_success                                    clean_error;
    mbtrain_rxinit_datasweep_rx_result                result_req;
    mbtrain_rxinit_datasweep_rx_sweep                 sweep_rx;
    nothing_rx                                        end_handshake_rx;

    // Function: new
    //
    // Creates a new virtual_sequence instance with the given name.

    extern function new(string name = "mbtrain_rxinit_datasweep_loop");


    // Task: pre_body
    //
    // Creates instances of child reactive sequences before body execution.

    extern task pre_body();


    // Task: body
    //
    // Retrieves sequencer handles via base class, then starts both reactive
    // sequences on their respective sequencers sequentially.

    extern task body();

endclass : mbtrain_rxinit_datasweep_loop


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

function mbtrain_rxinit_datasweep_loop::new(string name = "mbtrain_rxinit_datasweep_loop");
    super.new(name);
endfunction : new

// pre_body
// --------

task mbtrain_rxinit_datasweep_loop::pre_body();
    // tx sequences
    start_tx=mbtrain_rxinit_datasweep_tx_starthandshake::type_id::create("start_tx");
    lfsr_clear_tx = mbtrain_rxinit_datasweep_tx_lfsrclear::type_id::create("lfsr_clear_tx");
    pattern_tx=mbtrain_rxinit_datasweep_tx_pattern::type_id::create("pattern_tx");
    result_tx=mbtrain_rxinit_datasweep_tx_result::type_id::create("result_tx"); // controller sequencer
    sweep_tx=mbtrain_rxinit_datasweep_tx_result_rsp_allfail::type_id::create("sweep_tx");
    end_handshake_tx=mbtrain_rxinit_datasweep_tx_end::type_id::create("end_handshake_tx");
    // rx sequences
    start_rx=mbtrain_rxinit_datasweep_rx_starthandshake::type_id::create("start_rx");
    lfsr_clear_rx = mbtrain_rxinit_datasweep_rx_lfsrclear::type_id::create("lfsr_clear_rx");
    pattern_rx=mbtrain_rxinit_datasweep_rx_pattern::type_id::create("pattern_rx");
    result_rx=result_all_fail::type_id::create("result_rx"); // controller sequencer
    clean_error=result_success::type_id::create("clean_error"); // controller sequencer
    result_req=mbtrain_rxinit_datasweep_rx_result::type_id::create("result_req");
    sweep_rx=mbtrain_rxinit_datasweep_rx_sweep::type_id::create("sweep_rx");
    end_handshake_rx=nothing_rx::type_id::create("end_handshake_rx");
endtask

// body
// ----

task mbtrain_rxinit_datasweep_loop::body();
    super.body();
    start_tx.start(tx_fsm_sb_seqr);
    repeat (4) begin
        fork
        // tx thread
        begin
            
            lfsr_clear_tx.start(tx_fsm_sb_seqr);
            pattern_tx.start(tx_fsm_sb_seqr);
            result_tx.start(LTSM_ctrl_seqr);
            sweep_tx.start(tx_fsm_sb_seqr);      
        end
        // rx thread
        begin
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
        end
    join
    end
    
endtask : body