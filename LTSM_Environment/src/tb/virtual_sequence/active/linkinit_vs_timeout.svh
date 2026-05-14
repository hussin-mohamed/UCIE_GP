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


class linkinit_vs_timeout extends virtual_sequence_base;
    `uvm_object_utils(linkinit_vs_timeout)
    linkinit_tx_clk_req_handshake tx_clk_req_handshake_seq ;
    // rx sequences
    linkinit_rx_clk_req_handshake rx_clk_req_handshake_seq ;
    // common sequences
    linkinit_wake_req_handshake wake_req_handshake_seq ;
    linkinit_state_req_handshake state_req_handshake_seq ;
    //active
    active_tx_handshake start_handshake_seq;
    active_rx_handshake start_handshake_rx_seq;
    nothing_rx nothing_rx_seq;
    trainerror trainerror_seq;
    

    // Function: new
    //
    // Creates a new virtual_sequence instance with the given name.

    extern function new(string name = "linkinit_vs_timeout");


    // Task: pre_body
    //
    // Creates instances of child reactive sequences before body execution.

    extern task pre_body();


    // Task: body
    //
    // Retrieves sequencer handles via base class, then starts both reactive
    // sequences on their respective sequencers sequentially.

    extern task body();

endclass : linkinit_vs_timeout


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

function linkinit_vs_timeout::new(string name = "linkinit_vs_timeout");
    super.new(name);
endfunction : new

// pre_body
// --------

task linkinit_vs_timeout::pre_body();
    // tx sequences
    tx_clk_req_handshake_seq = linkinit_tx_clk_req_handshake::type_id::create("tx_clk_req_handshake_seq");
    start_handshake_seq = active_tx_handshake::type_id::create("start_handshake_seq");
    // rx sequences
    rx_clk_req_handshake_seq = linkinit_rx_clk_req_handshake::type_id::create("rx_clk_req_handshake_seq");
    start_handshake_rx_seq = active_rx_handshake::type_id::create("start_handshake_rx_seq");
    // common sequences
    wake_req_handshake_seq = linkinit_wake_req_handshake::type_id::create("tx_wake_req_handshake_seq");
    state_req_handshake_seq = linkinit_state_req_handshake::type_id::create("tx_state_req_handshake_seq");
    nothing_rx_seq = nothing_rx::type_id::create("nothing_rx_seq");
    trainerror_seq = trainerror::type_id::create("trainerror_seq");
    
endtask

// body
// ----

task linkinit_vs_timeout::body();
    super.body();
        //common_thread
        wake_req_handshake_seq.start(ltsm_rdi_seqr);
        state_req_handshake_seq.start(ltsm_rdi_seqr);  
        repeat(timeout/2+1)begin
        nothing_rx_seq.start(rx_fsm_sb_seqr);
        end
        `uvm_info(get_type_name(), $sformatf("Finished waiting for timeout duration: %0d cycles", timeout), UVM_MEDIUM)
       trainerror_seq.start(v_seqr);
endtask : body
