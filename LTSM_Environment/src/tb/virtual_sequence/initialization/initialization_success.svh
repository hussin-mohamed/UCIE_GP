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

class initialization_success extends virtual_sequence_base;
    `uvm_object_utils(initialization_success)
    ltsm_reset_v_sequence              reset;
    ltsm_sbinit_v_sequence             sbinit;
    ltsm_mbinit_cal_v_sequence         cal;
    ltsm_mbinit_param_v_seqeunce       param;
    ltsm_mbinit_repairclk_v_sequence   repairclk;
    ltsm_mbinit_repairval_v_sequence   repairval;
    ltsm_mbinit_repiarmb_v_sequence    repairmb;
    ltsm_mbinit_reversalmb_v_sequence  reversal;

    // Function: new
    //
    // Creates a new virtual_sequence instance with the given name.

    extern function new(string name = "initialization_success");


    // Task: pre_body
    //
    // Creates instances of child reactive sequences before body execution.

    extern task pre_body();


    // Task: body
    //
    // Retrieves sequencer handles via base class, then starts both reactive
    // sequences on their respective sequencers sequentially.

    extern task body();

endclass : initialization_success


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

function initialization_success::new(string name = "initialization_success");
    super.new(name);
endfunction : new

// pre_body
// --------

task initialization_success::pre_body();
    // tx sequences
    reset=ltsm_reset_v_sequence::type_id::create("reset");
    sbinit=ltsm_sbinit_v_sequence::type_id::create("sbinit");
    cal=ltsm_mbinit_cal_v_sequence::type_id::create("cal");
    param=ltsm_mbinit_param_v_seqeunce::type_id::create("param");
    repairclk=ltsm_mbinit_repairclk_v_sequence::type_id::create("repairclk");
    repairval=ltsm_mbinit_repairval_v_sequence::type_id::create("repairval");
    repairmb=ltsm_mbinit_repiarmb_v_sequence::type_id::create("repairmb");
    reversal=ltsm_mbinit_reversalmb_v_sequence::type_id::create("reversal");
endtask

// body
// ----

task initialization_success::body();
    super.body();
    reset.start(v_seqr);
    sbinit.start(v_seqr);
    param.start(v_seqr);
    cal.start(v_seqr);
    repairclk.start(v_seqr);
    repairval.start(v_seqr);
    reversal.start(v_seqr);
    repairmb.start(v_seqr);
endtask : body