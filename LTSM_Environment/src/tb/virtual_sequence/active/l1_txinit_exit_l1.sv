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


class l1_tx_vs_exit_l1 extends virtual_sequence_base;
    `uvm_object_utils(l1_tx_vs_exit_l1)
    l1_exit_l1    tx_exit_l1_seq ;
    // rx sequences
    l1_rx_exit_l1 rx_exit_l1_seq ;

    // Function: new
    //
    // Creates a new virtual_sequence instance with the given name.

    extern function new(string name = "l1_tx_vs_exit_l1");


    // Task: pre_body
    //
    // Creates instances of child reactive sequences before body execution.

    extern task pre_body();


    // Task: body
    //
    // Retrieves sequencer handles via base class, then starts both reactive
    // sequences on their respective sequencers sequentially.

    extern task body();

endclass : l1_tx_vs_exit_l1


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

function l1_tx_vs_exit_l1::new(string name = "l1_tx_vs_exit_l1");
    super.new(name);
endfunction : new

// pre_body
// --------

task l1_tx_vs_exit_l1::pre_body();
    // tx sequences
    tx_exit_l1_seq = l1_exit_l1::type_id::create("tx_exit_l1_seq");
    
endtask

// body
// ----
// local die request exit l1
task l1_tx_vs_exit_l1::body();
    super.body();
        tx_exit_l1_seq.start(ltsm_rdi_seqr); 
endtask : body

