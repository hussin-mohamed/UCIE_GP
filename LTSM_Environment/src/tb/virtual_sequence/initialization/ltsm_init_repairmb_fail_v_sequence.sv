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
// CLASS: ltsm_init_repairmb_fail_v_sequence
//
// this virtual sequence is used to mimic the initialization flow with degrade is not possible.
// 
// 
//
//------------------------------------------------------------------------------

class ltsm_init_repairmb_fail_v_sequence extends virtual_sequence_base;
    `uvm_object_utils(ltsm_init_repairmb_fail_v_sequence)
    ltsm_reset_v_sequence              reset;
    ltsm_sbinit_v_sequence             sbinit;
    ltsm_mbinit_cal_v_sequence         cal;
    ltsm_mbinit_param_v_seqeunce       param;
    ltsm_mbinit_repairclk_v_sequence   repairclk;
    ltsm_mbinit_repairval_v_sequence   repairval;
    ltsm_mbinit_repairmb_fail_v_sequence    repairmb;
    ltsm_mbinit_reversalmb_v_sequence  reversal;
    trainerror trainerror_vseq;

    ltsm_mbinit_repiarmb_v_sequence    repairmb_pass;

    reset_train_error_v_sequence reset_train_error;


    // Function: new
    //
    // Creates a new virtual_sequence instance with the given name.

    extern function new(string name = "ltsm_init_repairmb_fail_v_sequence");


    // Task: pre_body
    //
    // Creates instances of child reactive sequences before body execution.

    extern task pre_body();


    // Task: body
    //
    // Retrieves sequencer handles via base class, then starts both reactive
    // sequences on their respective sequencers sequentially.

    extern task body();

endclass : ltsm_init_repairmb_fail_v_sequence


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

function ltsm_init_repairmb_fail_v_sequence::new(string name = "ltsm_init_repairmb_fail_v_sequence");
    super.new(name);
endfunction : new

// pre_body
// --------

task ltsm_init_repairmb_fail_v_sequence::pre_body();
    // tx sequences
    reset=ltsm_reset_v_sequence::type_id::create("reset");
    sbinit=ltsm_sbinit_v_sequence::type_id::create("sbinit");
    cal=ltsm_mbinit_cal_v_sequence::type_id::create("cal");
    param=ltsm_mbinit_param_v_seqeunce::type_id::create("param");
    repairclk=ltsm_mbinit_repairclk_v_sequence::type_id::create("repairclk");
    repairval=ltsm_mbinit_repairval_v_sequence::type_id::create("repairval");
    repairmb=ltsm_mbinit_repairmb_fail_v_sequence::type_id::create("repairmb");
    reversal=ltsm_mbinit_reversalmb_v_sequence::type_id::create("reversal");
    trainerror_vseq = trainerror::type_id::create("trainerror_vseq");
    repairmb_pass = ltsm_mbinit_repiarmb_v_sequence::type_id::create("repairmb_pass");
    reset_train_error = reset_train_error_v_sequence::type_id::create("reset_train_error");
endtask

// body
// ----

task ltsm_init_repairmb_fail_v_sequence::body();
    super.body();
    reset.start(v_seqr);
    sbinit.start(v_seqr);
    param.start(v_seqr);
    cal.start(v_seqr);
    repairclk.start(v_seqr);
    repairval.start(v_seqr);
    reversal.start(v_seqr);
    repairmb.start(v_seqr);
    trainerror_vseq.start(v_seqr);
    // repeat the flow
    reset_train_error.start(v_seqr);
    sbinit.start(v_seqr);
    param.start(v_seqr);
    cal.start(v_seqr);
    repairclk.start(v_seqr);
    repairval.start(v_seqr);
    reversal.start(v_seqr);
    repairmb_pass.start(v_seqr);
endtask : body