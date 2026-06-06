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


class linkinit_reset_rdi extends virtual_sequence_base;
    `uvm_object_utils(linkinit_reset_rdi)
    linkinit_reset reset_seq;
    

    // Function: new
    //
    // Creates a new virtual_sequence instance with the given name.

    extern function new(string name = "linkinit_reset_rdi");


    // Task: pre_body
    //
    // Creates instances of child reactive sequences before body execution.

    extern task pre_body();


    // Task: body
    //
    // Retrieves sequencer handles via base class, then starts both reactive
    // sequences on their respective sequencers sequentially.

    extern task body();

endclass : linkinit_reset_rdi


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

function linkinit_reset_rdi::new(string name = "linkinit_reset_rdi");
    super.new(name);
endfunction : new

// pre_body
// --------

task linkinit_reset_rdi::pre_body();
    // tx sequences
    reset_seq = linkinit_reset::type_id::create("reset_seq");
  
    
endtask

// body
// ----

task linkinit_reset_rdi::body();
    super.body();
       reset_seq.start(ltsm_rdi_seqr);
endtask : body
